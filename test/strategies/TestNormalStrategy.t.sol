// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../Setup.sol";

contract TestNormalStrategy is Setup {
    // Needs default config so a pool is deployed so the default strategy is returned by strategy()
    function test_after_create_reverts_not_portfolio() public defaultConfig {
        IStrategy target = strategy();
        vm.expectRevert(NormalStrategy_NotPortfolio.selector);
        target.afterCreate(0, bytes(""));
    }

    // Needs default config so a pool is deployed so the default strategy is returned by strategy()
    function test_before_swap_reverts_not_portfolio() public defaultConfig {
        IStrategy target = strategy();
        vm.expectRevert(NormalStrategy_NotPortfolio.selector);
        target.beforeSwap(0, true, address(0));
    }
}
