// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioAllocate is Setup {
    function test_allocate_modifies_liquidity()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        // Arguments for test.
        uint128 amount = 0.1 ether;
        // Fetch the ghost variables to interact with the target pool.
        uint64 xid = ghost().poolId;
        // Fetch the variable we are changing (pool.liquidity).
        uint256 prev = ghost().pool().liquidity;
        // Trigger the function being tested.
        subject().multiprocess(
            FVMLib.encodeAllocate({
                useMax: uint8(0),
                poolId: xid,
                deltaLiquidity: amount
            })
        );
        // Fetch the variable changed.
        uint256 post = ghost().pool().liquidity;
        // Ghost assertions comparing the actual and expected deltas.
        assertEq(post, prev + amount, "pool.liquidity");
        // Direct assertions of pool state.
        assertEq(
            ghost().pool().liquidity,
            ghost().position(actor()).freeLiquidity,
            "position.freeLiquidity != pool.liquidity"
        );
    }

    function test_allocate_does_not_modify_timestamp()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        uint256 prev = ghost().pool().lastTimestamp;
        subject().multiprocess(
            FVMLib.encodeAllocate({
                useMax: uint8(0),
                poolId: xid,
                deltaLiquidity: amount
            })
        );
        uint256 post = ghost().pool().lastTimestamp;

        assertEq(post, prev, "pool.lastTimestamp");
    }

    function test_allocate_reserves_increase()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        uint256 prev_asset = ghost().reserve(ghost().asset().to_addr());
        uint256 prev_quote = ghost().reserve(ghost().quote().to_addr());
        (uint256 delta0, uint256 delta1) = ghost().pool().getPoolLiquidityDeltas({
            deltaLiquidity: int128(amount)
        });
        subject().multiprocess(
            FVMLib.encodeAllocate({
                useMax: uint8(0),
                poolId: xid,
                deltaLiquidity: amount
            })
        );
        uint256 post_asset = ghost().reserve(ghost().asset().to_addr());
        uint256 post_quote = ghost().reserve(ghost().quote().to_addr());

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
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        uint256 prev_asset = ghost().reserve(ghost().asset().to_addr());
        uint256 prev_quote = ghost().reserve(ghost().quote().to_addr());
        (uint256 delta0, uint256 delta1) = ghost().pool().getPoolLiquidityDeltas({
            deltaLiquidity: int128(amount)
        });
        subject().multiprocess(
            FVMLib.encodeAllocate({
                useMax: uint8(0),
                poolId: xid,
                deltaLiquidity: amount
            })
        );
        uint256 post_asset = ghost().reserve(ghost().asset().to_addr());
        uint256 post_quote = ghost().reserve(ghost().quote().to_addr());

        assertTrue(post_asset != 0, "pool.getReserve(asset) == 0");
        assertTrue(post_quote != 0, "pool.getReserve(quote) == 0");
        assertEq(post_asset, prev_asset + delta0, "pool.getReserve(asset)");
        assertEq(post_quote, prev_quote + delta1, "pool.getReserve(quote)");
    }

    function test_allocate_balances_increase()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        uint256 prev_asset =
            ghost().asset().to_token().balanceOf(address(subject()));
        uint256 prev_quote =
            ghost().quote().to_token().balanceOf(address(subject()));
        (uint256 delta0, uint256 delta1) = ghost().pool().getPoolLiquidityDeltas({
            deltaLiquidity: int128(amount)
        });
        subject().multiprocess(
            FVMLib.encodeAllocate({
                useMax: uint8(0),
                poolId: xid,
                deltaLiquidity: amount
            })
        );
        uint256 post_asset =
            ghost().asset().to_token().balanceOf(address(subject()));
        uint256 post_quote =
            ghost().quote().to_token().balanceOf(address(subject()));

        assertTrue(post_asset != 0, "asset.balanceOf(subject) == 0");
        assertTrue(post_quote != 0, "quote.balanceOf(subject) == 0");
        assertEq(post_asset, prev_asset + delta0, "asset.balanceOf(subject)");
        assertEq(post_quote, prev_quote + delta1, "quote.balanceOf(subject)");
    }

    function test_allocate_non_existent_pool_reverts() public useActor {
        uint64 failureArg = 51;
        vm.expectRevert(
            abi.encodeWithSelector(NonExistentPool.selector, failureArg)
        );
        subject().multiprocess(
            FVMLib.encodeAllocate({
                useMax: uint8(0),
                poolId: failureArg,
                deltaLiquidity: 1 ether
            })
        );
    }

    function test_allocate_zero_liquidity_reverts()
        public
        defaultConfig
        useActor
        isArmed
    {
        uint256 failureArg = 0;
        vm.expectRevert(ZeroLiquidity.selector);
        subject().multiprocess(
            FVMLib.encodeAllocate({
                useMax: uint8(0),
                poolId: ghost().poolId,
                deltaLiquidity: uint128(failureArg)
            })
        );
    }

    function test_allocate_liquidity_overflow_reverts()
        public
        defaultConfig
        useActor
        isArmed
    {
        uint256 failureArg = uint256(type(uint128).max) + 1;
        vm.expectRevert(); // safeCastTo128 reverts with no message, so it's just an "Evm Error".
        subject().multiprocess(
            FVMLib.encodeAllocate({
                useMax: uint8(0),
                poolId: ghost().poolId,
                deltaLiquidity: uint128(failureArg)
            })
        );
    }
}
