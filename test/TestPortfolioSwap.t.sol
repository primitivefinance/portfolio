// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioSwap is Setup {
    using AssemblyLib for uint256;
    using RMM01Lib for PortfolioPool;
    using FixedPointMathLib for uint256;

    function test_swap_increases_user_balance_token_out()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
        isArmed
    {
        // Estimate amount out.
        bool sellAsset = true;
        uint128 amtIn = 0.1 ether;
        uint128 amtOut = uint128(
            subject().getAmountOut(
                ghost().poolId, sellAsset, amtIn, address(this)
            )
        );

        uint256 prev = ghost().quote().to_token().balanceOf(actor());
        subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                amtIn,
                amtOut,
                uint8(sellAsset ? 1 : 0)
            )
        );
        uint256 post = ghost().quote().to_token().balanceOf(actor());

        assertTrue(post > prev, "balance-did-not-increase");
    }

    function test_swap_after_time_passed()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
        isArmed
    {
        bool sellAsset = true;
        uint128 amtIn = 0.1 ether;
        uint128 amtOut = uint128(
            subject().getAmountOut(ghost().poolId, sellAsset, amtIn, actor())
        );

        uint256 prev = ghost().quote().to_token().balanceOf(actor());

        vm.warp(
            block.timestamp
                + (uint256(ghost().pool().params.duration) / 2 * 60 * 60 * 24)
        );
        subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                amtIn,
                amtOut,
                uint8(sellAsset ? 1 : 0)
            )
        );
        uint256 post = ghost().quote().to_token().balanceOf(actor());

        assertTrue(post > prev, "physical-balance-did-not-increase");
    }

    function test_swap_protocol_fee()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
        isArmed
    {
        // Set fee
        SimpleRegistry(subjects().registry).setFee(address(subject()), 5);

        // Do swap
        bool sellAsset = true;
        uint128 amtIn = 0.1 ether;
        uint128 amtOut = uint128(
            subject().getAmountOut(
                ghost().poolId, sellAsset, amtIn, address(this)
            )
        );

        subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                amtIn,
                amtOut,
                uint8(sellAsset ? 1 : 0)
            )
        );

        uint256 preBal = ghost().asset().to_token().balanceOf(address(this));
        SimpleRegistry(subjects().registry).claimFee(
            address(subject()),
            ghost().asset().to_addr(),
            type(uint256).max,
            address(this)
        );
        uint256 postBal = ghost().asset().to_token().balanceOf(address(this));
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
        isArmed
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
        isArmed
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
        (uint256 prevXPerL, uint256 prevYPerL) = pool.getVirtualReservesWad();

        // Pre-invariant check will round the output token reserve up when computing
        // how much is in the reserve per liquidity.
        if (sellAsset) {
            prevXPerL = prevXPerL.divWadDown(pool.liquidity);
            prevYPerL = prevYPerL.divWadUp(pool.liquidity);
        } else {
            prevXPerL = prevXPerL.divWadUp(pool.liquidity);
            prevYPerL = prevYPerL.divWadDown(pool.liquidity);
        }

        try subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                amountIn,
                amountOut,
                uint8(sellAsset ? 1 : 0)
            )
        ) {
            pool = ghost().pool();

            (uint256 postXPerL, uint256 postYPerL) =
                pool.getVirtualReservesWad();
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
}
