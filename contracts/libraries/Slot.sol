// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UD60x18} from "@prb/math/UD60x18.sol";

import "./BitMath.sol" as BitMath;
import {Epoch} from "./Epoch.sol";
import {PoolId, Pool} from "./Pool.sol";

using {sync, cross} for Slot global;

type SlotId is bytes32;

struct Slot {
    uint256 liquidityGross;
    int256 pendingLiquidityGross;
    int256 swapLiquidityDelta;
    int256 maturedLiquidityDelta;
    int256 pendingLiquidityDelta;
    UD60x18 proceedsPerLiquidityOutside;
    UD60x18 feesAPerLiquidityOutside;
    UD60x18 feesBPerLiquidityOutside;
    uint256 lastUpdatedTimestamp;
    mapping(uint256 => SlotSnapshot) snapshots;
}

struct SlotSnapshot {
    UD60x18 proceedsPerLiquidityOutside;
    UD60x18 feesAPerLiquidityOutside;
    UD60x18 feesBPerLiquidityOutside;
}

function getSlotId(PoolId poolId, int128 slotIndex) pure returns (SlotId) {
    return SlotId.wrap(keccak256(abi.encodePacked(poolId, slotIndex)));
}

function sync(
    Slot storage slot,
    mapping(int16 => uint256) storage chunks,
    int24 slotIndex,
    Epoch memory epoch
) {
    uint256 epochsPassed = epoch.getEpochsPassedSince(slot.lastUpdatedTimestamp);
    if (epochsPassed > 0) {
        // update liquidity deltas for epoch transition
        slot.maturedLiquidityDelta += slot.pendingLiquidityDelta;
        slot.swapLiquidityDelta = slot.maturedLiquidityDelta;
        slot.pendingLiquidityDelta = int256(0);

        // update liquidity gross for epoch transition
        if (slot.pendingLiquidityGross < 0) {
            slot.liquidityGross -= uint256(slot.pendingLiquidityGross);

            if (slot.liquidityGross == 0) {
                (int16 chunk, uint8 bit) = BitMath.getSlotPositionInBitmap(slotIndex);
                chunks[chunk] = BitMath.flip(chunks[chunk], bit);
            }
        }
        slot.pendingLiquidityGross = int256(0);
    }
    slot.lastUpdatedTimestamp = block.timestamp;
}

function cross(
    Slot storage slot,
    uint256 epochId,
    UD60x18 proceedsPerLiquidity,
    UD60x18 feesAPerLiquidity,
    UD60x18 feesBPerLiquidity
) {
    slot.proceedsPerLiquidityOutside =
        proceedsPerLiquidity.sub(slot.proceedsPerLiquidityOutside);
    slot.feesAPerLiquidityOutside =
        feesAPerLiquidity.sub(slot.feesAPerLiquidityOutside);
    slot.feesBPerLiquidityOutside =
        feesBPerLiquidity.sub(slot.feesBPerLiquidityOutside);

    slot.snapshots[epochId] = SlotSnapshot({
        proceedsPerLiquidityOutside: slot.proceedsPerLiquidityOutside,
        feesAPerLiquidityOutside: slot.feesAPerLiquidityOutside,
        feesBPerLiquidityOutside: slot.feesBPerLiquidityOutside
    });
}
