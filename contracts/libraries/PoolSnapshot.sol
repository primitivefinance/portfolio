// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title   PoolSnapshot Library
/// @author  Primitive
/// @dev     Data structure library for PoolSnapshot
library PoolSnapshot {
    /// @notice                Stores the state of a PoolSnapshot
    struct Data {
        uint256 activeSqrtPriceFixedPoint;
        int128 activeSlotIndex;
        uint256 proceedsGrowthGlobalFixedPoint;
        uint256 feeGrowthGlobalAFixedPoint;
        uint256 feeGrowthGlobalBFixedPoint;
    }

    function getId(bytes32 poolId, uint256 epochId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(poolId, epochId));
    }
}
