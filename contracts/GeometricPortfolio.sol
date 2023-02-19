// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./Hyper.sol";
import "./libraries/RMM02Lib.sol";

contract GeometricPortfolio is HyperVirtual {
    using RMM02Lib for HyperPool;
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

    function afterSwapEffects(uint64 poolId, Iteration memory iteration) internal override returns (bool) {
        HyperPool storage pool = pools[poolId];

        int256 liveInvariantWad = 0; // todo: add prev invariant to iteration?

        return true;
    }

    uint public weight = 0.5 ether;

    function beforeSwap(uint64 poolId) internal override returns (bool, int256) {
        HyperPool storage pool = pools[poolId];
        int256 invariant = pool.invariantOf(pool.virtualX, pool.virtualY, weight);
        pool.syncPoolTimestamp(block.timestamp);

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

    // ===== View ===== //

    /** @dev Can be manipulated. */
    function getLatestPrice(uint64 poolId) public view returns (uint256 price) {
        price = pools[poolId].computePrice(weight);
    }

    function _estimateAmountOut(
        HyperPool memory pool,
        bool sellAsset,
        uint amountIn
    ) internal view override returns (uint output) {
        uint256 passed = getTimePassed(pool);
        (output, ) = pool.getPoolAmountOut(sellAsset, amountIn, weight);
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
