// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/test/utils/mocks/MockERC20.sol";

import "contracts/PortfolioLib.sol";
import {RMM01Portfolio as Portfolio} from "contracts/RMM01Portfolio.sol";

contract RevertCatcher {
    Portfolio public portfolio;

    constructor(address portfolio_) {
        portfolio = Portfolio(payable(portfolio_));
    }

    receive() external payable {}

    function approve(address token, address spender) external {
        MockERC20(token).approve(spender, type(uint256).max);
    }

    /**
     * @dev Assumes portfolio calls this, for testing only. Uses try catch to bubble up errors.
     */
    function process(bytes calldata data) external payable returns (bool) {
        try portfolio.multiprocess{value: msg.value}(data) {}
        catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }

    /**
     * @dev Assumes Portfolio calls this, for testing only. Uses try catch to bubble up errors.
     */
    function jumpProcess(bytes calldata data) external payable returns (bool) {
        try portfolio.multiprocess{value: msg.value}(data) {}
        catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }
}
