// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {RMM01Portfolio as Hyper} from "../../contracts/RMM01Portfolio.sol";
import "contracts/HyperLib.sol";
import "contracts/test/TestERC20.sol";

contract RevertCatcher {
    Hyper public hyper;

    constructor(address hyper_) {
        hyper = Hyper(payable(hyper_));
    }

    receive() external payable {}

    function approve(address token, address spender) external {
        TestERC20(token).approve(spender, type(uint256).max);
    }

    /** @dev Assumes Hyper calls this, for testing only. Uses try catch to bubble up errors. */
    function process(bytes calldata data) external payable returns (bool) {
        try hyper.multiprocess{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }

    /** @dev Assumes Hyper calls this, for testing only. Uses try catch to bubble up errors. */
    function jumpProcess(bytes calldata data) external payable returns (bool) {
        try hyper.multiprocess{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }
}
