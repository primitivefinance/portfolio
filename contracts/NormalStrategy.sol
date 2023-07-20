// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./interfaces/IStrategy.sol";
import "./interfaces/IPortfolio.sol";
import "./libraries/CurveLib.sol";
import "./libraries/BisectionLib.sol";
import "./libraries/PortfolioLib.sol";

contract NormalStrategy is IStrategy {
    using CurveLib for PortfolioPool;
    using CurveLib for PortfolioConfig;
    using AssemblyLib for int256;
    using AssemblyLib for uint256;
    using AssemblyLib for uint32;
    using SafeCastLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint128;
    using FixedPointMathLib for uint256;

    address public immutable portfolio;

    mapping(uint64 poolId => PortfolioConfig config) public configs;

    uint256 constant MINIMUM_INVARIANT_DELTA = 1;

    constructor(address portfolio_) {
        portfolio = portfolio_;
    }

    function afterCreate(
        uint64 poolId,
        bytes calldata data
    ) public override returns (bool success) {
        (PortfolioConfig memory config, uint256 priceWad) =
            abi.decode(data, (PortfolioConfig, uint256));

        configs[poolId].createConfig({
            strikePriceWad: config.strikePriceWad,
            volatilityBasisPoints: config.volatilityBasisPoints,
            durationSeconds: config.durationSeconds,
            isPerpetual: config.isPerpetual
        });
    }

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

    function verifySwap(
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
        bool valid = _validate(invariant, invariantAfterSwap);

        return (valid, invariantAfterSwap);
    }

    function _validate(
        int256 invariantBefore,
        int256 invariantAfter
    ) internal pure returns (bool) {
        int256 delta = invariantAfter - invariantBefore;
        if (delta < int256(MINIMUM_INVARIANT_DELTA)) return false;

        return true;
    }

    function verifyPool(uint64 poolId) public view override returns (bool) {
        // todo: refactor
        return IPortfolioStruct(portfolio).pools(poolId).exists();
    }

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

    function getInvariant(uint64 poolId)
        public
        view
        override
        returns (int256 invariant)
    {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        invariant = pool.getInvariant(configs[poolId]);
    }

    function getSwapInvariants(Order memory order)
        public
        view
        override
        returns (int256, int256)
    {
        PortfolioPool memory pool =
            IPortfolioStruct(portfolio).pools(order.poolId);
        (, int256 invariant, int256 postInvariant) = pool.getSwapInvariants({
            config: configs[order.poolId],
            order: order,
            timestamp: block.timestamp,
            protocolFee: IPortfolio(portfolio).protocolFee(),
            swapper: msg.sender
        });

        return (invariant, postInvariant);
    }

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

    function getFees(uint64)
        public
        view
        override
        returns (uint256, uint256, uint256)
    {
        return (0, 0, 0);
    }

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
        strategyData = abi.encode(config, priceWad);

        (initialX, initialY) =
            config.transform().approximateReservesGivenPrice(priceWad);
    }

    function approximateReservesGivenPrice(bytes memory data)
        public
        view
        override
        returns (uint256, uint256)
    {
        (PortfolioConfig memory config, uint256 priceWad) =
            abi.decode(data, (PortfolioConfig, uint256));
        NormalCurve memory curve = config.transform();
        return curve.approximateReservesGivenPrice(priceWad);
    }

    function simulateSwap(
        Order memory order,
        uint256 timestamp,
        address swapper
    )
        external
        view
        returns (bool success, int256 prevInvariant, int256 postInvariant)
    { }
}
