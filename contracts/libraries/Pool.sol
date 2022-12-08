// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UD60x18, toUD60x18} from "@prb/math/UD60x18.sol";

import {Epoch} from "./Epoch.sol";

using {sync} for Pool global;

type PoolId is bytes32;

enum PoolToken {
    A,
    B
}

struct Pool {
    address tokenA;
    address tokenB;
    uint256 swapLiquidity;
    uint256 maturedLiquidity;
    int256 pendingLiquidity;
    UD60x18 sqrtPrice;
    int128 slotIndex;
    UD60x18 proceedsPerLiquidity;
    UD60x18 feesAPerLiquidity;
    UD60x18 feesBPerLiquidity;
    uint256 lastUpdatedTimestamp;
    mapping(uint256 => Bid) bids;
    mapping(uint256 => PoolSnapshot) snapshots;
}

struct Bid {
    address refunder; // refund address if bid does not win
    address swapper; // address that gets a zero swap fee
    uint256 netFeeAmount; // bid amount - fee in the auction settlement token
    uint256 fee; // fee collected by auction fee collector in auction settlement token
    UD60x18 proceedsPerSecond; // calculated proceeds per second over an epoch, netFeeAmount / EPOCH_LENGTH
}

struct PoolSnapshot {
    UD60x18 sqrtPrice;
    int128 slotIndex;
    UD60x18 proceedsPerLiquidity;
    UD60x18 feesAPerLiquidity;
    UD60x18 feesBPerLiquidity;
}

function getPoolId(address tokenA, address tokenB) pure returns (PoolId) {
    if (tokenA == tokenB) revert();
    (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    return PoolId.wrap(keccak256(abi.encodePacked(tokenA, tokenB)));
}

function sync(Pool storage pool, Epoch memory epoch) returns (uint256 auctionFees) {
    uint256 epochsPassed = epoch.getEpochsPassedSince(pool.lastUpdatedTimestamp);
    if (epochsPassed > 0) {
        // update proceeds per liquidity distributed to end of epoch
        uint256 lastUpdateEpoch = epoch.id - epochsPassed;
        if (pool.maturedLiquidity > 0 && !pool.bids[lastUpdateEpoch].proceedsPerSecond.isZero()) {
            uint256 timeToTransition = epoch.endTime - (epochsPassed * epoch.length) - pool.lastUpdatedTimestamp;
            pool.proceedsPerLiquidity = pool.proceedsPerLiquidity.add(
                pool.bids[lastUpdateEpoch].proceedsPerSecond.mul(
                    toUD60x18(timeToTransition)).div(toUD60x18(pool.maturedLiquidity)
                )
            );
            auctionFees += pool.bids[lastUpdateEpoch].fee;
        }
        // save pool snapshot at end of epoch
        pool.snapshots[lastUpdateEpoch] = PoolSnapshot({
            sqrtPrice: pool.sqrtPrice,
            slotIndex: pool.slotIndex,
            proceedsPerLiquidity: pool.proceedsPerLiquidity,
            feesAPerLiquidity: pool.feesAPerLiquidity,
            feesBPerLiquidity: pool.feesBPerLiquidity
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
            if (pool.maturedLiquidity > 0 && !pool.bids[lastUpdateEpoch + 1].proceedsPerSecond.isZero()) {
                pool.proceedsPerLiquidity = pool.proceedsPerLiquidity.add(
                    pool.bids[lastUpdateEpoch + 1].proceedsPerSecond.mul(
                        toUD60x18(epoch.length)).div(toUD60x18(pool.maturedLiquidity))
                );
                auctionFees += pool.bids[lastUpdateEpoch + 1].fee;
            }
        }
    }
    // add proceeds for time passed in the current epoch
    uint256 timePassedInCurrentEpoch = block.timestamp - (epoch.endTime - epoch.length);
    if (pool.maturedLiquidity > 0 && timePassedInCurrentEpoch > 0) {
        pool.proceedsPerLiquidity = pool.proceedsPerLiquidity.add(
            pool.bids[epoch.id].proceedsPerSecond.mul(
                toUD60x18(timePassedInCurrentEpoch)).div(toUD60x18(pool.maturedLiquidity))
        );
    }
    // finally update last saved timestamp
    pool.lastUpdatedTimestamp = block.timestamp;
}
