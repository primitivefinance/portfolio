// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioSwap is Setup {
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
        uint128 amtOut =
            uint128(subject().getAmountOut(ghost().poolId, sellAsset, amtIn));

        uint256 prev = ghost().balance(address(this), ghost().quote().to_addr());
        subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                amtIn,
                amtOut,
                uint8(sellAsset ? 1 : 0)
            )
        );
        uint256 post = ghost().balance(address(this), ghost().quote().to_addr());

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
        uint128 amtOut =
            uint128(subject().getAmountOut(ghost().poolId, sellAsset, amtIn));

        uint256 prev = ghost().balance(address(this), ghost().quote().to_addr());

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
        uint256 post = ghost().balance(address(this), ghost().quote().to_addr());

        assertTrue(post > prev, "balance-did-not-increase");
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
        uint128 amtOut =
            uint128(subject().getAmountOut(ghost().poolId, sellAsset, amtIn));

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

    function test_swap_returned_results()
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
        uint128 amtOut =
            uint128(subject().getAmountOut(ghost().poolId, sellAsset, amtIn));

        bytes[] memory results = subject().multiprocess(
            FVMLib.encodeSwap(
                uint8(0),
                ghost().poolId,
                amtIn,
                amtOut,
                uint8(sellAsset ? 1 : 0)
            )
        );

        (uint64 poolId, uint256 input, uint256 output) = abi.decode(
            results[0],
            (uint64, uint256, uint256)
        );

        assertEq(poolId, ghost().poolId);
        assertEq(input, amtIn);
        assertEq(output, amtOut);
    }
}
