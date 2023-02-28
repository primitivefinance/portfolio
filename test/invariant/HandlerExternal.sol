// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./setup/HandlerBase.sol";

contract HandlerExternal is HandlerBase {
    function name() public view override returns (string memory) {
        return "external";
    }
}
