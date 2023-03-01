// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/**

  ------------------------------------

  Portfolio is a replicating market maker.

  ------------------------------------

  Primitive™

 */

import "./Portfolio.sol";
import "./libraries/RMM01Lib.sol";

contract RMM01Portfolio is PortfolioVirtual {
    using RMM01Lib for PortfolioPool;
    using SafeCastLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    using {Assembly.isBetween} for uint8;
    using {Assembly.scaleFromWadDownSigned} for int256;
    using {Assembly.scaleFromWadDown, Assembly.scaleFromWadUp, Assembly.scaleToWad} for uint256;

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
        int256 liveInvariantWad = 0; // todo: add prev invariant to iteration?
        // Apply priority invariant growth.
        if (msg.sender == pools[poolId].controller) {
            int256 delta = iteration.invariant - liveInvariantWad;
            uint256 deltaAbs = uint256(delta < 0 ? -delta : delta);
            if (deltaAbs != 0) _state.invariantGrowthGlobal = deltaAbs.divWadDown(iteration.liquidity); // todo: don't like this setting internal _state...
        }

        return true;
    }

    function _beforeSwapEffects(uint64 poolId) internal override returns (bool, int256) {
        (, int256 invariant, ) = _computeSyncedPrice(poolId);
        pools[poolId].syncPoolTimestamp(block.timestamp);

        if (pools[poolId].lastTau() == 0) return (false, invariant);

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
        uint tau = pools[poolId].lastTau();
        nextInvariant = RMM01Lib.invariantOf({self: pools[poolId], r1: reserve0, r2: reserve1, timeRemainingSec: tau}); // fix this is inverted?

        int256 liveInvariantWad = invariant.scaleFromWadDownSigned(pools[poolId].pair.decimalsQuote); // invariant is denominated in quote token.
        int256 nextInvariantWad = nextInvariant.scaleFromWadDownSigned(pools[poolId].pair.decimalsQuote);
        return (nextInvariantWad >= liveInvariantWad, nextInvariant);
    }

    function computeMaxInput(
        uint64 poolId,
        bool direction,
        uint reserveIn,
        uint liquidity
    ) public view override returns (uint) {
        uint maxInput;
        if (direction) {
            maxInput = (FixedPointMathLib.WAD - reserveIn).mulWadDown(liquidity); // There can be maximum 1:1 ratio between assets and liqudiity.
        } else {
            maxInput = (pools[poolId].params.maxPrice - reserveIn).mulWadDown(liquidity); // There can be maximum strike:1 liquidity ratio between quote and liquidity.
        }

        return maxInput;
    }

    function computeReservesFromPrice(
        uint64 poolId,
        uint price
    ) public view override returns (uint reserve0, uint reserve1) {
        (reserve1, reserve0) = RMM01Lib.computeReservesWithPrice({self: pools[poolId], priceWad: price, inv: 0});
    }

    function getLatestEstimatedPrice(uint64 poolId) public view override returns (uint price) {
        (price, , ) = _computeSyncedPrice(poolId);
    }

    /**
     * @dev Computes the price of the pool, which changes over time.
     *
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _computeSyncedPrice(
        uint64 poolId
    ) internal view returns (uint256 price, int256 invariant, uint256 updatedTau) {
        PortfolioPool memory pool = pools[poolId];
        if (!pool.exists()) revert NonExistentPool(poolId);
        uint timeSinceUpdate = _getTimePassed(pool);
        (invariant, updatedTau) = RMM01Lib.getNextInvariant({self: pool, timeSinceUpdate: timeSinceUpdate});
        price = RMM01Lib.getPriceWithX({
            R_x: pool.virtualX,
            stk: pool.params.maxPrice,
            vol: pool.params.volatility,
            tau: updatedTau
        });
    }

    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn
    ) public view override(Objective) returns (uint256 output) {
        PortfolioPool memory pool = pools[poolId];
        output = pool.getAmountOut({
            direction: sellAsset,
            amountIn: amountIn,
            secondsPassed: block.timestamp - pool.lastTimestamp // invariant: should not underflow.
        });
    }
}
