// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UD60x18} from "@prb/math/UD60x18.sol";

import {PoolId} from "./Pool.sol";

type SlotId is bytes32;

struct Slot {
    SlotId id;
    uint256 liquidityGross;
    int256 pendingLiquidityGross;
    int256 swapLiquidityDelta;
    int256 maturedLiquidityDelta;
    int256 pendingLiquidityDelta;
    UD60x18 proceedsPerLiquidityOutside;
    UD60x18 feesAPerLiquidityOutside;
    UD60x18 feesBPerLiquidityOutside;
    uint256 lastUpdatedTimestamp;
}

struct SlotSnapshot {
    UD60x18 proceedsPerLiquidityOutside;
    UD60x18 feesAPerLiquidityOutside;
    UD60x18 feesBPerLiquidityOutside;
}

function getSlotId(PoolId poolId, int128 slotIndex) pure returns (SlotId) {
    return SlotId.wrap(keccak256(abi.encodePacked(poolId, slotIndex)));
}

function getSlotSnapshot(Slot memory slot) pure returns (SlotSnapshot memory) {
    return
        SlotSnapshot({
            proceedsPerLiquidityOutside: slot.proceedsPerLiquidityOutside,
            feesAPerLiquidityOutside: slot.feesAPerLiquidityOutside,
            feesBPerLiquidityOutside: slot.feesBPerLiquidityOutside
        });
}
