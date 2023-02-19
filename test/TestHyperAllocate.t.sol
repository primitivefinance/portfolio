// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./Setup.sol";

contract TestHyperAllocate is Setup {
    function test_allocate_modifies_liquidity() public defaultConfig useActor usePairTokens(10 ether) isArmed {
        // Arguments for test.
        uint amount = 0.1 ether;
        // Fetch the ghost variables to interact with the target pool.
        uint64 xid = ghost().poolId;
        // Fetch the variable we are changing (pool.liquidity).
        uint prev = ghost().pool().liquidity;
        // Trigger the function being tested.
        subject().allocate({poolId: xid, amount: amount});
        // Fetch the variable changed.
        uint post = ghost().pool().liquidity;
        // Ghost assertions comparing the actual and expected deltas.
        assertEq(post, prev + amount, "pool.liquidity");
        // Direct assertions of pool state.
        assertEq(
            ghost().pool().liquidity,
            ghost().position(actor()).freeLiquidity,
            "position.freeLiquidity != pool.liquidity"
        );
    }

    function test_allocate_does_not_modify_timestamp() public defaultConfig useActor usePairTokens(10 ether) isArmed {
        uint amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        uint prev = ghost().pool().lastTimestamp;
        subject().allocate({poolId: xid, amount: amount});
        uint post = ghost().pool().lastTimestamp;

        assertEq(post, prev, "pool.lastTimestamp");
    }

    function test_allocate_reserves_increase() public defaultConfig useActor usePairTokens(10 ether) isArmed {
        uint amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        uint prev_asset = ghost().reserve(ghost().asset().to_addr());
        uint prev_quote = ghost().reserve(ghost().quote().to_addr());
        (uint delta0, uint delta1) = subject().allocate({poolId: xid, amount: amount});
        uint post_asset = ghost().reserve(ghost().asset().to_addr());
        uint post_quote = ghost().reserve(ghost().quote().to_addr());

        assertTrue(post_asset != 0, "pool.getReserve(asset) == 0");
        assertTrue(post_quote != 0, "pool.getReserve(quote) == 0");
        assertEq(post_asset, prev_asset + delta0, "pool.getReserve(asset)");
        assertEq(post_quote, prev_quote + delta1, "pool.getReserve(quote)");
    }

    /// todo: This is identical logic, only thing that changed was the config modifier.
    /// A better design might be to make the config modifer take a parameter
    /// that chooses the config?
    function test_allocate_reserves_increase_six_decimals()
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        uint amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        uint prev_asset = ghost().reserve(ghost().asset().to_addr());
        uint prev_quote = ghost().reserve(ghost().quote().to_addr());
        (uint delta0, uint delta1) = subject().allocate({poolId: xid, amount: amount});
        uint post_asset = ghost().reserve(ghost().asset().to_addr());
        uint post_quote = ghost().reserve(ghost().quote().to_addr());

        assertTrue(post_asset != 0, "pool.getReserve(asset) == 0");
        assertTrue(post_quote != 0, "pool.getReserve(quote) == 0");
        assertEq(post_asset, prev_asset + delta0, "pool.getReserve(asset)");
        assertEq(post_quote, prev_quote + delta1, "pool.getReserve(quote)");
    }

    function test_allocate_balances_increase() public defaultConfig useActor usePairTokens(10 ether) isArmed {
        uint amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        uint prev_asset = ghost().asset().to_token().balanceOf(address(subject()));
        uint prev_quote = ghost().quote().to_token().balanceOf(address(subject()));
        (uint delta0, uint delta1) = subject().allocate({poolId: xid, amount: amount});
        uint post_asset = ghost().asset().to_token().balanceOf(address(subject()));
        uint post_quote = ghost().quote().to_token().balanceOf(address(subject()));

        assertTrue(post_asset != 0, "asset.balanceOf(subject) == 0");
        assertTrue(post_quote != 0, "quote.balanceOf(subject) == 0");
        assertEq(post_asset, prev_asset + delta0, "asset.balanceOf(subject)");
        assertEq(post_quote, prev_quote + delta1, "quote.balanceOf(subject)");
    }

    function test_allocate_non_existent_pool_reverts() public useActor {
        uint64 failureArg = 51;
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        subject().allocate({poolId: failureArg, amount: 1 ether});
    }

    function test_allocate_zero_liquidity_reverts() public defaultConfig useActor isArmed {
        uint failureArg = 0;
        vm.expectRevert(ZeroLiquidity.selector);
        subject().allocate({poolId: ghost().poolId, amount: failureArg});
    }

    function test_allocate_liquidity_overflow_reverts() public defaultConfig useActor isArmed {
        uint failureArg = uint(type(uint128).max) + 1;
        vm.expectRevert(); // safeCastTo128 reverts with no message, so it's just an "Evm Error".
        subject().allocate({poolId: ghost().poolId, amount: failureArg});
    }
}
