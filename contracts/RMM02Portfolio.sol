// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./Portfolio.sol";
import "./libraries/RMM02Lib.sol";

/**
 * @title   Replicating Market Maker 01 Portfolio
 * @author  Primitive™
 */
contract RMM02Portfolio is PortfolioVirtual {
    using RMM02Lib for PortfolioPool;
    using AssemblyLib for uint256;
    using SafeCastLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    /**
     * @dev
     * Failing to pass a valid WETH contract that implements the `deposit()` function,
     * will cause all transactions with Portfolio to fail once address(this).balance > 0.
     *
     * @notice
     * Tokens sent to this contract are lost.
     */
    constructor(address weth) PortfolioVirtual(weth) {}

    // Implemented

    function _afterSwapEffects(uint64 poolId, Iteration memory iteration) internal override returns (bool) {
        PortfolioPool storage pool = pools[poolId];

        int256 liveInvariantWad = 0; // todo: add prev invariant to iteration?

        return true;
    }

    uint public weight = 0.5 ether;

    function _beforeSwapEffects(uint64 poolId) internal override returns (bool, int256) {
        PortfolioPool storage pool = pools[poolId];
        int256 invariant = pool.invariantOf(pool.virtualX, pool.virtualY, weight);
        pool.syncPoolTimestamp(block.timestamp);

        return (true, invariant);
    }

    function checkPosition(uint64 poolId, address owner, int delta) public view override returns (bool) {
        if (delta < 0) {
            uint256 distance = positions[owner][poolId].getTimeSinceChanged(block.timestamp);
            return (pools[poolId].params.jit <= distance);
        }

        return true;
    }

    function checkPool(uint64 poolId) public view override returns (bool) {
        return pools[poolId].exists();
    }

    function checkInvariant(
        uint64 poolId,
        int invariant,
        uint reserve0,
        uint reserve1
    ) public view override returns (bool, int256 nextInvariant) {
        int256 nextInvariant = pools[poolId].invariantOf({R_x: reserve0, R_y: reserve1, weight: weight}); // fix this is inverted?
        return (nextInvariant >= invariant, nextInvariant);
    }

    function computeMaxInput(
        uint64 poolId,
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
        uint64 poolId,
        uint price
    ) public view override returns (uint reserve0, uint reserve1) {
        uint balance = 1 ether;
        (reserve0, reserve1) = pools[poolId].computeReservesWithPrice(price, weight, balance);
    }

    function getLatestEstimatedPrice(uint64 poolId) public view override returns (uint price) {
        price = pools[poolId].computePrice(weight);
    }

    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn
    ) public view override(Objective) returns (uint256 output) {
        output = pools[poolId].getAmountOut({weight: weight, xIn: sellAsset, amountIn: amountIn, feeBps: 0});
    }
}
