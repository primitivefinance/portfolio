// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./IG3MStrategy.sol";

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
    ) external view returns (bool, int256) { }

    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) external view returns (uint256) { }

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
    { }

    function getInvariant(uint64 poolId) external view returns (int256) { }

    function validatePool(uint64 poolId)
        external
        view
        override
        returns (bool)
    { }
}
