// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioTransient is Setup {
    bytes[] instructions;

    function test_transient_beneficiary()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        address eve = address(5);
        uint128 liquidity = uint128(1 ether);
        instructions.push(FVM.encodeTransient(eve));
        instructions.push(
            FVM.encodeAllocate(uint8(0), ghost().poolId, liquidity)
        );
        subject().multiprocess(FVM.encodeJumpInstruction(instructions));
        assertEq(
            liquidity,
            ghost().position(eve).freeLiquidity,
            "eve does not have the liquidity"
        );
    }
}
