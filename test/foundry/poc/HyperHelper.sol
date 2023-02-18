// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/Hyper.sol";
import "contracts/libraries/RMM01Lib.sol";

contract HyperHelper is Hyper {
    constructor(address weth) Hyper(weth) {}

    function getPoolFeeGrowthAsset(uint64 poolId) public returns (uint) {
        return pools[poolId].feeGrowthGlobalAsset;
    }

    function getPosFeeGrowthAsset(address user, uint64 poolId) public returns (uint) {
        return positions[user][poolId].feeGrowthAssetLast;
    }

    function computePriceWithTick(int24 tick) public pure returns (uint256 price) {
        return RMM01Lib.computePriceWithTick(tick);
    }

    function computeTickWithPrice(uint256 price) public pure returns (int24 tick) {
        return RMM01Lib.computeTickWithPrice(price);
    }
}
