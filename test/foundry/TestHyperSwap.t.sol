// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperSwap is TestHyperSetup {
    modifier allocateFirst() {
        allocatePool(address(__hyperTestingContract__), defaultScenario.poolId, 10e19);
        _;
    }

    function testSwap_revert_ZeroInput() public {
        vm.expectRevert(ZeroInput.selector);
        __hyper__.swap(
            defaultScenario.poolId,
            true,
            0,
            0
        );
    }
}
