// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {HyperPool, JUST_IN_TIME_LIQUIDITY_POLICY} from "contracts/EnigmaTypes.sol";
import "contracts/Clock.sol" as Clock;
import "./setup/TestHyperSetup.sol";

contract TestHyperAllocate is TestHyperSetup {
    function testAllocateFull() public postTestInvariantChecks {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        assertTrue(pool.lastTimestamp != 0, "pool-created");

        uint256 price = pool.lastPrice;
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId));
        Pair memory pair = getPair(address(__hyperTestingContract__), uint24(defaultScenario.poolId >> 40));

        Epoch memory epoch = getEpoch(address(__hyperTestingContract__), defaultScenario.poolId);
        uint elapsed = epoch.getEpochsPassed(block.timestamp) * 3600; // todo: fix epoch time
        console.log(pool.params.duration);
        console.log(elapsed);
        uint tau = uint32((pool.params.duration - uint16(elapsed))) * 3600 seconds; // seconds
        console.log(tau);
        uint256 theoreticalR2 = Price.computeR2WithPrice(
            price,
            Price.computePriceWithTick(pool.params.maxTick),
            pool.params.volatility,
            tau
        );

        uint delLiquidity = 4_000_000;
        __hyperTestingContract__.allocate(defaultScenario.poolId, delLiquidity);

        uint256 globalR1 = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));
        uint256 globalR2 = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        assertApproxEqAbs(globalR2, (theoreticalR2 * delLiquidity) / 1e18, 1, "asset-reserve-theoretic");
    }

    function testAllocateUseMax() public postTestInvariantChecks {
        uint maxLiquidity = __hyperTestingContract__.getLiquidityMinted(
            defaultScenario.poolId,
            defaultScenario.asset.balanceOf(address(this)),
            defaultScenario.quote.balanceOf(address(this))
        );

        (uint deltaAsset, uint deltaQuote) = __hyperTestingContract__.getAllocateAmounts(
            defaultScenario.poolId,
            maxLiquidity
        );

        __hyperTestingContract__.allocate(defaultScenario.poolId, type(uint256).max);

        assertEq(maxLiquidity, getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity);
        assertEq(deltaAsset, getReserve(address(__hyperTestingContract__), address(defaultScenario.asset)));
        assertEq(deltaQuote, getReserve(address(__hyperTestingContract__), address(defaultScenario.quote)));
    }

    /**
     * note: Found an interesting overflow bug!
     * 170141183460469231731687303715884105728 is equal to 2^127.
     * Values between 2^127 and 2^128 will break allocate, because of the implicit conversion
     * from uint128 to int128 causing an overflow.
     */
    function testFuzzAllocateUnallocateSuccessful(uint128 deltaLiquidity) public postTestInvariantChecks {
        vm.assume(deltaLiquidity != 0);
        vm.assume(deltaLiquidity < (2 ** 126 - 1e36)); // note: if its 2^127, it could still overflow since liquidity is multiplied against token amounts in getAllocateAmounts.
        // TODO: Add use max flag support.
        _assertAllocate(deltaLiquidity);
    }

    /** @dev ALlocates then asserts the invariants. */
    function _assertAllocate(uint128 deltaLiquidity) internal {
        // Preconditions
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        assertTrue(pool.lastTimestamp != 0, "Pool not initialized");
        assertTrue(pool.lastPrice != 0, "Pool not created with a price");

        (uint expectedDeltaAsset, uint expectedDeltaQuote) = __hyperTestingContract__.getAllocateAmounts(
            defaultScenario.poolId,
            deltaLiquidity
        );
        defaultScenario.asset.mint(address(this), expectedDeltaAsset);
        defaultScenario.quote.mint(address(this), expectedDeltaQuote);

        // Execution
        HyperState memory prev = getState();
        (uint deltaAsset, uint deltaQuote) = __hyperTestingContract__.allocate(defaultScenario.poolId, deltaLiquidity);
        HyperState memory post = getState();

        // Postconditions
        {
            assertEq(deltaAsset, expectedDeltaAsset, "pool-delta-asset");
            assertEq(deltaQuote, expectedDeltaQuote, "pool-delta-quote");
            assertEq(post.totalPoolLiquidity, prev.totalPoolLiquidity + deltaLiquidity, "pool-total-liquidity");
            assertTrue(post.totalPoolLiquidity > prev.totalPoolLiquidity, "pool-liquidity-increases");
            assertEq(
                post.callerPositionLiquidity,
                prev.callerPositionLiquidity + deltaLiquidity,
                "position-liquidity-increases"
            );

            assertEq(post.reserveAsset, prev.reserveAsset + expectedDeltaAsset, "reserve-asset");
            assertEq(post.reserveQuote, prev.reserveQuote + expectedDeltaQuote, "reserve-quote");
            assertEq(post.physicalBalanceAsset, prev.physicalBalanceAsset + expectedDeltaAsset, "physical-asset");
            assertEq(post.physicalBalanceQuote, prev.physicalBalanceQuote + expectedDeltaQuote, "physical-quote");

            uint feeDelta0 = post.feeGrowthAssetPosition - prev.feeGrowthAssetPosition;
            uint feeDelta1 = post.feeGrowthAssetPool - prev.feeGrowthAssetPool;
            assertTrue(feeDelta0 == feeDelta1, "asset-growth");

            uint feeDelta2 = post.feeGrowthQuotePosition - prev.feeGrowthQuotePosition;
            uint feeDelta3 = post.feeGrowthQuotePool - prev.feeGrowthQuotePool;
            assertTrue(feeDelta2 == feeDelta3, "quote-growth");
        }

        // Unallocate
        customWarp(block.timestamp + JUST_IN_TIME_LIQUIDITY_POLICY); // TODO: make this public function.
        (uint unallocatedAsset, uint unallocatedQuote) = __hyperTestingContract__.unallocate(
            defaultScenario.poolId,
            deltaLiquidity
        );

        {
            HyperState memory end = getState();
            assertApproxEqAbs(unallocatedAsset, deltaAsset, 1, "unallocate-delta-asset");
            assertApproxEqAbs(unallocatedQuote, deltaQuote, 1, "unallocate-delta-quote");
            assertApproxEqAbs(end.reserveAsset, prev.reserveAsset, 1, "unallocate-reserve-asset");
            assertApproxEqAbs(end.reserveQuote, prev.reserveQuote, 1, "unallocate-reserve-quote");
            assertEq(end.totalPoolLiquidity, prev.totalPoolLiquidity, "unallocate-pool-liquidity");
            assertEq(end.totalPositionLiquidity, prev.totalPositionLiquidity, "unallocate-sum-position-liquidity");
            assertEq(end.callerPositionLiquidity, prev.callerPositionLiquidity, "unallocate-caller-position-liquidity");
        }
    }
}
