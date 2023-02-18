// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./Hyper.sol";
import {console} from "forge-std/Test.sol";

library GeometricMath {
    using FixedPointMathLib for uint;
    using FixedPointMathLib for int;

    /**
     * @custom:math k = 1 - (R1 / w)^(w) (R2/(1-w))^(1-w)
     */
    function invariantOf(HyperPool memory pool, uint r1, uint r2, uint weight) internal pure returns (int) {
        //(uint r1, uint r2) = (pool.virtualX, pool.virtualY);
        uint w1 = weight;
        uint w2 = 1 ether - weight;

        int part0 = int(r1.divWadDown(w1)).powWad(int(w1));
        int part1 = int(r2.divWadDown(w2)).powWad(int(w2));

        int result = (part0 * part1) / int(1 ether);
        return result;
    }

    function getAmountOut(
        HyperPool memory pool,
        uint weight,
        bool xIn,
        uint amountIn,
        uint feeBps
    ) internal view returns (uint) {
        if (xIn) {
            uint input = (pool.virtualX * 1 ether) / (pool.virtualX + amountIn);
            console.log(input);
            int bi = int(weight.divWadDown(1 ether - weight));
            console.logInt(bi);
            int pow = int(input).powWad(bi);
            console.logInt(pow);
            uint a0 = uint(pool.virtualY).mulWadDown(uint(int(1 ether) - pow));
            return a0;
        } else {
            return 72;
        }
    }

    // p = bi / wi / bo / wo
    // price = (bi / weight ) / (bo / (1 - weight))
    // price = bi * 1 / weight * (1 - weight) / bo
    // price * weight / (1 - weight) = bi / bo
    // price *
    function computeReservesWithPrice(
        HyperPool memory pool,
        uint price,
        uint weight,
        uint balance
    ) internal pure returns (uint r1, uint r2) {
        pool;
        uint wi = weight;
        uint wo = 1 ether - weight;

        r1 = balance;
        r2 = r1.divWadDown(price.mulWadDown(wi.divWadDown(1 ether - wo)));
    }

    function computePrice(HyperPool memory pool, uint weight) internal pure returns (uint price) {
        price = uint(pool.virtualX).divWadDown(weight).mulWadDown((1 ether - weight).divWadDown(uint(pool.virtualY)));
    }
}

contract GeometricPortfolio is HyperVirtual {
    using GeometricMath for HyperPool;
    using RMM01Lib for RMM01Lib.RMM;
    using SafeCastLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    using {Assembly.isBetween} for uint8;
    using {Assembly.scaleFromWadDownSigned} for int256;
    using {Assembly.scaleFromWadDown, Assembly.scaleFromWadUp, Assembly.scaleToWad} for uint256;

    /**
     * @dev
     * Failing to pass a valid WETH contract that implements the `deposit()` function,
     * will cause all transactions with Hyper to fail once address(this).balance > 0.
     *
     * @notice
     * Tokens sent to this contract are lost.
     */
    constructor(address weth) HyperVirtual(weth) {}

    // Implemented

    function afterSwapEffects(
        uint64 poolId,
        Iteration memory iteration,
        SwapState memory state
    ) internal override returns (bool) {
        HyperPool storage pool = pools[poolId];

        int256 liveInvariantWad = 0; // todo: add prev invariant to iteration?

        // Apply pool effects.
        _syncPool(
            poolId,
            iteration.virtualX,
            iteration.virtualY,
            iteration.liquidity,
            state.sell ? state.feeGrowthGlobal : 0,
            state.sell ? 0 : state.feeGrowthGlobal,
            state.invariantGrowthGlobal
        );

        return true;
    }

    uint public weight = 0.5 ether;

    function beforeSwap(uint64 poolId) internal override returns (bool, int256) {
        HyperPool storage pool = pools[poolId];
        int256 invariant = pool.invariantOf(pool.virtualX, pool.virtualY, weight);
        pool.syncPoolTimestamp(block.timestamp);

        RMM01Lib.RMM memory rmm = pool.getRMM();

        if (rmm.tau == 0) return (false, invariant);

        return (true, invariant);
    }

    function canUpdatePosition(
        HyperPool memory pool,
        HyperPosition memory position,
        int delta
    ) public view override returns (bool) {
        if (delta < 0) {
            uint256 distance = position.getTimeSinceChanged(block.timestamp);
            return (pool.params.jit <= distance);
        }

        return true;
    }

    function checkPool(HyperPool memory pool) public view override returns (bool) {
        return pool.exists();
    }

    function checkInvariant(
        HyperPool memory pool,
        int invariant,
        uint reserve0,
        uint reserve1
    ) public view override returns (bool, int256 nextInvariant) {
        int256 nextInvariant = pool.invariantOf({r1: reserve0, r2: reserve1, weight: weight}); // fix this is inverted?
        return (nextInvariant >= invariant, nextInvariant);
    }

    function computeMaxInput(
        HyperPool memory pool,
        bool direction,
        uint reserveIn,
        uint liquidity
    ) public view override returns (uint) {
        uint maxInput;
        if (direction) {
            maxInput = 10000 ether; // There can be maximum 1:1 ratio between assets and liqudiity.
        } else {
            maxInput = 10000 ether; // There can be maximum strike:1 liquidity ratio between quote and liquidity.
        }

        return maxInput;
    }

    function computeReservesFromPrice(
        HyperPool memory pool,
        uint price
    ) public view override returns (uint reserve0, uint reserve1) {
        uint balance = 1 ether;
        (reserve0, reserve1) = pool.computeReservesWithPrice(price, weight, balance);
    }

    function estimatePrice(uint64 poolId) public view override returns (uint price) {
        price = getLatestPrice(poolId);
    }

    function getReserves(HyperPool memory pool) public view override returns (uint reserve0, uint reserve1) {
        (reserve0, reserve1) = pool.getAmountsWad();
    }

    /**
     * @dev Effects on a Pool after a successful swap order condition has been met.
     */
    function _syncPool(
        uint64 poolId,
        uint256 nextVirtualX,
        uint256 nextVirtualY,
        uint256 liquidity,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote,
        uint256 invariantGrowthGlobal
    ) internal returns (uint256 timeDelta) {
        HyperPool storage pool = pools[poolId];

        timeDelta = getTimePassed(poolId);

        if (pool.virtualX != nextVirtualX) pool.virtualX = nextVirtualX.safeCastTo128();
        if (pool.virtualY != nextVirtualY) pool.virtualY = nextVirtualY.safeCastTo128();
        if (pool.liquidity != liquidity) pool.liquidity = liquidity.safeCastTo128();
        if (pool.lastTimestamp != block.timestamp) pool.syncPoolTimestamp(block.timestamp);

        pool.feeGrowthGlobalAsset = Assembly.computeCheckpoint(pool.feeGrowthGlobalAsset, feeGrowthGlobalAsset);
        pool.feeGrowthGlobalQuote = Assembly.computeCheckpoint(pool.feeGrowthGlobalQuote, feeGrowthGlobalQuote);
        pool.invariantGrowthGlobal = Assembly.computeCheckpoint(pool.invariantGrowthGlobal, invariantGrowthGlobal);
    }

    // ===== View ===== //

    /** @dev Can be manipulated. */
    function getLatestPrice(uint64 poolId) public view returns (uint256 price) {
        price = pools[poolId].computePrice(weight);
    }

    /** @dev Immediately next invariant value. */
    function getInvariant(uint64 poolId) public view returns (int256 invariant) {
        HyperPool memory pool = pools[poolId];
        invariant = pool.invariantOf(pool.virtualX, pool.virtualY, weight);
    }

    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn
    ) public view override(Objective) returns (uint256 output) {
        output = pools[poolId].getAmountOut({weight: weight, xIn: sellAsset, amountIn: amountIn, feeBps: 0});
    }
}
