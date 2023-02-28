// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestHyperSwap is Setup {
    function test_swap_increases_user_balance_token_out()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
        isArmed
    {
        // Estimate amount out.
        bool direction = true;
        uint128 amtIn = 0.1 ether;
        uint128 amtOut = uint128(subject().getAmountOut(ghost().poolId, direction, amtIn));

        uint prev = ghost().balance(address(this), ghost().quote().to_addr());
        subject().multiprocess(
            EnigmaLib.encodeSwap(uint8(0), ghost().poolId, 0x0, amtIn, 0x0, amtOut, uint8(direction ? 0 : 1))
        );
        uint post = ghost().balance(address(this), ghost().quote().to_addr());

        assertTrue(post > prev, "balance-did-not-increase");
    }
}
