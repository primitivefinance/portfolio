// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/utils/SafeCastLib.sol";
import "./Setup.sol";

contract TestPortfolioSwap is Setup {
    using SafeCastLib for uint256;
    using AssemblyLib for uint256;
    using AssemblyLib for uint128;
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for uint128;

    function test_swap_increases_user_balance_token_out()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
    {
        // Estimate amount out.
        bool sellAsset = true;
        uint128 amtIn = 0.1 ether;
        uint128 amtOut = uint128(
            subject().getAmountOut(ghost().poolId, sellAsset, amtIn, actor())
        );

        uint256 prev = ghost().quote().to_token().balanceOf(actor());
        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amtIn,
            output: amtOut,
            sellAsset: sellAsset
        });
        subject().swap(order);
        uint256 post = ghost().quote().to_token().balanceOf(actor());
        assertTrue(post > prev, "balance-did-not-increase");
    }

    function test_swap_after_time_passed()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = true;
        uint128 amtIn = 0.1 ether;
        uint128 amtOut = uint128(
            subject().getAmountOut(ghost().poolId, sellAsset, amtIn, actor())
        );

        uint256 prev = ghost().quote().to_token().balanceOf(actor());

        vm.warp(
            block.timestamp + (uint256(ghost().config().durationSeconds) / 2)
        );

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amtIn,
            output: amtOut,
            sellAsset: sellAsset
        });
        subject().swap(order);
        uint256 post = ghost().quote().to_token().balanceOf(actor());
        assertTrue(post > prev, "physical-balance-did-not-increase");
    }

    function test_swap_protocol_fee()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
    {
        // Set fee
        SimpleRegistry(subjects().registry).setFee(address(subject()), 5);

        // Do swap
        bool sellAsset = true;
        uint128 amtIn = 0.1 ether;
        uint128 amtOut = uint128(
            subject().getAmountOut(ghost().poolId, sellAsset, amtIn, actor())
        );

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amtIn,
            output: amtOut,
            sellAsset: sellAsset
        });
        subject().swap(order);

        uint256 preBal =
            ghost().asset().to_token().balanceOf(subjects().registry);
        SimpleRegistry(subjects().registry).claimFee(
            address(subject()), ghost().asset().to_addr(), type(uint256).max
        );
        uint256 postBal =
            ghost().asset().to_token().balanceOf(subjects().registry);
        assertTrue(postBal > preBal, "nothing claimed");
    }

    function testFuzz_swap_virtual_reserves_do_not_stay_the_same(
        bool sellAsset,
        uint128 amountIn,
        uint128 amountOut
    )
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
    {
        vm.assume(amountIn > 0);
        vm.assume(amountOut > 0);
        _swap_check_virtual_reserves(sellAsset, amountIn, amountOut);
    }

    function testFuzz_swap_virtual_reserves_do_not_stay_the_same_low_decimals(
        bool sellAsset,
        uint128 amountIn,
        uint128 amountOut
    )
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
    {
        vm.assume(amountIn > 0);
        vm.assume(amountOut > 0);
        _swap_check_virtual_reserves(sellAsset, amountIn, amountOut);
    }

    // todo: update this test to coerce the amount out so it will be a valid trade.
    // once the bisection update is merged in, getAmountOut can be used more reliably.
    function _swap_check_virtual_reserves(
        bool sellAsset,
        uint128 amountIn,
        uint128 amountOut
    ) internal {
        PortfolioPool memory pool = ghost().pool();
        (uint256 prevXPerL, uint256 prevYPerL) = (pool.virtualX, pool.virtualY);

        // Pre-invariant check will round the output token reserve up when computing
        // how much is in the reserve per liquidity.
        if (sellAsset) {
            prevXPerL = prevXPerL.divWadDown(pool.liquidity);
            prevYPerL = prevYPerL.divWadUp(pool.liquidity);
        } else {
            prevXPerL = prevXPerL.divWadUp(pool.liquidity);
            prevYPerL = prevYPerL.divWadDown(pool.liquidity);
        }

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amountIn,
            output: amountOut,
            sellAsset: sellAsset
        });
        try subject().swap(order) {
            pool = ghost().pool();

            (uint256 postXPerL, uint256 postYPerL) =
                (pool.virtualX, pool.virtualY);
            postXPerL = postXPerL.divWadDown(pool.liquidity);
            postYPerL = postYPerL.divWadDown(pool.liquidity);

            console.log("prevXPerL", prevXPerL);
            console.log("postXPerL", postXPerL);
            console.log("prevYPerL", prevYPerL);
            console.log("postYPerL", postYPerL);

            assertTrue(postXPerL != prevXPerL, "invariant-x-unchanged");
            assertTrue(postYPerL != prevYPerL, "invariant-y-unchanged");
        } catch {
            // Swap failed, so don't do anything.
        }
    }

    function testFuzz_swap_low_decimals(
        uint256 seed,
        uint128 amountIn
    )
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = seed % 2 == 0;
        _fuzz_swap(sellAsset, amountIn);
    }

    function testFuzz_swap_durationConfig(
        uint256 seed,
        uint128 amountIn
    )
        public
        fuzzConfig("durationSeconds", seed)
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = seed % 2 == 0;
        _fuzz_swap(sellAsset, amountIn);
    }

    function testFuzz_swap_volatilityConfig(
        uint256 seed,
        uint128 amountIn
    )
        public
        fuzzConfig("volatilityBasisPoints", seed)
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = seed % 2 == 0;
        _fuzz_swap(sellAsset, amountIn);
    }

    function testFuzz_swap_random_inputs(
        uint256 seed,
        uint64 amountIn,
        uint64 amountOut
    )
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        _fuzz_random_args(seed % 2 == 0, amountIn, amountOut);
    }

    function testFuzz_swap_random_small_inputs(
        uint256 seed,
        uint64 amountIn,
        uint64 amountOut
    )
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        amountIn = bound(amountIn, 1, 1000).safeCastTo64();
        amountOut = bound(amountOut, 1, 1000).safeCastTo64();
        _fuzz_random_args(seed % 2 == 0, amountIn, amountOut);
    }

    function testFuzz_swap_random_large_inputs(
        uint256 seed,
        uint128 amountIn,
        uint128 amountOut
    )
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        amountIn = bound(amountIn, type(uint128).max - 1e18, type(uint128).max)
            .safeCastTo128();
        amountOut = bound(
            amountOut, type(uint128).max - 1e18, type(uint128).max
        ).safeCastTo128();
        _fuzz_random_args(seed % 2 == 0, amountIn, amountOut);
    }

    function _fuzz_random_args(
        bool sellAsset,
        uint256 amountIn,
        uint256 amountOut
    ) internal {
        PortfolioPool memory pool = ghost().pool();

        // todo: do getSwapInvariants
        int256 prevInvariant = subject().getInvariant(ghost().poolId);

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amountIn.safeCastTo128(),
            output: amountOut.safeCastTo128(),
            sellAsset: sellAsset
        });

        try subject().swap(order) {
            pool = ghost().pool();

            int256 invariant = subject().getInvariant(ghost().poolId);
            // assertTrue(invariant >= 0, "invariant-negative"); todo: review if we need this?
            assertTrue(invariant >= prevInvariant, "invariant-decreased");
        } catch { }
    }

    function _fuzz_swap(bool sellAsset, uint128 amountIn) internal {
        vm.assume(amountIn > 100);

        uint256 reserveIn;

        PortfolioPool memory pool = ghost().pool();
        PortfolioPair memory pair = ghost().pair();
        if (sellAsset) {
            reserveIn = pool.virtualX;
        } else {
            reserveIn = pool.virtualY;
        }
        {
            Order memory maxOrder =
                subject().getMaxOrder(ghost().poolId, sellAsset, actor());
            uint256 maxAmountIn = maxOrder.input;

            uint256 decimalsIn =
                sellAsset ? pair.decimalsAsset : pair.decimalsQuote;

            // uint256 decimalsOut = sellAsset ? pair.decimalsQuote : pair.decimalsAsset;

            maxAmountIn = maxAmountIn.scaleFromWadDown(decimalsIn);
            vm.assume(maxAmountIn > amountIn);
        }

        uint128 amountOut = subject().getAmountOut(
            ghost().poolId, sellAsset, amountIn, actor()
        ).safeCastTo128();

        vm.assume(amountOut > 0);

        address tokenIn;
        address tokenOut;
        if (sellAsset) {
            tokenIn = pair.tokenAsset;
            tokenOut = pair.tokenQuote;
        } else {
            tokenIn = pair.tokenQuote;
            tokenOut = pair.tokenAsset;
        }

        uint256 prevPhysicalOut =
            IERC20(tokenOut).balanceOf(address(ghost().subject));

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amountIn,
            output: amountOut,
            sellAsset: sellAsset
        });
        subject().swap{ value: tokenIn == subject().WETH() ? amountIn : 0 }(
            order
        );

        uint256 postPhysicalOut =
            IERC20(tokenOut).balanceOf(address(ghost().subject));

        assertApproxEqAbs(
            postPhysicalOut,
            prevPhysicalOut - amountOut,
            1,
            "out-physical-not-eq"
        );
    }

    function test_swap_price_decreases()
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = true;
        uint256 amountIn = 0.01 ether;
        uint256 amountOut =
            subject().getAmountOut(ghost().poolId, sellAsset, amountIn, actor());

        (, int256 prev, int256 post) = IStrategy(
            subject().getStrategy(ghost().poolId)
        ).simulateSwap(
            Order({
                useMax: false,
                poolId: ghost().poolId,
                input: amountIn.safeCastTo128(),
                output: amountOut.safeCastTo128(),
                sellAsset: sellAsset
            }),
            block.timestamp,
            actor()
        );

        console.log("ivnariants");
        console.logInt(prev);
        console.logInt(post);

        _swap_assert_price(sellAsset, amountIn, amountOut);
    }

    function test_swap_price_increases()
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = false;
        uint256 amountIn = 0.01 ether;
        uint256 amountOut =
            subject().getAmountOut(ghost().poolId, sellAsset, amountIn, actor());

        _swap_assert_price(sellAsset, amountIn, amountOut);
    }

    function test_swap_price_decreases_low_decimals()
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = true;
        uint256 amountIn = uint256(0.01 ether).scaleFromWadDown(
            ghost().asset().to_token().decimals()
        );
        uint256 amountOut =
            subject().getAmountOut(ghost().poolId, sellAsset, amountIn, actor());

        _swap_assert_price(sellAsset, amountIn, amountOut);
    }

    function test_swap_price_increases_low_decimals()
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = false;
        uint256 amountIn = uint256(0.01 ether).scaleFromWadDown(
            ghost().quote().to_token().decimals()
        );
        uint256 amountOut =
            subject().getAmountOut(ghost().poolId, sellAsset, amountIn, actor());

        _swap_assert_price(sellAsset, amountIn, amountOut);
    }

    function _swap_assert_price(
        bool sellAsset,
        uint256 amountIn,
        uint256 amountOut
    ) internal {
        uint256 prevPrice = subject().getSpotPrice(ghost().poolId);
        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amountIn.safeCastTo128(),
            output: amountOut.safeCastTo128(),
            sellAsset: sellAsset
        });
        subject().swap(order);

        uint256 postPrice = subject().getSpotPrice(ghost().poolId);
        if (sellAsset) {
            assertTrue(postPrice < prevPrice, "price-not-decreased");
        } else {
            assertTrue(postPrice > prevPrice, "price-not-increased");
        }
    }

    function testFuzz_swap_invariant_gte_previous_invariant(
        bool sellAsset,
        uint256 amountIn,
        uint256 amountOut
    )
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(10 ether)
    {
        PortfolioPool memory pool = ghost().pool();
        PortfolioPair memory pair = ghost().pair();

        uint256 reserveXPerL;
        uint256 reserveYPerL;

        if (sellAsset) {
            reserveXPerL = pool.virtualX.divWadDown(pool.liquidity);
            reserveYPerL = pool.virtualY.divWadUp(pool.liquidity);
        } else {
            reserveXPerL = pool.virtualX.divWadUp(pool.liquidity);
            reserveYPerL = pool.virtualY.divWadDown(pool.liquidity);
        }

        {
            // bound the amounts to be within the max amount in and max amount out
            uint256 maxAmountIn =
                subject().getMaxOrder(ghost().poolId, sellAsset, actor()).input;

            amountIn = bound(amountIn, 1, maxAmountIn);
            amountOut = bound(
                amountOut, 1, ((sellAsset ? reserveYPerL : reserveXPerL) - 1)
            );

            amountIn = amountIn.scaleFromWadDown(
                sellAsset ? pair.decimalsAsset : pair.decimalsQuote
            );
            amountOut = amountOut.scaleFromWadDown(
                sellAsset ? pair.decimalsQuote : pair.decimalsAsset
            );

            _swap_check_invariant(sellAsset, amountIn, amountOut);
        }
    }

    function testFuzz_swap_amountIn_invariant_does_not_decrease(
        bool sellAsset,
        uint256 amountIn
    )
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(10 ether)
    {
        vm.assume(amountIn > 100);

        PortfolioPool memory pool = ghost().pool();

        uint256 reserveXPerL;
        uint256 reserveYPerL;

        if (sellAsset) {
            reserveXPerL = pool.virtualX.divWadDown(pool.liquidity);
            reserveYPerL = pool.virtualY.divWadUp(pool.liquidity);
        } else {
            reserveXPerL = pool.virtualX.divWadUp(pool.liquidity);
            reserveYPerL = pool.virtualY.divWadDown(pool.liquidity);
        }

        Order memory maxOrder =
            subject().getMaxOrder(ghost().poolId, sellAsset, actor());

        uint256 maxIn = maxOrder.input;

        vm.assume(maxIn > amountIn);

        uint256 amountOut =
            subject().getAmountOut(ghost().poolId, sellAsset, amountIn, actor());

        _swap_check_invariant(sellAsset, amountIn, amountOut);
    }

    function test_swap_deallocate_before_swap_reverts()
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(10 ether)
    {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(
            IPortfolioActions.deallocate, (false, ghost().poolId, 1 ether, 0, 0)
        );

        uint256 amountOut =
            subject().getAmountOut(ghost().poolId, true, 0.1 ether, actor());

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: 0.1 ether,
            output: uint128(amountOut),
            sellAsset: true
        });

        data[1] = abi.encodeCall(IPortfolioActions.swap, (order));

        // Reverts with an Portfolio_InvalidInvariant error
        vm.expectRevert();
        subject().multicall(data);
    }

    function test_swap_deallocate_before_swap_works()
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(10 ether)
    {
        subject().deallocate(false, ghost().poolId, 1 ether, 0, 0);

        uint256 amountOut =
            subject().getAmountOut(ghost().poolId, true, 0.1 ether, actor());

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: 0.1 ether,
            output: uint128(amountOut),
            sellAsset: true
        });

        subject().swap(order);
    }

    function _swap_check_invariant(
        bool sellAsset,
        uint256 amountIn,
        uint256 amountOut
    ) internal {
        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amountIn.safeCastTo128(),
            output: amountOut.safeCastTo128(),
            sellAsset: sellAsset
        });

        (bool swapSuccess, int256 prev, int256 post) = subject().simulateSwap({
            order: order,
            timestamp: block.timestamp,
            swapper: actor()
        });

        try subject().swap(order) {
            assertTrue(swapSuccess, "simulateSwap-failed but swap succeeded");
            assertTrue(post >= prev, "post-invariant-not-gte-prev");
        } catch {
            // do nothing, since it failed.
            assertTrue(!swapSuccess, "simulateSwap-succeeded but swap failed");
        }
    }

    /// blocked by https://github.com/primitivefinance/portfolio/issues/425
    function test_swap_use_max_from_surplus()
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        bool sellAsset = true;
        uint256 inputAmount = 0.1 ether;

        // transfer tokens directly to use for the input
        ghost().asset().to_token().transfer(address(subject()), inputAmount);

        // Estimate amount out.
        Order memory order = Order({
            useMax: true,
            poolId: ghost().poolId,
            input: 0,
            output: 0,
            sellAsset: sellAsset
        });

        order.output = uint128(
            subject().getAmountOut(
                order.poolId, sellAsset, inputAmount, actor()
            )
        );

        // Do the swap
        uint256 prevAssetBalance = ghost().asset().to_token().balanceOf(actor());
        subject().swap(order);
        uint256 postAssetBalance = ghost().asset().to_token().balanceOf(actor());

        // Asset balance shouldnt change since we used the max from surplus.
        assertEq(postAssetBalance, prevAssetBalance, "asset-balance-changed");
    }

    function test_swap_returns_native_decimals()
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
    {
        // Estimate amount out.
        bool sellAsset = true;
        uint128 amtIn = 0.1 ether;
        uint128 amtOut = uint128(
            subject().getAmountOut(ghost().poolId, sellAsset, amtIn, actor())
        );

        Order memory order = Order({
            useMax: false,
            poolId: ghost().poolId,
            input: amtIn,
            output: amtOut,
            sellAsset: sellAsset
        });
        (uint64 poolId, uint256 input, uint256 output) = subject().swap(order);
        assertEq(poolId, ghost().poolId, "poolId != ghost().poolId");
        assertEq(input, uint256(order.input), "input != order.input");
        assertEq(output, uint256(order.output), "output != order.output");
    }
}
