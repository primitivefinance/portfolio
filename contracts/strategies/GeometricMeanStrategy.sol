// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IPortfolio.sol";
import "../libraries/BisectionLib.sol";
import "../libraries/PortfolioLib.sol";
import "./IGeometricMeanStrategy.sol";

/// @dev Emitted when a hook is called by a non-portfolio address.
error GeometricMeanStrategy_NotPortfolio();

using { encode, decode, modify, tradingFunction } for G3MConfig global;

/// @dev Geometric mean strategy has two tokens with a weighted composition that sums to 1.
struct G3MConfig {
    uint256 assetWeightWad; // between 0 - 1E18
    uint256 quoteWeightWad; // between 0 - 1E18
}

/// @dev Uses abi to decode the strategy args into the G3M config.
function decode(bytes memory strategyArgs) pure returns (G3MConfig memory) {
    return abi.decode(strategyArgs, (G3MConfig));
}

/// @dev Used to edit the G3M config weights.
function modify(
    G3MConfig storage self,
    uint256 assetWeightWad,
    uint256 quoteWeightWad
) {
    self.assetWeightWad = assetWeightWad;
    self.quoteWeightWad = quoteWeightWad;
}

/// @dev Abi encodes the G3M config into strategy args.
function encode(G3MConfig memory self) pure returns (bytes memory) {
    return abi.encode(self);
}

/// @dev Invariant of the Geometric Mean trading rule.
function tradingFunction(
    G3MConfig memory self,
    uint256 reserveX,
    uint256 reserveY
) pure returns (int256 invariant) {
    uint256 w_x = self.assetWeightWad;
    uint256 w_y = WAD - w_x;

    int256 p_x = int256(reserveX.divWadDown(w_x)).powWad(int256(w_x)); // p_x = (x / w_x) ^ w_x
    int256 p_y = int256(reserveY.divWadDown(w_y)).powWad(int256(w_y)); // p_y = (y / w_y) ^ w_y

    invariant = p_x * p_y / int256(WAD); // invariant = p_x * p_y
}

function approximateAmountOut(
    PortfolioPool memory self,
    G3MConfig memory config,
    Order memory order,
    uint256 timestamp,
    uint256 protocolFee,
    address swapper
) internal view returns (uint256 amountOutWad) {
    if (sellAsset) {
        uint256 input =
            uint256(self.virtualX).divWadDown(uint256(self.virtualX + amountIn));
        int256 balanceIn = int256(weightIn.divWadDown(WAD - weightIn));
        int256 pow = int256(input).powWad(balanceIn);
        amountOut =
            uint256(self.virtualY).mulWadDown(uint256(int256(WAD) - pow));
    } else {
        // todo: implement opposite case.
    }
}

/**
 * @dev Computes a `price` in WAD units given a `weight` and reserve quantities in WAD.
 * @custom:math price = (R_x / w_x) * ((1 - w_x) / R_y)
 */
function approximatePriceGivenAssetWeight(
    PortfolioPool memory self,
    uint256 assetWeightWad
) internal pure returns (uint256 price) {
    price = uint256(self.virtualX).divWadDown(assetWeightWad).mulWadDown(
        (WAD - assetWeightWad).divWadDown(uint256(self.virtualY))
    );
}

function getInvariant(
    PortfolioPool memory self,
    G3MConfig memory config
) pure returns (int256) {
    return config.tradingFunction(self.virtualX, self.virtualY);
}

/**
 * @notice
 * Get the invariant values used to verify a swap given a swap order.
 *
 * @dev
 * Assumes order input and output amounts are in WAD units.
 * This is used to verify that the invariant has increased since the last swap.
 *
 * @param timestamp Expected timestamp of the swap to be included in a block.
 */
function getSwapInvariants(
    PortfolioPool memory self,
    G3MConfig memory config,
    Order memory order,
    uint256 timestamp,
    uint256 protocolFee,
    address swapper
)
    internal
    view
    returns (
        uint256 adjustedIndependentReserve,
        int256 prevInvariant,
        int256 postInvariant
    )
{
    // Computed using a rounded up output reserve per liquidity.
    prevInvariant = self.getInvariant(config);

    // Compute the next invariant if the swap amounts are non zero.
    (uint256 reserveX, uint256 reserveY) = (self.virtualX, self.virtualY);

    uint256 feeBps = swapper == self.controller
        ? self.priorityFeeBasisPoints
        : self.feeBasisPoints;

    // Compute the adjusted reserves.
    (,, reserveX, reserveY) =
        order.computeSwapResult(reserveX, reserveY, feeBps, protocolFee);

    postInvariant = config.tradingFunction(reserveX, reserveY);
    adjustedIndependentReserve = order.sellAsset ? reserveX : reserveY;
}

/// @title Geometric Mean Strategy
contract GeometricMeanStrategy is IGeometricMeanStrategy {
    using AssemblyLib for *;
    using FixedPointMathLib for *;
    using SafeCastLib for uint256;
    using {
        approximatePriceGivenAssetWeight,
        getInvariant,
        approximateAmountOut
    } for PortfolioPool;

    /// @dev Canonical Portfolio smart contract.
    address public immutable portfolio;

    /// @dev Tracks each pool strategy configuration.
    mapping(uint64 poolId => G3MConfig config) public configs;

    constructor(address portfolio_) {
        portfolio = portfolio_;
        emit Genesis(portfolio_);
    }

    /// @dev Mutable function hooks are only called by the immutable portfolio address.
    modifier hook() {
        if (msg.sender != portfolio) {
            revert GeometricMeanStrategy_NotPortfolio();
        }

        _;
    }

    // ====== Required ====== //

    /// @inheritdoc IStrategy
    function afterCreate(
        uint64 poolId,
        bytes calldata strategyArgs
    ) public hook returns (bool success) {
        G3MConfig memory config = strategyArgs.decode();

        // Assumes after the createPool call goes through it can never reach this again.
        configs[poolId].modify({
            assetWeightWad: config.assetWeightWad,
            quoteWeightWad: config.quoteWeightWad
        });

        // Config storage could have been altered with `modify`.
        config = configs[poolId];

        emit AfterCreate({
            portfolio: portfolio,
            poolId: poolId,
            assetWeightWad: config.assetWeightWad,
            quoteWeightWad: config.quoteWeightWad
        });

        return true;
    }

    /// @inheritdoc IStrategy
    function beforeSwap(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) public hook returns (bool, int256) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        G3MConfig memory config = configs[poolId];

        // This invariant uses the rounded up output reserves,
        // and computes the time remaining in the pool (a key parameter in the trading function)
        // using the `block.timestamp`.
        int256 invariant = pool.getInvariant(config);

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
        G3MConfig memory config = configs[poolId];
        price = config.approximatePriceGivenAssetWeight({
            assetWeightWad: config.assetWeightWad
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
        G3MConfig memory config = configs[poolId];

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
            tempInput = type(uint128).max - pool.virtualX;
            tempOutput = pool.virtualY;
            order.input =
                tempInput.scaleFromWadDown(pair.decimalsAsset).safeCastTo128();
            order.output =
                tempOutput.scaleFromWadDown(pair.decimalsQuote).safeCastTo128();
        } else {
            tempInput = type(uint128).max - pool.virtualY;
            tempOutput = pool.virtualX;
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
        invariant = pool.getInvariant(configs[poolId]);
    }

    // ====== Optional ====== //

    /**
     * @custom:math balanceOut = reserveX * (1 - weightX) / (price * weightOut)
     */
    function approximateYGivenXAndPrice(
        G3MConfig memory self,
        uint256 reserveX,
        uint256 priceWad
    ) public view returns (uint256, uint256) {
        uint256 weightOut = WAD - self.assetWeightWad;
        uint256 reserveY = reserveX.divWadDown(
            price.mulWadDown(self.assetWeightWad.divWadDown(WAD - weightOut))
        );

        return (reserveX, reserveY);
    }

    /**
     * @notice Get the data required for creating a pool with this strategy.
     *
     * @param assetWeightWad Weight of the asset token in the pool, in WAD units between 0 and 1E18.
     * @param quoteWeightWad Weight of the quote token in the pool, in WAD units between 0 and 1E18.
     * @param priceWad Initial price to approximately set the pool to, in WAD units.
     * @return strategyData Encoded configuration of the Normal Strategy parameters for `createPool`.
     * @return initialX Initial X reserves of a pool in WAD units, per WAD liquidity, at `priceWad`.
     * @return initialY Initial Y reserves of a pool in WAD units, per WAD liquidity, at `priceWad`.
     */
    function getStrategyData(
        uint256 assetWeightWad,
        uint256 quoteWeightWad,
        uint256 priceWad
    )
        public
        pure
        returns (bytes memory strategyData, uint256 initialX, uint256 initialY)
    {
        G3MConfig memory config = G3MConfig(assetWeightWad, quoteWeightWad);
        strategyData = config.encode();

        // Utilizes `durationSeconds` argument as the `timeRemainingSeconds` parameter.
        (initialX, initialY) = config.approximateReservesGivenPrice(priceWad);
    }
}
