// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./Portfolio.sol";
import "./libraries/RMM01Lib.sol";

/**
 * @title   RMM-01 Portfolio
 * @author  Primitive™
 */
contract RMM01Portfolio is PortfolioVirtual {
    using RMM01Lib for PortfolioPool;
    using AssemblyLib for int256;
    using AssemblyLib for uint256;
    using SafeCastLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    constructor(address weth) PortfolioVirtual(weth) {}

    /**
     * @dev Computes the price of the pool, which changes over time.
     *
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price
     * movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _computeSyncedPrice(
        uint64 poolId
    ) internal view returns (uint256 price, int256 invariant, uint256 updatedTau) {
        PortfolioPool memory pool = pools[poolId];
        if (!pool.exists()) revert NonExistentPool(poolId);
        uint256 timeSinceUpdate = _getTimePassed(pool);
        (invariant, updatedTau) = RMM01Lib.getNextInvariant({self: pool, timeSinceUpdate: timeSinceUpdate});
        price = RMM01Lib.getPriceWithX({
            R_x: pool.virtualX,
            stk: pool.params.maxPrice,
            vol: pool.params.volatility,
            tau: updatedTau
        });
    }

    /// @inheritdoc Objective
    function _afterSwapEffects(uint64 poolId, Iteration memory iteration) internal override returns (bool) {
        int256 liveInvariantWad = 0; // todo: add prev invariant to iteration?
        // Apply priority invariant growth.
        if (msg.sender == pools[poolId].controller) {
            int256 delta = iteration.invariant - liveInvariantWad;
            uint256 deltaAbs = uint256(delta < 0 ? -delta : delta);
            if (deltaAbs != 0) _state.invariantGrowthGlobal = deltaAbs.divWadDown(iteration.liquidity); // todo: don't
            // like this setting internal _state...
        }

        return true;
    }

    /// @inheritdoc Objective
    function _beforeSwapEffects(uint64 poolId) internal override returns (bool, int256) {
        (, int256 invariant, ) = _computeSyncedPrice(poolId);
        pools[poolId].syncPoolTimestamp(block.timestamp);

        if (pools[poolId].lastTau() == 0) return (false, invariant);

        return (true, invariant);
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
        uint256 tau = pools[poolId].lastTau();
        nextInvariant = RMM01Lib.invariantOf({
            self: pools[poolId],
            R_x: reserveX,
            R_y: reserveY,
            timeRemainingSec: tau
        });

        // Invariant for RMM01 is denominated in the `quote` token.
        int256 liveInvariantWad = invariant.scaleFromWadDownSigned(pools[poolId].pair.decimalsQuote);
        int256 nextInvariantWad = nextInvariant.scaleFromWadDownSigned(pools[poolId].pair.decimalsQuote);
        return (nextInvariantWad >= liveInvariantWad, nextInvariant);
    }

    /// @inheritdoc Objective
    function computeMaxInput(
        uint64 poolId,
        bool direction,
        uint256 reserveIn,
        uint256 liquidity
    ) public view override returns (uint256) {
        uint256 maxInput;
        if (direction) {
            maxInput = (FixedPointMathLib.WAD - reserveIn).mulWadDown(liquidity); // There can be maximum 1:1 ratio
            // between assets and liqudiity.
        } else {
            maxInput = (pools[poolId].params.maxPrice - reserveIn).mulWadDown(liquidity); // There can be maximum
            // strike:1 liquidity ratio between quote and liquidity.
        }

        return maxInput;
    }

    /// @inheritdoc Objective
    function computeReservesFromPrice(
        uint64 poolId,
        uint256 price
    ) public view override returns (uint256 reserveX, uint256 reserveY) {
        (reserveY, reserveX) = RMM01Lib.computeReservesWithPrice({
            self: pools[poolId],
            priceWad: price,
            invariantWad: 0
        });
    }

    /// @inheritdoc Objective
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn
    ) public view override(Objective) returns (uint256 output) {
        PortfolioPool memory pool = pools[poolId];
        output = pool.getAmountOut({
            sellAsset: sellAsset,
            amountIn: amountIn,
            secondsPassed: block.timestamp - pool.lastTimestamp
        });
    }

    /// @inheritdoc Objective
    function getLatestEstimatedPrice(uint64 poolId) public view override returns (uint256 price) {
        (price, , ) = _computeSyncedPrice(poolId);
    }
}
