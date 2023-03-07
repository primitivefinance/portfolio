// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioDeallocate is Setup {
    function test_deallocate_max() public noJit defaultConfig useActor usePairTokens(10 ether) isArmed {
        uint128 amt = 1 ether;
        subject().multiprocess(FVMLib.encodeAllocate(uint8(0), ghost().poolId, amt));

        // Deallocating liquidity can round down.
        uint256 prev = ghost().position(address(this)).freeLiquidity;
        subject().multiprocess(FVMLib.encodeDeallocate(uint8(1), ghost().poolId, amt));
        uint256 post = ghost().position(address(this)).freeLiquidity;

        assertApproxEqAbs(post, prev - amt, 1, "liquidity-did-not-decrease");
    }
}
