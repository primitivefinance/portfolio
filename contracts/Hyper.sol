// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {UD60x18, fromUD60x18, toUD60x18, wrap as wrapUD60x18, ZERO as zeroUD60x18, HALF_UNIT as halfUD60x18} from "@prb/math/UD60x18.sol";

import {IHyper} from "./interfaces/IHyper.sol";

import "./libraries/BitMath.sol" as BitMath;
import "./libraries/BrainMath.sol" as BrainMath;

import {Epoch} from "./libraries/Epoch.sol";
import {getPoolId, getPoolSnapshot, PoolId, Pool, PoolToken, PoolSnapshot, Bid} from "./libraries/Pool.sol";
import {getSlotId, getSlotSnapshot, SlotId, Slot, SlotSnapshot} from "./libraries/Slot.sol";
import {getPositionId, getPerLiquiditiesInside, getEarnings, PerLiquiditiesInside, Earnings, PositionId, Position} from "./libraries/Position.sol";

// TODO:
// - Reentrancy guard
// - ETH / WETH
// - check the types
// - price limit on swap
// - fix amount out
// - slot index spacing

contract Hyper is IHyper, Test {
    address public immutable AUCTION_SETTLEMENT_TOKEN;
    uint256 public immutable AUCTION_LENGTH;

    UD60x18 public immutable PUBLIC_SWAP_FEE;
    UD60x18 public immutable AUCTION_FEE;

    Epoch public epoch;

    mapping(PoolId => Pool) public pools;
    mapping(SlotId => Slot) public slots;
    mapping(PositionId => Position) public positions;

    mapping(PoolId => mapping(int16 => uint256)) public bitmaps;
    mapping(PoolId => mapping(uint256 => Bid)) public bids;
    mapping(PoolId => mapping(uint256 => PoolSnapshot)) public poolSnapshots;

    mapping(SlotId => mapping(uint256 => SlotSnapshot)) public slotSnapshots;

    /// @notice Internal token balances
    /// user => token => balance
    mapping(address => mapping(address => uint256)) public internalBalances;

    address public auctionFeeCollector;

    constructor(
        uint256 startTime,
        address _auctionSettlementToken,
        uint256 _epochLength,
        uint256 _auctionLength,
        UD60x18 _publicSwapFee,
        UD60x18 _auctionFee
    ) {
        auctionFeeCollector = msg.sender;

        require(startTime > block.timestamp && _epochLength > 0);
        epoch = Epoch({id: 0, endTime: startTime, length: _epochLength});

        require(_auctionSettlementToken != address(0));
        AUCTION_SETTLEMENT_TOKEN = _auctionSettlementToken;

        require(_auctionLength > 0 && _auctionLength < (_epochLength / 2));
        AUCTION_LENGTH = _auctionLength;

        require(_publicSwapFee.gt(zeroUD60x18) && _publicSwapFee.lt(halfUD60x18));
        PUBLIC_SWAP_FEE = _publicSwapFee;

        require(_auctionFee.gt(zeroUD60x18) && _auctionFee.lt(halfUD60x18));
        AUCTION_FEE = _auctionFee;
    }

    modifier started() {
        if (epoch.id == 0) revert IHyper.HyperNotStartedError();
        _;
    }

    /// @notice Adds `amount` of `token` to `to` internal balance
    function fund(
        address to,
        address token,
        uint256 amount
    ) public started {
        SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
        internalBalances[to][token] += amount;
        emit Fund(to, token, amount);
    }

    /// @notice Transfers `amount` of `token` from the sender internal balance to `to`
    function withdraw(
        address to,
        address token,
        uint256 amount
    ) public started {
        require(internalBalances[msg.sender][token] >= amount);
        internalBalances[msg.sender][token] -= amount;
        SafeTransferLib.safeTransferFrom(ERC20(token), address(this), to, amount);
        emit Withdraw(to, token, amount);
    }

    function syncEpoch() internal {
        if (block.timestamp >= epoch.endTime) {
            uint256 epochsPassed = (block.timestamp - epoch.endTime) / epoch.length;
            epoch.id += (1 + epochsPassed);
            epoch.endTime += (epoch.length + (epochsPassed * epoch.length));
            emit SetEpoch(epoch.id, epoch.endTime);
        }
    }

    function syncPool(Pool storage pool, Epoch memory readEpoch) internal {
        uint256 epochsPassed = readEpoch.getEpochsPassed(pool.lastUpdatedTimestamp);
        if (epochsPassed > 0) {
            uint256 lastUpdatedEpochId = readEpoch.getLastUpdatedId(epochsPassed);
            // distribute remaining proceeds in lastUpdatedEpochId
            if (pool.maturedLiquidity > 0) {
                UD60x18 proceedsPerSecond = bids[pool.id][lastUpdatedEpochId].proceedsPerSecond;
                if (!proceedsPerSecond.isZero()) {
                    // calculate seconds remaining in lastUpdatedEpochId
                    uint256 timeToTransition = epoch.getTimeToTransition(epochsPassed, pool.lastUpdatedTimestamp);
                    // multiple seconds remaining by proceedsPerSecond in lastUpdatedEpochId and add to pool
                    pool.proceedsPerLiquidity = pool.proceedsPerLiquidity.add(
                        proceedsPerSecond.mul(toUD60x18(timeToTransition)).div(toUD60x18(pool.maturedLiquidity))
                    );
                }
            }
            // save pool snapshot for lastUpdatedEpochId
            poolSnapshots[pool.id][lastUpdatedEpochId] = getPoolSnapshot(pool);
            // update the pool's liquidity due to the transition
            if (pool.pendingLiquidity > 0) {
                pool.maturedLiquidity += uint256(pool.pendingLiquidity);
            } else {
                pool.maturedLiquidity -= BrainMath.abs(pool.pendingLiquidity);
            }
            pool.swapLiquidity = pool.maturedLiquidity;
            pool.pendingLiquidity = int256(0);
            // auction fees only accrue after an epoch transition
            internalBalances[auctionFeeCollector][AUCTION_SETTLEMENT_TOKEN] += bids[pool.id][lastUpdatedEpochId].fee;
            if (epochsPassed > 1) {
                // update proceeds per liquidity distributed for next epoch if needed
                if (pool.maturedLiquidity > 0) {
                    UD60x18 proceedsPerSecond = bids[pool.id][lastUpdatedEpochId + 1].proceedsPerSecond;
                    if (!proceedsPerSecond.isZero()) {
                        pool.proceedsPerLiquidity = pool.proceedsPerLiquidity.add(
                            bids[pool.id][lastUpdatedEpochId + 1].proceedsPerSecond.mul(toUD60x18(epoch.length)).div(
                                toUD60x18(pool.maturedLiquidity)
                            )
                        );
                    }
                }
                // add auction fees
                internalBalances[auctionFeeCollector][AUCTION_SETTLEMENT_TOKEN] += bids[pool.id][lastUpdatedEpochId + 1]
                    .fee;
            }
        }
        // add proceeds for time passed in the current epoch
        if (pool.maturedLiquidity > 0) {
            uint256 timePassedInCurrentEpoch = readEpoch.getTimePassedInCurrentEpoch(pool.lastUpdatedTimestamp);
            if (timePassedInCurrentEpoch > 0) {
                UD60x18 proceedsPerSecond = bids[pool.id][readEpoch.id].proceedsPerSecond;
                if (!proceedsPerSecond.isZero()) {
                    pool.proceedsPerLiquidity = pool.proceedsPerLiquidity.add(
                        proceedsPerSecond.mul(toUD60x18(timePassedInCurrentEpoch)).div(toUD60x18(pool.maturedLiquidity))
                    );
                }
            }
        }
        pool.lastUpdatedTimestamp = block.timestamp;
    }

    function syncSlot(
        PoolId poolId,
        Slot storage slot,
        int128 slotIndex,
        Epoch memory readEpoch
    ) internal {
        uint256 epochsPassed = readEpoch.getEpochsPassed(slot.lastUpdatedTimestamp);
        if (epochsPassed > 0) {
            // update liquidity deltas for epoch transition
            slot.maturedLiquidityDelta += slot.pendingLiquidityDelta;
            slot.swapLiquidityDelta = slot.maturedLiquidityDelta;
            slot.pendingLiquidityDelta = int256(0);

            // update liquidity gross for epoch transition
            if (slot.pendingLiquidityGross < 0) {
                slot.liquidityGross -= BrainMath.abs(slot.pendingLiquidityGross);
                if (slot.liquidityGross == 0) {
                    (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(int24(slotIndex));
                    bitmaps[poolId][chunk] = BitMath.flip(bitmaps[poolId][chunk], bit);
                    delete slots[slot.id];
                    return;
                }
            }
            slot.pendingLiquidityGross = int256(0);
        }
        slot.lastUpdatedTimestamp = block.timestamp;
    }

    function syncPosition(
        Position storage position,
        Pool memory pool,
        Slot memory lowerSlot,
        Slot memory upperSlot,
        Epoch memory readEpoch
    ) internal {
        Earnings memory earnings;

        uint256 epochsPassed = readEpoch.getEpochsPassed(position.lastUpdatedTimestamp);
        if (epochsPassed > 0) {
            if (position.pendingLiquidity != 0) {
                uint256 lastUpdatedEpochId = readEpoch.getLastUpdatedId(epochsPassed);
                PoolSnapshot memory poolSnapshot = poolSnapshots[pool.id][lastUpdatedEpochId];
                {
                    // get per liquidities inside through end of last update epoch
                    PerLiquiditiesInside memory perLiquiditiesInside = getPerLiquiditiesInside(
                        position,
                        poolSnapshot,
                        slotSnapshots[lowerSlot.id][lastUpdatedEpochId],
                        slotSnapshots[upperSlot.id][lastUpdatedEpochId]
                    );
                    // get earnings from growth in per liquidities
                    (earnings.amountA, earnings.amountB, earnings.amountC) = getEarnings(
                        position,
                        perLiquiditiesInside.proceedsPerLiquidityInside,
                        perLiquiditiesInside.feesAPerLiquidityInside,
                        perLiquiditiesInside.feesBPerLiquidityInside
                    );
                    // update per liquidities inside
                    position.proceedsPerLiquidityInsideLast = perLiquiditiesInside.proceedsPerLiquidityInside;
                    position.feesAPerLiquidityInsideLast = perLiquiditiesInside.feesAPerLiquidityInside;
                    position.feesBPerLiquidityInsideLast = perLiquiditiesInside.feesBPerLiquidityInside;
                }
                // if liquidity was kicked out, add the underlying tokens
                if (position.pendingLiquidity < 0) {
                    (uint256 kickedOutTokenA, uint256 kickedOutTokenB) = BrainMath.calculateLiquidityUnderlying(
                        BrainMath.abs(position.pendingLiquidity),
                        poolSnapshot.sqrtPrice,
                        position.lowerSlotIndex,
                        position.upperSlotIndex,
                        BrainMath.Rounding.Down
                    );
                    earnings.amountA += kickedOutTokenA;
                    earnings.amountB += kickedOutTokenB;
                    // update position matured liquidity
                    position.maturedLiquidity -= BrainMath.abs(position.pendingLiquidity);
                } else {
                    position.maturedLiquidity += uint256(position.pendingLiquidity);
                }
                // finally update swap liquidity and pending liquidity
                position.swapLiquidity = position.maturedLiquidity;
                position.pendingLiquidity = int256(0);
            }
        }
        {
            // get per liquidities inside through end of last update epoch
            PerLiquiditiesInside memory perLiquiditiesInside = getPerLiquiditiesInside(
                position,
                getPoolSnapshot(pool),
                getSlotSnapshot(lowerSlot),
                getSlotSnapshot(upperSlot)
            );
            (uint256 earningsA, uint256 earningsB, uint256 earningsC) = getEarnings(
                position,
                perLiquiditiesInside.proceedsPerLiquidityInside,
                perLiquiditiesInside.feesAPerLiquidityInside,
                perLiquiditiesInside.feesBPerLiquidityInside
            );
            earnings.amountA += earningsA;
            earnings.amountB += earningsB;
            earnings.amountC += earningsC;
            // update per liquidities inside
            position.proceedsPerLiquidityInsideLast = perLiquiditiesInside.proceedsPerLiquidityInside;
            position.feesAPerLiquidityInsideLast = perLiquiditiesInside.feesAPerLiquidityInside;
            position.feesBPerLiquidityInsideLast = perLiquiditiesInside.feesBPerLiquidityInside;
        }
        // update internal balances
        if (earnings.amountA != 0) internalBalances[msg.sender][pool.tokenA] += earnings.amountA;
        if (earnings.amountB != 0) internalBalances[msg.sender][pool.tokenB] += earnings.amountB;
        if (earnings.amountC != 0) internalBalances[msg.sender][AUCTION_SETTLEMENT_TOKEN] += earnings.amountC;

        position.lastUpdatedTimestamp = block.timestamp;
    }

    function start() public {
        require(epoch.id == 0 && block.timestamp >= epoch.endTime, "Hyper not started yet.");
        syncEpoch();
    }

    function activatePool(
        address tokenA,
        address tokenB,
        UD60x18 sqrtPrice
    ) public started {
        syncEpoch();

        PoolId poolId = getPoolId(tokenA, tokenB);
        Pool storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp != 0) revert IHyper.PoolAlreadyInitializedError();
        pool.id = poolId;
        pool.tokenA = tokenA;
        pool.tokenB = tokenB;
        pool.sqrtPrice = sqrtPrice;
        pool.slotIndex = BrainMath.getSlotAtSqrtPrice(sqrtPrice);
        pool.lastUpdatedTimestamp = block.timestamp;
        emit ActivatePool(tokenA, tokenB);
    }

    function updateLiquidity(
        PoolId poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        int256 amount
    ) public started {
        if (lowerSlotIndex >= upperSlotIndex) revert IHyper.PositionInvalidRangeError();
        if (amount == 0) revert IHyper.AmountZeroError();

        Pool storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert IHyper.PoolUninitializedError();

        syncEpoch();
        syncPool(pool, epoch);

        SlotId lowerSlotId;
        Slot storage lowerSlot;
        {
            lowerSlotId = getSlotId(poolId, int24(lowerSlotIndex));
            lowerSlot = slots[lowerSlotId];
            syncSlot(poolId, lowerSlot, lowerSlotIndex, epoch);
        }

        SlotId upperSlotId;
        Slot storage upperSlot;
        {
            upperSlotId = getSlotId(poolId, int24(upperSlotIndex));
            upperSlot = slots[upperSlotId];
            syncSlot(poolId, upperSlot, upperSlotIndex, epoch);
        }

        Position storage position;
        {
            position = positions[getPositionId(msg.sender, poolId, lowerSlotIndex, upperSlotIndex)];
        }

        if (position.lastUpdatedTimestamp == 0) {
            if (amount < 0) revert IHyper.RemoveLiquidityUninitializedError();
            position.lowerSlotIndex = lowerSlotIndex;
            position.upperSlotIndex = upperSlotIndex;
            position.lastUpdatedTimestamp = block.timestamp;
        } else {
            syncPosition(position, pool, lowerSlot, upperSlot, epoch);
        }

        if (amount > 0) {
            _addLiquidity(pool, lowerSlot, upperSlot, position, uint256(amount));
        } else {
            // save slot snapshots
            slotSnapshots[lowerSlot.id][epoch.id] = getSlotSnapshot(lowerSlot);
            slotSnapshots[upperSlot.id][epoch.id] = getSlotSnapshot(upperSlot);
            // remove liquidity
            _removeLiquidity(pool, lowerSlot, upperSlot, position, BrainMath.abs(amount));
        }

        emit UpdateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, amount);
    }

    function _addLiquidity(
        Pool storage pool,
        Slot storage lowerSlot,
        Slot storage upperSlot,
        Position storage position,
        uint256 amount
    ) internal {
        uint256 addAmountLeft = amount;

        uint256 amountA;
        uint256 amountB;

        // use negative pending liquidity first
        if (position.pendingLiquidity < 0) {
            uint256 addedPending = BrainMath.abs(position.pendingLiquidity) >= amount
                ? amount
                : BrainMath.abs(position.pendingLiquidity);

            position.pendingLiquidity += int256(addedPending);

            lowerSlot.pendingLiquidityDelta += int256(addedPending);
            upperSlot.pendingLiquidityDelta -= int256(addedPending);

            lowerSlot.pendingLiquidityGross += int256(addedPending);
            upperSlot.pendingLiquidityGross += int256(addedPending);

            if (position.lowerSlotIndex <= pool.slotIndex && pool.slotIndex < position.upperSlotIndex) {
                pool.pendingLiquidity += int256(addedPending);
            }

            addAmountLeft -= addedPending;
        }

        if (addAmountLeft > 0) {
            position.swapLiquidity += addAmountLeft;
            position.pendingLiquidity += int256(addAmountLeft);

            lowerSlot.swapLiquidityDelta += int256(addAmountLeft);
            lowerSlot.pendingLiquidityDelta += int256(addAmountLeft);
            if (lowerSlot.liquidityGross == 0) {
                // flip slot in bitmap
                (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(int24(position.lowerSlotIndex));
                bitmaps[pool.id][chunk] = BitMath.flip(bitmaps[pool.id][chunk], bit);
                // initialize per liquidity outside values
                if (pool.slotIndex >= position.lowerSlotIndex) {
                    lowerSlot.proceedsPerLiquidityOutside = pool.proceedsPerLiquidity;
                    lowerSlot.feesAPerLiquidityOutside = pool.feesAPerLiquidity;
                    lowerSlot.feesBPerLiquidityOutside = pool.feesBPerLiquidity;
                }
                lowerSlot.liquidityGross += uint256(addAmountLeft);
            }

            upperSlot.swapLiquidityDelta -= int256(addAmountLeft);
            upperSlot.pendingLiquidityDelta -= int256(addAmountLeft);
            if (upperSlot.liquidityGross == 0) {
                // flip slot in bitmap
                (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(int24(position.upperSlotIndex));
                bitmaps[pool.id][chunk] = BitMath.flip(bitmaps[pool.id][chunk], bit);
                // initialize per liquidity outside values
                if (pool.slotIndex >= position.upperSlotIndex) {
                    upperSlot.proceedsPerLiquidityOutside = pool.proceedsPerLiquidity;
                    upperSlot.feesAPerLiquidityOutside = pool.feesAPerLiquidity;
                    upperSlot.feesBPerLiquidityOutside = pool.feesBPerLiquidity;
                }
                upperSlot.liquidityGross += uint256(addAmountLeft);
            }
            (amountA, amountB) = BrainMath.calculateLiquidityUnderlying(
                addAmountLeft,
                pool.sqrtPrice,
                position.lowerSlotIndex,
                position.upperSlotIndex,
                BrainMath.Rounding.Up
            );
            if (position.lowerSlotIndex <= pool.slotIndex && position.upperSlotIndex > pool.slotIndex) {
                pool.swapLiquidity += addAmountLeft;
                pool.pendingLiquidity += int256(addAmountLeft);
            }
        }

        if (amountA != 0) settleToken(pool.tokenA, amountA);
        if (amountB != 0) settleToken(pool.tokenB, amountB);
    }

    function _removeLiquidity(
        Pool storage pool,
        Slot storage lowerSlot,
        Slot storage upperSlot,
        Position storage position,
        uint256 amount
    ) internal {
        uint256 removeAmountLeft = amount;

        uint256 amountA;
        uint256 amountB;

        // remove positive pending liquidity immediately
        if (position.pendingLiquidity > 0) {
            if (position.swapLiquidity < amount) revert IHyper.RemovePendingLiquidityError();

            uint256 removedPending = uint256(position.pendingLiquidity) >= amount
                ? amount
                : uint256(position.pendingLiquidity);

            position.swapLiquidity -= removedPending;
            position.pendingLiquidity -= int256(removedPending);

            lowerSlot.swapLiquidityDelta -= int256(removedPending);
            lowerSlot.pendingLiquidityDelta -= int256(removedPending);
            lowerSlot.liquidityGross -= removedPending;

            if (lowerSlot.liquidityGross == 0) {
                (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(int24(position.lowerSlotIndex));
                bitmaps[pool.id][chunk] = BitMath.flip(bitmaps[pool.id][chunk], bit);
                delete slots[lowerSlot.id];
            }

            upperSlot.swapLiquidityDelta += int256(removedPending);
            upperSlot.pendingLiquidityDelta += int256(removedPending);
            upperSlot.liquidityGross -= removedPending;

            if (upperSlot.liquidityGross == 0) {
                (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(int24(position.upperSlotIndex));
                bitmaps[pool.id][chunk] = BitMath.flip(bitmaps[pool.id][chunk], bit);
                delete slots[upperSlot.id];
            }

            // credit tokens owed to the position immediately
            (amountA, amountB) = BrainMath.calculateLiquidityUnderlying(
                removedPending,
                pool.sqrtPrice,
                position.lowerSlotIndex,
                position.upperSlotIndex,
                BrainMath.Rounding.Down
            );

            if (position.lowerSlotIndex <= pool.slotIndex && position.upperSlotIndex > pool.slotIndex) {
                pool.swapLiquidity -= removedPending;
                pool.pendingLiquidity -= int256(removedPending);
            }

            removeAmountLeft -= removedPending;
        } else {
            if (position.swapLiquidity - BrainMath.abs(position.pendingLiquidity) < amount)
                revert IHyper.RemoveLiquidityError();
        }

        // schedule removeAmountLeft to be removed from remaining liquidity
        if (removeAmountLeft > 0) {
            position.pendingLiquidity -= int256(removeAmountLeft);

            lowerSlot.pendingLiquidityDelta -= int256(removeAmountLeft);
            upperSlot.pendingLiquidityDelta += int256(removeAmountLeft);

            lowerSlot.pendingLiquidityGross -= int256(removeAmountLeft);
            upperSlot.pendingLiquidityGross -= int256(removeAmountLeft);

            if (position.lowerSlotIndex <= pool.slotIndex && pool.slotIndex < position.upperSlotIndex) {
                pool.pendingLiquidity -= int256(removeAmountLeft);
            }
        }

        // add to internal balance
        if (amountA != 0) internalBalances[msg.sender][pool.tokenA] += amountA;
        if (amountB != 0) internalBalances[msg.sender][pool.tokenB] += amountB;
    }

    struct SwapDetails {
        UD60x18 feeTier;
        uint256 remaining;
        uint256 amountOut;
        int128 slotIndex;
        UD60x18 sqrtPrice;
        uint256 swapLiquidity;
        uint256 maturedLiquidity;
        int256 pendingLiquidity;
        UD60x18 feesPerLiquidity;
        bool nextSlotInitialized;
        int128 nextSlotIndex;
        UD60x18 nextSqrtPrice;
    }

    function swap(
        PoolId poolId,
        PoolToken tokenIn,
        uint256 amountIn
    ) public started {
        if (amountIn == 0) revert IHyper.AmountZeroError();

        Pool storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert IHyper.PoolNotInitializedError();

        syncEpoch();
        syncPool(pool, epoch);

        SwapDetails memory swapDetails = SwapDetails({
            feeTier: msg.sender == bids[poolId][epoch.id].swapper ? wrapUD60x18(0) : PUBLIC_SWAP_FEE,
            remaining: amountIn,
            amountOut: 0,
            slotIndex: pool.slotIndex,
            sqrtPrice: pool.sqrtPrice,
            swapLiquidity: pool.swapLiquidity,
            maturedLiquidity: pool.maturedLiquidity,
            pendingLiquidity: pool.pendingLiquidity,
            feesPerLiquidity: tokenIn == PoolToken.A ? pool.feesAPerLiquidity : pool.feesBPerLiquidity,
            nextSlotInitialized: false,
            nextSlotIndex: 0,
            nextSqrtPrice: wrapUD60x18(0)
        });

        while (swapDetails.remaining > 0) {
            {
                // Get the next slot or the border of a bitmap
                (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(int24(swapDetails.slotIndex));
                (bool hasNextSlot, uint8 nextSlotBit) = BitMath.findNextSlotWithinChunk(
                    bitmaps[poolId][chunk],
                    bit,
                    tokenIn == PoolToken.A ? BitMath.SearchDirection.Left : BitMath.SearchDirection.Right
                );
                swapDetails.nextSlotInitialized = hasNextSlot;
                swapDetails.nextSlotIndex = int128(chunk) * 256 + int8(nextSlotBit);
                swapDetails.nextSqrtPrice = BrainMath.getSqrtPriceAtSlot(swapDetails.nextSlotIndex);
            }
            uint256 remainingFeeAmount = fromUD60x18(swapDetails.feeTier.mul(toUD60x18(swapDetails.remaining)).ceil());
            uint256 maxToDelta = tokenIn == PoolToken.A
                ? BrainMath.getDeltaAToNextPrice(
                    swapDetails.sqrtPrice,
                    swapDetails.nextSqrtPrice,
                    swapDetails.swapLiquidity,
                    BrainMath.Rounding.Up
                )
                : BrainMath.getDeltaBToNextPrice(
                    swapDetails.sqrtPrice,
                    swapDetails.nextSqrtPrice,
                    swapDetails.swapLiquidity,
                    BrainMath.Rounding.Up
                );
            if (swapDetails.remaining < maxToDelta + remainingFeeAmount) {
                // remove fees from remaining amount
                swapDetails.remaining -= remainingFeeAmount;
                // save fees per liquidity
                swapDetails.feesPerLiquidity = swapDetails.feesPerLiquidity.add(
                    toUD60x18(remainingFeeAmount).div(toUD60x18(swapDetails.swapLiquidity))
                );
                // update price and amount out after swapping remaining amount
                UD60x18 targetPrice = tokenIn == PoolToken.A
                    ? BrainMath.getTargetPriceUsingDeltaA(
                        swapDetails.sqrtPrice,
                        swapDetails.swapLiquidity,
                        swapDetails.remaining
                    )
                    : BrainMath.getTargetPriceUsingDeltaB(
                        swapDetails.sqrtPrice,
                        swapDetails.swapLiquidity,
                        swapDetails.remaining
                    );
                swapDetails.amountOut += tokenIn == PoolToken.A
                    ? BrainMath.getDeltaBToNextPrice(
                        swapDetails.sqrtPrice,
                        targetPrice,
                        swapDetails.swapLiquidity,
                        BrainMath.Rounding.Down
                    )
                    : BrainMath.getDeltaAToNextPrice(
                        swapDetails.sqrtPrice,
                        targetPrice,
                        swapDetails.swapLiquidity,
                        BrainMath.Rounding.Down
                    );
                swapDetails.remaining = 0;
                swapDetails.sqrtPrice = targetPrice;
                swapDetails.slotIndex = BrainMath.getSlotAtSqrtPrice(swapDetails.sqrtPrice);
            } else {
                // swapping maxToDelta, only take fees on this amount
                uint256 maxFeeAmount = fromUD60x18(swapDetails.feeTier.mul(toUD60x18(maxToDelta)).ceil());
                // remove fees and swap amount
                swapDetails.remaining -= maxFeeAmount + maxToDelta;
                // update fees per liquidity
                swapDetails.feesPerLiquidity = swapDetails.feesPerLiquidity.add(
                    toUD60x18(maxFeeAmount).div(toUD60x18(swapDetails.swapLiquidity))
                );
                // update price and amount out after swapping
                swapDetails.amountOut += tokenIn == PoolToken.A
                    ? BrainMath.getDeltaBToNextPrice(
                        swapDetails.sqrtPrice,
                        swapDetails.nextSqrtPrice,
                        swapDetails.swapLiquidity,
                        BrainMath.Rounding.Down
                    )
                    : BrainMath.getDeltaAToNextPrice(
                        swapDetails.sqrtPrice,
                        swapDetails.nextSqrtPrice,
                        swapDetails.swapLiquidity,
                        BrainMath.Rounding.Down
                    );
                swapDetails.sqrtPrice = swapDetails.nextSqrtPrice;
                swapDetails.slotIndex = swapDetails.nextSlotIndex;
                // cross the next initialized slot
                if (swapDetails.nextSlotInitialized) {
                    // sync slot
                    SlotId nextSlotId = getSlotId(poolId, swapDetails.nextSlotIndex);
                    Slot storage nextSlot = slots[nextSlotId];
                    syncSlot(poolId, nextSlot, swapDetails.nextSlotIndex, epoch);
                    // update per liquidities outside
                    nextSlot.proceedsPerLiquidityOutside = pool.proceedsPerLiquidity.sub(
                        nextSlot.proceedsPerLiquidityOutside
                    );
                    nextSlot.feesAPerLiquidityOutside = (
                        tokenIn == PoolToken.A ? swapDetails.feesPerLiquidity : pool.feesAPerLiquidity
                    ).sub(nextSlot.feesAPerLiquidityOutside);
                    nextSlot.feesBPerLiquidityOutside = (
                        tokenIn == PoolToken.A ? pool.feesBPerLiquidity : swapDetails.feesPerLiquidity
                    ).sub(nextSlot.feesBPerLiquidityOutside);
                    // save slot snapshot for the current epoch id
                    slotSnapshots[nextSlotId][epoch.id] = getSlotSnapshot(nextSlot);
                    // update swap details state (eventually gets saved to pool)
                    if (tokenIn == PoolToken.A) {
                        // moving down the grid, from right to left (receiving less tokenB per input tokenA)
                        swapDetails.swapLiquidity = nextSlot.swapLiquidityDelta > 0
                            ? swapDetails.swapLiquidity - uint256(nextSlot.swapLiquidityDelta)
                            : swapDetails.swapLiquidity + BrainMath.abs(nextSlot.swapLiquidityDelta);
                        swapDetails.maturedLiquidity = nextSlot.maturedLiquidityDelta > 0
                            ? swapDetails.maturedLiquidity - uint256(nextSlot.maturedLiquidityDelta)
                            : swapDetails.maturedLiquidity + BrainMath.abs(nextSlot.maturedLiquidityDelta);
                        swapDetails.pendingLiquidity -= nextSlot.pendingLiquidityDelta;
                    } else {
                        // moving up the grid, from left to right (receiving less tokenA per input tokenB)
                        swapDetails.swapLiquidity = nextSlot.swapLiquidityDelta > 0
                            ? swapDetails.swapLiquidity + uint256(nextSlot.swapLiquidityDelta)
                            : swapDetails.swapLiquidity - BrainMath.abs(nextSlot.swapLiquidityDelta);
                        swapDetails.maturedLiquidity = nextSlot.maturedLiquidityDelta > 0
                            ? swapDetails.maturedLiquidity + uint256(nextSlot.maturedLiquidityDelta)
                            : swapDetails.maturedLiquidity - BrainMath.abs(nextSlot.maturedLiquidityDelta);
                        swapDetails.pendingLiquidity += nextSlot.pendingLiquidityDelta;
                    }
                }
            }
        }
        // update pool's state based on swap details
        pool.sqrtPrice = swapDetails.sqrtPrice;
        pool.slotIndex = swapDetails.slotIndex;
        pool.swapLiquidity = swapDetails.swapLiquidity;
        pool.maturedLiquidity = swapDetails.maturedLiquidity;
        pool.pendingLiquidity = swapDetails.pendingLiquidity;
        if (tokenIn == PoolToken.A) {
            pool.feesAPerLiquidity = swapDetails.feesPerLiquidity;

            // TODO: review order of operations
            settleToken(pool.tokenA, amountIn);
            internalBalances[msg.sender][pool.tokenB] += swapDetails.amountOut;
        } else {
            pool.feesBPerLiquidity = swapDetails.feesPerLiquidity;

            // TODO: review order of operations
            settleToken(pool.tokenB, amountIn);
            internalBalances[msg.sender][pool.tokenA] += swapDetails.amountOut;
        }
    }

    function bid(
        PoolId poolId,
        uint256 epochId,
        address refunder,
        address swapper,
        uint256 amount
    ) public started {
        if (amount == 0) revert IHyper.AmountZeroError();

        Pool storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert IHyper.PoolNotInitializedError();

        syncEpoch();

        if (epochId != epoch.id + 1) revert IHyper.InvalidBidEpochError();
        if (block.timestamp < epoch.endTime - AUCTION_LENGTH) revert IHyper.AuctionNotStartedError();

        // @dev: pool needs to sync here, assumes no bids otherwise for the next epoch
        syncPool(pool, epoch);

        uint256 fee = fromUD60x18(AUCTION_FEE.mul(toUD60x18(amount)).ceil());
        uint256 netFeeAmount = amount - fee;

        Bid memory leadingBid = bids[poolId][epochId];

        if (netFeeAmount > leadingBid.netFeeAmount) {
            // refund previous bid amount to it's refunder address
            internalBalances[leadingBid.refunder][AUCTION_SETTLEMENT_TOKEN] += leadingBid.netFeeAmount + leadingBid.fee;
            // calculate new proceeds per second
            UD60x18 proceedsPerSecond = toUD60x18(netFeeAmount).div(toUD60x18(epoch.length));
            // set new leading bid
            bids[poolId][epochId] = Bid({
                refunder: refunder,
                swapper: swapper,
                netFeeAmount: netFeeAmount,
                fee: fee,
                proceedsPerSecond: proceedsPerSecond
            });
            // settle tokens owed from msg.sender
            settleToken(AUCTION_SETTLEMENT_TOKEN, amount);

            emit LeadingBid(poolId, epochId, swapper, amount, proceedsPerSecond);
        }
    }

    function settleToken(address token, uint256 amountOwed) internal {
        if (internalBalances[msg.sender][token] >= amountOwed) {
            internalBalances[msg.sender][token] -= amountOwed;
        } else {
            amountOwed -= internalBalances[msg.sender][token];
            internalBalances[msg.sender][token] = 0;
            uint256 initialBalance = ERC20(token).balanceOf(address(this));
            SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amountOwed);
            require(
                ERC20(token).balanceOf(address(this)) >= initialBalance + amountOwed,
                "Insufficient tokens transferred in"
            );
        }
    }
}
