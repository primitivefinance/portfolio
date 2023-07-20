// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IPortfolio.sol";
import "../libraries/BisectionLib.sol";
import "../libraries/PortfolioLib.sol";
import "./INormalStrategy.sol";
import "./NormalStrategyLib.sol";

/**
 * @title
 * Normal Strategy
 *
 * @author
 * Primitive
 *
 * @notice
 * Distributes liquidity across a normal distribution.
 */
contract NormalStrategy is INormalStrategy {
    using AssemblyLib for *;
    using FixedPointMathLib for *;
    using SafeCastLib for uint256;
    using NormalStrategyLib for bytes;
    using NormalStrategyLib for PortfolioPool;
    using NormalStrategyLib for PortfolioConfig;

    address public immutable portfolio;

    mapping(uint64 poolId => PortfolioConfig config) public configs;

    uint256 constant MINIMUM_INVARIANT_DELTA = 1;

    constructor(address portfolio_) {
        portfolio = portfolio_;
    }

    // ====== Required ====== //

    /// @inheritdoc IStrategy
    function afterCreate(
        uint64 poolId,
        bytes calldata strategyArgs
    ) public override returns (bool success) {
        PortfolioConfig memory config = strategyArgs.decode();

        configs[poolId].modify({
            strikePriceWad: config.strikePriceWad,
            volatilityBasisPoints: config.volatilityBasisPoints,
            durationSeconds: config.durationSeconds,
            isPerpetual: config.isPerpetual
        });
    }

    /// @inheritdoc IStrategy
    function beforeSwap(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) public override returns (bool, int256) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);

        (, int256 invariant,) = pool.getSwapInvariants({
            config: configs[poolId],
            order: Order({
                input: 0,
                output: 0,
                useMax: false,
                poolId: poolId,
                sellAsset: sellAsset
            }),
            timestamp: block.timestamp,
            protocolFee: IPortfolioGetters(portfolio).protocolFee(),
            swapper: swapper
        });

        if (pool.expired(configs[poolId])) return (false, invariant);

        return (true, invariant);
    }

    /// @inheritdoc IStrategy
    function validatePool(uint64 poolId) public view override returns (bool) {
        // todo: refactor
        return IPortfolioStruct(portfolio).pools(poolId).exists();
    }

    /// @inheritdoc IStrategy
    function validateSwap(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY
    ) public view override returns (bool, int256) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);

        // Update the reserves in memory.
        pool.virtualX = reserveX.safeCastTo128();
        pool.virtualY = reserveY.safeCastTo128();

        // Compute the new invariant.
        int256 invariantAfterSwap = pool.getInvariant(configs[poolId]);
        bool valid = _validateSwap(invariant, invariantAfterSwap);

        return (valid, invariantAfterSwap);
    }

    function _validateSwap(
        int256 invariantBefore,
        int256 invariantAfter
    ) internal pure returns (bool) {
        int256 delta = invariantAfter - invariantBefore;
        if (delta < int256(MINIMUM_INVARIANT_DELTA)) return false;

        return true;
    }

    /// @inheritdoc IPortfolioStrategy
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) public view override returns (uint256 output) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);

        PortfolioPair memory pair =
            IPortfolioStruct(portfolio).pairs(uint24(poolId >> 40));
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
            protocolFee: IPortfolio(portfolio).protocolFee(),
            swapper: swapper
        });

        uint256 outputDec = sellAsset ? pair.decimalsQuote : pair.decimalsAsset;
        output = output.scaleFromWadDown(outputDec);
    }

    /// @inheritdoc IPortfolioStrategy
    function getSpotPrice(uint64 poolId)
        public
        view
        override
        returns (uint256 price)
    {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        price = configs[poolId].transform().approximatePriceGivenX({
            reserveXPerWad: pool.virtualX.divWadDown(pool.liquidity)
        });
    }

    /// @inheritdoc IPortfolioStrategy
    function getMaxOrder(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) public view override returns (Order memory) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        PortfolioConfig memory config = configs[poolId];
        NormalCurve memory curve = config.transform();

        (uint256 upperX, uint256 lowerX) = curve.getReserveXBounds();
        (uint256 upperY, uint256 lowerY) = curve.getReserveYBounds();

        Order memory order = Order({
            input: 0,
            output: 0,
            useMax: false,
            poolId: poolId,
            sellAsset: sellAsset
        });

        if (sellAsset) {
            order.input = upperX.mulWadDown(pool.liquidity).safeCastTo128()
                - pool.virtualX - 1;
            order.output = pool.virtualY
                - lowerY.mulWadDown(pool.liquidity).safeCastTo128() + 1;
        } else {
            order.input = upperY.mulWadDown(pool.liquidity).safeCastTo128()
                - pool.virtualY - 1;
            order.output = pool.virtualX
                - lowerX.mulWadDown(pool.liquidity).safeCastTo128() + 1;
        }

        return order;
    }

    /// @inheritdoc IPortfolioStrategy
    function simulateSwap(
        Order memory order,
        uint256 timestamp,
        address swapper
    )
        external
        view
        returns (bool success, int256 prevInvariant, int256 postInvariant)
    {
        PortfolioPool memory pool =
            IPortfolioStruct(portfolio).pools(order.poolId);

        (, prevInvariant, postInvariant) = pool.getSwapInvariants({
            config: configs[order.poolId],
            order: order,
            timestamp: timestamp,
            protocolFee: IPortfolio(portfolio).protocolFee(),
            swapper: swapper
        });

        success = _validateSwap(prevInvariant, postInvariant);
    }

    /// @inheritdoc IPortfolioStrategy
    function getInvariant(uint64 poolId)
        public
        view
        override
        returns (int256 invariant)
    {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        invariant = pool.getInvariant(configs[poolId]);
    }

    // ====== Optional ====== //

    function approximateReservesGivenPrice(
        uint256 priceWad,
        bytes memory strategyArgs
    ) public view override returns (uint256, uint256) {
        PortfolioConfig memory config = strategyArgs.decode();
        NormalCurve memory curve = config.transform();
        return curve.approximateReservesGivenPrice(priceWad);
    }

    function getStrategyData(
        uint256 strikePriceWad,
        uint256 volatilityBasisPoints,
        uint256 durationSeconds,
        bool isPerpetual,
        uint256 priceWad
    )
        public
        pure
        override
        returns (bytes memory strategyData, uint256 initialX, uint256 initialY)
    {
        PortfolioConfig memory config = PortfolioConfig(
            strikePriceWad.safeCastTo128(),
            volatilityBasisPoints.safeCastTo32(),
            durationSeconds.safeCastTo32(),
            0, // creationTimestamp isnt set, its set to block.timestamp
            isPerpetual
        );
        strategyData = config.encode();

        (initialX, initialY) =
            config.transform().approximateReservesGivenPrice(priceWad);
    }
}
