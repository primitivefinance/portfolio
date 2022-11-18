// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BrainMath.sol";
import "./Epoch.sol";
import "./GlobalDefaults.sol";
import "./Pool.sol";
import "./Slot.sol";
import "./PoolSnapshot.sol";
import "./SlotSnapshot.sol";

/// @title   Pool Library
/// @author  Primitive
/// @dev     Data structure library for Positions
library Position {
    using Epoch for Epoch.Data;
    using Pool for Pool.Data;
    using Pool for mapping(bytes32 => Pool.Data);
    using PoolSnapshot for PoolSnapshot.Data;
    using PoolSnapshot for mapping(bytes32 => PoolSnapshot.Data);
    using Slot for Slot.Data;
    using Slot for mapping(bytes32 => Slot.Data);
    using SlotSnapshot for SlotSnapshot.Data;
    using SlotSnapshot for mapping(bytes32 => SlotSnapshot.Data);

    /// @notice                Stores the state of a position
    struct Data {
        int128 lowerSlotIndex;
        int128 upperSlotIndex;
        uint256 liquidity;
        uint256 liquidityMatured;
        int256 liquidityPending;
        uint256 proceedsGrowthInsideLastFixedPoint;
        uint256 feeGrowthInsideLastAFixedPoint;
        uint256 feeGrowthInsideLastBFixedPoint;
        uint256 tokensOwedA;
        uint256 tokensOwedB;
        uint256 tokensOwedC; // auction settlement token
        uint256 lastUpdatedTimestamp;
    }

    function getId(
        address owner,
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, poolId, lowerSlotIndex, upperSlotIndex));
    }

    /// @notice                Updates the position data w.r.t. time passing
    /// @dev                   Assumes the position has been initialized.
    function sync(
        Data storage position,
        Pool.Data memory pool,
        Epoch.Data memory epoch,
        Slot.Data memory lowerSlot,
        Slot.Data memory upperSlot,
        bytes32 poolId,
        bytes32 lowerSlotId,
        bytes32 upperSlotId,
        mapping(bytes32 => PoolSnapshot.Data) storage poolSnapshots,
        mapping(bytes32 => SlotSnapshot.Data) storage slotSnapshots
    ) internal {
        uint256 epochsPassed = (epoch.endTime - position.lastUpdatedTimestamp) / EPOCH_LENGTH;
        if (epochsPassed > 0) {
            if (position.liquidityPending != 0) {
                // get proceed & fee growth inside through the end of the pending epoch
                uint256 lastUpdateEpoch = epoch.id - epochsPassed;
                PoolSnapshot.Data memory poolSnapshot = poolSnapshots[PoolSnapshot.getId(poolId, lastUpdateEpoch)];
                (
                    uint256 proceedsGrowthInsideThroughLastUpdate,
                    uint256 feeGrowthInsideAThroughLastUpdate,
                    uint256 feeGrowthInsideBThroughLastUpdate
                ) = getGrowthInsideThroughEpoch(
                        poolSnapshot,
                        slotSnapshots[SlotSnapshot.getId(lowerSlotId, lastUpdateEpoch)],
                        slotSnapshots[SlotSnapshot.getId(upperSlotId, lastUpdateEpoch)],
                        position.lowerSlotIndex,
                        position.upperSlotIndex
                    );
                // update tokens owed before pending state applied
                position.tokensOwedA += PRBMathUD60x18.mul(
                    position.liquidity,
                    feeGrowthInsideAThroughLastUpdate - position.feeGrowthInsideLastAFixedPoint
                );
                position.tokensOwedB += PRBMathUD60x18.mul(
                    position.liquidity,
                    feeGrowthInsideBThroughLastUpdate - position.feeGrowthInsideLastBFixedPoint
                );
                if (position.liquidityMatured > 0) {
                    position.tokensOwedC += PRBMathUD60x18.mul(
                        position.liquidityMatured,
                        proceedsGrowthInsideThroughLastUpdate - position.proceedsGrowthInsideLastFixedPoint
                    );
                }
                position.proceedsGrowthInsideLastFixedPoint = proceedsGrowthInsideThroughLastUpdate;
                position.feeGrowthInsideLastAFixedPoint = feeGrowthInsideAThroughLastUpdate;
                position.feeGrowthInsideLastBFixedPoint = feeGrowthInsideBThroughLastUpdate;
                // if liquidity was kicked out, add the underlying tokens to tokens owed
                if (position.liquidityPending < 0) {
                    (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
                        PRICE_GRID_FIXED_POINT,
                        uint256(position.liquidityPending),
                        poolSnapshot.activeSqrtPriceFixedPoint,
                        poolSnapshot.activeSlotIndex,
                        position.lowerSlotIndex,
                        position.upperSlotIndex
                    );
                    position.tokensOwedA += amountA;
                    position.tokensOwedB += amountB;
                    position.liquidity -= uint256(position.liquidityPending);
                    position.liquidityMatured -= uint256(position.liquidityPending);
                } else {
                    // liquidity matured
                    position.liquidityMatured += uint256(position.liquidityPending);
                }
                // zero out pending liquidity
                position.liquidityPending = int256(0);
            }
        }

        // calculate tokens owed due to growth since last update
        (uint256 proceedsGrowthInside, uint256 feeGrowthInsideA, uint256 feeGrowthInsideB) = getGrowthInside(
            pool,
            lowerSlot,
            upperSlot,
            position.lowerSlotIndex,
            position.upperSlotIndex
        );
        position.tokensOwedA += PRBMathUD60x18.mul(
            position.liquidity,
            feeGrowthInsideA - position.feeGrowthInsideLastAFixedPoint
        );
        position.tokensOwedB += PRBMathUD60x18.mul(
            position.liquidity,
            feeGrowthInsideB - position.feeGrowthInsideLastBFixedPoint
        );
        if (position.liquidityMatured > 0) {
            position.tokensOwedC += PRBMathUD60x18.mul(
                position.liquidityMatured,
                proceedsGrowthInside - position.proceedsGrowthInsideLastFixedPoint
            );
        }
        position.proceedsGrowthInsideLastFixedPoint = proceedsGrowthInside;
        position.feeGrowthInsideLastAFixedPoint = feeGrowthInsideA;
        position.feeGrowthInsideLastBFixedPoint = feeGrowthInsideB;

        position.lastUpdatedTimestamp = block.timestamp;
    }

    function getGrowthInside(
        Pool.Data memory pool,
        Slot.Data memory lowerSlot,
        Slot.Data memory upperSlot,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    )
        internal
        pure
        returns (
            uint256 proceedsGrowthInside,
            uint256 feeGrowthInsideA,
            uint256 feeGrowthInsideB
        )
    {
        uint256 proceedsGrowthAbove = pool.activeSlotIndex >= upperSlotIndex
            ? pool.proceedsGrowthGlobalFixedPoint - upperSlot.proceedsGrowthOutsideFixedPoint
            : upperSlot.proceedsGrowthOutsideFixedPoint;
        uint256 feeGrowthAboveA = pool.activeSlotIndex >= upperSlotIndex
            ? pool.feeGrowthGlobalAFixedPoint - upperSlot.feeGrowthOutsideAFixedPoint
            : upperSlot.feeGrowthOutsideAFixedPoint;
        uint256 feeGrowthAboveB = pool.activeSlotIndex >= upperSlotIndex
            ? pool.feeGrowthGlobalBFixedPoint - upperSlot.feeGrowthOutsideBFixedPoint
            : upperSlot.feeGrowthOutsideBFixedPoint;

        uint256 proceedsGrowthBelow = pool.activeSlotIndex >= lowerSlotIndex
            ? lowerSlot.proceedsGrowthOutsideFixedPoint
            : pool.proceedsGrowthGlobalFixedPoint - lowerSlot.proceedsGrowthOutsideFixedPoint;
        uint256 feeGrowthBelowA = pool.activeSlotIndex >= lowerSlotIndex
            ? lowerSlot.feeGrowthOutsideAFixedPoint
            : pool.feeGrowthGlobalAFixedPoint - lowerSlot.feeGrowthOutsideAFixedPoint;
        uint256 feeGrowthBelowB = pool.activeSlotIndex >= lowerSlotIndex
            ? lowerSlot.feeGrowthOutsideBFixedPoint
            : pool.feeGrowthGlobalBFixedPoint - lowerSlot.feeGrowthOutsideBFixedPoint;

        proceedsGrowthInside = pool.proceedsGrowthGlobalFixedPoint - proceedsGrowthBelow - proceedsGrowthAbove;
        feeGrowthInsideA = pool.feeGrowthGlobalAFixedPoint - feeGrowthBelowA - feeGrowthAboveA;
        feeGrowthInsideB = pool.feeGrowthGlobalBFixedPoint - feeGrowthBelowB - feeGrowthAboveB;
    }

    function getGrowthInsideThroughEpoch(
        PoolSnapshot.Data memory poolSnapshot,
        SlotSnapshot.Data memory lowerSlotSnapshot,
        SlotSnapshot.Data memory upperSlotSnapshot,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    )
        internal
        pure
        returns (
            uint256 proceedsGrowthInside,
            uint256 feeGrowthInsideA,
            uint256 feeGrowthInsideB
        )
    {
        uint256 proceedsGrowthAbove = poolSnapshot.activeSlotIndex >= upperSlotIndex
            ? poolSnapshot.proceedsGrowthGlobalFixedPoint - upperSlotSnapshot.proceedsGrowthOutsideFixedPoint
            : upperSlotSnapshot.proceedsGrowthOutsideFixedPoint;
        uint256 feeGrowthAboveA = poolSnapshot.activeSlotIndex >= upperSlotIndex
            ? poolSnapshot.feeGrowthGlobalAFixedPoint - upperSlotSnapshot.feeGrowthOutsideAFixedPoint
            : upperSlotSnapshot.feeGrowthOutsideAFixedPoint;
        uint256 feeGrowthAboveB = poolSnapshot.activeSlotIndex >= upperSlotIndex
            ? poolSnapshot.feeGrowthGlobalBFixedPoint - upperSlotSnapshot.feeGrowthOutsideBFixedPoint
            : upperSlotSnapshot.feeGrowthOutsideBFixedPoint;

        uint256 proceedsGrowthBelow = poolSnapshot.activeSlotIndex >= lowerSlotIndex
            ? lowerSlotSnapshot.proceedsGrowthOutsideFixedPoint
            : poolSnapshot.proceedsGrowthGlobalFixedPoint - lowerSlotSnapshot.proceedsGrowthOutsideFixedPoint;
        uint256 feeGrowthBelowA = poolSnapshot.activeSlotIndex >= lowerSlotIndex
            ? lowerSlotSnapshot.feeGrowthOutsideAFixedPoint
            : poolSnapshot.feeGrowthGlobalAFixedPoint - lowerSlotSnapshot.feeGrowthOutsideAFixedPoint;
        uint256 feeGrowthBelowB = poolSnapshot.activeSlotIndex >= lowerSlotIndex
            ? lowerSlotSnapshot.feeGrowthOutsideBFixedPoint
            : poolSnapshot.feeGrowthGlobalBFixedPoint - lowerSlotSnapshot.feeGrowthOutsideBFixedPoint;

        proceedsGrowthInside = poolSnapshot.proceedsGrowthGlobalFixedPoint - proceedsGrowthBelow - proceedsGrowthAbove;
        feeGrowthInsideA = poolSnapshot.feeGrowthGlobalAFixedPoint - feeGrowthBelowA - feeGrowthAboveA;
        feeGrowthInsideB = poolSnapshot.feeGrowthGlobalBFixedPoint - feeGrowthBelowB - feeGrowthAboveB;
    }
}
