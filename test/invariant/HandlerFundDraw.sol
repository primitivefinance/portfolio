// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./setup/HandlerBase.sol";

contract HandlerFundDraw is HandlerBase {
    function name() public view override returns (string memory) {
        return "fund-draw";
    }

    function fund_asset(
        uint256 amount,
        uint256 seed
    ) public countCall("fund-draw") createActor useActor(seed) usePool(seed) {
        amount = bound(amount, 1, 1e36);

        // If net balance > 0, there are tokens in the contract which are not in a pool or balance.
        // They will be credited to the msg.sender of the next call.
        int256 netAssetBalance = ctx.subject().getNetBalance(address(ctx.ghost().asset().to_token()));
        int256 netQuoteBalance = ctx.subject().getNetBalance(address(ctx.ghost().quote().to_token()));
        assertTrue(netAssetBalance >= 0, "negative-net-asset-tokens");
        assertTrue(netQuoteBalance >= 0, "negative-net-quote-tokens");

        vm.prank(ctx.actor());
        ctx.ghost().asset().to_token().approve(address(ctx.subject()), amount);
        deal(address(ctx.ghost().asset().to_token()), ctx.actor(), amount);

        uint256 preRes = ctx.ghost().reserve(address(ctx.ghost().asset().to_token()));
        uint256 preBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().asset().to_token()));
        vm.prank(ctx.actor());
        ctx.subject().fund(address(ctx.ghost().asset().to_token()), amount);
        uint256 postRes = ctx.ghost().reserve(address(ctx.ghost().asset().to_token()));
        uint256 postBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().asset().to_token()));

        assertEq(postBal, preBal + amount + uint256(netAssetBalance), "fund-delta-asset-balance");
        assertEq(postRes, preRes + amount + uint256(netQuoteBalance), "fund-delta-asset-reserve");
    }

    function fund_quote(
        uint256 amount,
        uint256 seed
    ) public countCall("fund-draw") createActor useActor(seed) usePool(seed) {
        amount = bound(amount, 1, 1e36);

        vm.prank(ctx.actor());
        ctx.ghost().quote().to_token().approve(address(ctx.subject()), amount);
        deal(address(ctx.ghost().quote().to_token()), ctx.actor(), amount);

        uint256 preRes = ctx.ghost().reserve(address(ctx.ghost().quote().to_token()));
        uint256 preBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().quote().to_token()));
        vm.prank(ctx.actor());
        ctx.subject().fund(address(ctx.ghost().quote().to_token()), amount);
        uint256 postRes = ctx.ghost().reserve(address(ctx.ghost().quote().to_token()));
        uint256 postBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().quote().to_token()));

        assertEq(postBal, preBal + amount, "fund-delta-quote-balance");
        assertEq(postRes, preRes + amount, "fund-delta-quote-reserve");
    }
}
