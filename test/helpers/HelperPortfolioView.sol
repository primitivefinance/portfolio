// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "contracts/libraries/EnigmaLib.sol" as Processor;
import "contracts/libraries/AccountLib.sol" as Operating;
import "contracts/libraries/RMM01Lib.sol";
import {PortfolioPair, PortfolioCurve, PortfolioPool, PortfolioPosition} from "contracts/PortfolioLib.sol";
import {TestERC20} from "contracts/test/TestERC20.sol";
import {IPortfolioStruct} from "../HelperGhostLib.sol";

interface PortfolioLike {
    function getReserve(address) external view returns (uint256);

    function getBalance(address, address) external view returns (uint256);

    function getPairNonce() external view returns (uint16);
}

struct PortfolioState {
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

contract HelperPortfolioView {
    using RMM01Lib for PortfolioPool;

    function getPool(address portfolio, uint64 poolId) public view returns (PortfolioPool memory) {
        return IPortfolioStruct(portfolio).pools(poolId);
    }

    function getCurve(address portfolio, uint64 poolId) public view returns (PortfolioCurve memory) {
        PortfolioPool memory pool = getPool(portfolio, poolId);
        return pool.params;
    }

    function getPair(address portfolio, uint24 pairId) public view returns (PortfolioPair memory) {
        return IPortfolioStruct(portfolio).pairs(pairId);
    }

    function getPosition(
        address portfolio,
        address owner,
        uint64 positionId
    ) public view returns (PortfolioPosition memory) {
        return IPortfolioStruct(portfolio).positions(owner, positionId);
    }

    function getReserve(address portfolio, address token) public view returns (uint256) {
        return PortfolioLike(portfolio).getReserve(token);
    }

    function getBalance(address portfolio, address owner, address token) public view returns (uint256) {
        return PortfolioLike(portfolio).getBalance(owner, token);
    }

    function _getPool(IPortfolioStruct portfolio, uint64 poolId) public view returns (PortfolioPool memory) {
        return (portfolio).pools(poolId);
    }

    function _getPosition(
        IPortfolioStruct portfolio,
        address owner,
        uint64 positionId
    ) public view returns (PortfolioPosition memory) {
        return portfolio.positions(owner, positionId);
    }

    function _getReserve(PortfolioLike portfolio, TestERC20 token) public view returns (uint256) {
        return portfolio.getReserve(address(token));
    }

    function _getBalance(PortfolioLike portfolio, address owner, TestERC20 token) public view returns (uint256) {
        return portfolio.getBalance(owner, address(token));
    }

    /** @dev Fetches pool state and account state for a single pool's tokens. */
    function getState(
        address portfolio,
        uint64 poolId,
        address caller,
        address[] memory owners
    ) public view returns (PortfolioState memory) {
        PortfolioPair memory pair = getPair(portfolio, Processor.decodePairIdFromPoolId(poolId));
        address asset = pair.tokenAsset;
        address quote = pair.tokenQuote;

        PortfolioPool memory pool = getPool(portfolio, poolId);
        PortfolioPosition memory position = getPosition(portfolio, caller, poolId);

        PortfolioState memory state = PortfolioState(
            getReserve(portfolio, asset),
            getReserve(portfolio, quote),
            getPhysicalBalance(portfolio, asset),
            getPhysicalBalance(portfolio, quote),
            getBalanceSum(portfolio, asset, owners),
            getBalanceSum(portfolio, quote, owners),
            getPositionLiquiditySum(portfolio, poolId, owners),
            position.freeLiquidity,
            pool.liquidity,
            pool.feeGrowthGlobalAsset,
            pool.feeGrowthGlobalQuote,
            position.feeGrowthAssetLast,
            position.feeGrowthQuoteLast
        );

        return state;
    }

    function getPhysicalBalance(address portfolio, address token) public view returns (uint256) {
        return Operating.__balanceOf__(token, portfolio);
    }

    function getVirtualBalance(
        address portfolio,
        address token,
        address[] memory owners
    ) public view returns (uint256) {
        uint256 sum = getReserve(portfolio, token) + getBalanceSum(portfolio, token, owners);
        return sum;
    }

    function getBalanceSum(address portfolio, address token, address[] memory owners) public view returns (uint256) {
        uint256 sum;
        for (uint256 x; x != owners.length; ++x) {
            sum += getBalance(portfolio, owners[x], token);
        }

        return sum;
    }

    function getPositionLiquiditySum(
        address portfolio,
        uint64 poolId,
        address[] memory owners
    ) public view returns (uint256) {
        uint256 sum;
        for (uint256 i; i != owners.length; ++i) {
            sum += getPosition(portfolio, owners[i], poolId).freeLiquidity;
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
        address portfolio,
        uint64 poolId,
        bool sellAsset,
        uint256 input
    ) public view returns (uint256) {
        PortfolioPool memory pool = getPool(portfolio, poolId);
        uint256 passed = block.timestamp - pool.lastTimestamp;
        uint256 output = pool.getAmountOut(sellAsset, input, passed);
        return output;
    }
}
