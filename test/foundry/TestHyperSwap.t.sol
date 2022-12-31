// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperSwap is TestHyperSetup {
    modifier allocateFirst() {
        __hyperTestingContract__.allocate(defaultScenario.poolId, 1e18);
        _;
    }

    function testSwap_should_succeed() public allocateFirst {
        (uint output, uint remainder) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            false,
            10000,
            type(uint128).max
        );
    }

    function testSwap_back_and_forth_outputs_less() public allocateFirst {
        uint256 start = 10000;

        (uint output, ) = __hyperTestingContract__.swap(defaultScenario.poolId, false, start, type(uint128).max);

        (uint finalOutput, ) = __hyperTestingContract__.swap(defaultScenario.poolId, true, output, type(uint128).max);

        assertGt(start, finalOutput);
    }

    function testSwap_revert_PoolExpiredError() public allocateFirst {
        customWarp(
            block.timestamp +
                __hyperTestingContract__.computeTau(defaultScenario.poolId) +
                __hyperTestingContract__.BUFFER() +
                1
        );

        uint timestamp = __hyperTestingContract__.timestamp();
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        Epoch memory epoch = getEpoch(address(__hyperTestingContract__), defaultScenario.poolId);
        uint current = epoch.getEpochsPassed(timestamp);
        uint tau;
        console.log(current, pool.params.duration);
        if (current <= pool.params.duration)
            tau = uint(pool.params.duration - current) * __hyperTestingContract__.EPOCH_INTERVAL(); // expired
        console.log(tau);
        console.log(__hyperTestingContract__.computeTau(defaultScenario.poolId));

        vm.expectRevert(PoolExpiredError.selector);
        __hyperTestingContract__.swap(defaultScenario.poolId, false, 10000, 50);
    }

    function testSwap_revert_ZeroInput() public {
        vm.expectRevert(ZeroInput.selector);
        __hyperTestingContract__.swap(defaultScenario.poolId, true, 0, 0);
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
