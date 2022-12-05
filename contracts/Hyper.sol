// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UD60x18, fromUD60x18, toUD60x18, wrap as wrapUD60x18} from "@prb/math/UD60x18.sol";

import "./interfaces/IHyper.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

import "./libraries/BitMath.sol";
import "./libraries/BrainMath.sol";
import "./libraries/GlobalDefaults.sol";

import {BalanceChange} from "./libraries/BalanceChange.sol";
import {Epoch} from "./libraries/Epoch.sol";
import {Pool, Bid, getPoolId} from "./libraries/Pool.sol";
import {Position, PositionBalanceChange, getPositionId} from "./libraries/Position.sol";
import {Slot, SlotSnapshot, getSlotId} from "./libraries/Slot.sol";

// TODO: Reentrancy guard

contract Hyper is IHyper {
    Epoch public epoch;

    mapping(bytes32 => Pool) public pools;
    mapping(bytes32 => Slot) public slots;
    mapping(bytes32 => Position) public positions;

    // TODO: Not sure if this should be stored here
    mapping(bytes32 => mapping(int16 => uint256)) public bitmaps;

    /// @notice Internal token balances
    /// user => token => balance
    mapping(address => mapping(address => uint256)) public internalBalances;

    address public auctionFeeCollector;

    constructor(uint256 startTime, address _auctionFeeCollector) {
        require(startTime > block.timestamp);
        epoch = Epoch({id: 0, endTime: startTime});
        auctionFeeCollector = _auctionFeeCollector;
    }

    modifier started() {
        if (epoch.id < 1) revert HyperNotStartedError();
        _;
    }

    function getGlobalDefaults()
        public
        pure
        override
        returns (
            UD60x18 publicSwapFee,
            uint256 epochLength,
            uint256 auctionLength,
            address auctionSettlementToken,
            UD60x18 auctionFee
        )
    {
        publicSwapFee = PUBLIC_SWAP_FEE;
        epochLength = EPOCH_LENGTH;
        auctionLength = AUCTION_LENGTH;
        auctionSettlementToken = AUCTION_SETTLEMENT_TOKEN;
        auctionFee = AUCTION_FEE;
    }

    function getLeadingBid(bytes32 poolId, uint256 epochId)
        public
        view
        override
        started
        returns (
            address refunder,
            address swapper,
            uint256 amount,
            UD60x18 proceedsPerSecond
        )
    {
        Pool storage pool = pools[poolId];
        refunder = pool.bids[epochId].refunder;
        swapper = pool.bids[epochId].swapper;
        amount = pool.bids[epochId].netFeeAmount + pool.bids[epochId].fee;
        proceedsPerSecond = pool.bids[epochId].proceedsPerSecond;
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
        if (pool.lastUpdatedTimestamp != 0) revert PoolAlreadyInitializedError();
        pool.tokenA = tokenA;
        pool.tokenB = tokenB;
        pool.sqrtPrice = sqrtPrice;
        pool.slotIndex = _getSlotAtSqrtPrice(sqrtPrice);
        pool.lastUpdatedTimestamp = block.timestamp;
        emit ActivatePool(tokenA, tokenB);
    }

    function updateLiquidity(
        bytes32 poolId,
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
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        int256 amount
    ) internal started returns (BalanceChange[3] memory balanceChanges) {
        // TODO: Add a proper revert error
        if (lowerSlotIndex > upperSlotIndex) revert();

        if (amount == 0) revert AmountZeroError();

        Pool storage pool = pools[poolId];

        // TODO: Add a proper revert error
        if (pool.lastUpdatedTimestamp == 0) revert();

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
            // TODO: Add a proper revert error
            if (amount < 0) revert();
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
                uint256(amount)
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
            uint256 addedPending = abs(position.pendingLiquidity) >= amount ? amount : abs(position.pendingLiquidity);

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
                (int16 chunk, uint8 bit) = getSlotPositionInBitmap(int24(position.lowerSlotIndex));
                chunks[chunk] = flip(chunks[chunk], bit);
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
                (int16 chunk, uint8 bit) = getSlotPositionInBitmap(int24(position.upperSlotIndex));
                chunks[chunk] = flip(chunks[chunk], bit);
                // initialize per liquidity outside values
                if (pool.slotIndex >= position.upperSlotIndex) {
                    upperSlot.proceedsPerLiquidityOutside = pool.proceedsPerLiquidity;
                    upperSlot.feesAPerLiquidityOutside = pool.feesAPerLiquidity;
                    upperSlot.feesBPerLiquidityOutside = pool.feesBPerLiquidity;
                }
                upperSlot.liquidityGross += uint256(addAmountLeft);
            }
            (amountA, amountB) = _calculateLiquidityUnderlying(
                addAmountLeft,
                pool.sqrtPrice,
                pool.slotIndex,
                position.lowerSlotIndex,
                position.upperSlotIndex,
                true
            );
            if (amountA != 0 && amountB != 0) {
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
            // TODO: Add a proper revert error
            if (position.swapLiquidity < amount) revert();

            uint256 removedPending = uint256(position.pendingLiquidity) >= amount
                ? amount
                : uint256(position.pendingLiquidity);

            position.swapLiquidity -= removedPending;
            position.pendingLiquidity -= int256(removedPending);

            lowerSlot.swapLiquidityDelta -= int256(removedPending);
            lowerSlot.pendingLiquidityDelta -= int256(removedPending);
            lowerSlot.liquidityGross -= removedPending;

            if (lowerSlot.liquidityGross == 0) {
                (int16 chunk, uint8 bit) = getSlotPositionInBitmap(int24(position.lowerSlotIndex));
                chunks[chunk] = flip(chunks[chunk], bit);
            }

            upperSlot.swapLiquidityDelta += int256(removedPending);
            upperSlot.pendingLiquidityDelta += int256(removedPending);
            upperSlot.liquidityGross -= removedPending;

            if (upperSlot.liquidityGross == 0) {
                (int16 chunk, uint8 bit) = getSlotPositionInBitmap(int24(position.upperSlotIndex));
                chunks[chunk] = flip(chunks[chunk], bit);
            }

            // credit tokens owed to the position immediately
            (amountA, amountB) = _calculateLiquidityUnderlying(
                removedPending,
                pool.sqrtPrice,
                pool.slotIndex,
                position.lowerSlotIndex,
                position.upperSlotIndex,
                false
            );

            if (amountA != 0 && amountB != 0) {
                pool.swapLiquidity -= removedPending;
                pool.pendingLiquidity -= int256(removedPending);
            }

            removeAmountLeft -= removedPending;
        } else {
            if (position.swapLiquidity - abs(position.pendingLiquidity) < amount) revert();
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
        bytes32 poolId,
        uint256 amountIn,
        bool direction,
        bool transferOut
    ) public {
        BalanceChange[2] memory balanceChanges = _swap(poolId, amountIn, direction);
        for (uint256 i = 0; i < balanceChanges.length; ++i) {
            _settleBalanceChange(balanceChanges[i], transferOut);
        }
    }

    function _swap(
        bytes32 poolId,
        uint256 amountIn,
        bool direction
    ) internal started returns (BalanceChange[2] memory balanceChanges) {
        // TODO: Add a proper revert error
        if (amountIn == 0) revert();

        Pool storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert(); // TODO: revert PoolNotInitialized();

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
            feesPerLiquidity: wrapUD60x18(0),
            nextSlotInitialized: false,
            nextSlotIndex: 0,
            nextSqrtPrice: wrapUD60x18(0)
        });

        while (swapDetails.remaining > 0) {
            {
                // Get the next slot or the border of a bitmap
                (int16 chunk, uint8 bit) = getSlotPositionInBitmap(int24(swapDetails.slotIndex));
                (bool hasNextSlot, uint8 nextSlotBit) = findNextSlotWithinChunk(
                    // If direction is true: swapping A for B
                    // Decreasing the slot index -> going right into the bitmap (reducing the index)
                    bitmaps[poolId][chunk],
                    bit,
                    !direction
                );
                swapDetails.nextSlotInitialized = hasNextSlot;
                swapDetails.nextSlotIndex = int128(chunk * 256 + int8(nextSlotBit));
                swapDetails.nextSqrtPrice = _getSqrtPriceAtSlot(swapDetails.nextSlotIndex);
            }

            uint256 remainingFeeAmount = fromUD60x18(swapDetails.feeTier.mul(toUD60x18(swapDetails.remaining)).ceil());

            if (direction) {
                // TODO: Double check if we should round up or not
                uint256 maxXToDelta = getDeltaXToNextPrice(
                    swapDetails.sqrtPrice,
                    swapDetails.nextSqrtPrice,
                    swapDetails.swapLiquidity,
                    true
                );
                if (swapDetails.remaining - remainingFeeAmount < maxXToDelta) {
                    // remove fees from remaining amount
                    swapDetails.remaining -= remainingFeeAmount;
                    // save fees per liquidity
                    swapDetails.feesPerLiquidity = swapDetails.feesPerLiquidity.add(
                        toUD60x18(remainingFeeAmount).div(toUD60x18(swapDetails.swapLiquidity))
                    );
                    // update price and amount out after swapping remaining amount
                    UD60x18 targetPrice = getTargetPriceUsingDeltaX(
                        swapDetails.sqrtPrice,
                        swapDetails.swapLiquidity,
                        swapDetails.remaining
                    );
                    swapDetails.amountOut += getDeltaYToNextPrice(
                        swapDetails.sqrtPrice,
                        targetPrice,
                        swapDetails.swapLiquidity,
                        false
                    );
                    swapDetails.remaining = 0;
                    swapDetails.sqrtPrice = targetPrice;
                    swapDetails.slotIndex = _getSlotAtSqrtPrice(swapDetails.sqrtPrice);
                } else {
                    // swapping maxXToDelta, only take fees on this amount
                    uint256 maxXFeeAmount = fromUD60x18(swapDetails.feeTier.mul(toUD60x18(maxXToDelta)).ceil());
                    // remove fees and swap amount
                    swapDetails.remaining -= maxXFeeAmount + maxXToDelta;
                    // save fees per liquidity
                    swapDetails.feesPerLiquidity = swapDetails.feesPerLiquidity.add(
                        toUD60x18(maxXFeeAmount).div(toUD60x18(swapDetails.swapLiquidity))
                    );
                    // update price and amount out after swapping
                    swapDetails.amountOut += getDeltaYToNextPrice(
                        swapDetails.sqrtPrice,
                        swapDetails.nextSqrtPrice,
                        swapDetails.swapLiquidity,
                        false
                    );
                    swapDetails.sqrtPrice = swapDetails.nextSqrtPrice;
                    swapDetails.slotIndex = swapDetails.nextSlotIndex;
                    // cross the next initialized slot
                    if (swapDetails.nextSlotInitialized) {
                        Slot storage nextSlot = slots[getSlotId(poolId, swapDetails.nextSlotIndex)];
                        nextSlot.sync(bitmaps[poolId], int24(swapDetails.nextSlotIndex), epoch);
                        // TODO: need to update pool's per liquidity values or pass swapDetails
                        nextSlot.cross(pool, epoch.id);

                        swapDetails.swapLiquidity = nextSlot.swapLiquidityDelta > 0
                            ? swapDetails.swapLiquidity - uint256(nextSlot.swapLiquidityDelta)
                            : swapDetails.swapLiquidity + abs(nextSlot.swapLiquidityDelta);

                        swapDetails.maturedLiquidity = nextSlot.maturedLiquidityDelta > 0
                            ? swapDetails.maturedLiquidity - uint256(nextSlot.maturedLiquidityDelta)
                            : swapDetails.maturedLiquidity + abs(nextSlot.maturedLiquidityDelta);

                        swapDetails.pendingLiquidity -= nextSlot.pendingLiquidityDelta;
                    }
                }
            } else {
                // TODO: Double check if we should round up or not
                uint256 maxYToDelta = getDeltaYToNextPrice(
                    swapDetails.sqrtPrice,
                    _getSqrtPriceAtSlot(swapDetails.nextSlotIndex),
                    swapDetails.swapLiquidity,
                    true
                );
                if (swapDetails.remaining - remainingFeeAmount < maxYToDelta) {
                    // remove fees from remaining amount
                    swapDetails.remaining -= remainingFeeAmount;
                    // save fees per liquidity
                    swapDetails.feesPerLiquidity = swapDetails.feesPerLiquidity.add(
                        toUD60x18(remainingFeeAmount).div(toUD60x18(swapDetails.swapLiquidity))
                    );
                    // update price and amount out after swapping remaining amount
                    UD60x18 targetPrice = getTargetPriceUsingDeltaY(
                        swapDetails.sqrtPrice,
                        swapDetails.swapLiquidity,
                        swapDetails.remaining
                    );
                    swapDetails.amountOut += getDeltaXToNextPrice(
                        swapDetails.sqrtPrice,
                        targetPrice,
                        swapDetails.swapLiquidity,
                        false
                    );
                    swapDetails.remaining = 0;
                    swapDetails.sqrtPrice = targetPrice;
                    swapDetails.slotIndex = _getSlotAtSqrtPrice(swapDetails.sqrtPrice);
                } else {
                    // swapping maxYToDelta, only take fees on this amount
                    uint256 maxYFeeAmount = fromUD60x18(swapDetails.feeTier.mul(toUD60x18(maxYToDelta)).ceil());
                    // remove fees and swap amount
                    swapDetails.remaining -= maxYFeeAmount + maxYToDelta;
                    // save fees per liquidity
                    swapDetails.feesPerLiquidity = swapDetails.feesPerLiquidity.add(
                        toUD60x18(maxYFeeAmount).div(toUD60x18(swapDetails.swapLiquidity))
                    );
                    // update price and amount out after swapping
                    swapDetails.amountOut += getDeltaXToNextPrice(
                        swapDetails.sqrtPrice,
                        swapDetails.nextSqrtPrice,
                        swapDetails.swapLiquidity,
                        false
                    );
                    swapDetails.sqrtPrice = swapDetails.nextSqrtPrice;
                    swapDetails.slotIndex = swapDetails.nextSlotIndex;
                    // cross the next initialized slot
                    if (swapDetails.nextSlotInitialized) {
                        Slot storage nextSlot = slots[getSlotId(poolId, swapDetails.nextSlotIndex)];
                        nextSlot.sync(bitmaps[poolId], int24(swapDetails.nextSlotIndex), epoch);
                        // TODO: need to update pool's per liquidity values or pass swapDetails
                        nextSlot.cross(pool, epoch.id);

                        swapDetails.swapLiquidity = nextSlot.swapLiquidityDelta > 0
                            ? swapDetails.swapLiquidity + uint256(nextSlot.swapLiquidityDelta)
                            : swapDetails.swapLiquidity - abs(nextSlot.swapLiquidityDelta);

                        swapDetails.maturedLiquidity = nextSlot.maturedLiquidityDelta > 0
                            ? swapDetails.maturedLiquidity + uint256(nextSlot.maturedLiquidityDelta)
                            : swapDetails.maturedLiquidity - abs(nextSlot.maturedLiquidityDelta);

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
        if (direction) {
            pool.feesAPerLiquidity = pool.feesAPerLiquidity.add(swapDetails.feesPerLiquidity);

            balanceChanges[0] = BalanceChange({token: pool.tokenA, amount: -int256(amountIn)});
            balanceChanges[1] = BalanceChange({token: pool.tokenB, amount: int256(swapDetails.amountOut)});
        } else {
            pool.feesBPerLiquidity = pool.feesBPerLiquidity.add(swapDetails.feesPerLiquidity);

            balanceChanges[0] = BalanceChange({token: pool.tokenA, amount: int256(amountIn)});
            balanceChanges[1] = BalanceChange({token: pool.tokenB, amount: -int256(swapDetails.amountOut)});
        }
    }

    function bid(
        bytes32 poolId,
        uint256 epochId,
        address refunder,
        address swapper,
        uint256 amount
    ) public {
        BalanceChange memory balanceChange = _bid(poolId, epochId, refunder, swapper, amount);
        _settleBalanceChange(balanceChange, false);
    }

    function _bid(
        bytes32 poolId,
        uint256 epochId,
        address refunder,
        address swapper,
        uint256 amount
    ) internal started returns (BalanceChange memory balanceChange) {
        if (amount == 0) revert AmountZeroError();

        Pool storage pool = pools[poolId];
        // TODO: Add a proper revert error
        if (pool.lastUpdatedTimestamp == 0) revert();

        bool newEpoch = epoch.sync();
        if (newEpoch) emit SetEpoch(epoch.id, epoch.endTime);

        // TODO: Add a proper revert error
        if (epochId != epoch.id + 1) revert();
        // TODO: Add a proper revert error
        if (block.timestamp < epoch.endTime - AUCTION_LENGTH) revert();

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
                proceedsPerSecond: toUD60x18(netFeeAmount).div(toUD60x18(EPOCH_LENGTH))
            });
            emit LeadingBid(poolId, epochId, swapper, amount, pool.bids[epochId].proceedsPerSecond);
        }
        balanceChange.token = AUCTION_SETTLEMENT_TOKEN;
    }

    function _settleBalanceChange(BalanceChange memory balanceChange, bool transferOut) internal {
        if (balanceChange.amount < 0) {
            if (internalBalances[msg.sender][balanceChange.token] >= abs(balanceChange.amount)) {
                internalBalances[msg.sender][balanceChange.token] -= abs(balanceChange.amount);
            } else {
                uint256 amountOwed = abs(balanceChange.amount) - internalBalances[msg.sender][balanceChange.token];
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
                SafeTransferLib.safeTransfer(ERC20(balanceChange.token), msg.sender, abs(balanceChange.amount));
            } else {
                internalBalances[msg.sender][balanceChange.token] += uint256(balanceChange.amount);
            }
        }
    }
}
