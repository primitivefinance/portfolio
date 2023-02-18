// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestPriceSetup.sol";

contract TestPriceInvariant is TestPriceSetup {
    using RMM01Lib for RMM01Lib.RMM;

    function testInvariantReturnsZeroWithDefaultPool() public {
        int256 actual = cases[0].invariantOf(DEFAULT_QUOTE_RESERVE, DEFAULT_ASSET_RESERVE);
        assertEq(actual, 0);
    }
}
