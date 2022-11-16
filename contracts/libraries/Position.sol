// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Epoch.sol";
import "./GlobalDefaults.sol";
import "./Pool.sol";

/// @title   Pool Library
/// @author  Primitive
/// @dev     Data structure library for Positions
library Position {
    /// @notice                Stores the state of a position
    struct Data {
        int128 lowerSlotIndex;
        int128 upperSlotIndex;
        uint256 liquidityOwned;
        uint256 liquidityMatured;
        int256 liquidityPending;
        uint256 proceedsGrowthInsideLastFixedPoint;
        uint256 feeGrowthInsideLastAFixedPoint;
        uint256 feeGrowthInsideLastBFixedPoint;
        // TODO: Should we track these fees with precision or nah?
        uint256 tokensOwedAFixedPoint;
        uint256 tokensOwedBFixedPoint;
        uint256 tokensOwedCFixedPoint; // auction settlement token
        uint256 lastUpdatedTimestamp;
    }

    function getId(
        address owner,
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, poolId, lowerSlotIndex, upperSlotIndex));
    }

    /// @notice                Updates the position data w.r.t. time passing
    function sync(
        Data storage position,
        Pool.Data memory pool,
        Epoch.Data memory epoch
    ) internal {}
}
