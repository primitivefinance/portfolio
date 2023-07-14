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

    // todo: clean up
    function createPool(
        uint24 pairId,
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint16 feeBasisPoints,
        uint16 priorityFeeBasisPoints,
        address controller,
        bytes calldata data
    ) public payable override returns (uint64 poolId) {
        (PortfolioConfig memory config, uint256 priceWad) =
            abi.decode(data, (PortfolioConfig, uint256));

        if (reserveXPerWad == 0 && reserveYPerWad == 0) {
            (reserveXPerWad, reserveYPerWad) =
                config.transform().approximateReservesGivenPrice(priceWad);
        }

        poolId = super.createPool(
            pairId,
            reserveXPerWad,
            reserveYPerWad,
            feeBasisPoints,
            priorityFeeBasisPoints,
            controller,
            data
        );

        configs[poolId].createConfig({
            strikePriceWad: config.strikePriceWad,
            volatilityBasisPoints: config.volatilityBasisPoints,
            durationSeconds: config.durationSeconds,
            isPerpetual: false
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

        (, invariant,) = pool.getSwapInvariants({
            config: configs[poolId],
            order: Order({
                input: 0,
                output: 0,
                useMax: false,
                poolId: poolId,
                sellAsset: sellAsset
            }),
            timestamp: block.timestamp,
            protocolFee: 0,
            swapper: address(0)
        });

        // todo: price
        price = configs[poolId].transform().approximatePriceGivenX({
            reserveXPerWad: pool.virtualX.divWadDown(pool.liquidity)
        });
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
        // todo: refactor
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
        // todo: refactor with better invariant standardiation

        // Computes the time until pool maturity or zero if expired.
        PortfolioPool memory pool = pools[poolId];
        pool.virtualX = reserveX.safeCastTo128();
        pool.virtualY = reserveY.safeCastTo128();

        nextInvariant = pool.getInvariant(configs[poolId]);
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
        // todo: refactor to new getMaximiumOrder method

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
                reserveXPerWad: 0,
                reserveYPerWad: 0,
                strikePriceWad: config.strikePriceWad,
                standardDeviationWad: config.volatilityBasisPoints.bpsToPercentWad(),
                timeRemainingSeconds: pool.computeLatestTau(config),
                invariant: 0
            }),
            priceWad: price
        });
    }

    function getInvariants(Order memory order)
        public
        view
        returns (int256, int256)
    {
        PortfolioPool storage pool = pools[order.poolId];
        (, int256 invariant, int256 postInvariant) = pool.getSwapInvariants({
            config: configs[order.poolId],
            order: order,
            timestamp: block.timestamp,
            protocolFee: protocolFee,
            swapper: msg.sender
        });

        return (invariant, postInvariant);
    }

    /// @inheritdoc Portfolio
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) public view override(Portfolio) returns (uint256 output) {
        PortfolioPool memory pool = pools[poolId];

        PortfolioPair memory pair = pairs[uint24(poolId >> 40)];
        amountIn = amountIn.scaleToWad(
            sellAsset ? pair.decimalsAsset : pair.decimalsQuote
        );

        output = pool.approximateAmountOut({
            config: configs[poolId],
            order: Order({
                input: amountIn.safeCastTo128(),
                output: 0,
                useMax: false,
                poolId: poolId,
                sellAsset: sellAsset
            }),
            timestamp: block.timestamp,
            protocolFee: protocolFee,
            swapper: swapper
        });

        uint256 outputDec = sellAsset ? pair.decimalsQuote : pair.decimalsAsset;
        output = output.scaleFromWadDown(outputDec);
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

    function getMaxOrder(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external view override returns (Order memory) {
        // todo: implement
    }

    function simulateSwap(
        Order memory args,
        uint256 timestamp,
        address swapper
    )
        external
        view
        override
        returns (bool success, int256 prevInvariant, int256 postInvariant)
    {
        // todo: implement
    }
}
