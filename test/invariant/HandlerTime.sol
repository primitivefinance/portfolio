// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/HandlerBase.sol";

contract HandlerTime is HandlerBase {
    function name() public view override returns (string memory) {
        return "time";
    }

    function warper(uint256 amount) external {
        vm.warp(block.timestamp + bound(amount, 1, 365 days));
    }

    function warpAfterMaturity(uint256 amount) external {
        amount = bound(amount, 1 days, 700 days);
        uint256 maturity = ctx.ghost().pool().params.maturity();
        vm.warp(maturity + amount);
    }
}
