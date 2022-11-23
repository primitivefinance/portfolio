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
        int256 swapLiquidityDelta;
        int256 pendingSwapLiquidityDelta;
        int256 maturedLiquidityDelta;
        int256 pendingMaturedLiquidityDelta;
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

    function sync(Data storage slot, Epoch.Data memory epoch) internal {
        uint256 epochsPassed = (epoch.endTime - (slot.lastUpdatedTimestamp + 1)) / EPOCH_LENGTH;
        // TODO: double check boundary condition
        if (epochsPassed > 0) {
            // update liquidity delta values for epoch transition
            slot.swapLiquidityDelta += slot.pendingSwapLiquidityDelta;
            slot.maturedLiquidityDelta += slot.pendingMaturedLiquidityDelta;

            // update liquidity gross for epoch transition
            if (slot.pendingLiquidityGross < 0) {
                slot.liquidityGross -= uint256(slot.pendingLiquidityGross);
                // TODO: If liquidity gross is now zero, remove from bitmap
            }

            slot.pendingSwapLiquidityDelta = int256(0);
            slot.pendingMaturedLiquidityDelta = int256(0);
            slot.pendingLiquidityGross = int256(0);
        }
        slot.lastUpdatedTimestamp = block.timestamp;
    }
}
