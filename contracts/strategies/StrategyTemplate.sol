// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IStrategy.sol";

/**
 * @title Portfolio Strategy Template
 * @author Primitive™
 * @notice This abstract contract can be extended to create custom strategies
 * for Portfolio.
 */
abstract contract StrategyTemplate is IStrategy {
    /// @dev Thrown when the sender is not the Portfolio contract.
    error NotPortfolio();

    /// @dev Address of the Portfolio contract.
    address public immutable portfolio;

    /// @param portfolio_ Address of the Portfolio contract.
    constructor(address portfolio_) {
        portfolio = portfolio_;
    }

    /// @dev Modifier to check that the sender is the Portfolio contract.
    modifier onlyPortfolio() {
        if (msg.sender != portfolio) revert NotPortfolio();
        _;
    }
}
