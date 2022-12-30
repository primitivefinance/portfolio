// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperSwap is TestHyperSetup {
    modifier allocateFirst() {
        __hyperTestingContract__.allocate(defaultScenario.poolId, 1e18);
        _;
    }

    function testSwap_should_succeed() public allocateFirst() {
        __hyperTestingContract__.swap(
            defaultScenario.poolId,
            false,
            10000,
            type(uint256).max
        );
    }

    function testSwap_revert_ZeroInput() public {
        vm.expectRevert(ZeroInput.selector);
        __hyperTestingContract__.swap(
            defaultScenario.poolId,
            true,
            0,
            0
        );
    }

    /*
    function testSwap_revert_NonExistentPool() public {
        vm.expectRevert(NonExistentPool.selector);
        __hyperTestingContract__.swap(
            42,
            true,
            1,
            0
        );
    }
    */
}
