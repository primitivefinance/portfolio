// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./setup/HandlerBase.sol";

contract HandlerDeposit is HandlerBase {
    function deposit(uint256 amount, uint256 actorSeed) external createActor useActor(actorSeed) {
        amount = bound(amount, 1, 1e36);

        vm.deal(ctx.actor(), amount);

        address weth = ctx.subject().WETH();

        uint256 preBal = ctx.ghost().balance(ctx.actor(), weth);
        uint256 preRes = ctx.ghost().reserve(weth);
        vm.prank(ctx.actor());
        ctx.subject().deposit{value: amount}();
        uint256 postRes = ctx.ghost().reserve(weth);
        uint256 postBal = ctx.ghost().balance(ctx.actor(), weth);

        assertEq(postRes, preRes + amount, "weth-reserve");
        assertEq(postBal, preBal + amount, "weth-balance");
        assertEq(address(ctx.subject()).balance, 0, "eth-balance");
        assertEq(ctx.ghost().balance(address(ctx.subject()), weth), postRes, "weth-physical");
    }
}
