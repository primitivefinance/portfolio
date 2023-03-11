// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./Portfolio.sol";
import "./libraries/RMM03Lib.sol";

/**
 * @title   RMM-03 Portfolio
 * @author  Primitive™
 */
contract RMM03Portfolio is PortfolioVirtual {
    using RMM03Lib for PortfolioPool;
    using AssemblyLib for uint256;
    using SafeCastLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    constructor(address weth) PortfolioVirtual(weth) {}

    // Implemented

    /// @inheritdoc Objective
    function _afterSwapEffects(uint64 poolId, Iteration memory iteration) internal override returns (bool) {
        return true;
    }

    /// @inheritdoc Objective
    function _beforeSwapEffects(uint64 poolId) internal override returns (bool, int256) {
        PortfolioPool storage pool = pools[poolId];
        pool.syncPoolTimestamp(block.timestamp);

        bool valid = true;
        int256 invariant = pool.invariantOf(pool.virtualX, pool.virtualY);
        return (valid, invariant);
    }

    /// @inheritdoc Objective
    function checkPosition(uint64 poolId, address owner, int256 delta) public view override returns (bool) {
        // Just in time liquidity protection.
        if (delta < 0) {
            uint256 distance = positions[owner][poolId].getTimeSinceChanged(block.timestamp);
            return (pools[poolId].params.jit <= distance);
        }

        return true;
    }

    /// @inheritdoc Objective
    function checkPool(uint64 poolId) public view override returns (bool) {
        return pools[poolId].exists();
    }

    /// @inheritdoc Objective
    function checkInvariant(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY
    ) public view override returns (bool, int256 nextInvariant) {
        nextInvariant = pools[poolId].invariantOf({R_x: reserveX, R_y: reserveY}); // fix this is inverted?

        bool valid = nextInvariant >= invariant;
        return (valid, nextInvariant);
    }

    /// @inheritdoc Objective
    function computeMaxInput(
        uint64 poolId,
        bool sellAsset,
        uint256 reserveIn,
        uint256 liquidity
    ) public view override returns (uint256) {
        uint256 maxInput;
        if (sellAsset) {
            maxInput = 10000 ether; // There can be maximum 1:1 ratio between assets and liqudiity.
        } else {
            maxInput = 10000 ether; // There can be maximum strike:1 liquidity ratio between quote and liquidity.
        }

        return maxInput;
    }

    /// @inheritdoc Objective
    function computeReservesFromPrice(
        uint64 poolId,
        uint256 price
    ) public view override returns (uint256 reserveX, uint256 reserveY) {
        (reserveX, reserveY) = pools[poolId].computeReservesWithPrice(price);
    }

    /// @inheritdoc Objective
    function getLatestEstimatedPrice(uint64 poolId) public view override returns (uint256 price) {
        price = pools[poolId].computePrice();
    }

    /// @inheritdoc Objective
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn
    ) public view override(Objective) returns (uint256 output) {
        output = pools[poolId].getAmountOut({sellAsset: sellAsset, amountIn: amountIn});
    }
}
