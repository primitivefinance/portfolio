// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./libraries/BrainMath.sol";
import "./libraries/Epoch.sol";
import "./libraries/GlobalDefaults.sol";
import "./libraries/Pool.sol";
import "./libraries/PoolSnapshot.sol";
import "./libraries/Position.sol";
import "./libraries/Slot.sol";
import "./libraries/SlotSnapshot.sol";

// TODO:
// - Add WETH wrapping / unwrapping
// - Add the internal balances, fund and withdraw
// - Add Multicall?
// - Fixed point library
// - Slippage checks
// - Extra function parameters
// - Events
// - Custom errors
// - Interface
// - slots bitmap

contract Smol {
    using Epoch for Epoch.Data;
    using Pool for Pool.Data;
    using Pool for mapping(bytes32 => Pool.Data);
    using PoolSnapshot for PoolSnapshot.Data;
    using PoolSnapshot for mapping(bytes32 => PoolSnapshot.Data);
    using Position for Position.Data;
    using Position for mapping(bytes32 => Position.Data);
    using Slot for Slot.Data;
    using Slot for mapping(bytes32 => Slot.Data);
    using SlotSnapshot for SlotSnapshot.Data;
    using SlotSnapshot for mapping(bytes32 => SlotSnapshot.Data);

    Epoch.Data public epoch;

    mapping(bytes32 => Pool.Data) public pools;
    mapping(bytes32 => Position.Data) public positions;
    mapping(bytes32 => Slot.Data) public slots;

    mapping(bytes32 => PoolSnapshot.Data) private poolSnapshots;
    mapping(bytes32 => SlotSnapshot.Data) private slotSnapshots;

    constructor(uint256 transitionTime) {
        require(transitionTime > block.timestamp);
        epoch = Epoch.Data({id: 0, endTime: transitionTime});
    }

    function activatePool(
        address tokenA,
        address tokenB,
        uint256 activeSqrtPriceFixedPoint
    ) public {
        epoch.sync();
        pools.activate(tokenA, tokenB, activeSqrtPriceFixedPoint);

        // TODO: emit ActivatePool event
    }

    function updateLiquidity(
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        int256 amount
    ) public {
        if (lowerSlotIndex > upperSlotIndex) revert();
        if (amount == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

        epoch.sync();
        pool.sync(epoch, poolId, poolSnapshots);

        bytes32 lowerSlotId = Slot.getId(poolId, lowerSlotIndex);
        Slot.Data storage lowerSlot = slots[lowerSlotId];
        lowerSlot.sync(epoch);

        bytes32 upperSlotId = Slot.getId(poolId, upperSlotIndex);
        Slot.Data storage upperSlot = slots[upperSlotId];
        upperSlot.sync(epoch);

        bytes32 positionId = Position.getId(msg.sender, poolId, lowerSlotIndex, upperSlotIndex);
        Position.Data storage position = positions[positionId];

        if (position.lastUpdatedTimestamp == 0) {
            if (amount < 0) revert();
            position.lowerSlotIndex = lowerSlotIndex;
            position.upperSlotIndex = upperSlotIndex;
            position.lastUpdatedTimestamp = block.timestamp;
        } else {
            position.sync(
                pool,
                epoch,
                lowerSlot,
                upperSlot,
                poolId,
                lowerSlotId,
                upperSlotId,
                poolSnapshots,
                slotSnapshots
            );
        }

        if (amount > 0) {
            _addLiquidity(pool, lowerSlot, upperSlot, position, uint256(amount));
        } else {
            _removeLiquidity(pool, lowerSlotId, upperSlotId, lowerSlot, upperSlot, position, uint256(amount));
        }
    }

    function _addLiquidity(
        Pool.Data storage pool,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot,
        Position.Data storage position,
        uint256 amount
    ) internal {
        position.liquidity += amount;
        position.liquidityPending += int256(amount);

        lowerSlot.liquidityDelta += int256(amount);
        lowerSlot.liquidityPendingDelta += int256(amount);
        if (lowerSlot.liquidityGross == uint256(0)) {
            // TODO: add to / initialize slot in bitmap
            // TODO: initialize growth outside values
            lowerSlot.liquidityGross += uint256(amount);
        }

        upperSlot.liquidityDelta -= int256(amount);
        upperSlot.liquidityPendingDelta -= int256(amount);
        if (upperSlot.liquidityGross == uint256(0)) {
            // TODO: add to / initialize slot in bitmap
            // TODO: initialize growth outside values
            upperSlot.liquidityGross += uint256(amount);
        }

        (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
            PRICE_GRID_FIXED_POINT,
            amount,
            pool.activeSqrtPriceFixedPoint,
            pool.activeSlotIndex,
            position.lowerSlotIndex,
            position.upperSlotIndex
        );
        if (amountA != 0 && amountB != 0) {
            pool.activeLiquidity += amount;
            pool.activeLiquidityPending += int256(amount);
        }
        // TODO: Request amountA & amountB from msg.sender

        // TODO: Emit add liquidity event
    }

    function _removeLiquidity(
        Pool.Data storage pool,
        bytes32 lowerSlotId,
        bytes32 upperSlotId,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot,
        Position.Data storage position,
        uint256 amount
    ) internal {
        uint256 removeAmountLeft = amount;

        // remove positive pending liquidity balance immediately
        if (position.liquidityPending > int256(0)) {
            // pending + matured = position.liquidity when liquidity pending is positive
            if (position.liquidity < amount) revert();

            uint256 removeLiquidityPending = uint256(position.liquidityPending) >= amount
                ? amount
                : uint256(position.liquidityPending);

            lowerSlot.liquidityDelta -= int256(removeLiquidityPending);
            lowerSlot.liquidityPendingDelta -= int256(removeLiquidityPending);
            lowerSlot.liquidityGross -= removeLiquidityPending;

            upperSlot.liquidityDelta += int256(removeLiquidityPending);
            upperSlot.liquidityPendingDelta += int256(removeLiquidityPending);
            upperSlot.liquidityGross -= removeLiquidityPending;

            position.liquidity -= removeLiquidityPending;
            position.liquidityPending -= int256(removeLiquidityPending);

            // credit tokens owed to the position immediately
            (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
                PRICE_GRID_FIXED_POINT,
                removeLiquidityPending,
                pool.activeSqrtPriceFixedPoint,
                pool.activeSlotIndex,
                position.lowerSlotIndex,
                position.upperSlotIndex
            );

            position.tokensOwedA += amountA;
            position.tokensOwedB += amountB;

            if (amountA != 0 && amountB != 0) {
                pool.activeLiquidity -= removeLiquidityPending;
                pool.activeLiquidityPending -= int256(removeLiquidityPending);
            }

            removeAmountLeft -= removeLiquidityPending;
        } else {
            // pending + position.liquidity = remaining liquidity when liquidity pending is negative (or zero)
            if (position.liquidity - uint256(position.liquidityPending) < amount) revert();
        }

        // schedule removeAmountLeft to be removed from remaining liquidity
        if (removeAmountLeft > 0) {
            lowerSlot.liquidityPendingDelta -= int256(removeAmountLeft);
            upperSlot.liquidityPendingDelta += int256(removeAmountLeft);

            position.liquidityPending -= int256(removeAmountLeft);

            if (position.lowerSlotIndex <= pool.activeSlotIndex && pool.activeSlotIndex < position.upperSlotIndex) {
                pool.activeLiquidityPending -= int256(removeAmountLeft);
            }
        }

        // save slot snapshots
        slotSnapshots[SlotSnapshot.getId(lowerSlotId, epoch.id)] = SlotSnapshot.Data({
            proceedsGrowthOutsideFixedPoint: lowerSlot.proceedsGrowthOutsideFixedPoint,
            feeGrowthOutsideAFixedPoint: lowerSlot.feeGrowthOutsideAFixedPoint,
            feeGrowthOutsideBFixedPoint: lowerSlot.feeGrowthOutsideBFixedPoint
        });
        slotSnapshots[SlotSnapshot.getId(upperSlotId, epoch.id)] = SlotSnapshot.Data({
            proceedsGrowthOutsideFixedPoint: upperSlot.proceedsGrowthOutsideFixedPoint,
            feeGrowthOutsideAFixedPoint: upperSlot.feeGrowthOutsideAFixedPoint,
            feeGrowthOutsideBFixedPoint: upperSlot.feeGrowthOutsideBFixedPoint
        });

        // TODO: emit RemoveLiquidity event
    }

    struct SwapCache {
        int128 activeSlotIndex;
        uint256 slotProportionF;
        uint256 activeLiquidity;
        uint256 activePrice;
        int128 slotIndexOfNextDelta;
        int128 nextDelta;
    }

    function swap(
        address tokenA,
        address tokenB,
        uint256 tendered,
        bool direction
    ) public {
        uint256 tenderedRemaining = tendered;
        uint256 received;

        uint256 cumulativeFees;
        SwapCache memory swapCache;

        if (!direction) {} else {}
    }

    function bid(
        bytes32 poolId,
        uint256 epochId,
        uint256 amount,
        address arbRightOwner
    ) public {
        if (amount == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

        epoch.sync();
        if (epochId != epoch.id + 1) revert();
        if (block.timestamp < epoch.endTime - AUCTION_LENGTH) revert();

        pool.sync(epoch, poolId, poolSnapshots); // @dev: pool needs to sync here, assumes no bids otherwise

        // TODO: take fee from bid

        uint256 bidProceedsPerSecondFixedPoint = PRBMathUD60x18.div(amount, EPOCH_LENGTH);
        if (bidProceedsPerSecondFixedPoint > pool.pendingProceedsPerSecondFixedPoint) {
            // TODO: Request auction settlement tokens from bidder
            // TODO: Refund previous bid
            pool.pendingProceedsPerSecondFixedPoint = bidProceedsPerSecondFixedPoint;
            pool.pendingArbRightOwner = arbRightOwner;
        }
    }
}
