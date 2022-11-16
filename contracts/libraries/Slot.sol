struct Slot {
    int256 liquidityDelta;
    int256 liquidityMaturedDelta;
    int256 liquidityPendingDelta;
    uint256 proceedsGrowthOutsideFixedPoint;
    uint256 feeGrowthOutsideAFixedPoint;
    uint256 feeGrowthOutsideBFixedPoint;
    uint256 lastUpdatedTimestamp;
}

function _getSlotId(bytes32 poolId, int128 slotIndex) pure returns (bytes32) {
    return keccak256(abi.encodePacked(poolId, slotIndex));
}
