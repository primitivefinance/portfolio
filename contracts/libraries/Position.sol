struct Position {
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

function _getPositionId(
    address owner,
    bytes32 poolId,
    int128 lowerSlotIndex,
    int128 upperSlotIndex
) pure returns (bytes32) {
    return keccak256(abi.encodePacked(owner, poolId, lowerSlotIndex, upperSlotIndex));
}
