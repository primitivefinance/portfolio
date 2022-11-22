// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BrainMath.sol";
import "./Epoch.sol";
import "./GlobalDefaults.sol";

/// @title   Pool Library
/// @author  Primitive
/// @dev     Data structure library for Pools
library Pool {
    using Epoch for Epoch.Data;

    struct Data {
        address tokenA;
        address tokenB;
        uint256 activeLiquidity;
        uint256 activeLiquidityMatured;
        int256 activeLiquidityPending;
        uint256 activeSqrtPriceFixedPoint;
        int128 activeSlotIndex;
        uint256 proceedsGrowthGlobalFixedPoint;
        uint256 feeGrowthGlobalAFixedPoint;
        uint256 feeGrowthGlobalBFixedPoint;
        uint256 lastUpdatedTimestamp;
        mapping(uint256 => Bid) bids;
        mapping(uint256 => Snapshot) snapshots;
    }

    struct Bid {
        address refunder; // refund address if bid does not win
        address swapper; // address that gets a zero swap fee
        uint256 amount; // total bid amount in the auction settlement token
        uint256 proceedsPerSecondFixedPoint; // calculated proceeds per second over an epoch
    }

    struct Snapshot {
        uint256 activeSqrtPriceFixedPoint;
        int128 activeSlotIndex;
        uint256 proceedsGrowthGlobalFixedPoint;
        uint256 feeGrowthGlobalAFixedPoint;
        uint256 feeGrowthGlobalBFixedPoint;
    }

    function getId(address tokenA, address tokenB) public pure returns (bytes32) {
        if (tokenA == tokenB) revert();
        (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    function activate(
        mapping(bytes32 => Data) storage pools,
        address tokenA,
        address tokenB,
        uint256 activeSqrtPriceFixedPoint
    ) internal {
        Data storage pool = pools[getId(tokenA, tokenB)];

        if (pool.lastUpdatedTimestamp != 0) revert();
        pool.tokenA = tokenA;
        pool.tokenB = tokenB;
        pool.activeSqrtPriceFixedPoint = activeSqrtPriceFixedPoint;
        // TODO: set active slot index?
        pool.lastUpdatedTimestamp = block.timestamp;
    }

    function sync(Data storage pool, Epoch.Data memory epoch) internal {
        uint256 epochsPassed = (epoch.endTime - pool.lastUpdatedTimestamp) / EPOCH_LENGTH;
        if (epochsPassed > 0) {
            // update proceeds growth to epoch transition
            uint256 lastUpdateEpoch = epoch.id - epochsPassed;
            if (pool.activeLiquidityMatured > 0) {
                uint256 timeToTransition = (epoch.endTime - pool.lastUpdatedTimestamp) - (epochsPassed * EPOCH_LENGTH);
                pool.proceedsGrowthGlobalFixedPoint += PRBMathUD60x18.div(
                    PRBMathUD60x18.mul(pool.bids[lastUpdateEpoch].proceedsPerSecondFixedPoint, timeToTransition),
                    pool.activeLiquidityMatured
                );
            }
            if (pool.activeLiquidityPending < 0) {
                pool.activeLiquidity -= uint256(pool.activeLiquidityPending);
                pool.activeLiquidityMatured -= uint256(pool.activeLiquidityPending);
            } else {
                pool.activeLiquidityMatured += uint256(pool.activeLiquidityPending);
            }
            pool.activeLiquidityPending = int256(0);
            // save snapshot
            pool.snapshots[lastUpdateEpoch] = Snapshot({
                activeSqrtPriceFixedPoint: pool.activeSqrtPriceFixedPoint,
                activeSlotIndex: pool.activeSlotIndex,
                proceedsGrowthGlobalFixedPoint: pool.proceedsGrowthGlobalFixedPoint,
                feeGrowthGlobalAFixedPoint: pool.feeGrowthGlobalAFixedPoint,
                feeGrowthGlobalBFixedPoint: pool.feeGrowthGlobalBFixedPoint
            });
            // update proceeds for next epoch if pool untouched for multiple epochs
            if (epochsPassed > 1) {
                if (pool.activeLiquidityMatured > 0) {
                    pool.proceedsGrowthGlobalFixedPoint += PRBMathUD60x18.div(
                        PRBMathUD60x18.mul(pool.bids[lastUpdateEpoch + 1].proceedsPerSecondFixedPoint, EPOCH_LENGTH),
                        pool.activeLiquidityMatured
                    );
                }
                // don't save snapshot since no position was touched during epoch
            }
        }
        // add proceeds for time passed in the current epoch
        uint256 timePassedInCurrentEpoch = block.timestamp - (epoch.endTime - EPOCH_LENGTH);
        if (pool.activeLiquidityMatured > 0 && timePassedInCurrentEpoch > 0) {
            pool.proceedsGrowthGlobalFixedPoint += PRBMathUD60x18.div(
                PRBMathUD60x18.mul(pool.bids[epoch.id].proceedsPerSecondFixedPoint, timePassedInCurrentEpoch),
                pool.activeLiquidityMatured
            );
        }
        // finally update last saved timestamp
        pool.lastUpdatedTimestamp = block.timestamp;
    }
}
