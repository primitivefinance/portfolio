// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {RMM01Portfolio as Portfolio} from "../../contracts/RMM01Portfolio.sol";
import "contracts/PortfolioLib.sol";
import "contracts/test/TestERC20.sol";

contract RevertCatcher {
    Portfolio public portfolio;

    constructor(address Portfolio_) {
        portfolio = Portfolio(payable(Portfolio_));
    }

    receive() external payable {}

    function approve(address token, address spender) external {
        TestERC20(token).approve(spender, type(uint256).max);
    }

    /** @dev Assumes portfolio calls this, for testing only. Uses try catch to bubble up errors. */
    function process(bytes calldata data) external payable returns (bool) {
        try portfolio.multiprocess{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }

    /** @dev Assumes Portfolio calls this, for testing only. Uses try catch to bubble up errors. */
    function jumpProcess(bytes calldata data) external payable returns (bool) {
        try portfolio.multiprocess{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }
}
