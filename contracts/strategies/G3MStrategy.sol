// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./IG3MStrategy.sol";
import "./G3MStrategyLib.sol";
import "../interfaces/IPortfolio.sol";
import "../libraries/SwapLib.sol";
import "../libraries/AssemblyLib.sol";
import "../libraries/PoolLib.sol";

contract G3MStrategy is IG3MStrategy {
    using AssemblyLib for *;

    address public immutable portfolio;

    mapping(uint64 => IG3MStrategy.Config) public configs;

    modifier onlyPortfolio() {
        if (msg.sender != portfolio) revert NotPortfolio();
        _;
    }

    constructor(address portfolio_) {
        portfolio = portfolio_;
    }

    /// @inheritdoc IStrategy
    function afterCreate(
        uint64 poolId,
        bytes calldata strategyArgs
    ) external returns (bool success) {
        (
            address controller,
            uint256 startWeightX,
            uint256 endWeightX,
            uint256 startUpdate,
            uint256 endUpdate
        ) = abi.decode(
            strategyArgs, (address, uint256, uint256, uint256, uint256)
        );
        configs[poolId] = Config({
            controller: controller,
            startWeightX: startWeightX,
            endWeightX: endWeightX,
            startUpdate: startUpdate,
            endUpdate: endUpdate
        });
        return true;
    }

    /// @inheritdoc IStrategy
    function validatePool(uint64 poolId)
        external
        view
        override
        returns (bool)
    {
        return configs[poolId].startWeightX != 0;
    }

    error NotController();

    function updatePool(
        uint64 poolId,
        address caller,
        bytes memory data
    ) external onlyPortfolio {
        if (caller != configs[poolId].controller) revert NotController();

        // TODO: Add some actual features here
    }

    /// @inheritdoc IStrategy
    function beforeSwap(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external returns (bool, int256) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        (uint256 weightX, uint256 weightY) = computeWeights(poolId);

        int256 invariant = int256(
            G3MStrategyLib.computeInvariant(
                pool.virtualX, weightX, pool.virtualY, weightY
            )
        );
        return (true, invariant);
    }

    /// @inheritdoc IStrategy
    function validateSwap(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY
    ) external view returns (bool, int256) {
        (uint256 weightX, uint256 weightY) = computeWeights(poolId);

        uint256 postInvariant = G3MStrategyLib.computeInvariant(
            reserveX, weightX, reserveY, weightY
        );

        return (
            _validateSwap(uint256(invariant), postInvariant),
            int256(postInvariant)
        );
    }

    function _validateSwap(
        uint256 preInvariant,
        uint256 postInvariant
    ) internal pure returns (bool) {
        return postInvariant > preInvariant;
    }

    /// @inheritdoc IPortfolioStrategy
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) external view returns (uint256 output) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        (uint256 weightX, uint256 weightY) = computeWeights(poolId);

        PortfolioPair memory pair =
            IPortfolioStruct(portfolio).pairs(PoolId.wrap(poolId).pairId());

        amountIn = amountIn.scaleToWad(
            sellAsset ? pair.decimalsAsset : pair.decimalsQuote
        );

        uint256 fees = amountIn * pool.feeBasisPoints / BASIS_POINT_DIVISOR;
        uint256 amountInMinusFees = amountIn - fees;

        output = G3MStrategyLib.computeAmountOutGivenAmountIn(
            amountInMinusFees,
            sellAsset ? pool.virtualX : pool.virtualY,
            sellAsset ? weightX : weightY,
            sellAsset ? pool.virtualY : pool.virtualX,
            sellAsset ? weightY : weightX
        );

        uint256 outputDec = sellAsset ? pair.decimalsQuote : pair.decimalsAsset;
        output = output.scaleFromWadDown(outputDec);
    }

    /// @inheritdoc IPortfolioStrategy
    function getSpotPrice(uint64 poolId)
        external
        view
        returns (uint256 price)
    {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        (uint256 weightX, uint256 weightY) = computeWeights(poolId);

        price = G3MStrategyLib.computeSpotPrice(
            pool.virtualY, weightY, pool.virtualX, weightX
        );
    }

    /// @inheritdoc IPortfolioStrategy
    function getMaxOrder(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external view returns (Order memory) { }

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
        (uint256 weightX, uint256 weightY) = computeWeights(order.poolId);

        prevInvariant = int256(
            G3MStrategyLib.computeInvariant(
                pool.virtualX, weightX, pool.virtualY, weightY
            )
        );

        postInvariant = int256(
            G3MStrategyLib.computeInvariant(
                order.sellAsset
                    ? pool.virtualX + order.input
                    : pool.virtualX - order.input,
                weightX,
                order.sellAsset
                    ? pool.virtualY - order.output
                    : pool.virtualY + order.output,
                weightY
            )
        );

        success = postInvariant > prevInvariant;
    }

    /// @inheritdoc IPortfolioStrategy
    function getInvariant(uint64 poolId) external view returns (int256) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);
        (uint256 weightX, uint256 weightY) = computeWeights(poolId);

        return int256(
            G3MStrategyLib.computeInvariant(
                pool.virtualX, weightX, pool.virtualY, weightY
            )
        );
    }

    function getStrategyData(bytes memory data)
        external
        pure
        returns (bytes memory strategyData, uint256 initialX, uint256 initialY)
    {
        (
            address controller,
            uint256 reserveX,
            uint256 startWeightX,
            uint256 endWeightX,
            uint256 startUpdate,
            uint256 endUpdate,
            uint256 price
        ) = abi.decode(
            data,
            (address, uint256, uint256, uint256, uint256, uint256, uint256)
        );

        strategyData = abi.encode(
            controller, startWeightX, endWeightX, startUpdate, endUpdate
        );
        initialX = reserveX;
        initialY = G3MStrategyLib.computeReserveInGivenPrice(
            price, reserveX, FixedPointMathLib.WAD - startWeightX, startWeightX
        );
    }

    function computeWeights(uint64 poolId)
        internal
        view
        returns (uint256 weightX, uint256 weightY)
    {
        Config memory config = configs[poolId];

        uint256 duration =
            configs[poolId].endUpdate - configs[poolId].startUpdate;
        uint256 timeElapsed = block.timestamp - configs[poolId].startUpdate;
        uint256 t = timeElapsed * WAD / duration;
        uint256 fw0 = G3MStrategyLib.computeISFunction(config.startWeightX);
        uint256 fw1 = G3MStrategyLib.computeISFunction(config.endWeightX);

        weightX = G3MStrategyLib.computeSFunction(t, fw1 - fw0, fw0);
        weightY = WAD - weightX;
    }
}
