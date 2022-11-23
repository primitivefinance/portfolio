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
        uint256 swapLiquidity;
        int256 pendingSwapLiquidity;
        uint256 maturedLiquidity;
        int256 pendingMaturedLiquidity;
        uint256 proceedsPerLiquidityInsideLastFixedPoint;
        uint256 feesAPerLiquidityInsideLastFixedPoint;
        uint256 feesBPerLiquidityInsideLastFixedPoint;
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
        uint256 epochsPassed = (epoch.endTime - (position.lastUpdatedTimestamp + 1)) / EPOCH_LENGTH;
        // TODO: double check boundary condition
        if (epochsPassed > 0) {
            if (position.pendingSwapLiquidity != 0 || position.pendingMaturedLiquidity != 0) {
                uint256 lastUpdateEpoch = epoch.id - epochsPassed;
                // update earnings through end of last update epoch
                balanceChange = position.updateEarningsThroughEpoch(
                    pool.snapshots[lastUpdateEpoch],
                    lowerSlot.snapshots[lastUpdateEpoch],
                    upperSlot.snapshots[lastUpdateEpoch]
                );

                if (position.pendingSwapLiquidity < 0) {
                    // if liquidity was kicked out, add the underlying tokens
                    (uint256 underlyingA, uint256 underlyingB) = _calculateLiquidityDeltas(
                        PRICE_GRID_FIXED_POINT,
                        uint256(position.pendingSwapLiquidity),
                        pool.snapshots[lastUpdateEpoch].sqrtPriceFixedPoint,
                        pool.snapshots[lastUpdateEpoch].slotIndex,
                        position.lowerSlotIndex,
                        position.upperSlotIndex
                    );
                    balanceChange.tokenA += underlyingA;
                    balanceChange.tokenB += underlyingB;

                    position.swapLiquidity -= uint256(position.pendingSwapLiquidity);
                }

                if (position.pendingMaturedLiquidity < 0) {
                    position.maturedLiquidity -= uint256(position.pendingMaturedLiquidity);
                } else {
                    position.maturedLiquidity += uint256(position.pendingMaturedLiquidity);
                }

                position.pendingSwapLiquidity = int256(0);
                position.pendingMaturedLiquidity = int256(0);
            }
        }

        // calculate earnings since last update
        {
            PositiveBalanceChange memory _balanceChange = position.updateEarnings(pool, lowerSlot, upperSlot);
            balanceChange.tokenA += _balanceChange.tokenA;
            balanceChange.tokenB += _balanceChange.tokenB;
            balanceChange.tokenC += _balanceChange.tokenC;
        }

        // finally update position timestamp
        position.lastUpdatedTimestamp = block.timestamp;
    }

    function updateEarnings(
        Data storage position,
        Pool.Data storage pool,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot
    ) internal returns (PositiveBalanceChange memory balanceChange) {
        (
            uint256 proceedsPerLiquidityInside,
            uint256 feesAPerLiquidityInside,
            uint256 feesBPerLiquidityInside
        ) = getEarningsInside(pool, lowerSlot, upperSlot, position.lowerSlotIndex, position.upperSlotIndex);
        balanceChange.tokenA = PRBMathUD60x18.mul(
            position.swapLiquidity,
            feesAPerLiquidityInside - position.feesAPerLiquidityInsideLastFixedPoint
        );
        balanceChange.tokenB = PRBMathUD60x18.mul(
            position.swapLiquidity,
            feesBPerLiquidityInside - position.feesBPerLiquidityInsideLastFixedPoint
        );
        if (position.maturedLiquidity > 0) {
            balanceChange.tokenC = PRBMathUD60x18.mul(
                position.maturedLiquidity,
                proceedsPerLiquidityInside - position.proceedsPerLiquidityInsideLastFixedPoint
            );
        }
        position.proceedsPerLiquidityInsideLastFixedPoint = proceedsPerLiquidityInside;
        position.feesAPerLiquidityInsideLastFixedPoint = feesAPerLiquidityInside;
        position.feesBPerLiquidityInsideLastFixedPoint = feesBPerLiquidityInside;
    }

    function updateEarningsThroughEpoch(
        Data storage position,
        Pool.Snapshot storage poolSnapshot,
        Slot.Snapshot storage lowerSlotSnapshot,
        Slot.Snapshot storage upperSlotSnapshot
    ) internal returns (PositiveBalanceChange memory balanceChange) {
        (
            uint256 proceedsPerLiquidityInsideThroughLastUpdate,
            uint256 feesAPerLiquidityInsideThroughLastUpdate,
            uint256 feesBPerLiquidityInsideThroughLastUpdate
        ) = getEarningsInsideThroughEpoch(
                poolSnapshot,
                lowerSlotSnapshot,
                upperSlotSnapshot,
                position.lowerSlotIndex,
                position.upperSlotIndex
            );
        balanceChange.tokenA = PRBMathUD60x18.mul(
            position.swapLiquidity,
            feesAPerLiquidityInsideThroughLastUpdate - position.feesAPerLiquidityInsideLastFixedPoint
        );
        balanceChange.tokenB = PRBMathUD60x18.mul(
            position.swapLiquidity,
            feesBPerLiquidityInsideThroughLastUpdate - position.feesBPerLiquidityInsideLastFixedPoint
        );
        if (position.maturedLiquidity > 0) {
            balanceChange.tokenC = PRBMathUD60x18.mul(
                position.maturedLiquidity,
                proceedsPerLiquidityInsideThroughLastUpdate - position.proceedsPerLiquidityInsideLastFixedPoint
            );
        }
        position.proceedsPerLiquidityInsideLastFixedPoint = proceedsPerLiquidityInsideThroughLastUpdate;
        position.feesAPerLiquidityInsideLastFixedPoint = feesAPerLiquidityInsideThroughLastUpdate;
        position.feesBPerLiquidityInsideLastFixedPoint = feesBPerLiquidityInsideThroughLastUpdate;
    }

    function getEarningsInside(
        Pool.Data storage pool,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    )
        internal
        view
        returns (
            uint256 proceedsPerLiquidityInside,
            uint256 feesAPerLiquidityInside,
            uint256 feesBPerLiquidityInside
        )
    {
        uint256 proceedsPerLiquidityAbove = pool.slotIndex >= upperSlotIndex
            ? pool.proceedsPerLiquidityFixedPoint - upperSlot.proceedsPerLiquidityOutsideFixedPoint
            : upperSlot.proceedsPerLiquidityOutsideFixedPoint;
        uint256 feesAPerLiquidityAbove = pool.slotIndex >= upperSlotIndex
            ? pool.feesAPerLiquidityFixedPoint - upperSlot.feesAPerLiquidityOutsideFixedPoint
            : upperSlot.feesAPerLiquidityOutsideFixedPoint;
        uint256 feesBPerLiquidityAbove = pool.slotIndex >= upperSlotIndex
            ? pool.feesBPerLiquidityFixedPoint - upperSlot.feesBPerLiquidityOutsideFixedPoint
            : upperSlot.feesBPerLiquidityOutsideFixedPoint;

        uint256 proceedsPerLiquidityBelow = pool.slotIndex >= lowerSlotIndex
            ? lowerSlot.proceedsPerLiquidityOutsideFixedPoint
            : pool.proceedsPerLiquidityFixedPoint - lowerSlot.proceedsPerLiquidityOutsideFixedPoint;
        uint256 feesAPerLiquidityBelow = pool.slotIndex >= lowerSlotIndex
            ? lowerSlot.feesAPerLiquidityOutsideFixedPoint
            : pool.feesAPerLiquidityFixedPoint - lowerSlot.feesAPerLiquidityOutsideFixedPoint;
        uint256 feesBPerLiquidityBelow = pool.slotIndex >= lowerSlotIndex
            ? lowerSlot.feesBPerLiquidityOutsideFixedPoint
            : pool.feesBPerLiquidityFixedPoint - lowerSlot.feesBPerLiquidityOutsideFixedPoint;

        proceedsPerLiquidityInside =
            pool.proceedsPerLiquidityFixedPoint -
            proceedsPerLiquidityBelow -
            proceedsPerLiquidityAbove;
        feesAPerLiquidityInside = pool.feesAPerLiquidityFixedPoint - feesAPerLiquidityBelow - feesAPerLiquidityAbove;
        feesBPerLiquidityInside = pool.feesBPerLiquidityFixedPoint - feesBPerLiquidityBelow - feesBPerLiquidityAbove;
    }

    function getEarningsInsideThroughEpoch(
        Pool.Snapshot storage poolSnapshot,
        Slot.Snapshot storage lowerSlotSnapshot,
        Slot.Snapshot storage upperSlotSnapshot,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    )
        internal
        view
        returns (
            uint256 proceedsPerLiquidityInside,
            uint256 feesAPerLiquidityInside,
            uint256 feesBPerLiquidityInside
        )
    {
        uint256 proceedsPerLiquidityAbove = poolSnapshot.slotIndex >= upperSlotIndex
            ? poolSnapshot.proceedsPerLiquidityFixedPoint - upperSlotSnapshot.proceedsPerLiquidityOutsideFixedPoint
            : upperSlotSnapshot.proceedsPerLiquidityOutsideFixedPoint;
        uint256 feesAPerLiquidityAbove = poolSnapshot.slotIndex >= upperSlotIndex
            ? poolSnapshot.feesAPerLiquidityFixedPoint - upperSlotSnapshot.feesAPerLiquidityOutsideFixedPoint
            : upperSlotSnapshot.feesAPerLiquidityOutsideFixedPoint;
        uint256 feesBPerLiquidityAbove = poolSnapshot.slotIndex >= upperSlotIndex
            ? poolSnapshot.feesBPerLiquidityFixedPoint - upperSlotSnapshot.feesBPerLiquidityOutsideFixedPoint
            : upperSlotSnapshot.feesBPerLiquidityOutsideFixedPoint;

        uint256 proceedsPerLiquidityBelow = poolSnapshot.slotIndex >= lowerSlotIndex
            ? lowerSlotSnapshot.proceedsPerLiquidityOutsideFixedPoint
            : poolSnapshot.proceedsPerLiquidityFixedPoint - lowerSlotSnapshot.proceedsPerLiquidityOutsideFixedPoint;
        uint256 feesAPerLiquidityBelow = poolSnapshot.slotIndex >= lowerSlotIndex
            ? lowerSlotSnapshot.feesAPerLiquidityOutsideFixedPoint
            : poolSnapshot.feesAPerLiquidityFixedPoint - lowerSlotSnapshot.feesAPerLiquidityOutsideFixedPoint;
        uint256 feesBPerLiquidityBelow = poolSnapshot.slotIndex >= lowerSlotIndex
            ? lowerSlotSnapshot.feesBPerLiquidityOutsideFixedPoint
            : poolSnapshot.feesBPerLiquidityFixedPoint - lowerSlotSnapshot.feesBPerLiquidityOutsideFixedPoint;

        proceedsPerLiquidityInside =
            poolSnapshot.proceedsPerLiquidityFixedPoint -
            proceedsPerLiquidityBelow -
            proceedsPerLiquidityAbove;
        feesAPerLiquidityInside =
            poolSnapshot.feesAPerLiquidityFixedPoint -
            feesAPerLiquidityBelow -
            feesAPerLiquidityAbove;
        feesBPerLiquidityInside =
            poolSnapshot.feesBPerLiquidityFixedPoint -
            feesBPerLiquidityBelow -
            feesBPerLiquidityAbove;
    }
}
