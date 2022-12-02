// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {EPOCH_LENGTH} from "./GlobalDefaults.sol";

import "./BrainMath.sol";
import {Epoch} from "./Epoch.sol";

using {sync} for Pool global;

struct Pool {
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
    mapping(uint256 => PoolSnapshot) snapshots;
}

struct Bid {
    address refunder; // refund address if bid does not win
    address swapper; // address that gets a zero swap fee
    uint256 netFeeAmount; // bid amount - fee in the auction settlement token
    uint256 fee; // fee collected by auction fee collector in auction settlement token
    uint256 proceedsPerSecondFixedPoint; // calculated proceeds per second over an epoch, netFeeAmount / EPOCH_LENGTH
}

struct PoolSnapshot {
    uint256 sqrtPriceFixedPoint;
    int128 slotIndex;
    uint256 proceedsPerLiquidityFixedPoint;
    uint256 feesAPerLiquidityFixedPoint;
    uint256 feesBPerLiquidityFixedPoint;
}

function getPoolId(address tokenA, address tokenB) pure returns (bytes32) {
    if (tokenA == tokenB) revert();
    (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    return keccak256(abi.encodePacked(tokenA, tokenB));
}

function sync(Pool storage pool, Epoch memory epoch) returns (uint256 auctionFees) {
    uint256 epochsPassed = (epoch.endTime - (pool.lastUpdatedTimestamp + 1)) / EPOCH_LENGTH;
    // TODO: double check boundary condition
    if (epochsPassed > 0) {
        // update proceeds per liquidity distributed to end of epoch
        uint256 lastUpdateEpoch = epoch.id - epochsPassed;
        if (pool.maturedLiquidity > 0 && pool.bids[lastUpdateEpoch].proceedsPerSecondFixedPoint > 0) {
            uint256 timeToTransition = epoch.endTime - (epochsPassed * EPOCH_LENGTH) - pool.lastUpdatedTimestamp;
            pool.proceedsPerLiquidityFixedPoint += PRBMathUD60x18.div(
                PRBMathUD60x18.mul(pool.bids[lastUpdateEpoch].proceedsPerSecondFixedPoint, timeToTransition),
                pool.maturedLiquidity
            );
            auctionFees += pool.bids[lastUpdateEpoch].fee;
        }
        // save pool snapshot at end of epoch
        pool.snapshots[lastUpdateEpoch] = PoolSnapshot({
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
            if (pool.maturedLiquidity > 0 && pool.bids[lastUpdateEpoch + 1].proceedsPerSecondFixedPoint > 0) {
                pool.proceedsPerLiquidityFixedPoint += PRBMathUD60x18.div(
                    PRBMathUD60x18.mul(pool.bids[lastUpdateEpoch + 1].proceedsPerSecondFixedPoint, EPOCH_LENGTH),
                    pool.maturedLiquidity
                );
                auctionFees += pool.bids[lastUpdateEpoch + 1].fee;
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
