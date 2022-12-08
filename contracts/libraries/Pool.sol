// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UD60x18} from "@prb/math/UD60x18.sol";

type PoolId is bytes32;

enum PoolToken {
    A,
    B
}

struct Pool {
    PoolId id;
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

function getPoolSnapshot(Pool memory pool) pure returns (PoolSnapshot memory) {
    return
        PoolSnapshot({
            sqrtPrice: pool.sqrtPrice,
            slotIndex: pool.slotIndex,
            proceedsPerLiquidity: pool.proceedsPerLiquidity,
            feesAPerLiquidity: pool.feesAPerLiquidity,
            feesBPerLiquidity: pool.feesBPerLiquidity
        });
}
