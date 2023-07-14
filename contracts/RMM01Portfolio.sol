// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./Portfolio.sol";
import "./libraries/CurveLib.sol";
import "./libraries/BisectionLib.sol";

/**
 * @title   RMM-01 Portfolio
 * @author  Primitive™
 */
contract RMM01Portfolio is Portfolio {
    using CurveLib for PortfolioPool;
    using CurveLib for PortfolioConfig;
    using AssemblyLib for int256;
    using AssemblyLib for uint256;
    using AssemblyLib for uint32;
    using SafeCastLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint128;
    using FixedPointMathLib for uint256;

    int256 internal constant MINIMUM_INVARIANT_DELTA = 1;

    constructor(address weth, address registry) Portfolio(weth, registry) { }

    mapping(uint64 => PortfolioConfig) public configs;

    function createPool(
        uint24 pairId,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint128 strikePrice,
        uint128 price
    ) external payable override returns (uint64 poolId) {
        /* poolId = super.createPool(
            pairId,
            controller,
            priorityFee,
            fee,
            volatility,
            duration,
            strikePrice,
            price
        ); */

        configs[poolId].createConfig({
            strikePriceWad: strikePrice,
            volatilityBasisPoints: volatility,
            durationSeconds: duration,
            isPerpetual: duration == type(uint16).max
        });
    }

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
        /* (iteration, tau) = pool.getSwapData({
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
        }); */
    }

    /// @inheritdoc Portfolio
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
        if (pools[poolId].computeLatestTau(configs[poolId]) == 0) {
            return (false, invariant);
        }

        return (true, invariant);
    }

    /// @inheritdoc Portfolio
    function checkPool(uint64 poolId) public view override returns (bool) {
        return pools[poolId].exists();
    }

    /// @inheritdoc Portfolio
    function checkInvariant(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY,
        uint256 timestamp
    ) public view override returns (bool, int256 nextInvariant) {
        // Computes the time until pool maturity or zero if expired.
        uint256 tau = pools[poolId].computeTau(configs[poolId], timestamp);
        nextInvariant = pools[poolId].getInvariant(configs[poolId]);
        return (
            nextInvariant - invariant >= MINIMUM_INVARIANT_DELTA, nextInvariant
        );
    }

    /// @inheritdoc Portfolio
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
            maxInput = (configs[poolId].strikePriceWad - reserveIn - 1)
                .mulWadDown(liquidity);
        }

        return maxInput;
    }

    /// @inheritdoc Portfolio
    function computeReservesFromPrice(
        uint64 poolId,
        uint256 price
    ) public view override returns (uint256 reserveX, uint256 reserveY) {
        PortfolioPool storage pool = pools[poolId];
        PortfolioConfig memory config = configs[poolId];

        (reserveX, reserveY) = approximateReservesGivenPrice({
            self: NormalCurve({
                reserveXPerWad: pool.virtualX.divWadDown(pool.liquidity),
                reserveYPerWad: pool.virtualY.divWadDown(pool.liquidity),
                strikePriceWad: config.strikePriceWad,
                standardDeviationWad: config.volatilityBasisPoints.bpsToPercentWad(),
                timeRemainingSeconds: pool.computeLatestTau(config)
            }),
            priceWad: price
        });
    }

    /// @inheritdoc Portfolio
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) public view override(Portfolio) returns (uint256 output) {
        PortfolioPool memory pool = pools[poolId];
        /* output = pool.getAmountOut({
            sellAsset: sellAsset,
            amountIn: amountIn,
            timestamp: block.timestamp,
            swapper: swapper
        }); */
    }

    /// @inheritdoc Portfolio
    function getSpotPrice(uint64 poolId)
        public
        view
        override
        returns (uint256 price)
    {
        (price,,) = _getLatestInvariantAndVirtualPrice(poolId, true);
    }
}
