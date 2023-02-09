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
        // HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);

        uint input = DEFAULT_SWAP_INPUT;
        uint expected = DEFAULT_SWAP_OUTPUT; // 6 decimals
        // (uint out, ) = pool.getAmountOut(true, input, 0);

        // (uint a, uint b) = pool.getVirtualReserves();

        (uint output, ) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            true,
            input,
            0 // limit
        );

        assertEq(output, expected, "expected-output");

        // (uint amount0, uint amount1) = pool.getAmounts();
    }

    function testSwap_back_and_forth_outputs_less() public allocateFirst {
        uint256 start = 10000;
        uint limit = 1;

        bool direction = false;
        (uint output, ) = __hyperTestingContract__.swap(defaultScenario.poolId, direction, start, limit);

        direction = true;
        (uint finalOutput, ) = __hyperTestingContract__.swap(defaultScenario.poolId, direction, output, limit);

        assertGt(start, finalOutput);
    }

    function testSwap_revert_PoolExpired() public allocateFirst {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        uint end = pool.params.createdAt + Assembly.convertDaysToSeconds(pool.params.duration);
        vm.warp(end + 1);
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

    // maxInput case
    function testSwap_pays_fee_maxInput() public allocateFirst {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);

        uint maxInput = getMaxSwapAssetInWad(pool);
        uint extra = 1;
        // (uint out, ) = pool.getAmountOut(true, maxInput + extra, 0);

        uint prevFeeGrowthAsset = pool.feeGrowthGlobalAsset;
        (, uint remainder) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            true,
            maxInput + extra,
            0 // limit
        );

        pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        uint postFeeGrowthAsset = pool.feeGrowthGlobalAsset;

        assertEq(remainder, extra, "expected-output");
        assertTrue(postFeeGrowthAsset > prevFeeGrowthAsset, "fee-did-not-increase");
    }

    // not maxInput case
    function testSwap_pays_fee() public allocateFirst {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);

        uint maxInput = getMaxSwapAssetInWad(pool);
        // (uint out, ) = pool.getAmountOut(true, maxInput - 1, 0);

        uint prevFeeGrowthAsset = pool.feeGrowthGlobalAsset;
        (, uint remainder) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            true,
            maxInput - 1,
            0 // limit
        );

        pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        uint postFeeGrowthAsset = pool.feeGrowthGlobalAsset;

        assertEq(remainder, 0, "expected-output");
        assertTrue(postFeeGrowthAsset > prevFeeGrowthAsset, "fee-did-not-increase");
    }

    /// todo: Fix this test! view this plot: `yarn plot --strike 1 --vol 1 --tau 365 --price 1 --epsilon 180 --swapAssetIn 0.1`
    /* function testSwap_small_tau() public allocateFirst {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);

        vm.warp(pool.params.maturity() - 100);

        pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);

        uint maxInput = getMaxSwapAssetInWad(pool);
        (uint out, ) = pool.getAmountOut(true, maxInput - 1, 0);

        uint prevFeeGrowthAsset = pool.feeGrowthGlobalAsset;
        (uint output, uint remainder) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            true,
            maxInput - 1,
            0 // limit
        );

        pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        uint postFeeGrowthAsset = pool.feeGrowthGlobalAsset;

        assertEq(remainder, 0, "expected-output");
        assertTrue(postFeeGrowthAsset > prevFeeGrowthAsset, "fee-did-not-increase");
    } */

    function test_swap_invariant_growth() public {
        __hyperTestingContract__.allocate(_scenario_controlled.poolId, 10 ether);
        HyperPool memory pool = getPool(address(__hyperTestingContract__), _scenario_controlled.poolId);

        uint maxInput = getMaxSwapAssetInWad(pool);
        uint input = (maxInput * 1 ether) / 2 ether; // half of max input.
        (uint out, ) = pool.getPoolAmountOut(true, input, 0);
        out = (out * 9000) / 10000; // 90% of output, so invariant is positive.

        uint prevInvariantGrowth = pool.invariantGrowthGlobal;

        bytes memory data = Enigma.encodeSwap(
            0,
            _scenario_controlled.poolId,
            0x0,
            uint128(input),
            0x0,
            uint128(out),
            0
        );
        (bool success, ) = address(__hyperTestingContract__).call(data);
        assertTrue(success, "swap failed");

        pool = getPool(address(__hyperTestingContract__), _scenario_controlled.poolId);
        uint postInvariantGrowth = pool.invariantGrowthGlobal;

        assertTrue(postInvariantGrowth > prevInvariantGrowth, "invariant-did-not-increase");
    }
}
