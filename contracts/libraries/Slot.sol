// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title   Slot Library
/// @author  Primitive
/// @dev     Data structure library for Slots
library Slot {
    /// @notice                Stores the state of a slot
    struct Data {
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
}
