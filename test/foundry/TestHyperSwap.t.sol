// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/HyperLib.sol" as HyperTypes;
import "./setup/TestHyperSetup.sol";
import "test/helpers/HelperHyperProfiles.sol";

contract TestHyperSwap is TestHyperSetup {
    modifier allocateFirst() {
        __hyperTestingContract__.allocate(defaultScenario.poolId, 10 ether);
        _;
    }

    // todo: fake test
    function testSwap_should_succeed() public allocateFirst {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);

        uint input = DEFAULT_SWAP_INPUT;
        uint expected = DEFAULT_SWAP_OUTPUT; // 6 decimals
        (uint out, ) = pool.getAmountOut(
            getPair(address(__hyperTestingContract__), uint24(defaultScenario.poolId >> 40)),
            true,
            input,
            0
        );

        (uint output, uint remainder) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            true,
            input,
            0 // limit
        );

        assertEq(output, expected, "expected-output");

        (uint amount0, uint amount1) = pool.getAmounts();
        console.log("amounts", amount0, amount1);
        console.log("outputs, actual, expected", output, out);
    }

    function testSwap_back_and_forth_outputs_less() public allocateFirst {
        uint256 start = 10000;

        bool direction = false;
        (uint output, ) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            direction,
            start,
            direction ? 0 : type(uint128).max
        );

        direction = true;
        (uint finalOutput, ) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            direction,
            output,
            direction ? 0 : type(uint128).max
        );

        assertGt(start, finalOutput);
    }

    function testSwap_revert_PoolExpired() public allocateFirst {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        uint end = pool.params.createdAt + Assembly.convertDaysToSeconds(pool.params.duration);
        customWarp(end + 1);
        vm.expectRevert(PoolExpired.selector);
        __hyperTestingContract__.swap(defaultScenario.poolId, false, 10000, type(uint128).max);
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
