// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Epoch.sol";

/// @title   Slot Library
/// @author  Primitive
/// @dev     Data structure library for Slots
library Slot {
    using Epoch for Epoch.Data;

    struct Data {
        uint256 liquidityGross;
        int256 pendingLiquidityGross;
        int256 liquidityDelta;
        int256 liquidityMaturedDelta;
        int256 liquidityPendingDelta;
        uint256 proceedsGrowthOutsideFixedPoint;
        uint256 feeGrowthOutsideAFixedPoint;
        uint256 feeGrowthOutsideBFixedPoint;
        mapping(uint256 => Snapshot) snapshots;
        uint256 lastUpdatedTimestamp;
    }

    struct Snapshot {
        uint256 proceedsGrowthOutsideFixedPoint;
        uint256 feeGrowthOutsideAFixedPoint;
        uint256 feeGrowthOutsideBFixedPoint;
    }

    function getId(bytes32 poolId, int128 slotIndex) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(poolId, slotIndex));
    }

    function sync(Data storage slot, Epoch.Data memory epoch) internal {
        uint256 epochsPassed = (epoch.endTime - slot.lastUpdatedTimestamp) / EPOCH_LENGTH;
        if (epochsPassed > 0) {
            if (slot.liquidityPendingDelta < 0) {
                slot.liquidityDelta += slot.liquidityPendingDelta;
                slot.liquidityMaturedDelta += slot.liquidityPendingDelta;
            } else if (slot.liquidityPendingDelta > 0) {
                slot.liquidityMaturedDelta += slot.liquidityPendingDelta;
            }
            slot.liquidityPendingDelta = int256(0);

            if (slot.pendingLiquidityGross < 0) {
                slot.liquidityGross -= uint256(slot.pendingLiquidityGross);
                // TODO: If liquidity gross is now zero, remove from bitmap
            }
            slot.pendingLiquidityGross = int256(0);
        }
        slot.lastUpdatedTimestamp = block.timestamp;
    }
}
