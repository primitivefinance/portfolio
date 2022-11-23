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
        uint256 swapLiquidity;
        uint256 maturedLiquidity;
        int256 pendingLiquidity;
        uint256 sqrtPriceFixedPoint;
        int128 slotIndex;
        uint256 proceedsPerLiquidityFixedPoint;
        uint256 feesAPerLiquidityFixedPoint;
        uint256 feesBPerLiquidityFixedPoint;
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
        uint256 sqrtPriceFixedPoint;
        int128 slotIndex;
        uint256 proceedsPerLiquidityFixedPoint;
        uint256 feesAPerLiquidityFixedPoint;
        uint256 feesBPerLiquidityFixedPoint;
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
        uint256 sqrtPriceFixedPoint
    ) internal {
        Data storage pool = pools[getId(tokenA, tokenB)];

        if (pool.lastUpdatedTimestamp != 0) revert();
        pool.tokenA = tokenA;
        pool.tokenB = tokenB;
        pool.sqrtPriceFixedPoint = sqrtPriceFixedPoint;
        // TODO: set active slot index?
        pool.lastUpdatedTimestamp = block.timestamp;
    }

    function sync(Data storage pool, Epoch.Data memory epoch) internal {
        uint256 epochsPassed = (epoch.endTime - (pool.lastUpdatedTimestamp + 1)) / EPOCH_LENGTH;
        // TODO: double check boundary condition
        if (epochsPassed > 0) {
            // update proceeds per liquidity distributed to end of epoch
            uint256 lastUpdateEpoch = epoch.id - epochsPassed;
            if (pool.maturedLiquidity > 0) {
                uint256 timeToTransition = epoch.endTime - (epochsPassed * EPOCH_LENGTH) - pool.lastUpdatedTimestamp;
                pool.proceedsPerLiquidityFixedPoint += PRBMathUD60x18.div(
                    PRBMathUD60x18.mul(pool.bids[lastUpdateEpoch].proceedsPerSecondFixedPoint, timeToTransition),
                    pool.maturedLiquidity
                );
            }
            // save pool snapshot at end of epoch
            pool.snapshots[lastUpdateEpoch] = Snapshot({
                sqrtPriceFixedPoint: pool.sqrtPriceFixedPoint,
                slotIndex: pool.slotIndex,
                proceedsPerLiquidityFixedPoint: pool.proceedsPerLiquidityFixedPoint,
                feesAPerLiquidityFixedPoint: pool.feesAPerLiquidityFixedPoint,
                feesBPerLiquidityFixedPoint: pool.feesBPerLiquidityFixedPoint
            });
            // update matured liquidity for epoch transition
            if (pool.pendingLiquidity > 0) {
                pool.maturedLiquidity += uint256(pool.pendingLiquidity);
            } else {
                pool.maturedLiquidity -= uint256(pool.pendingLiquidity);
            }
            pool.swapLiquidity = pool.maturedLiquidity;
            pool.pendingLiquidity = int256(0);
            // update proceeds per liquidity distributed for next epoch if needed
            if (epochsPassed > 1) {
                if (pool.maturedLiquidity > 0) {
                    pool.proceedsPerLiquidityFixedPoint += PRBMathUD60x18.div(
                        PRBMathUD60x18.mul(pool.bids[lastUpdateEpoch + 1].proceedsPerSecondFixedPoint, EPOCH_LENGTH),
                        pool.maturedLiquidity
                    );
                }
            }
        }
        // add proceeds for time passed in the current epoch
        uint256 timePassedInCurrentEpoch = block.timestamp - (epoch.endTime - EPOCH_LENGTH);
        if (pool.maturedLiquidity > 0 && timePassedInCurrentEpoch > 0) {
            pool.proceedsPerLiquidityFixedPoint += PRBMathUD60x18.div(
                PRBMathUD60x18.mul(pool.bids[epoch.id].proceedsPerSecondFixedPoint, timePassedInCurrentEpoch),
                pool.maturedLiquidity
            );
        }
        // finally update last saved timestamp
        pool.lastUpdatedTimestamp = block.timestamp;
    }
}
