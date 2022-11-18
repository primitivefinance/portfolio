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
// - Epochs / staking feature
// - Auction
// - Events
// - Custom errors
// - Interface
// - Change `addLiquidity` to `updateLiquidity`
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

    function addLiquidity(
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        uint256 amount
    ) public {
        if (lowerSlotIndex > upperSlotIndex) revert();
        if (amount == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

        epoch.sync();
        pool.sync(epoch, poolId, poolSnapshots);

        bytes32 positionId = Position.getId(msg.sender, poolId, lowerSlotIndex, upperSlotIndex);
        Position.Data storage position = positions[positionId];

        bytes32 lowerSlotId = Slot.getId(poolId, position.lowerSlotIndex);
        Slot.Data storage lowerSlot = slots[lowerSlotId];
        lowerSlot.sync(epoch);

        bytes32 upperSlotId = Slot.getId(poolId, position.upperSlotIndex);
        Slot.Data storage upperSlot = slots[upperSlotId];
        upperSlot.sync(epoch);

        if (position.lastUpdatedTimestamp != 0) {
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

        position.liquidity += amount;
        position.liquidityPending += int256(amount);

        {
            lowerSlot.liquidityDelta += int256(amount);
            lowerSlot.liquidityPendingDelta += int256(amount);

            if (lowerSlot.liquidityGross == uint256(0)) {
                // TODO: add to / initialize slot in bitmap
                // TODO: initialize growth outside values
                lowerSlot.liquidityGross += uint256(amount);
            }
        }

        {
            upperSlot.liquidityDelta -= int256(amount);
            upperSlot.liquidityPendingDelta -= int256(amount);

            if (upperSlot.liquidityGross == uint256(0)) {
                // TODO: add to / initialize slot in bitmap
                // TODO: initialize growth outside values
                upperSlot.liquidityGross += uint256(amount);
            }
        }

        {
            (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
                PRICE_GRID_FIXED_POINT,
                amount,
                pool.activeSqrtPriceFixedPoint,
                pool.activeSlotIndex,
                lowerSlotIndex,
                upperSlotIndex
            );
            if (amountA != 0 && amountB != 0) {
                pool.activeLiquidity += amount;
                pool.activeLiquidityPending += int256(amount);
            }
        }

        // TODO: Request tokens from msg.sender

        // TODO: emit AddLiquidity event
    }

    function removeLiquidity(
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        uint256 amount
    ) public {
        if (lowerSlotIndex > upperSlotIndex) revert();
        if (amount == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

        epoch.sync();
        pool.sync(epoch, poolId, poolSnapshots);

        bytes32 positionId = Position.getId(msg.sender, poolId, lowerSlotIndex, upperSlotIndex);
        Position.Data storage position = positions[positionId];

        bytes32 lowerSlotId = Slot.getId(poolId, position.lowerSlotIndex);
        Slot.Data storage lowerSlot = slots[lowerSlotId];
        lowerSlot.sync(epoch);

        bytes32 upperSlotId = Slot.getId(poolId, position.upperSlotIndex);
        Slot.Data storage upperSlot = slots[upperSlotId];
        upperSlot.sync(epoch);

        if (position.lastUpdatedTimestamp != 0) {
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

        // a few cases
        // 1. positive liquidity pending is enough to cover withdrawal, in which case tokens are sent now
        // 2. something else
        // 3. something else

        uint256 remainingLiquidity = position.liquidityPending > int256(0)
            ? position.liquidity
            : position.liquidity - uint256(position.liquidityPending);
        require(remainingLiquidity >= amount);

        {
            lowerSlot.liquidityPendingDelta -= int256(amount);
            lowerSlot.pendingLiquidityGross -= int256(amount);
        }

        {
            upperSlot.liquidityDelta -= int256(amount);
            upperSlot.liquidityPendingDelta -= int256(amount);

            if (upperSlot.liquidityGross == uint256(0)) {
                // TODO: add to / initialize slot in bitmap
                // TODO: initialize growth outside values
                upperSlot.liquidityGross += uint256(amount);
            }
        }

        {
            (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
                PRICE_GRID_FIXED_POINT,
                amount,
                pool.activeSqrtPriceFixedPoint,
                pool.activeSlotIndex,
                lowerSlotIndex,
                upperSlotIndex
            );
            if (amountA != 0 && amountB != 0) {
                pool.activeLiquidity += amount;
                pool.activeLiquidityPending += int256(amount);
            }
        }

        // TODO: Request tokens from msg.sender

        // TODO: emit AddLiquidity event
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
}
