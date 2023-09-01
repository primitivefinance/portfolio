// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../contracts/PortfolioRegistry.sol";

contract TestPortfolioRegistry is Test {
    PortfolioRegistry public registry;

    function test_controller() public {
        registry = new PortfolioRegistry(address(this));
        assertEq(registry.controller(), address(this));
    }
}
