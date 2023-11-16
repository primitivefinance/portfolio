// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../interfaces/IStrategy.sol";

interface IG3MStrategy is IStrategy {
    error NotPortfolio();

    struct Config {
        uint256 weightX;
    }
}
