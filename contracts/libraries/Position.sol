// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UD60x18, fromUD60x18, toUD60x18} from "@prb/math/UD60x18.sol";

import "./BrainMath.sol" as BrainMath;
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
    UD60x18 proceedsPerLiquidityInsideLast;
    UD60x18 feesAPerLiquidityInsideLast;
    UD60x18 feesBPerLiquidityInsideLast;
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

struct PositionBalanceChange {
    uint256 amountA;
    uint256 amountB;
    uint256 amountC;
}

function sync(
    Position storage position,
    Pool storage pool,
    Slot storage lowerSlot,
    Slot storage upperSlot,
    Epoch memory epoch
) returns (PositionBalanceChange memory balanceChange) {
    uint256 epochsPassed = epoch.getEpochsPassedSince(position.lastUpdatedTimestamp);
    if (epochsPassed > 0) {
        if (position.pendingLiquidity != 0) {
            uint256 lastUpdateEpoch = epoch.id - epochsPassed;
            // update balanceChange through end of last update epoch
            balanceChange = position.updateEarningsThroughEpoch(
                pool.snapshots[lastUpdateEpoch],
                lowerSlot.snapshots[lastUpdateEpoch],
                upperSlot.snapshots[lastUpdateEpoch]
            );

            if (position.pendingLiquidity < 0) {
                // if liquidity was kicked out, add the underlying tokens
                (uint256 underlyingA, uint256 underlyingB) = BrainMath._calculateLiquidityUnderlying(
                    uint256(position.pendingLiquidity),
                    pool.snapshots[lastUpdateEpoch].sqrtPrice,
                    position.lowerSlotIndex,
                    position.upperSlotIndex,
                    false
                );
                balanceChange.amountA += underlyingA;
                balanceChange.amountB += underlyingB;

                position.maturedLiquidity -= uint256(position.pendingLiquidity);
            } else {
                position.maturedLiquidity += uint256(position.pendingLiquidity);
            }
            position.swapLiquidity = position.maturedLiquidity;
            position.pendingLiquidity = int256(0);
        }
    }

    // calculate balanceChange since last update
    {
        PositionBalanceChange memory _balanceChange = position.updateEarnings(pool, lowerSlot, upperSlot);
        balanceChange.amountA += _balanceChange.amountA;
        balanceChange.amountB += _balanceChange.amountB;
        balanceChange.amountC += _balanceChange.amountC;
    }

    // finally update position timestamp
    position.lastUpdatedTimestamp = block.timestamp;
}

function updateEarnings(
    Position storage position,
    Pool storage pool,
    Slot storage lowerSlot,
    Slot storage upperSlot
) returns (PositionBalanceChange memory balanceChange) {
    (
        UD60x18 proceedsPerLiquidityInside,
        UD60x18 feesAPerLiquidityInside,
        UD60x18 feesBPerLiquidityInside
    ) = getEarningsInside(
        pool,
        lowerSlot,
        upperSlot,
        position.lowerSlotIndex,
        position.upperSlotIndex
    );

    balanceChange = getBalanceChange(
        position,
        proceedsPerLiquidityInside,
        feesAPerLiquidityInside,
        feesBPerLiquidityInside
    );

    position.proceedsPerLiquidityInsideLast = proceedsPerLiquidityInside;
    position.feesAPerLiquidityInsideLast = feesAPerLiquidityInside;
    position.feesBPerLiquidityInsideLast = feesBPerLiquidityInside;
}

function updateEarningsThroughEpoch(
    Position storage position,
    PoolSnapshot storage poolSnapshot,
    SlotSnapshot storage lowerSlotSnapshot,
    SlotSnapshot storage upperSlotSnapshot
) returns (PositionBalanceChange memory balanceChange) {
    (
        UD60x18 proceedsPerLiquidityInsideThroughEpoch,
        UD60x18 feesAPerLiquidityInsideThroughEpoch,
        UD60x18 feesBPerLiquidityInsideThroughEpoch
    ) = getEarningsInsideThroughEpoch(
            poolSnapshot,
            lowerSlotSnapshot,
            upperSlotSnapshot,
            position.lowerSlotIndex,
            position.upperSlotIndex
        );

    balanceChange = getBalanceChange(
        position,
        proceedsPerLiquidityInsideThroughEpoch,
        feesAPerLiquidityInsideThroughEpoch,
        feesBPerLiquidityInsideThroughEpoch
    );

    position.proceedsPerLiquidityInsideLast = proceedsPerLiquidityInsideThroughEpoch;
    position.feesAPerLiquidityInsideLast = feesAPerLiquidityInsideThroughEpoch;
    position.feesBPerLiquidityInsideLast = feesBPerLiquidityInsideThroughEpoch;
}

function getBalanceChange(
    Position storage position,
    UD60x18 proceedsPerLiquidityInside,
    UD60x18 feesAPerLiquidityInside,
    UD60x18 feesBPerLiquidityInside
) view returns (PositionBalanceChange memory balanceChange) {
    UD60x18 swapLiquidity = toUD60x18(position.swapLiquidity);

    balanceChange.amountA = fromUD60x18(
        swapLiquidity.mul(feesAPerLiquidityInside.sub(position.feesAPerLiquidityInsideLast))
    );
    balanceChange.amountB = fromUD60x18(
        swapLiquidity.mul(feesBPerLiquidityInside.sub(position.feesBPerLiquidityInsideLast))
    );
    if (position.maturedLiquidity > 0) {
        balanceChange.amountC = fromUD60x18(toUD60x18(position.maturedLiquidity).mul(proceedsPerLiquidityInside.sub(position.proceedsPerLiquidityInsideLast)));
    }
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
        UD60x18 proceedsPerLiquidityInside,
        UD60x18 feesAPerLiquidityInside,
        UD60x18 feesBPerLiquidityInside
    )
{
    {
        UD60x18 proceedsPerLiquidityAbove = pool.slotIndex >= upperSlotIndex
            ? pool.proceedsPerLiquidity.sub(upperSlot.proceedsPerLiquidityOutside)
            : upperSlot.proceedsPerLiquidityOutside;
        UD60x18 proceedsPerLiquidityBelow = pool.slotIndex >= lowerSlotIndex
            ? lowerSlot.proceedsPerLiquidityOutside
            : pool.proceedsPerLiquidity.sub(lowerSlot.proceedsPerLiquidityOutside);
        proceedsPerLiquidityInside =
            pool.proceedsPerLiquidity.sub(proceedsPerLiquidityBelow).sub(proceedsPerLiquidityAbove);
    }
    {
        UD60x18 feesAPerLiquidityAbove = pool.slotIndex >= upperSlotIndex
            ? pool.feesAPerLiquidity.sub(upperSlot.feesAPerLiquidityOutside)
            : upperSlot.feesAPerLiquidityOutside;
        UD60x18 feesAPerLiquidityBelow = pool.slotIndex >= lowerSlotIndex
            ? lowerSlot.feesAPerLiquidityOutside
            : pool.feesAPerLiquidity.sub(lowerSlot.feesAPerLiquidityOutside);
        feesAPerLiquidityInside = pool.feesAPerLiquidity.sub(feesAPerLiquidityBelow).sub(feesAPerLiquidityAbove);
    }
    {
        UD60x18 feesBPerLiquidityAbove = pool.slotIndex >= upperSlotIndex
            ? pool.feesBPerLiquidity.sub(upperSlot.feesBPerLiquidityOutside)
            : upperSlot.feesBPerLiquidityOutside;
        UD60x18 feesBPerLiquidityBelow = pool.slotIndex >= lowerSlotIndex
            ? lowerSlot.feesBPerLiquidityOutside
            : pool.feesBPerLiquidity.sub(lowerSlot.feesBPerLiquidityOutside);
        feesBPerLiquidityInside = pool.feesBPerLiquidity.sub(feesBPerLiquidityBelow).sub(feesBPerLiquidityAbove);
    }
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
        UD60x18 proceedsPerLiquidityInside,
        UD60x18 feesAPerLiquidityInside,
        UD60x18 feesBPerLiquidityInside
    )
{
    {
        UD60x18 proceedsPerLiquidityAbove = poolSnapshot.slotIndex >= upperSlotIndex
            ? poolSnapshot.proceedsPerLiquidity.sub(upperSlotSnapshot.proceedsPerLiquidityOutside)
            : upperSlotSnapshot.proceedsPerLiquidityOutside;
        UD60x18 proceedsPerLiquidityBelow = poolSnapshot.slotIndex >= lowerSlotIndex
            ? lowerSlotSnapshot.proceedsPerLiquidityOutside
            : poolSnapshot.proceedsPerLiquidity.sub(lowerSlotSnapshot.proceedsPerLiquidityOutside);
        proceedsPerLiquidityInside =
            poolSnapshot.proceedsPerLiquidity.sub(proceedsPerLiquidityBelow).sub(proceedsPerLiquidityAbove);
    }
    {
        UD60x18 feesAPerLiquidityAbove = poolSnapshot.slotIndex >= upperSlotIndex
            ? poolSnapshot.feesAPerLiquidity.sub(upperSlotSnapshot.feesAPerLiquidityOutside)
            : upperSlotSnapshot.feesAPerLiquidityOutside;
        UD60x18 feesAPerLiquidityBelow = poolSnapshot.slotIndex >= lowerSlotIndex
            ? lowerSlotSnapshot.feesAPerLiquidityOutside
            : poolSnapshot.feesAPerLiquidity.sub(lowerSlotSnapshot.feesAPerLiquidityOutside);
        feesAPerLiquidityInside =
            poolSnapshot.feesAPerLiquidity.sub(feesAPerLiquidityBelow).sub(feesAPerLiquidityAbove);
    }
    {
        UD60x18 feesBPerLiquidityAbove = poolSnapshot.slotIndex >= upperSlotIndex
            ? poolSnapshot.feesBPerLiquidity.sub(upperSlotSnapshot.feesBPerLiquidityOutside)
            : upperSlotSnapshot.feesBPerLiquidityOutside;
        UD60x18 feesBPerLiquidityBelow = poolSnapshot.slotIndex >= lowerSlotIndex
            ? lowerSlotSnapshot.feesBPerLiquidityOutside
            : poolSnapshot.feesBPerLiquidity.sub(lowerSlotSnapshot.feesBPerLiquidityOutside);
        feesBPerLiquidityInside =
            poolSnapshot.feesBPerLiquidity.sub(feesBPerLiquidityBelow).sub(feesBPerLiquidityAbove);
    }
}
