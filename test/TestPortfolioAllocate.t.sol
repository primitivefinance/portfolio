// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioAllocate is Setup {
    using AssemblyLib for uint256;

    uint256 constant TEST_ALLOCATE_MIN_DURATION = 1;
    uint256 constant TEST_ALLOCATE_MAX_DURATION = 720;

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

        ConfigType memory testConfig = DefaultStrategy.getTestConfig({
            portfolio: address(subject()),
            strikePriceWad: 1 ether,
            volatilityBasisPoints: 100,
            durationSeconds: 100 * 1 days,
            isPerpetual: false,
            priceWad: 1 ether
        });

        data[1] = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                0, // magic pair id to use the nonce, which is the createPairId!
                testConfig.reserveXPerWad,
                testConfig.reserveYPerWad,
                100, // fee
                0, // prior fee
                address(0), // controller
                subject().DEFAULT_STRATEGY(),
                testConfig.strategyArgs
            )
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

        (,, uint128 liquidity,,,,,) = subject().pools(poolId);

        assertEq(liquidity, 1 ether, "liquidity");
    }

    function test_allocate_weth()
        public
        wethConfig
        useActor
        usePairTokens(500 ether)
    {
        vm.deal(actor(), 250 ether);
        subject().allocate{ value: 250 ether }(
            false,
            address(this),
            ghost().poolId,
            1 ether,
            type(uint128).max,
            type(uint128).max
        );
    }

    function test_allocate_recipient_weth()
        public
        wethConfig
        useActor
        usePairTokens(500 ether)
    {
        vm.deal(actor(), 250 ether);
        subject().allocate{ value: 250 ether }(
            false,
            address(0xbeef),
            ghost().poolId,
            1 ether,
            type(uint128).max,
            type(uint128).max
        );

        assertEq(ghost().position(address(this)), 0);
        assertEq(ghost().position(address(0xbeef)), 1 ether - BURNED_LIQUIDITY);
    }

    function test_allocate_recipient_tokens()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
    {
        subject().allocate(
            false,
            address(0xbeef),
            ghost().poolId,
            1 ether,
            type(uint128).max,
            type(uint128).max
        );

        assertEq(ghost().position(address(this)), 0);
        assertEq(ghost().position(address(0xbeef)), 1 ether - BURNED_LIQUIDITY);
    }

    function test_allocate_multicall_modifies_liquidity()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
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

    function test_allocate_modifies_liquidity()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
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
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;
        uint256 prev = ghost().pool().lastTimestamp;
        subject().allocate(
            false,
            address(this),
            xid,
            amount,
            type(uint128).max,
            type(uint128).max
        );

        uint256 post = ghost().pool().lastTimestamp;
        assertEq(post, prev, "pool.lastTimestamp");
    }

    function test_allocate_reserves_increase()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;
        uint256 prev_asset = ghost().reserve(ghost().asset().to_addr());
        uint256 prev_quote = ghost().reserve(ghost().quote().to_addr());
        (uint256 delta0, uint256 delta1) = ghost().pool().getPoolLiquidityDeltas({
            deltaLiquidity: int128(amount)
        });
        subject().allocate(
            false,
            address(this),
            xid,
            amount,
            type(uint128).max,
            type(uint128).max
        );
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
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;
        vm.expectRevert();
        subject().allocate(
            false, address(this), xid, amount, 0, type(uint128).max
        );
    }

    function test_allocate_reverts_when_max_delta_reached()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;
        vm.expectRevert();
        subject().allocate(
            false, address(this), xid, amount, type(uint128).max, 0
        );
    }

    /// todo: This is identical logic, only thing that changed was the config modifier.
    /// A better design might be to make the config modifer take a parameter
    /// that chooses the config?
    function test_allocate_reserves_increase_six_decimals()
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(10 ether)
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        uint256 prev_asset = ghost().reserve(ghost().asset().to_addr());
        uint256 prev_quote = ghost().reserve(ghost().quote().to_addr());
        (uint256 delta0, uint256 delta1) = ghost().pool().getPoolLiquidityDeltas({
            deltaLiquidity: int128(amount)
        });

        subject().allocate(
            false,
            address(this),
            xid,
            amount,
            type(uint128).max,
            type(uint128).max
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

        subject().allocate(
            false,
            address(this),
            xid,
            amount,
            type(uint128).max,
            type(uint128).max
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
            abi.encodeWithSelector(
                Portfolio_NonExistentPool.selector, failureArg
            )
        );

        subject().allocate(
            false,
            address(this),
            failureArg,
            1 ether,
            type(uint128).max,
            type(uint128).max
        );
    }

    function test_allocate_zero_liquidity_reverts()
        public
        defaultConfig
        useActor
    {
        uint256 failureArg = 0;
        vm.expectRevert(Portfolio_ZeroLiquidityAllocate.selector);

        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            uint128(failureArg),
            type(uint128).max,
            type(uint128).max
        );
    }

    function test_allocate_liquidity_overflow_reverts()
        public
        defaultConfig
        useActor
    {
        uint256 failureArg = uint256(type(uint128).max) + 1;
        vm.expectRevert(); // safeCastTo128 reverts with no message, so it's just an "Evm Error".

        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            uint128(failureArg),
            type(uint128).max,
            type(uint128).max
        );
    }

    function test_allocate_fee_on_transfer_token()
        public
        feeOnTokenTransferConfig
        usePairTokens(10 ether)
        useActor
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;
        (uint256 amount0,) =
            subject().getLiquidityDeltas(ghost().poolId, int128(amount));
        uint256 fee0 = amount0 * 1 / 100;
        // uint256 fee1 = amount1 * 1 / 100;

        vm.expectRevert(
            abi.encodeWithSelector(
                Portfolio_Insolvent.selector,
                ghost().asset().to_addr(),
                -int256(fee0)
            )
        );

        subject().allocate(
            false,
            address(this),
            xid,
            amount,
            type(uint128).max,
            type(uint128).max
        );

        int256 net = ghost().net(ghost().asset().to_addr());
        console.logInt(net);
        assertTrue(net >= 0, "Negative net balance for token");
    }

    function testFuzz_allocate_low_decimals_modifies_liquidity(uint64 liquidity)
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY * 1e4))
    {
        vm.assume(liquidity > 1e15);
        _simple_allocate_check_liquidity(liquidity);
    }

    function testFuzz_allocate_duration_modifies_liquidity(
        uint16 duration,
        uint64 liquidity
    )
        public
        durationConfig(
            uint16(
                bound(
                    duration, TEST_ALLOCATE_MIN_DURATION, TEST_ALLOCATE_MAX_DURATION
                )
            )
        )
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
    {
        vm.assume(liquidity > 0);
        _simple_allocate_check_liquidity(liquidity);
    }

    function testFuzz_allocate_low_duration_modifies_liquidity(
        uint16 duration,
        uint64 liquidity
    )
        public
        durationConfig(
            uint16(
                bound(
                    duration,
                    TEST_ALLOCATE_MIN_DURATION,
                    TEST_ALLOCATE_MIN_DURATION + 100
                )
            )
        )
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
    {
        vm.assume(liquidity > 0);
        _simple_allocate_check_liquidity(liquidity);
    }

    function testFuzz_allocate_high_duration_modifies_liquidity(
        uint16 duration,
        uint64 liquidity
    )
        public
        durationConfig(
            uint16(
                bound(
                    duration,
                    TEST_ALLOCATE_MAX_DURATION - 100,
                    TEST_ALLOCATE_MAX_DURATION
                )
            )
        )
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
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

        subject().allocate(
            false,
            address(this),
            xid,
            amount,
            type(uint128).max,
            type(uint128).max
        );

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

    function test_allocate_useMax()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
    {
        uint128 liquidity = 1 ether;

        subject().allocate(
            false,
            actor(),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );

        ConfigType memory testConfig =
            DefaultStrategy.getDefaultTestConfig(address(subject()));

        uint64 poolId = subject().createPool(
            1, // pair id
            testConfig.reserveXPerWad, //x
            testConfig.reserveYPerWad, // y
            30, // fee
            0, // priority fee
            address(0),
            subject().DEFAULT_STRATEGY(),
            testConfig.strategyArgs
        );

        uint128 liq = ghost().position(actor());
        (uint128 deltaAsset, uint128 deltaQuote) =
            subject().getLiquidityDeltas(ghost().poolId, int128(liq));

        uint128 maxLiquidity =
            subject().getMaxLiquidity(ghost().poolId, deltaAsset, deltaQuote);

        uint256 preAssetBalance =
            ghost().asset().to_token().balanceOf(address(actor()));
        uint256 preQuoteBalance =
            ghost().quote().to_token().balanceOf(address(actor()));

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(
            IPortfolioActions.deallocate,
            (true, ghost().poolId, 0, type(uint128).min, type(uint128).min)
        );
        data[1] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                true,
                actor(),
                poolId,
                maxLiquidity,
                type(uint128).max,
                type(uint128).max
            )
        );

        bytes[] memory res = subject().multicall(data);

        (uint256 assetDeallocate, uint256 quoteDeallocate) =
            abi.decode(res[0], (uint256, uint256));

        (uint256 assetAllocate, uint256 quoteAllocate) =
            abi.decode(res[1], (uint256, uint256));

        uint256 postAssetBalance =
            ghost().asset().to_token().balanceOf(address(actor()));

        uint256 postQuoteBalance =
            ghost().quote().to_token().balanceOf(address(actor()));

        assertEq(
            postAssetBalance,
            preAssetBalance + assetDeallocate - assetAllocate,
            "asset balance"
        );
        assertEq(
            postQuoteBalance,
            preQuoteBalance + quoteDeallocate - quoteAllocate,
            "quote balance"
        );
    }
}
