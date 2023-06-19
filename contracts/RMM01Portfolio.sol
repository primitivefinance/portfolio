// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./Portfolio.sol";
import "./libraries/RMM01Lib.sol";
import "./libraries/BisectionLib.sol";

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
    using FixedPointMathLib for uint128;
    using FixedPointMathLib for uint256;

    int256 internal constant MINIMUM_INVARIANT_DELTA = 1;

    constructor(
        address weth,
        address registry
    ) PortfolioVirtual(weth, registry) { }

    /**
     * @dev Computes the latest invariant and spot price of the pool using the latest timestamp.
     *
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price
     * movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _getLatestInvariantAndVirtualPrice(
        uint64 poolId,
        bool sellAsset
    ) internal view returns (uint256 price, int256 invariant, uint256 tau) {
        PortfolioPool storage pool = pools[poolId];

        Iteration memory iteration;
        (iteration, tau) = pool.getSwapData({
            sellAsset: sellAsset,
            amountInWad: 0, // Sets iteration.input to 0, which is not used in this function.
            timestamp: block.timestamp, // Latest timestamp to compute the latest invariant.
            swapper: address(0) // Setting the swap effects the swap fee %, which is not used in this function.
        });

        invariant = iteration.prevInvariant;

        // Approximated and rounded down in all cases via rounding down of virtualX.
        price = RMM01Lib.getPriceWithX({
            R_x: iteration.virtualX.divWadDown(iteration.liquidity),
            stk: pool.params.strikePrice,
            vol: pool.params.volatility,
            tau: tau
        });
    }

    /// @inheritdoc Objective
    function _beforeSwapEffects(
        uint64 poolId,
        bool sellAsset
    ) internal override returns (bool, int256) {
        (, int256 invariant,) =
            _getLatestInvariantAndVirtualPrice(poolId, sellAsset);

        // Sets the pool's lastTimestamp to the current block timestamp, in storage.
        pools[poolId].syncPoolTimestamp(block.timestamp);

        // Buffer for post-maturity swaps would go here.
        // Without a buffer, it's never possible to take trades at tau == 0.
        // This is acceptable.
        if (pools[poolId].lastTau() == 0) return (false, invariant);

        return (true, invariant);
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
        uint256 reserveY,
        uint256 timestamp
    ) public view override returns (bool, int256 nextInvariant) {
        // Computes the time until pool maturity or zero if expired.
        uint256 tau = pools[poolId].computeTau(timestamp);
        nextInvariant = RMM01Lib.invariantOf({
            self: pools[poolId],
            R_x: reserveX,
            R_y: reserveY,
            timeRemainingSec: tau
        });
        return (
            nextInvariant - invariant >= MINIMUM_INVARIANT_DELTA, nextInvariant
        );
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
            // invariant: x reserve < 1E18
            maxInput =
                (FixedPointMathLib.WAD - reserveIn - 1).mulWadDown(liquidity);
        } else {
            // invariant: y reserve < strikePrice
            maxInput = (pools[poolId].params.strikePrice - reserveIn - 1)
                .mulWadDown(liquidity);
        }

        return maxInput;
    }

    /// @inheritdoc Objective
    function computeReservesFromPrice(
        uint64 poolId,
        uint256 price
    ) public view override returns (uint256 reserveX, uint256 reserveY) {
        (reserveX, reserveY) = RMM01Lib.computeReservesWithPrice({
            self: pools[poolId],
            priceWad: price,
            invariantWad: 0
        });
    }

    /// @inheritdoc Objective
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) public view override(Objective) returns (uint256 output) {
        PortfolioPool memory pool = pools[poolId];
        output = pool.getAmountOut({
            sellAsset: sellAsset,
            amountIn: amountIn,
            timestamp: block.timestamp,
            swapper: swapper
        });
    }

    /// @inheritdoc Objective
    function getSpotPrice(uint64 poolId)
        public
        view
        override
        returns (uint256 price)
    {
        (price,,) = _getLatestInvariantAndVirtualPrice(poolId, true);
    }
}
