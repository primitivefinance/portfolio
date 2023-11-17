// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./IG3MStrategy.sol";
import "./G3MStrategyLib.sol";
import "../interfaces/IPortfolio.sol";

contract G3MStrategy is IG3MStrategy {
    address public immutable portfolio;

    mapping(uint64 => IG3MStrategy.Config) public configs;

    modifier onlyPortfolio() {
        if (msg.sender != portfolio) revert NotPortfolio();
        _;
    }

    constructor(address portfolio_) {
        portfolio = portfolio_;
    }

    function afterCreate(
        uint64 poolId,
        bytes calldata strategyArgs
    ) external returns (bool success) {
        (uint256 weightX) = abi.decode(strategyArgs, (uint256));
        configs[poolId] = Config(weightX);
        return true;
    }

    function validatePool(uint64 poolId)
        external
        view
        override
        returns (bool)
    {
        return configs[poolId].weightX != 0;
    }

    function beforeSwap(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external returns (bool, int256) { }

    function validateSwap(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY
    ) external view returns (bool, int256) {
        uint256 postInvariant = G3MStrategyLib.computeInvariant(
            reserveX,
            configs[poolId].weightX,
            reserveY,
            FixedPointMathLib.WAD - configs[poolId].weightX
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

    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) external view returns (uint256) {
        PortfolioPool memory pool = IPortfolioStruct(portfolio).pools(poolId);

        uint256 amountOut = G3MStrategyLib.computeAmountOutGivenAmountIn(
            amountIn,
            sellAsset ? pool.virtualX : pool.virtualY,
            sellAsset
                ? configs[poolId].weightX
                : FixedPointMathLib.WAD - configs[poolId].weightX,
            sellAsset ? pool.virtualY : pool.virtualX,
            sellAsset
                ? FixedPointMathLib.WAD - configs[poolId].weightX
                : configs[poolId].weightX
        );

        return amountOut;
    }

    function getSpotPrice(uint64 poolId)
        external
        view
        returns (uint256 price)
    { }

    function getMaxOrder(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external view returns (Order memory) { }

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

        prevInvariant = int256(
            G3MStrategyLib.computeInvariant(
                pool.virtualX,
                configs[order.poolId].weightX,
                pool.virtualY,
                FixedPointMathLib.WAD - configs[order.poolId].weightX
            )
        );

        postInvariant = int256(
            G3MStrategyLib.computeInvariant(
                order.sellAsset
                    ? pool.virtualX + order.input
                    : pool.virtualX - order.input,
                configs[order.poolId].weightX,
                order.sellAsset
                    ? pool.virtualY - order.output
                    : pool.virtualY + order.output,
                FixedPointMathLib.WAD - configs[order.poolId].weightX
            )
        );

        success = postInvariant > prevInvariant;
    }

    function getInvariant(uint64 poolId) external view returns (int256) { }

    function getStrategyData(
        uint256 reserveX,
        uint256 weightX,
        uint256 price
    )
        external
        pure
        returns (bytes memory strategyData, uint256 initialX, uint256 initialY)
    {
        strategyData = abi.encode(weightX);
        initialX = reserveX;
        initialY = G3MStrategyLib.computeReserveInGivenPrice(
            price, reserveX, FixedPointMathLib.WAD - weightX, weightX
        );
    }
}
