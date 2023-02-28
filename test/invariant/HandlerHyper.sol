// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./setup/HandlerBase.sol";

contract HandlerHyper is HandlerBase {
    function name() public view override returns (string memory) {
        return "hyper";
    }

    function deposit(uint128 amount, uint seed) external createActor useActor(seed) countCall("deposit") {
        vm.assume(amount > 0);
        console.log(ctx.actor());
        vm.deal(ctx.actor(), amount);

        ctx.subject().deposit{value: amount}();
    }

    function callSummary() external view {
        console.log("deposit", calls["deposit"]);
    }
}
