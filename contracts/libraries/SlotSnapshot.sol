// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title   SlotSnapshot Library
/// @author  Primitive
/// @dev     Data structure library for SlotSnapshot
library SlotSnapshot {
    /// @notice                Stores the state of a SlotSnapshot
    struct Data {
        uint256 proceedsGrowthOutsideFixedPoint;
        uint256 feeGrowthOutsideAFixedPoint;
        uint256 feeGrowthOutsideBFixedPoint;
    }

    function getId(bytes32 slotId, uint256 epochId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(slotId, epochId));
    }
}
