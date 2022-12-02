// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {EPOCH_LENGTH} from "./GlobalDefaults.sol";

import "./BrainMath.sol";
import {Epoch} from "./Epoch.sol";
import {Pool, PoolSnapshot} from "./Pool.sol";
import {Slot, SlotSnapshot} from "./Slot.sol";

using {sync} for Position global;
using {updateEarnings, updateEarningsThroughEpoch} for Position;

struct Position {
    int128 lowerSlotIndex;
    int128 upperSlotIndex;
    uint256 swapLiquidity;
    uint256 maturedLiquidity;
    int256 pendingLiquidity;
    uint256 proceedsPerLiquidityInsideLastFixedPoint;
    uint256 feesAPerLiquidityInsideLastFixedPoint;
    uint256 feesBPerLiquidityInsideLastFixedPoint;
    uint256 lastUpdatedTimestamp;
}

function getPositionId(
    address owner,
    bytes32 poolId,
    int128 lowerSlotIndex,
    int128 upperSlotIndex
) pure returns (bytes32) {
    return keccak256(abi.encodePacked(owner, poolId, lowerSlotIndex, upperSlotIndex));
}

struct PositiveBalanceChange {
    uint256 tokenA;
    uint256 tokenB;
    uint256 tokenC;
}

function sync(
    Position storage position,
    Pool storage pool,
    Slot storage lowerSlot,
    Slot storage upperSlot,
    Epoch memory epoch
) returns (PositiveBalanceChange memory balanceChange) {
    uint256 epochsPassed = (epoch.endTime - (position.lastUpdatedTimestamp + 1)) / EPOCH_LENGTH;
    // TODO: double check boundary condition
    if (epochsPassed > 0) {
        if (position.pendingLiquidity != 0) {
            uint256 lastUpdateEpoch = epoch.id - epochsPassed;
            // update earnings through end of last update epoch
            balanceChange = position.updateEarningsThroughEpoch(
                pool.snapshots[lastUpdateEpoch],
                lowerSlot.snapshots[lastUpdateEpoch],
                upperSlot.snapshots[lastUpdateEpoch]
            );

            if (position.pendingLiquidity < 0) {
                // if liquidity was kicked out, add the underlying tokens
                (uint256 underlyingA, uint256 underlyingB) = _calculateLiquidityDeltas(
                    uint256(position.pendingLiquidity),
                    pool.snapshots[lastUpdateEpoch].sqrtPriceFixedPoint,
                    pool.snapshots[lastUpdateEpoch].slotIndex,
                    position.lowerSlotIndex,
                    position.upperSlotIndex
                );
                balanceChange.tokenA += underlyingA;
                balanceChange.tokenB += underlyingB;

                position.maturedLiquidity -= uint256(position.pendingLiquidity);
            } else {
                position.maturedLiquidity += uint256(position.pendingLiquidity);
            }
            pool.swapLiquidity = position.maturedLiquidity;
            pool.pendingLiquidity = int256(0);
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
    Position storage position,
    Pool storage pool,
    Slot storage lowerSlot,
    Slot storage upperSlot
) returns (PositiveBalanceChange memory balanceChange) {
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
    Position storage position,
    PoolSnapshot storage poolSnapshot,
    SlotSnapshot storage lowerSlotSnapshot,
    SlotSnapshot storage upperSlotSnapshot
) returns (PositiveBalanceChange memory balanceChange) {
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
    Pool storage pool,
    Slot storage lowerSlot,
    Slot storage upperSlot,
    int128 lowerSlotIndex,
    int128 upperSlotIndex
)
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
    PoolSnapshot storage poolSnapshot,
    SlotSnapshot storage lowerSlotSnapshot,
    SlotSnapshot storage upperSlotSnapshot,
    int128 lowerSlotIndex,
    int128 upperSlotIndex
)
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
