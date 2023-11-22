// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IStrategy.sol";

abstract contract StrategyTemplate is IStrategy {
    error NotPortfolio();

    address public immutable portfolio;

    constructor(address portfolio_) {
        portfolio = portfolio_;
    }

    modifier onlyPortfolio() {
        if (msg.sender != portfolio) revert NotPortfolio();
        _;
    }
}
