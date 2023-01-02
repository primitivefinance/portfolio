// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/Enigma.sol" as Processor;
import "contracts/OS.sol" as Operating;
import {Pair, HyperCurve, HyperPool, HyperPosition} from "contracts/HyperLib.sol";

interface IHyperStruct {
    function pairs(uint24 pairId) external view returns (Pair memory);

    function positions(address owner, uint64 positionId) external view returns (HyperPosition memory);

    function pools(uint64 poolId) external view returns (HyperPool memory);
}

interface HyperLike {
    function getReserve(address) external view returns (uint);

    function getBalance(address, address) external view returns (uint);

    function getPairNonce() external view returns (uint16);
}

struct HyperState {
    uint reserveAsset; // getReserve
    uint reserveQuote; // getReserve
    uint physicalBalanceAsset; // balanceOf
    uint physicalBalanceQuote; // balanceOf
    uint totalBalanceAsset; // sum of all balances from getBalance
    uint totalBalanceQuote; // sum of all balances from getBalance
    uint totalPositionLiquidity; // sum of all position liquidity
    uint callerPositionLiquidity; // position.freeLiquidity
    uint totalPoolLiquidity; // pool.liquidity
    uint feeGrowthAssetPool; // getPool
    uint feeGrowthQuotePool; // getPool
    uint feeGrowthAssetPosition; // getPosition
    uint feeGrowthQuotePosition; // getPosition
}

interface TokenLike {
    function balanceOf(address) external view returns (uint);
}

contract HelperHyperView {
    function getPool(address hyper, uint64 poolId) public view returns (HyperPool memory) {
        return IHyperStruct(hyper).pools(poolId);
    }

    function getCurve(address hyper, uint64 poolId) public view returns (HyperCurve memory) {
        HyperPool memory pool = getPool(hyper, poolId);
        return pool.params;
    }

    function getPair(address hyper, uint24 pairId) public view returns (Pair memory) {
        return IHyperStruct(hyper).pairs(pairId);
    }

    function getPosition(address hyper, address owner, uint64 positionId) public view returns (HyperPosition memory) {
        return IHyperStruct(hyper).positions(owner, positionId);
    }

    function getReserve(address hyper, address token) public view returns (uint) {
        return HyperLike(hyper).getReserve(token);
    }

    function getBalance(address hyper, address owner, address token) public view returns (uint) {
        return HyperLike(hyper).getBalance(owner, token);
    }

    /** @dev Fetches pool state and account state for a single pool's tokens. */
    function getState(
        address hyper,
        uint64 poolId,
        address caller,
        address[] memory owners
    ) public view returns (HyperState memory) {
        Pair memory pair = getPair(hyper, Processor.decodePairIdFromPoolId(poolId));
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

    function getPhysicalBalance(address hyper, address token) public view returns (uint) {
        return Operating.__balanceOf__(token, hyper);
    }

    function getVirtualBalance(address hyper, address token, address[] memory owners) public view returns (uint) {
        uint sum = getReserve(hyper, token) + getBalanceSum(hyper, token, owners);
        return sum;
    }

    function getBalanceSum(address hyper, address token, address[] memory owners) public view returns (uint) {
        uint sum;
        for (uint x; x != owners.length; ++x) {
            sum += getBalance(hyper, owners[x], token);
        }

        return sum;
    }

    function getPositionLiquiditySum(address hyper, uint64 poolId, address[] memory owners) public view returns (uint) {
        uint sum;
        for (uint i; i != owners.length; ++i) {
            sum += getPosition(hyper, owners[i], poolId).freeLiquidity;
        }

        return sum;
    }

    function getMaxSwapLimit(bool sellAsset) public view returns (uint) {
        if (sellAsset) {
            // price goes down
            return 0;
        } else {
            // price goes up
            return type(uint).max;
        }
    }
}
