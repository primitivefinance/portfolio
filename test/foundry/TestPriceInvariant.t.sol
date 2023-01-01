// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestPriceSetup.sol";

contract TestPriceInvariant is TestPriceSetup {
    using Price for Price.RMM;

    function testInvariantReturnsZeroWithDefaultPool() public {
        int actual = cases[0].invariant(DEFAULT_QUOTE_RESERVE, DEFAULT_ASSET_RESERVE);
        assertEq(actual, 0);
    }
}
