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
        uint128 amtOut = uint128(subject().getAmountOut(ghost().poolId, sellAsset, amtIn));

        uint256 prev = ghost().balance(address(this), ghost().quote().to_addr());
        subject().multiprocess(
            EnigmaLib.encodeSwap(uint8(0), ghost().poolId, 0x0, amtIn, 0x0, amtOut, uint8(sellAsset ? 1 : 0))
        );
        uint256 post = ghost().balance(address(this), ghost().quote().to_addr());

        assertTrue(post > prev, "balance-did-not-increase");
    }
}
