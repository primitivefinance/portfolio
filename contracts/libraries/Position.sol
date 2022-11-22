// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BrainMath.sol";
import "./Epoch.sol";
import "./GlobalDefaults.sol";
import "./Pool.sol";
import "./Slot.sol";

/// @title   Pool Library
/// @author  Primitive
/// @dev     Data structure library for Positions
library Position {
    using Epoch for Epoch.Data;
    using Pool for Pool.Data;
    using Pool for mapping(bytes32 => Pool.Data);
    using Position for Position.Data;
    using Slot for Slot.Data;
    using Slot for mapping(bytes32 => Slot.Data);

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
        uint256 lastUpdatedTimestamp;
    }

    struct PositiveBalanceChange {
        uint256 tokenA;
        uint256 tokenB;
        uint256 tokenC;
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
        Pool.Data storage pool,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot,
        Epoch.Data memory epoch
    ) internal returns (PositiveBalanceChange memory balanceChange) {
        uint256 epochsPassed = (epoch.endTime - position.lastUpdatedTimestamp) / EPOCH_LENGTH;
        if (epochsPassed > 0) {
            if (position.liquidityPending != 0) {
                uint256 lastUpdateEpoch = epoch.id - epochsPassed;
                // update growth values through end of pending epoch
                balanceChange = position.updateGrowthThroughEpoch(
                    pool.snapshots[lastUpdateEpoch],
                    lowerSlot.snapshots[lastUpdateEpoch],
                    upperSlot.snapshots[lastUpdateEpoch]
                );

                if (position.liquidityPending < 0) {
                    // if liquidity was kicked out, add the underlying tokens
                    (uint256 underlyingA, uint256 underlyingB) = _calculateLiquidityDeltas(
                        PRICE_GRID_FIXED_POINT,
                        uint256(position.liquidityPending),
                        pool.snapshots[lastUpdateEpoch].activeSqrtPriceFixedPoint,
                        pool.snapshots[lastUpdateEpoch].activeSlotIndex,
                        position.lowerSlotIndex,
                        position.upperSlotIndex
                    );
                    balanceChange.tokenA += underlyingA;
                    balanceChange.tokenB += underlyingB;

                    position.liquidity -= uint256(position.liquidityPending);
                    position.liquidityMatured -= uint256(position.liquidityPending);
                } else {
                    position.liquidityMatured += uint256(position.liquidityPending);
                }
                position.liquidityPending = int256(0);
            }
        }

        // calculate earned tokens due to growth since last update
        {
            PositiveBalanceChange memory _balanceChange = position.updateGrowth(pool, lowerSlot, upperSlot);
            balanceChange.tokenA += _balanceChange.tokenA;
            balanceChange.tokenB += _balanceChange.tokenB;
            balanceChange.tokenC += _balanceChange.tokenC;
        }

        // finally update position timestamp
        position.lastUpdatedTimestamp = block.timestamp;
    }

    function updateGrowth(
        Data storage position,
        Pool.Data storage pool,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot
    ) internal returns (PositiveBalanceChange memory balanceChange) {
        (uint256 proceedsGrowthInside, uint256 feeGrowthInsideA, uint256 feeGrowthInsideB) = getGrowthInside(
            pool,
            lowerSlot,
            upperSlot,
            position.lowerSlotIndex,
            position.upperSlotIndex
        );
        balanceChange.tokenA = PRBMathUD60x18.mul(
            position.liquidity,
            feeGrowthInsideA - position.feeGrowthInsideLastAFixedPoint
        );
        balanceChange.tokenB = PRBMathUD60x18.mul(
            position.liquidity,
            feeGrowthInsideB - position.feeGrowthInsideLastBFixedPoint
        );
        if (position.liquidityMatured > 0) {
            balanceChange.tokenC = PRBMathUD60x18.mul(
                position.liquidityMatured,
                proceedsGrowthInside - position.proceedsGrowthInsideLastFixedPoint
            );
        }
        position.proceedsGrowthInsideLastFixedPoint = proceedsGrowthInside;
        position.feeGrowthInsideLastAFixedPoint = feeGrowthInsideA;
        position.feeGrowthInsideLastBFixedPoint = feeGrowthInsideB;
    }

    function updateGrowthThroughEpoch(
        Data storage position,
        Pool.Snapshot storage poolSnapshot,
        Slot.Snapshot storage lowerSlotSnapshot,
        Slot.Snapshot storage upperSlotSnapshot
    ) internal returns (PositiveBalanceChange memory balanceChange) {
        (
            uint256 proceedsGrowthInsideThroughLastUpdate,
            uint256 feeGrowthInsideAThroughLastUpdate,
            uint256 feeGrowthInsideBThroughLastUpdate
        ) = getGrowthInsideThroughEpoch(
                poolSnapshot,
                lowerSlotSnapshot,
                upperSlotSnapshot,
                position.lowerSlotIndex,
                position.upperSlotIndex
            );
        balanceChange.tokenA = PRBMathUD60x18.mul(
            position.liquidity,
            feeGrowthInsideAThroughLastUpdate - position.feeGrowthInsideLastAFixedPoint
        );
        balanceChange.tokenB = PRBMathUD60x18.mul(
            position.liquidity,
            feeGrowthInsideBThroughLastUpdate - position.feeGrowthInsideLastBFixedPoint
        );
        if (position.liquidityMatured > 0) {
            balanceChange.tokenC = PRBMathUD60x18.mul(
                position.liquidityMatured,
                proceedsGrowthInsideThroughLastUpdate - position.proceedsGrowthInsideLastFixedPoint
            );
        }
        position.proceedsGrowthInsideLastFixedPoint = proceedsGrowthInsideThroughLastUpdate;
        position.feeGrowthInsideLastAFixedPoint = feeGrowthInsideAThroughLastUpdate;
        position.feeGrowthInsideLastBFixedPoint = feeGrowthInsideBThroughLastUpdate;
    }

    function getGrowthInside(
        Pool.Data storage pool,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    )
        internal
        view
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
        Pool.Snapshot storage poolSnapshot,
        Slot.Snapshot storage lowerSlotSnapshot,
        Slot.Snapshot storage upperSlotSnapshot,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    )
        internal
        view
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
