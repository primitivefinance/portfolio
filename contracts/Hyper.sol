// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IHyper} from "./interfaces/IHyper.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

import "./libraries/BitMath.sol";
import "./libraries/BrainMath.sol";
import "./libraries/Epoch.sol";
import "./libraries/GlobalDefaults.sol";
import "./libraries/Pool.sol";
import "./libraries/Position.sol";
import "./libraries/Slot.sol";

// TODO:
// - Add WETH wrapping / unwrapping
// - Add Multicall?
// - Fixed point library
// - Slippage checks
// - Extra function parameters
// - Custom errors
// - slots bitmap
// - swap

contract Hyper is IHyper {
    using Epoch for Epoch.Data;
    using Pool for Pool.Data;
    using Pool for mapping(bytes32 => Pool.Data);
    using Position for Position.Data;
    using Position for mapping(bytes32 => Position.Data);
    using Slot for Slot.Data;
    using Slot for mapping(bytes32 => Slot.Data);

    Epoch.Data public epoch;

    mapping(bytes32 => Pool.Data) public pools;
    mapping(bytes32 => Slot.Data) public slots;
    mapping(bytes32 => Position.Data) public positions;

    // TODO: Not sure if this should be stored here
    mapping(bytes32 => mapping(int16 => uint256)) public bitmaps;

    /// @notice Internal token balances
    mapping(address => mapping(address => uint256)) public internalBalances;

    address public auctionFeeCollector;

    constructor(uint256 startTime, address _auctionFeeCollector) {
        require(startTime > block.timestamp);
        epoch = Epoch.Data({id: 0, endTime: startTime});
        auctionFeeCollector = _auctionFeeCollector;
    }

    modifier started() {
        require(epoch.id > 0, "Hyper not started yet.");
        _;
    }

    function getGlobalDefaults()
        public
        pure
        override
        returns (
            uint256 publicSwapFee,
            uint256 epochLength,
            uint256 auctionLength,
            address auctionSettlementToken,
            uint256 auctionFee
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
            uint256 proceedsPerSecondFixedPoint
        )
    {
        Pool.Data storage pool = pools[poolId];
        refunder = pool.bids[epochId].refunder;
        swapper = pool.bids[epochId].swapper;
        amount = pool.bids[epochId].amount;
        proceedsPerSecondFixedPoint = pool.bids[epochId].proceedsPerSecondFixedPoint;
    }

    function start() public {
        epoch.sync();
        require(epoch.id > 0, "Hyper not started yet.");
        emit SetEpoch(epoch.id, epoch.endTime);
    }

    function fund(
        address to,
        address token,
        uint256 amount
    ) public started {
        SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
        internalBalances[to][token] += amount;
        emit Fund(to, token, amount);
    }

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
        uint256 sqrtPriceFixedPoint
    ) public started {
        bool newEpoch = epoch.sync();
        if (newEpoch) emit SetEpoch(epoch.id, epoch.endTime);
        pools.activate(tokenA, tokenB, sqrtPriceFixedPoint);
        emit ActivatePool(tokenA, tokenB);
    }

    function updateLiquidity(
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        int256 amount
    ) public started {
        if (lowerSlotIndex > upperSlotIndex) revert();
        if (amount == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

        bool newEpoch = epoch.sync();
        if (newEpoch) emit SetEpoch(epoch.id, epoch.endTime);
        pool.sync(epoch);

        bytes32 lowerSlotId = Slot.getId(poolId, int24(lowerSlotIndex));
        Slot.Data storage lowerSlot = slots[lowerSlotId];
        lowerSlot.sync(bitmaps[poolId], int24(lowerSlotIndex), epoch);

        bytes32 upperSlotId = Slot.getId(poolId, int24(upperSlotIndex));
        Slot.Data storage upperSlot = slots[upperSlotId];
        upperSlot.sync(bitmaps[poolId], int24(upperSlotIndex), epoch);

        bytes32 positionId = Position.getId(msg.sender, poolId, lowerSlotIndex, upperSlotIndex);
        Position.Data storage position = positions[positionId];

        if (position.lastUpdatedTimestamp == 0) {
            if (amount < 0) revert();
            position.lowerSlotIndex = lowerSlotIndex;
            position.upperSlotIndex = upperSlotIndex;
            position.lastUpdatedTimestamp = block.timestamp;
        } else {
            position.sync(pool, lowerSlot, upperSlot, epoch);
        }

        if (amount > 0) {
            _addLiquidity(pool, bitmaps[poolId], lowerSlot, upperSlot, position, uint256(amount));
        } else {
            _removeLiquidity(pool, bitmaps[poolId], lowerSlot, upperSlot, position, uint256(amount));
        }

        emit UpdateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, amount);
    }

    function _addLiquidity(
        Pool.Data storage pool,
        mapping(int16 => uint256) storage chunks,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot,
        Position.Data storage position,
        uint256 amount
    ) internal {
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
                (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(int24(position.lowerSlotIndex));
                chunks[chunk] = BitMath.flip(chunks[chunk], bit);
                // initialize per liquidity outside values
                if (pool.slotIndex >= position.lowerSlotIndex) {
                    lowerSlot.proceedsPerLiquidityOutsideFixedPoint = pool.proceedsPerLiquidityFixedPoint;
                    lowerSlot.feesAPerLiquidityOutsideFixedPoint = pool.feesAPerLiquidityFixedPoint;
                    lowerSlot.feesBPerLiquidityOutsideFixedPoint = pool.feesBPerLiquidityFixedPoint;
                } else {
                    lowerSlot.proceedsPerLiquidityOutsideFixedPoint = 0;
                    lowerSlot.feesAPerLiquidityOutsideFixedPoint = 0;
                    lowerSlot.feesBPerLiquidityOutsideFixedPoint = 0;
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
                    upperSlot.proceedsPerLiquidityOutsideFixedPoint = pool.proceedsPerLiquidityFixedPoint;
                    upperSlot.feesAPerLiquidityOutsideFixedPoint = pool.feesAPerLiquidityFixedPoint;
                    upperSlot.feesBPerLiquidityOutsideFixedPoint = pool.feesBPerLiquidityFixedPoint;
                } else {
                    upperSlot.proceedsPerLiquidityOutsideFixedPoint = 0;
                    upperSlot.feesAPerLiquidityOutsideFixedPoint = 0;
                    upperSlot.feesBPerLiquidityOutsideFixedPoint = 0;
                }
                upperSlot.liquidityGross += uint256(addAmountLeft);
            }

            (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
                addAmountLeft,
                pool.sqrtPriceFixedPoint,
                pool.slotIndex,
                position.lowerSlotIndex,
                position.upperSlotIndex
            );
            if (amountA != 0 && amountB != 0) {
                pool.swapLiquidity += addAmountLeft;
                pool.pendingLiquidity += int256(addAmountLeft);
            }

            // TODO: Remove amountA & amountB from internal balance
        }
    }

    function _removeLiquidity(
        Pool.Data storage pool,
        mapping(int16 => uint256) storage chunks,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot,
        Position.Data storage position,
        uint256 amount
    ) internal {
        uint256 removeAmountLeft = amount;

        // remove positive pending liquidity immediately
        if (position.pendingLiquidity > 0) {
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
            (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
                removedPending,
                pool.sqrtPriceFixedPoint,
                pool.slotIndex,
                position.lowerSlotIndex,
                position.upperSlotIndex
            );

            // TODO: add amountA & b to internal balance

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
        lowerSlot.snapshots[epoch.id] = Slot.Snapshot({
            proceedsPerLiquidityOutsideFixedPoint: lowerSlot.proceedsPerLiquidityOutsideFixedPoint,
            feesAPerLiquidityOutsideFixedPoint: lowerSlot.feesAPerLiquidityOutsideFixedPoint,
            feesBPerLiquidityOutsideFixedPoint: lowerSlot.feesBPerLiquidityOutsideFixedPoint
        });
        upperSlot.snapshots[epoch.id] = Slot.Snapshot({
            proceedsPerLiquidityOutsideFixedPoint: upperSlot.proceedsPerLiquidityOutsideFixedPoint,
            feesAPerLiquidityOutsideFixedPoint: upperSlot.feesAPerLiquidityOutsideFixedPoint,
            feesBPerLiquidityOutsideFixedPoint: upperSlot.feesBPerLiquidityOutsideFixedPoint
        });
    }

    struct SwapDetails {
        int128 activeSlot;
        uint256 swapLiquidity;
        uint256 amountOut;
        uint256 cumulativeFeesPerLiquidityFixedPoint;
        int128 slotIndexOfNextDelta;
        uint256 sqrtPriceOfNextDeltaFixedPoint;
        uint256 remaining;
        int256 nextDelta;
        uint256 sqrtPriceFixedPoint;
    }

    function swap(
        bytes32 poolId,
        uint256 amountIn,
        bool direction
    )
        public
        // TODO: Add an amount limit and a recipient address
        started
    {
        if (amountIn == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert(); // TODO: revert PoolNotInitialized();

        bool newEpoch = epoch.sync();
        if (newEpoch) emit SetEpoch(epoch.id, epoch.endTime);

        pool.sync(epoch);

        SwapDetails memory swapDetails = SwapDetails({
            activeSlot: pool.slotIndex,
            swapLiquidity: pool.swapLiquidity,
            amountOut: 0,
            cumulativeFeesPerLiquidityFixedPoint: 0,
            sqrtPriceOfNextDeltaFixedPoint: 0,
            slotIndexOfNextDelta: 0,
            remaining: amountIn,
            nextDelta: 0,
            sqrtPriceFixedPoint: pool.sqrtPriceFixedPoint
        });

        uint256 feeTier = msg.sender == pool.bids[epoch.id].swapper
            ? 0 : PUBLIC_SWAP_FEE;

        while (swapDetails.remaining > 0) {
            // Get the next slot or the border of a bitmap
            (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(int24(swapDetails.activeSlot));
            (bool hasNextSlot, uint8 nextSlotBit) = BitMath.findNextSlotWithinChunk(
                // If direction is true: swapping A for B
                // Decreasing the slot index -> going right into the bitmap (reducing the index)
                bitmaps[poolId][chunk],
                bit,
                !direction
            );

            swapDetails.slotIndexOfNextDelta = int128(chunk * 256 + int8(nextSlotBit));
            swapDetails.sqrtPriceOfNextDeltaFixedPoint = _getSqrtPriceAtSlot(swapDetails.slotIndexOfNextDelta);

            uint256 deltaX;
            uint256 deltaY;

            if (direction) {
                deltaX = getDeltaXToNextPrice(
                    swapDetails.sqrtPriceFixedPoint,
                    swapDetails.sqrtPriceOfNextDeltaFixedPoint,
                    swapDetails.swapLiquidity
                );

                if (swapDetails.remaining <= deltaX) {
                    uint256 feeAmount = swapDetails.remaining * feeTier / 10_000;
                    swapDetails.cumulativeFeesPerLiquidityFixedPoint += PRBMathUD60x18.div(feeAmount, swapDetails.swapLiquidity);

                    uint256 targetPrice = getTargetPriceUsingDeltaX(
                        swapDetails.sqrtPriceFixedPoint,
                        swapDetails.swapLiquidity,
                        swapDetails.remaining
                    );

                    deltaY = getDeltaYToNextPrice(
                        swapDetails.sqrtPriceFixedPoint,
                        targetPrice,
                        swapDetails.swapLiquidity
                    );

                    swapDetails.sqrtPriceFixedPoint = targetPrice;
                    swapDetails.activeSlot = _getSlotAtSqrtPrice(targetPrice);
                    swapDetails.remaining = 0;
                } else {
                    swapDetails.remaining -= deltaX;
                    swapDetails.activeSlot = swapDetails.slotIndexOfNextDelta;
                    swapDetails.sqrtPriceFixedPoint = swapDetails.sqrtPriceOfNextDeltaFixedPoint;

                    if (hasNextSlot) {
                        Slot.Data storage nextSlot = slots[Slot.getId(poolId, swapDetails.slotIndexOfNextDelta)];
                        nextSlot.sync(bitmaps[poolId], int24(swapDetails.slotIndexOfNextDelta), epoch);
                        nextSlot.cross(pool, epoch.id);


                    }
                }

                swapDetails.amountOut += deltaY;
            } else {
                deltaY = getDeltaYToNextPrice(
                    swapDetails.sqrtPriceFixedPoint,
                    _getSqrtPriceAtSlot(swapDetails.slotIndexOfNextDelta),
                    swapDetails.swapLiquidity
                );

                if (swapDetails.remaining <= deltaY) {
                    swapDetails.remaining = 0;
                } else {
                    swapDetails.remaining -= deltaY;
                }

                swapDetails.amountOut += deltaX;
            }

            if (hasNextSlot) {
                // crossing the tick
            }
        }
    }

    function bid(
        bytes32 poolId,
        uint256 epochId,
        address refunder,
        address swapper,
        uint256 amount
    ) public started {
        if (amount == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

        bool newEpoch = epoch.sync();
        if (newEpoch) emit SetEpoch(epoch.id, epoch.endTime);

        if (epochId != epoch.id + 1) revert();
        if (block.timestamp < epoch.endTime - AUCTION_LENGTH) revert();

        pool.sync(epoch); // @dev: pool needs to sync here, assumes no bids otherwise

        uint256 fee = (amount * AUCTION_FEE) / 10000;
        amount -= fee;

        if (amount > pool.bids[epochId].amount) {
            // TO-DO: balance changes for msg.sender, auctionFeeCollector, previous bid refunder
            pool.bids[epochId] = Pool.Bid({
                refunder: refunder,
                swapper: swapper,
                amount: amount,
                proceedsPerSecondFixedPoint: PRBMathUD60x18.div(amount, EPOCH_LENGTH)
            });
        }

        emit LeadingBid(poolId, epochId, swapper, amount);
    }
}
