// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/EnigmaTypes.sol" as HyperTypes;
import "./setup/TestHyperSetup.sol";
import "test/helpers/HelperHyperProfiles.sol";

contract TestHyperSwap is TestHyperSetup {
    modifier allocateFirst() {
        __hyperTestingContract__.allocate(defaultScenario.poolId, 1e18);
        _;
    }

    function testSwap_should_succeed() public allocateFirst {
        uint input = DEFAULT_SWAP_INPUT;
        uint expected = DEFAULT_SWAP_OUTPUT; // 6 decimals
        (uint output, uint remainder) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            false,
            input,
            type(uint128).max // limit
        );

        assertEq(output, expected, "expected-output");
    }

    function testSwap_back_and_forth_outputs_less() public allocateFirst {
        uint256 start = 10000;

        (uint output, ) = __hyperTestingContract__.swap(defaultScenario.poolId, false, start, type(uint128).max);

        (uint finalOutput, ) = __hyperTestingContract__.swap(defaultScenario.poolId, true, output, type(uint128).max);

        assertGt(start, finalOutput);
    }

    function testSwap_revert_PoolExpired() public allocateFirst {
        customWarp(
            block.timestamp + __hyperTestingContract__.computeCurrentTau(defaultScenario.poolId) + HyperTypes.BUFFER + 1
        );

        uint timestamp = __hyperTestingContract__.timestamp();
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        Epoch memory epoch = getEpoch(address(__hyperTestingContract__), defaultScenario.poolId);
        uint current = epoch.getEpochsPassed(timestamp);
        uint tau;
        console.log(current, pool.params.duration);
        if (current <= pool.params.duration) tau = uint(pool.params.duration - current) * EPOCH_INTERVAL; // expired
        console.log(tau);
        console.log(__hyperTestingContract__.computeCurrentTau(defaultScenario.poolId));

        vm.expectRevert(PoolExpired.selector);
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
