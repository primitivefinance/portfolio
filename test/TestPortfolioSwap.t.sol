// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioSwap is Setup {
    using AssemblyLib for uint256;
    using RMM01Lib for PortfolioPool;

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

    function testFuzz_swap_back_and_forth(uint128 amountIn)
        public
        defaultConfig
        useActor
        usePairTokens(1000 ether)
        allocateSome(25 ether)
        isArmed
    {
        bool sellAsset = true;
        vm.assume(amountIn > 100);
        PortfolioPool memory pool = ghost().pool();
        uint256 maxIn = Objective(address(subject())).computeMaxInput(
            ghost().poolId,
            sellAsset,
            sellAsset ? pool.virtualX : pool.virtualY,
            pool.liquidity
        );
        vm.assume(maxIn > amountIn);

        uint128 amountOut = uint128(
            subject().getAmountOut(
                ghost().poolId, sellAsset, uint128(amountIn), actor()
            )
        );
        vm.assume(amountOut > 0);
        subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                amountIn,
                amountOut,
                uint8(sellAsset ? 1 : 0)
            )
        );

        uint256 profits = subject().getAmountOut(
            ghost().poolId, !sellAsset, amountOut, actor()
        );
        console.log("profits", profits);

        try subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                amountOut,
                amountIn + 1,
                uint8(sellAsset ? 0 : 1)
            )
        ) {
            // Fail the test if the swap succeeds.
            assertTrue(false, "swap-back-and-forth-failed");
        } catch (bytes memory) {
            // do nothing if failed
        }
    }

    function testFuzz_swap_check_invariant(uint128 amountIn)
        public
        defaultConfig
        useActor
        usePairTokens(1000 ether)
        allocateSome(25 ether)
        isArmed
    {
        bool sellAsset = true;
        vm.assume(amountIn > 100);
        PortfolioPool memory pool = ghost().pool();
        uint256 maxIn = Objective(address(subject())).computeMaxInput(
            ghost().poolId,
            sellAsset,
            sellAsset ? pool.virtualX : pool.virtualY,
            pool.liquidity
        );
        vm.assume(maxIn > amountIn);

        uint128 amountOut = uint128(
            subject().getAmountOut(
                ghost().poolId, sellAsset, uint128(amountIn), actor()
            )
        );
        vm.assume(amountOut > 0);

        (, int256 prevInvariant) = RMM01Portfolio(payable(address(subject())))
            .checkInvariant(
            ghost().poolId,
            int256(0),
            pool.virtualX,
            pool.virtualY,
            block.timestamp
        );
        subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                amountIn,
                amountOut,
                uint8(sellAsset ? 1 : 0)
            )
        );

        pool = ghost().pool();
        (, int256 invariant) = RMM01Portfolio(payable(address(subject())))
            .checkInvariant(
            ghost().poolId,
            prevInvariant,
            pool.virtualX,
            pool.virtualY,
            block.timestamp
        );

        console.logInt(prevInvariant);
        console.logInt(invariant);
        assertTrue(invariant >= prevInvariant, "invalid invariant condition");
    }

    function test_swap_quote_in()
        public
        stablecoinPortfolioConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
        isArmed
    {
        PortfolioPool memory pool = ghost().pool();
        (, int256 invariant) = RMM01Portfolio(payable(address(subject())))
            .checkInvariant(
            ghost().poolId,
            int256(0),
            pool.virtualX,
            pool.virtualY,
            block.timestamp
        );

        bool sellAsset = false;
        uint256 amountIn = uint256(1 ether).scaleFromWadDown(
            ghost().quote().to_token().decimals()
        );
        uint256 amountOut =
            subject().getAmountOut(ghost().poolId, sellAsset, amountIn, actor());

        subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                uint128(amountIn),
                uint128(amountOut),
                uint8(sellAsset ? 1 : 0)
            )
        );

        int256 prev = invariant;
        pool = ghost().pool();
        (, invariant) = RMM01Portfolio(payable(address(subject())))
            .checkInvariant(
            ghost().poolId,
            int256(0),
            pool.virtualX,
            pool.virtualY,
            block.timestamp
        );
        console.logInt(invariant);
        int256 post = invariant;
        int256 diff = post - prev;
        console.logInt(diff);

        pool = ghost().pool();
        (uint256 x, uint256 y) = (pool.virtualX, pool.virtualY);

        console.log("X: %s", x);
        console.log("Y: %s", y);
        // Invariant should increase because fees are non-zero.
        assertTrue(invariant > prev, "invariant-did-not-increase");
    }
}
