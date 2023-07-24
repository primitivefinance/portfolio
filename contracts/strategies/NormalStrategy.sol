// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IPortfolio.sol";
import "../libraries/BisectionLib.sol";
import "../libraries/PortfolioLib.sol";
import "./INormalStrategy.sol";
import "./NormalStrategyLib.sol";

/// @dev Enforces minimum positive invariant growth for swaps in pools using this strategy.
uint256 constant MINIMUM_INVARIANT_DELTA = 1;

/**
 * @title
 * Normal Strategy
 *
 * @author
 * Primitive™
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

    /// @dev Canonical Portfolio smart contract.
    address public immutable portfolio;

    /// @dev Tracks each pool strategy configuration.
    mapping(uint64 poolId => PortfolioConfig config) public configs;

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
        // This strategy is validated by default for any pool that uses it.
        return true;
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

    /**
     * @notice
     * Validates the invariant rule of swaps.
     *
     * @dev
     * This is a critical check because it's possible for the invariant
     * to be manipulated in a way that keeps it the same,
     * but the reserves are adjusted in a way that credits tokens
     * to the caller. In that scenario, while the trading function says the swap
     * is valid because the invariant did not change, the exact adjusted reserves
     * could have found a combination that takes advantage of the trading function's
     * error. The trading function used by this strategy has approximation error.
     * To avoid this scenario that introduces a potential attack vector or weapon,
     * a minimum __positive__ invariant delta is enforced.
     *
     * @param invariantBefore Invariant computed during the `beforeSwap` hook call.
     * @param invariantAfter Invariant computed during the `validateSwap` hook call.
     */
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
            IPortfolioStruct(portfolio).pairs(PoolId.wrap(poolId).pair());

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

    /**
     * @notice
     * Approximates the x and y reserves per liquidity given a price.
     *
     * @dev
     * Derived from the original trading function, the function
     * is an approximation with error. This should not be relied upon
     * to get a pool to an exact price, but it can be used to get it very close.
     *
     * @custom:warning
     * This function can be manipulated to return a bad price
     * if the caller relies upon this method onchain. Do not rely on
     * the result of this function onchain.
     *
     * @param priceWad Price of the asset to approximate the reserves at, in WAD units.
     * @param strategyArgs Encoded normal strategy arguments: abi.encode(PortfolioConfig).
     * @return reserveXPerWad X reserves per WAD liquidity at `priceWad`, in WAD units.
     * @return reserveYPerWad Y reserves per WAD liquidity at `priceWad`, in WAD units.
     */
    function approximateReservesGivenPrice(
        uint256 priceWad,
        bytes memory strategyArgs
    ) public view override returns (uint256, uint256) {
        PortfolioConfig memory config = strategyArgs.decode();
        NormalCurve memory curve = config.transform();
        return curve.approximateReservesGivenPrice(priceWad);
    }

    /**
     * @notice
     * Get the data required for creating a pool with this strategy.
     *
     * @param strikePriceWad Strike price is the terminal price of the asset token offered by the pool, in WAD units.
     * @param volatilityBasisPoints Affects the range of prices that the pool can be traded at, in basis points.
     * @param durationSeconds The duration of the pool until swaps can no longer happen, in seconds.
     * @param isPerpetual If swaps can always occur in the pool; the time to expiry is fixed.
     * @param priceWad Initial price to approximately set the pool to, in WAD units.
     * @return strategyData Encoded configuration of the Normal Strategy parameters for `createPool`.
     * @return initialX Initial X reserves of a pool in WAD units, per WAD liquidity, at `priceWad`.
     * @return initialY Initial Y reserves of a pool in WAD units, per WAD liquidity, at `priceWad`.
     */
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
