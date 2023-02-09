// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperUnallocate is TestHyperSetup {
    function testUnallocateUseMax() public postTestInvariantChecks {
        __hyperTestingContract__.allocate(defaultScenario.poolId, 1 ether);

        // uint256 maxLiquidity = getPosition(address(__hyperTestingContract__), msg.sender, defaultScenario.poolId).freeLiquidity;

        __hyperTestingContract__.unallocate(defaultScenario.poolId, type(uint256).max);

        assertEq(0, getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity);
    }
}
