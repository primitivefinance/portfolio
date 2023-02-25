// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestHyperUnallocate is Setup {
    function test_unallocate_max() public noJit defaultConfig useActor usePairTokens(10 ether) isArmed {
        uint128 amt = 1 ether;
        subject().multiprocess(EnigmaLib.encodeAllocate(uint8(0), ghost().poolId, 0x0, amt));

        // Unallocating liquidity can round down.
        uint prev = ghost().position(address(this)).freeLiquidity;
        subject().multiprocess(EnigmaLib.encodeUnallocate(uint8(1), ghost().poolId, 0x0, amt));
        uint post = ghost().position(address(this)).freeLiquidity;

        assertApproxEqAbs(post, prev - amt, 1, "liquidity-did-not-decrease");
    }
}
