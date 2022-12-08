// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UD60x18, fromUD60x18, toUD60x18, wrap as wrapUD60x18, ZERO as zeroUD60x18, HALF_UNIT as halfUD60x18} from "@prb/math/UD60x18.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

import {IHyper} from "./interfaces/IHyper.sol";

import "./libraries/BitMath.sol" as BitMath;
import "./libraries/BrainMath.sol" as BrainMath;

import {BalanceChange} from "./libraries/BalanceChange.sol";
import {Epoch} from "./libraries/Epoch.sol";
import {getPoolId, PoolId, Pool, PoolToken, Bid} from "./libraries/Pool.sol";
import {getSlotId, SlotId, Slot, SlotSnapshot} from "./libraries/Slot.sol";
import {getPositionId, PositionId, Position, PositionBalanceChange} from "./libraries/Position.sol";

// TODO: Reentrancy guard

contract Hyper is IHyper {
    address public immutable AUCTION_SETTLEMENT_TOKEN;
    uint256 public immutable AUCTION_LENGTH;

    UD60x18 public immutable PUBLIC_SWAP_FEE;
    UD60x18 public immutable AUCTION_FEE;

    Epoch public epoch;

    mapping(PoolId => Pool) public pools;
    mapping(SlotId => Slot) public slots;
    mapping(PositionId => Position) public positions;

    mapping(PoolId => mapping(int16 => uint256)) public bitmaps;

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
        if (epoch.id < 1) revert IHyper.HyperNotStartedError();
        _;
    }

    function bids(PoolId poolId, uint256 epochId)
        public
        view
        override
        returns (
            address,
            address,
            uint256,
            UD60x18
        )
    {
        Bid storage bid = pools[poolId].bids[epochId];
        return (bid.refunder, bid.swapper, bid.netFeeAmount + bid.fee, bid.proceedsPerSecond);
    }

    function start() public {
        epoch.sync();
        require(epoch.id > 0, "Hyper not started yet.");
        emit SetEpoch(epoch.id, epoch.endTime);
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

    function activatePool(
        address tokenA,
        address tokenB,
        UD60x18 sqrtPrice
    ) public started {
        bool newEpoch = epoch.sync();
        if (newEpoch) emit SetEpoch(epoch.id, epoch.endTime);

        Pool storage pool = pools[getPoolId(tokenA, tokenB)];
        if (pool.lastUpdatedTimestamp != 0) revert IHyper.PoolAlreadyInitializedError();
        pool.tokenA = tokenA;
        pool.tokenB = tokenB;
        pool.sqrtPrice = sqrtPrice;
        pool.slotIndex = BrainMath._getSlotAtSqrtPrice(sqrtPrice);
        pool.lastUpdatedTimestamp = block.timestamp;
        emit ActivatePool(tokenA, tokenB);
    }

    function updateLiquidity(
        PoolId poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        int256 amount,
        bool transferOut
    ) public {
        BalanceChange[3] memory balanceChanges = _updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, amount);
        for (uint256 i = 0; i < balanceChanges.length; ++i) {
            _settleBalanceChange(balanceChanges[i], transferOut);
        }
    }

    function _updateLiquidity(
        PoolId poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        int256 amount
    ) internal started returns (BalanceChange[3] memory balanceChanges) {
        if (lowerSlotIndex >= upperSlotIndex) revert IHyper.PositionInvalidRangeError();
        if (amount == 0) revert IHyper.AmountZeroError();

        Pool storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert IHyper.PoolUninitializedError();

        {
            bool newEpoch = epoch.sync();
            if (newEpoch) emit SetEpoch(epoch.id, epoch.endTime);
        }

        {
            uint256 auctionFees = pool.sync(epoch);
            if (auctionFees > 0) {
                internalBalances[auctionFeeCollector][AUCTION_SETTLEMENT_TOKEN] += auctionFees;
            }
        }

        Slot storage lowerSlot;
        {
            lowerSlot = slots[getSlotId(poolId, int24(lowerSlotIndex))];
            lowerSlot.sync(bitmaps[poolId], int24(lowerSlotIndex), epoch);
        }

        Slot storage upperSlot;
        {
            upperSlot = slots[getSlotId(poolId, int24(upperSlotIndex))];
            upperSlot.sync(bitmaps[poolId], int24(upperSlotIndex), epoch);
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
            PositionBalanceChange memory syncBalanceChange = position.sync(pool, lowerSlot, upperSlot, epoch);
            if (syncBalanceChange.amountA != 0) balanceChanges[0].amount = int256(syncBalanceChange.amountA);
            if (syncBalanceChange.amountB != 0) balanceChanges[1].amount = int256(syncBalanceChange.amountB);
            if (syncBalanceChange.amountC != 0) balanceChanges[2].amount = int256(syncBalanceChange.amountC);
        }

        if (amount > 0) {
            (uint256 addAmountA, uint256 addAmountB) = _addLiquidity(
                pool,
                bitmaps[poolId],
                lowerSlot,
                upperSlot,
                position,
                uint256(amount)
            );
            if (addAmountA != 0) balanceChanges[0].amount -= int256(addAmountA);
            if (addAmountB != 0) balanceChanges[1].amount -= int256(addAmountB);
        } else {
            (uint256 removeAmountA, uint256 removeAmountB) = _removeLiquidity(
                pool,
                bitmaps[poolId],
                lowerSlot,
                upperSlot,
                position,
                BrainMath.abs(amount)
            );
            if (removeAmountA != 0) balanceChanges[0].amount += int256(removeAmountA);
            if (removeAmountB != 0) balanceChanges[1].amount += int256(removeAmountB);
        }

        balanceChanges[0].token = pool.tokenA;
        balanceChanges[1].token = pool.tokenB;
        balanceChanges[2].token = AUCTION_SETTLEMENT_TOKEN;

        emit UpdateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, amount);
    }

    function _addLiquidity(
        Pool storage pool,
        mapping(int16 => uint256) storage chunks,
        Slot storage lowerSlot,
        Slot storage upperSlot,
        Position storage position,
        uint256 amount
    ) internal returns (uint256 amountA, uint256 amountB) {
        uint256 addAmountLeft = amount;

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
                chunks[chunk] = BitMath.flip(chunks[chunk], bit);
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
                chunks[chunk] = BitMath.flip(chunks[chunk], bit);
                // initialize per liquidity outside values
                if (pool.slotIndex >= position.upperSlotIndex) {
                    upperSlot.proceedsPerLiquidityOutside = pool.proceedsPerLiquidity;
                    upperSlot.feesAPerLiquidityOutside = pool.feesAPerLiquidity;
                    upperSlot.feesBPerLiquidityOutside = pool.feesBPerLiquidity;
                }
                upperSlot.liquidityGross += uint256(addAmountLeft);
            }
            (amountA, amountB) = BrainMath._calculateLiquidityUnderlying(
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
    }

    function _removeLiquidity(
        Pool storage pool,
        mapping(int16 => uint256) storage chunks,
        Slot storage lowerSlot,
        Slot storage upperSlot,
        Position storage position,
        uint256 amount
    ) internal returns (uint256 amountA, uint256 amountB) {
        uint256 removeAmountLeft = amount;

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
                chunks[chunk] = BitMath.flip(chunks[chunk], bit);
            }

            upperSlot.swapLiquidityDelta += int256(removedPending);
            upperSlot.pendingLiquidityDelta += int256(removedPending);
            upperSlot.liquidityGross -= removedPending;

            if (upperSlot.liquidityGross == 0) {
                (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(int24(position.upperSlotIndex));
                chunks[chunk] = BitMath.flip(chunks[chunk], bit);
            }

            // credit tokens owed to the position immediately
            (amountA, amountB) = BrainMath._calculateLiquidityUnderlying(
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

        // save slot snapshots
        lowerSlot.snapshots[epoch.id] = SlotSnapshot({
            proceedsPerLiquidityOutside: lowerSlot.proceedsPerLiquidityOutside,
            feesAPerLiquidityOutside: lowerSlot.feesAPerLiquidityOutside,
            feesBPerLiquidityOutside: lowerSlot.feesBPerLiquidityOutside
        });
        upperSlot.snapshots[epoch.id] = SlotSnapshot({
            proceedsPerLiquidityOutside: upperSlot.proceedsPerLiquidityOutside,
            feesAPerLiquidityOutside: upperSlot.feesAPerLiquidityOutside,
            feesBPerLiquidityOutside: upperSlot.feesBPerLiquidityOutside
        });
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
        uint256 amountIn,
        bool transferOut
    ) public {
        BalanceChange[2] memory balanceChanges = _swap(poolId, tokenIn, amountIn);
        for (uint256 i = 0; i < balanceChanges.length; ++i) {
            _settleBalanceChange(balanceChanges[i], transferOut);
        }
    }

    function _swap(
        PoolId poolId,
        PoolToken tokenIn,
        uint256 amountIn
    ) internal started returns (BalanceChange[2] memory balanceChanges) {
        if (amountIn == 0) revert IHyper.AmountZeroError();

        Pool storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert IHyper.PoolNotInitializedError();

        bool newEpoch = epoch.sync();
        if (newEpoch) emit SetEpoch(epoch.id, epoch.endTime);

        {
            uint256 auctionFees = pool.sync(epoch);
            if (auctionFees > 0) {
                internalBalances[auctionFeeCollector][AUCTION_SETTLEMENT_TOKEN] += auctionFees;
            }
        }

        SwapDetails memory swapDetails = SwapDetails({
            feeTier: msg.sender == pool.bids[epoch.id].swapper ? wrapUD60x18(0) : PUBLIC_SWAP_FEE,
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
                    // If pool token in is A -> decreasing slot index
                    // decreasing slot index -> going right into the bitmap (reducing the index)
                    bitmaps[poolId][chunk],
                    bit,
                    tokenIn == PoolToken.A ? BitMath.SearchDirection.Right : BitMath.SearchDirection.Left
                );
                swapDetails.nextSlotInitialized = hasNextSlot;
                swapDetails.nextSlotIndex = int128(chunk * 256 + int8(nextSlotBit));
                swapDetails.nextSqrtPrice = BrainMath._getSqrtPriceAtSlot(swapDetails.nextSlotIndex);
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
                swapDetails.slotIndex = BrainMath._getSlotAtSqrtPrice(swapDetails.sqrtPrice);
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
                    // update slot
                    Slot storage nextSlot = slots[getSlotId(poolId, swapDetails.nextSlotIndex)];
                    nextSlot.sync(bitmaps[poolId], int24(swapDetails.nextSlotIndex), epoch);
                    nextSlot.cross(
                        epoch.id,
                        pool.proceedsPerLiquidity,
                        tokenIn == PoolToken.A ? swapDetails.feesPerLiquidity : pool.feesAPerLiquidity,
                        tokenIn == PoolToken.A ? pool.feesBPerLiquidity : swapDetails.feesPerLiquidity
                    );
                    // update swap details state (eventually gets saved to pool)
                    if (tokenIn == PoolToken.A) {
                        // crosing slot from right to left
                        swapDetails.swapLiquidity = nextSlot.swapLiquidityDelta > 0
                            ? swapDetails.swapLiquidity - uint256(nextSlot.swapLiquidityDelta)
                            : swapDetails.swapLiquidity + BrainMath.abs(nextSlot.swapLiquidityDelta);
                        swapDetails.maturedLiquidity = nextSlot.maturedLiquidityDelta > 0
                            ? swapDetails.maturedLiquidity - uint256(nextSlot.maturedLiquidityDelta)
                            : swapDetails.maturedLiquidity + BrainMath.abs(nextSlot.maturedLiquidityDelta);
                        swapDetails.pendingLiquidity -= nextSlot.pendingLiquidityDelta;
                    } else {
                        // crosing slot from left to right
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

            balanceChanges[0] = BalanceChange({token: pool.tokenA, amount: -int256(amountIn)});
            balanceChanges[1] = BalanceChange({token: pool.tokenB, amount: int256(swapDetails.amountOut)});
        } else {
            pool.feesBPerLiquidity = swapDetails.feesPerLiquidity;

            balanceChanges[0] = BalanceChange({token: pool.tokenA, amount: int256(amountIn)});
            balanceChanges[1] = BalanceChange({token: pool.tokenB, amount: -int256(swapDetails.amountOut)});
        }
    }

    function bid(
        PoolId poolId,
        uint256 epochId,
        address refunder,
        address swapper,
        uint256 amount
    ) public {
        BalanceChange memory balanceChange = _bid(poolId, epochId, refunder, swapper, amount);
        _settleBalanceChange(balanceChange, false);
    }

    function _bid(
        PoolId poolId,
        uint256 epochId,
        address refunder,
        address swapper,
        uint256 amount
    ) internal started returns (BalanceChange memory balanceChange) {
        if (amount == 0) revert IHyper.AmountZeroError();

        Pool storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert IHyper.PoolNotInitializedError();

        bool newEpoch = epoch.sync();
        if (newEpoch) emit SetEpoch(epoch.id, epoch.endTime);

        if (epochId != epoch.id + 1) revert IHyper.InvalidBidEpochError();
        if (block.timestamp < epoch.endTime - AUCTION_LENGTH) revert IHyper.AuctionNotStartedError();

        // @dev: pool needs to sync here, assumes no bids otherwise
        {
            uint256 auctionFees = pool.sync(epoch);
            if (auctionFees > 0) {
                internalBalances[auctionFeeCollector][AUCTION_SETTLEMENT_TOKEN] += auctionFees;
            }
        }

        uint256 fee = fromUD60x18(AUCTION_FEE.mul(toUD60x18(amount)).ceil());
        uint256 netFeeAmount = amount - fee;

        if (netFeeAmount > pool.bids[epochId].netFeeAmount) {
            // refund previous bid amount to it's refunder address
            internalBalances[pool.bids[epochId].refunder][AUCTION_SETTLEMENT_TOKEN] +=
                pool.bids[epochId].netFeeAmount +
                pool.bids[epochId].fee;
            // update the balance change amount to be paid from msg.sender
            balanceChange.amount = -int256(amount);
            // set new leading bid
            pool.bids[epochId] = Bid({
                refunder: refunder,
                swapper: swapper,
                netFeeAmount: netFeeAmount,
                fee: fee,
                proceedsPerSecond: toUD60x18(netFeeAmount).div(toUD60x18(epoch.length))
            });
            emit LeadingBid(poolId, epochId, swapper, amount, pool.bids[epochId].proceedsPerSecond);
        }
        balanceChange.token = AUCTION_SETTLEMENT_TOKEN;
    }

    function _settleBalanceChange(BalanceChange memory balanceChange, bool transferOut) internal {
        if (balanceChange.amount < 0) {
            if (internalBalances[msg.sender][balanceChange.token] >= BrainMath.abs(balanceChange.amount)) {
                internalBalances[msg.sender][balanceChange.token] -= BrainMath.abs(balanceChange.amount);
            } else {
                uint256 amountOwed = BrainMath.abs(balanceChange.amount) -
                    internalBalances[msg.sender][balanceChange.token];
                internalBalances[msg.sender][balanceChange.token] = 0;
                uint256 initBalance = ERC20(balanceChange.token).balanceOf(address(this));
                SafeTransferLib.safeTransferFrom(ERC20(balanceChange.token), msg.sender, address(this), amountOwed);
                require(
                    ERC20(balanceChange.token).balanceOf(address(this)) >= initBalance + amountOwed,
                    "Insufficient tokens transferred in"
                );
            }
        } else if (balanceChange.amount > 0) {
            if (transferOut) {
                SafeTransferLib.safeTransfer(
                    ERC20(balanceChange.token),
                    msg.sender,
                    BrainMath.abs(balanceChange.amount)
                );
            } else {
                internalBalances[msg.sender][balanceChange.token] += uint256(balanceChange.amount);
            }
        }
    }
}
