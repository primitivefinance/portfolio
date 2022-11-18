// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Epoch.sol";

/// @title   Slot Library
/// @author  Primitive
/// @dev     Data structure library for Slots
library Slot {
    using Epoch for Epoch.Data;

    /// @notice                Stores the state of a slot
    struct Data {
        uint256 liquidityGross;
        int256 liquidityDelta;
        int256 liquidityMaturedDelta;
        int256 liquidityPendingDelta;
        uint256 proceedsGrowthOutsideFixedPoint;
        uint256 feeGrowthOutsideAFixedPoint;
        uint256 feeGrowthOutsideBFixedPoint;
        uint256 lastUpdatedTimestamp;
    }

    function getId(bytes32 poolId, int128 slotIndex) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(poolId, slotIndex));
    }

    /// @notice                Updates the slot data w.r.t. time passing
    function sync(Data storage slot, Epoch.Data memory epoch) internal {
        uint256 epochsPassed = (epoch.endTime - slot.lastUpdatedTimestamp) / EPOCH_LENGTH;
        if (epochsPassed > 0) {
            if (slot.liquidityPendingDelta < 0) {
                slot.liquidityDelta += slot.liquidityPendingDelta;
                slot.liquidityMaturedDelta += slot.liquidityPendingDelta;
            } else if (slot.liquidityPendingDelta > 0) {
                slot.liquidityMaturedDelta += slot.liquidityPendingDelta;
            }
        }
        slot.lastUpdatedTimestamp = block.timestamp;
    }
}
