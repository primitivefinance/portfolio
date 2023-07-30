// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IPortfolio.sol";
import "../libraries/BisectionLib.sol";
import "../libraries/PortfolioLib.sol";
import "./INormalStrategy.sol";
import "./NormalStrategyLib.sol";

/// @dev Emitted when a hook is called by a non-portfolio address.
error NormalStrategy_NotPortfolio();

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
        emit Genesis(portfolio_);
    }

    /// @dev Mutable function hooks are only called by the immutable portfolio address.
    modifier hook() {
        if (msg.sender != portfolio) revert NormalStrategy_NotPortfolio();

        _;
    }

    // ====== Required ====== //

    /// @inheritdoc IStrategy
    function afterCreate(
        uint64 poolId,
        bytes calldata strategyArgs
    ) public hook returns (bool success) {
        PortfolioConfig memory config = strategyArgs.decode();

        // Assumes after the createPool call goes through it can never reach this again.
        configs[poolId].modify({
            strikePriceWad: config.strikePriceWad,
            volatilityBasisPoints: config.volatilityBasisPoints,
            durationSeconds: config.durationSeconds,
            isPerpetual: config.isPerpetual
        });

        // Config storage could have been altered with `modify`.
        config = configs[poolId];

        emit AfterCreate({
            portfolio: portfolio,
            poolId: poolId,
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
    ) public hook returns (bool, int256) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        PortfolioConfig memory config = configs[poolId];

        // This invariant uses the rounded up output reserves,
        // and computes the time remaining in the pool (a key parameter in the trading function)
        // using the `block.timestamp`.
        int256 invariant =
            pool.getInvariantUp(config, sellAsset, block.timestamp);

        if (pool.expired(config)) return (false, invariant);

        return (true, invariant);
    }

    /// @inheritdoc IStrategy
    function validatePool(uint64 poolId) public view returns (bool) {
        // This strategy is validated by default for any pool that uses it.
        return true;
    }

    /// @inheritdoc IStrategy
    function validateSwap(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY
    ) public view returns (bool, int256) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);

        // Update the reserves in memory.
        pool.virtualX = reserveX.safeCastTo128();
        pool.virtualY = reserveY.safeCastTo128();

        // Compute the new invariant.
        int256 invariantAfterSwap = pool.getInvariantDown(configs[poolId]);
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
        if (delta < MINIMUM_INVARIANT_DELTA) return false;

        return true;
    }

    /// @inheritdoc IPortfolioStrategy
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) public view returns (uint256 output) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);

        PortfolioPair memory pair =
            IPortfolioStruct(portfolio).pairs(PoolId.wrap(poolId).pairId());

        amountIn = amountIn.scaleToWad(
            sellAsset ? pair.decimalsAsset : pair.decimalsQuote
        );

        output = pool.approximateAmountOut({
            config: configs[poolId],
            order: Order({
                input: amountIn.safeCastTo128(),
                output: 1, // to avoid revert from zero adjustment
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
    function getSpotPrice(uint64 poolId) public view returns (uint256 price) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        PortfolioConfig memory config = configs[poolId];

        NormalCurve memory curve = config.transform();

        // The `transform` function does not recompute the time remaining.
        // Overwrite it manually so the approximation uses the new time remaining,
        // instead of the initial full duration on pool creation.
        curve.timeRemainingSeconds = config.computeTau(block.timestamp);

        // The `transform` function also sets `invariant` to 0.
        // This is fine because it's not required for the price calculation.
        price = curve.approximatePriceGivenX({
            reserveXPerWad: pool.virtualX.divWadDown(pool.liquidity)
        });
    }

    /// @inheritdoc IPortfolioStrategy
    function getMaxOrder(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) public view returns (Order memory) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        PortfolioPair memory pair =
            IPortfolioStruct(portfolio).pairs(PoolId.wrap(poolId).pairId());
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

        uint256 tempInput;
        uint256 tempOutput;

        if (sellAsset) {
            tempInput = upperX.mulWadDown(pool.liquidity) - pool.virtualX - 1;
            tempOutput = pool.virtualY - lowerY.mulWadDown(pool.liquidity) - 1;
            order.input =
                tempInput.scaleFromWadDown(pair.decimalsAsset).safeCastTo128();
            order.output =
                tempOutput.scaleFromWadDown(pair.decimalsQuote).safeCastTo128();
        } else {
            tempInput = upperY.mulWadDown(pool.liquidity) - pool.virtualY - 1;
            tempOutput = pool.virtualX - lowerX.mulWadDown(pool.liquidity) - 1;

            order.input =
                tempInput.scaleFromWadDown(pair.decimalsQuote).safeCastTo128();
            order.output =
                tempOutput.scaleFromWadDown(pair.decimalsAsset).safeCastTo128();
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

        PortfolioPair memory pair = IPortfolioStruct(portfolio).pairs(
            PoolId.wrap(order.poolId).pairId()
        );

        // Swap requires an intermediary state where all units are in WAD.
        SwapState memory inter;
        if (order.sellAsset) {
            inter.decimalsInput = pair.decimalsAsset;
            inter.decimalsOutput = pair.decimalsQuote;
            inter.tokenInput = pair.tokenAsset;
            inter.tokenOutput = pair.tokenQuote;
        } else {
            inter.decimalsInput = pair.decimalsQuote;
            inter.decimalsOutput = pair.decimalsAsset;
            inter.tokenInput = pair.tokenQuote;
            inter.tokenOutput = pair.tokenAsset;
        }

        inter.amountInputUnit = order.input;
        inter.amountOutputUnit = order.output;
        inter = inter.toWad();
        order.input = inter.amountInputUnit.safeCastTo128();
        order.output = inter.amountOutputUnit.safeCastTo128();

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
        returns (int256 invariant)
    {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        invariant = pool.getInvariantDown(configs[poolId]);
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
    ) public view returns (uint256, uint256) {
        PortfolioConfig memory config = strategyArgs.decode();
        NormalCurve memory curve = config.transform();

        // Assumes the `config.creationTimestamp` is set to `block.timestamp`.
        // Therefore, `curve.timeRemainingSeconds` is equal to the full duration, `config.durationSeconds`.
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

        // Utilizes `durationSeconds` argument as the `timeRemainingSeconds` parameter.
        (initialX, initialY) =
            config.transform().approximateReservesGivenPrice(priceWad);
    }
}
