// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/libraries/EnigmaLib.sol" as Processor;
import "contracts/libraries/AccountLib.sol" as Operating;
import "contracts/libraries/RMM01Lib.sol";
import {HyperPair, HyperCurve, HyperPool, HyperPosition} from "contracts/HyperLib.sol";
import {TestERC20} from "contracts/test/TestERC20.sol";
import {IHyperStruct} from "../HelperGhostLib.sol";

interface HyperLike {
    function getReserve(address) external view returns (uint256);

    function getBalance(address, address) external view returns (uint256);

    function getPairNonce() external view returns (uint16);
}

struct HyperState {
    uint256 reserveAsset; // getReserve
    uint256 reserveQuote; // getReserve
    uint256 physicalBalanceAsset; // balanceOf
    uint256 physicalBalanceQuote; // balanceOf
    uint256 totalBalanceAsset; // sum of all balances from getBalance
    uint256 totalBalanceQuote; // sum of all balances from getBalance
    uint256 totalPositionLiquidity; // sum of all position liquidity
    uint256 callerPositionLiquidity; // position.freeLiquidity
    uint256 totalPoolLiquidity; // pool.liquidity
    uint256 feeGrowthAssetPool; // getPool
    uint256 feeGrowthQuotePool; // getPool
    uint256 feeGrowthAssetPosition; // getPosition
    uint256 feeGrowthQuotePosition; // getPosition
}

interface TokenLike {
    function balanceOf(address) external view returns (uint256);
}

contract HelperHyperView {
    using RMM01Lib for HyperPool;

    function getPool(address hyper, uint64 poolId) public view returns (HyperPool memory) {
        return IHyperStruct(hyper).pools(poolId);
    }

    function getCurve(address hyper, uint64 poolId) public view returns (HyperCurve memory) {
        HyperPool memory pool = getPool(hyper, poolId);
        return pool.params;
    }

    function getPair(address hyper, uint24 pairId) public view returns (HyperPair memory) {
        return IHyperStruct(hyper).pairs(pairId);
    }

    function getPosition(address hyper, address owner, uint64 positionId) public view returns (HyperPosition memory) {
        return IHyperStruct(hyper).positions(owner, positionId);
    }

    function getReserve(address hyper, address token) public view returns (uint256) {
        return HyperLike(hyper).getReserve(token);
    }

    function getBalance(address hyper, address owner, address token) public view returns (uint256) {
        return HyperLike(hyper).getBalance(owner, token);
    }

    function _getPool(IHyperStruct hyper, uint64 poolId) public view returns (HyperPool memory) {
        return (hyper).pools(poolId);
    }

    function _getPosition(
        IHyperStruct hyper,
        address owner,
        uint64 positionId
    ) public view returns (HyperPosition memory) {
        return hyper.positions(owner, positionId);
    }

    function _getReserve(HyperLike hyper, TestERC20 token) public view returns (uint256) {
        return hyper.getReserve(address(token));
    }

    function _getBalance(HyperLike hyper, address owner, TestERC20 token) public view returns (uint256) {
        return hyper.getBalance(owner, address(token));
    }

    /** @dev Fetches pool state and account state for a single pool's tokens. */
    function getState(
        address hyper,
        uint64 poolId,
        address caller,
        address[] memory owners
    ) public view returns (HyperState memory) {
        HyperPair memory pair = getPair(hyper, Processor.decodePairIdFromPoolId(poolId));
        address asset = pair.tokenAsset;
        address quote = pair.tokenQuote;

        HyperPool memory pool = getPool(hyper, poolId);
        HyperPosition memory position = getPosition(hyper, caller, poolId);

        HyperState memory state = HyperState(
            getReserve(hyper, asset),
            getReserve(hyper, quote),
            getPhysicalBalance(hyper, asset),
            getPhysicalBalance(hyper, quote),
            getBalanceSum(hyper, asset, owners),
            getBalanceSum(hyper, quote, owners),
            getPositionLiquiditySum(hyper, poolId, owners),
            position.freeLiquidity,
            pool.liquidity,
            pool.feeGrowthGlobalAsset,
            pool.feeGrowthGlobalQuote,
            position.feeGrowthAssetLast,
            position.feeGrowthQuoteLast
        );

        return state;
    }

    function getPhysicalBalance(address hyper, address token) public view returns (uint256) {
        return Operating.__balanceOf__(token, hyper);
    }

    function getVirtualBalance(address hyper, address token, address[] memory owners) public view returns (uint256) {
        uint256 sum = getReserve(hyper, token) + getBalanceSum(hyper, token, owners);
        return sum;
    }

    function getBalanceSum(address hyper, address token, address[] memory owners) public view returns (uint256) {
        uint256 sum;
        for (uint256 x; x != owners.length; ++x) {
            sum += getBalance(hyper, owners[x], token);
        }

        return sum;
    }

    function getPositionLiquiditySum(
        address hyper,
        uint64 poolId,
        address[] memory owners
    ) public view returns (uint256) {
        uint256 sum;
        for (uint256 i; i != owners.length; ++i) {
            sum += getPosition(hyper, owners[i], poolId).freeLiquidity;
        }

        return sum;
    }

    function getMaxSwapLimit(bool sellAsset) public pure returns (uint256) {
        if (sellAsset) {
            // price goes down
            return 0;
        } else {
            // price goes up
            return type(uint256).max;
        }
    }

    function helperGetAmountOut(
        address hyper,
        uint64 poolId,
        bool sellAsset,
        uint256 input
    ) public view returns (uint256) {
        HyperPool memory pool = getPool(hyper, poolId);
        uint256 passed = block.timestamp - pool.lastTimestamp;
        uint256 output = pool.getAmountOut(sellAsset, input, passed);
        return output;
    }
}
