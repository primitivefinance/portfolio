// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {EPOCH_LENGTH} from "./GlobalDefaults.sol";

import "./Epoch.sol";
import "./BitMath.sol";

/// @title   Slot Library
/// @author  Primitive
/// @dev     Data structure library for Slots
library Slot {
    using Epoch for Epoch.Data;

    struct Data {
        uint256 liquidityGross;
        int256 pendingLiquidityGross;
        int256 swapLiquidityDelta;
        int256 maturedLiquidityDelta;
        int256 pendingLiquidityDelta;
        uint256 proceedsPerLiquidityOutsideFixedPoint;
        uint256 feesAPerLiquidityOutsideFixedPoint;
        uint256 feesBPerLiquidityOutsideFixedPoint;
        uint256 lastUpdatedTimestamp;
        mapping(uint256 => Snapshot) snapshots;
    }

    struct Snapshot {
        uint256 proceedsPerLiquidityOutsideFixedPoint;
        uint256 feesAPerLiquidityOutsideFixedPoint;
        uint256 feesBPerLiquidityOutsideFixedPoint;
    }

    function getId(bytes32 poolId, int128 slotIndex) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(poolId, slotIndex));
    }

    function sync(
        Data storage slot,
        mapping(int16 => uint256) storage chunks,
        int24 slotIndex,
        Epoch.Data memory epoch
    ) internal {
        uint256 epochsPassed = (epoch.endTime - (slot.lastUpdatedTimestamp + 1)) / EPOCH_LENGTH;
        // TODO: double check boundary condition
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
}
