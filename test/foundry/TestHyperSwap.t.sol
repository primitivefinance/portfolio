// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperSwap is TestHyperSetup {
    modifier allocateFirst() {
        __hyperTestingContract__.allocate(defaultScenario.poolId, 1e18);
        _;
    }

    function testSwap_should_succeed() public allocateFirst() {
        (uint output, uint remainder) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            false,
            10000,
            type(uint256).max
        );
    }

    function testSwap_back_and_forth_outputs_less() public allocateFirst() {
        uint256 start = 10000;

        (uint output, ) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            false,
            start,
            type(uint256).max
        );

        (uint finalOutput, ) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            true,
            output,
            type(uint256).max
        );

        assertGt(start, finalOutput);
    }

    function testSwap_revert_PoolExpiredError() public allocateFirst() {
        (
            uint256 lastPrice,
            int24 lastTick,
            uint256 blockTimestamp,
            uint256 liquidity,
            uint256 stakedLiquidity,
            uint256 borrowableLiquidity,
            int256 epochStakedLiquidityDelta,
            address prioritySwapper,
            uint256 priorityPaymentPerSecond,
            uint256 feeGrowthGlobalAsset,
            uint256 feeGrowthGlobalQuote
        ) = __hyperTestingContract__.pools(
            defaultScenario.poolId
        );

        vm.warp(blockTimestamp + __hyperTestingContract__.BUFFER());

        vm.expectRevert(PoolExpiredError.selector);

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
