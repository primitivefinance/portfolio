// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./setup/HandlerBase.sol";

contract HandlerHyper is HandlerBase {
    function deposit(uint amount, uint seed) external countCall("deposit") createActor useActor(seed) {
        amount = bound(amount, 1, 1e36);

        vm.deal(ctx.actor(), amount);

        address weth = ctx.subject().WETH();

        uint256 preBal = ctx.ghost().balance(ctx.actor(), weth);
        uint256 preRes = ctx.ghost().reserve(weth);

        ctx.subject().deposit{value: amount}();

        uint256 postRes = ctx.ghost().reserve(weth);
        uint256 postBal = ctx.ghost().balance(ctx.actor(), weth);

        assertEq(postRes, preRes + amount, "weth-reserve");
        assertEq(postBal, preBal + amount, "weth-balance");
        assertEq(address(ctx.subject()).balance, 0, "eth-balance");
        assertEq(ctx.ghost().balance(address(ctx.subject()), weth), postRes, "weth-physical");
    }

    function fund_asset(
        uint256 amount,
        uint256 seed
    ) public countCall("fund-asset") createActor useActor(seed) usePool(seed) {
        amount = bound(amount, 1, 1e36);

        // If net balance > 0, there are tokens in the contract which are not in a pool or balance.
        // They will be credited to the msg.sender of the next call.
        int256 netAssetBalance = ctx.subject().getNetBalance(address(ctx.ghost().asset().to_token()));
        int256 netQuoteBalance = ctx.subject().getNetBalance(address(ctx.ghost().quote().to_token()));
        assertTrue(netAssetBalance >= 0, "negative-net-asset-tokens");
        assertTrue(netQuoteBalance >= 0, "negative-net-quote-tokens");

        ctx.ghost().asset().to_token().approve(address(ctx.subject()), amount);
        deal(address(ctx.ghost().asset().to_token()), ctx.actor(), amount);

        uint256 preRes = ctx.ghost().reserve(address(ctx.ghost().asset().to_token()));
        uint256 preBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().asset().to_token()));

        ctx.subject().fund(address(ctx.ghost().asset().to_token()), amount);
        uint256 postRes = ctx.ghost().reserve(address(ctx.ghost().asset().to_token()));
        uint256 postBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().asset().to_token()));

        assertEq(postBal, preBal + amount + uint256(netAssetBalance), "fund-delta-asset-balance");
        assertEq(postRes, preRes + amount + uint256(netQuoteBalance), "fund-delta-asset-reserve");
    }

    function fund_quote(
        uint256 amount,
        uint256 seed
    ) public countCall("fund-quote") createActor useActor(seed) usePool(seed) {
        amount = bound(amount, 1, 1e36);

        ctx.ghost().quote().to_token().approve(address(ctx.subject()), amount);
        deal(address(ctx.ghost().quote().to_token()), ctx.actor(), amount);

        uint256 preRes = ctx.ghost().reserve(address(ctx.ghost().quote().to_token()));
        uint256 preBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().quote().to_token()));

        ctx.subject().fund(address(ctx.ghost().quote().to_token()), amount);
        uint256 postRes = ctx.ghost().reserve(address(ctx.ghost().quote().to_token()));
        uint256 postBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().quote().to_token()));

        assertEq(postBal, preBal + amount, "fund-delta-quote-balance");
        assertEq(postRes, preRes + amount, "fund-delta-quote-reserve");
    }

    function callSummary() external view {
        console.log("deposit", calls["deposit"]);
        console.log("fund-asset", calls["fund-asset"]);
        console.log("fund-quote", calls["fund-quote"]);
    }
}
