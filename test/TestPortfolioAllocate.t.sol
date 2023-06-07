// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioAllocate is Setup {
    using AssemblyLib for uint256;

    function test_multicall_create_pair_pool_allocate() public useActor {
        MockERC20 tokenA = new MockERC20("TokenA", "AAA", 18);
        MockERC20 tokenB = new MockERC20("TokenB", "BBB", 18);

        tokenA.mint(actor(), 100 ether);
        tokenB.mint(actor(), 100 ether);

        tokenA.approve(address(subject()), type(uint256).max);
        tokenB.approve(address(subject()), type(uint256).max);

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeCall(
            IPortfolioActions.createPair, (address(tokenA), address(tokenB))
        );

        data[1] = abi.encodeCall(
            IPortfolioActions.createPool,
            (0, address(0), 1, 100, 100, 100, 1 ether, 1 ether)
        );

        uint64 poolId = AssemblyLib.encodePoolId(1, false, 1);

        data[2] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                poolId,
                1 ether,
                type(uint128).max,
                type(uint128).max
            )
        );

        subject().multicall(data);

        (,, uint128 liquidity,,,,) = subject().pools(poolId);

        assertEq(liquidity, 1 ether, "liquidity");
    }

    function test_allocate_weth()
        public
        wethConfig
        useActor
        usePairTokens(500 ether)
        isArmed
    {
        vm.deal(actor(), 250 ether);

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                1 ether,
                type(uint128).max,
                type(uint128).max
            )
        );

        subject().multicall{ value: 250 ether }(data);
    }

    function test_allocate_multicall_modifies_liquidity()
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

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                xid,
                amount,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);

        // Fetch the variable changed.
        uint256 post = ghost().pool().liquidity;
        // Ghost assertions comparing the actual and expected deltas.
        assertEq(post, prev + amount, "pool.liquidity");
        // Direct assertions of pool state.
        assertEq(
            ghost().pool().liquidity - BURNED_LIQUIDITY,
            ghost().position(actor()),
            "position != pool.liquidity"
        );
    }

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

        subject().allocate(
            false,
            address(this),
            xid,
            amount,
            type(uint128).max,
            type(uint128).max
        );

        // Fetch the variable changed.
        uint256 post = ghost().pool().liquidity;
        // Ghost assertions comparing the actual and expected deltas.
        assertEq(post, prev + amount, "pool.liquidity");
        // Direct assertions of pool state.
        assertEq(
            ghost().pool().liquidity - BURNED_LIQUIDITY,
            ghost().position(actor()),
            "position != pool.liquidity"
        );
    }

    // todo: Use max now only uses entire transient balances, which need to be increased from a swap output or deallocatye.
    /* function test_allocate_use_max()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        // Deposit tokens which will be used to compute max liquidity.
        subject().fund(ghost().asset().to_addr(), type(uint256).max);
        subject().fund(ghost().quote().to_addr(), type(uint256).max);

        subject().multiprocess(
            FVMLib.encodeAllocateOrDeallocate({
                shouldAllocate: true,
                useMax: uint8(1),
                poolId: ghost().poolId,
                deltaLiquidity: 1,
                deltaQuote: type(uint128).max,
                deltaAsset: type(uint128).max
            })
        );
        assertEq(
            ghost().pool().liquidity,
            ghost().position(actor()).liquidity,
            "position != pool.liquidity"
        );
    } */

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

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                xid,
                amount,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);

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
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                xid,
                amount,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);

        uint256 post_asset = ghost().reserve(ghost().asset().to_addr());
        uint256 post_quote = ghost().reserve(ghost().quote().to_addr());

        assertTrue(post_asset != 0, "pool.getReserve(asset) == 0");
        assertTrue(post_quote != 0, "pool.getReserve(quote) == 0");
        assertEq(post_asset, prev_asset + delta0, "pool.getReserve(asset)");
        assertEq(post_quote, prev_quote + delta1, "pool.getReserve(quote)");
    }

    function test_allocate_reverts_when_max_quote_reached()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        vm.expectRevert();

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (false, address(this), xid, amount, 0, type(uint128).max)
        );
        subject().multicall(instructions);
    }

    function test_allocate_reverts_when_max_delta_reached()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        vm.expectRevert();

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (false, address(this), xid, amount, type(uint128).max, 0)
        );
        subject().multicall(instructions);
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

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                xid,
                amount,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);

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

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                xid,
                amount,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);

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

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                failureArg,
                1 ether,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);
    }

    function test_allocate_zero_liquidity_reverts()
        public
        defaultConfig
        useActor
        isArmed
    {
        uint256 failureArg = 0;
        vm.expectRevert(ZeroLiquidity.selector);

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                uint128(failureArg),
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);
    }

    function test_allocate_liquidity_overflow_reverts()
        public
        defaultConfig
        useActor
        isArmed
    {
        uint256 failureArg = uint256(type(uint128).max) + 1;
        vm.expectRevert(); // safeCastTo128 reverts with no message, so it's just an "Evm Error".

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                uint128(failureArg),
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);
    }

    function test_allocate_fee_on_transfer_token()
        public
        feeOnTokenTransferConfig
        usePairTokens(10 ether)
        useActor
        isArmed
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        (uint256 amount0, uint256 amount1) =
            subject().getLiquidityDeltas(ghost().poolId, int128(amount));
        uint256 fee0 = amount0 * 1 / 100;
        // uint256 fee1 = amount1 * 1 / 100;

        vm.expectRevert(
            abi.encodeWithSelector(
                NegativeBalance.selector,
                ghost().asset().to_addr(),
                -int256(fee0)
            )
        );

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                xid,
                amount,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);

        int256 net = ghost().net(ghost().asset().to_addr());

        console.logInt(net);
        assertTrue(net >= 0, "Negative net balance for token");
    }

    function testFuzz_allocate_low_decimals_modifies_liquidity(uint64 liquidity)
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY * 1e3))
        isArmed
    {
        vm.assume(liquidity > 10 ** (18 - 6));
        _simple_allocate_check_liquidity(liquidity);
    }

    function testFuzz_allocate_duration_modifies_liquidity(
        uint16 duration,
        uint64 liquidity
    )
        public
        durationConfig(uint16(bound(duration, MIN_DURATION, MAX_DURATION)))
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
        isArmed
    {
        vm.assume(liquidity > 0);
        _simple_allocate_check_liquidity(liquidity);
    }

    function testFuzz_allocate_low_duration_modifies_liquidity(
        uint16 duration,
        uint64 liquidity
    )
        public
        durationConfig(uint16(bound(duration, MIN_DURATION, MIN_DURATION + 100)))
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
        isArmed
    {
        vm.assume(liquidity > 0);
        _simple_allocate_check_liquidity(liquidity);
    }

    function testFuzz_allocate_high_duration_modifies_liquidity(
        uint16 duration,
        uint64 liquidity
    )
        public
        durationConfig(uint16(bound(duration, MAX_DURATION - 100, MAX_DURATION)))
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
        isArmed
    {
        vm.assume(liquidity > 0);
        _simple_allocate_check_liquidity(liquidity);
    }

    function testFuzz_allocate_volatility_modifies_liquidity(
        uint16 volatility,
        uint64 liquidity
    )
        public
        volatilityConfig(uint16(bound(volatility, MIN_VOLATILITY, MAX_VOLATILITY)))
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
        isArmed
    {
        vm.assume(liquidity > 0);
        _simple_allocate_check_liquidity(liquidity);
    }

    function testFuzz_allocate_low_volatility_modifies_liquidity(
        uint16 volatility,
        uint64 liquidity
    )
        public
        volatilityConfig(
            uint16(bound(volatility, MIN_VOLATILITY, MIN_VOLATILITY + 100))
        )
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
        isArmed
    {
        vm.assume(liquidity > 0);
        _simple_allocate_check_liquidity(liquidity);
    }

    function testFuzz_allocate_high_volatility_modifies_liquidity(
        uint16 volatility,
        uint64 liquidity
    )
        public
        volatilityConfig(
            uint16(bound(volatility, MIN_VOLATILITY, MIN_VOLATILITY + 100))
        )
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
        isArmed
    {
        vm.assume(liquidity > 0);
        _simple_allocate_check_liquidity(liquidity);
    }

    function _simple_allocate_check_liquidity(uint128 amount) internal {
        uint64 xid = ghost().poolId;
        (uint128 expectedA, uint128 expectedQ) =
            subject().getLiquidityDeltas(ghost().poolId, int128(amount));
        uint256 prev = ghost().pool().liquidity;
        (uint256 prevA, uint256 prevQ) = (
            ghost().asset().to_token().balanceOf(address(subject())),
            ghost().quote().to_token().balanceOf(address(subject()))
        );

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                xid,
                amount,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(instructions);

        uint256 post = ghost().pool().liquidity;
        (uint256 postA, uint256 postQ) = (
            ghost().asset().to_token().balanceOf(address(subject())),
            ghost().quote().to_token().balanceOf(address(subject()))
        );

        (uint256 postR_A, uint256 postR_Q) = (
            ghost().reserve(ghost().asset().to_addr()),
            ghost().reserve(ghost().quote().to_addr())
        );

        // Rounding up the scaled down reserves ensures the physical balances are
        // always greater than or equal to the reserve values for this test.
        // If they round up to a value which is greater than the physical balance,
        // it means the reserves have more than the physical balance, breaking our core
        // invariant which checks the difference of physical to reserve balance always being
        // positive.
        postR_A = postR_A.scaleFromWadUp(ghost().asset().to_token().decimals());
        postR_Q = postR_Q.scaleFromWadUp(ghost().quote().to_token().decimals());

        assertApproxEqAbs(postA, prevA + expectedA, 1, "pool asset balance"); // Can be 1 wei off due to rounding in getLiquidityAmounts.
        assertApproxEqAbs(postQ, prevQ + expectedQ, 1, "pool quote balance"); // Can be 1 wei off due to rounding in getLiquidityAmounts.
        assertEq(postR_A, postA, "pool asset reserve");
        assertEq(postR_Q, postQ, "pool quote reserve");
        assertEq(post, prev + amount, "pool.liquidity");
        assertEq(
            ghost().pool().liquidity - BURNED_LIQUIDITY,
            ghost().position(actor()),
            "position.liquidity != pool.liquidity"
        );
    }
}
