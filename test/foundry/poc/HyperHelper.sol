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
}
