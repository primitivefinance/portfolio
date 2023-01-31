// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

/**
 @custom:docs

 Fee Buckets and Claiming
    - Users allocate tokens to pools which issue liquidity represent their proportion of deposit.
    - Users swap against the pool and pay the swap fee. Absolute fees per liquidity unit is tracked in the `feeGrowth` variables.
    - The `liquidity` variable of each pool is the total supply of liquidity.
    - Fee growth is always based on `liquidity`.
 */
contract TestHyperClaim is TestHyperSetup {
    using FixedPointMathLib for uint;
    using Price for Price.RMM;

    function testClaimNoPosition_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(NonExistentPosition.selector, address(this), defaultScenario.poolId));
        __hyperTestingContract__.claim(defaultScenario.poolId, 0, 0);
    }

    function testClaim_successful_PositionOwedAmountsReturnsZero() public {
        basicAllocate();
        basicSwap();

        // Has asset tokens owed

        HyperPosition memory pos = _getPosition(hs(), address(this), defaultScenario.poolId);
        HyperPool memory pool = _getPool(hs(), defaultScenario.poolId);
        uint tokensOwed = Assembly
            .computeCheckpointDistance(pool.feeGrowthGlobalAsset, pos.feeGrowthAssetLast)
            .mulWadDown(pool.liquidity);

        uint pre = _getBalance(hx(), address(this), (defaultScenario.asset));
        __hyperTestingContract__.claim(defaultScenario.poolId, tokensOwed, 0);
        uint post = _getBalance(hx(), address(this), (defaultScenario.asset));

        pos = _getPosition(hs(), address(this), defaultScenario.poolId);

        assertEq(post, pre + tokensOwed, "delta");
        assertEq(post, tokensOwed, "claimed-bal");
        assertEq(pos.tokensOwedAsset, 0, "zero-claim");
    }

    function testClaimGetBalanceReturnsFeeAmount_asset() public {
        basicAllocate();
        basicSwap();

        // Has asset tokens owed

        HyperPosition memory pos = _getPosition(hs(), address(this), defaultScenario.poolId);
        HyperPool memory pool = _getPool(hs(), defaultScenario.poolId);
        uint tokensOwed = Assembly
            .computeCheckpointDistance(pool.feeGrowthGlobalAsset, pos.feeGrowthAssetLast)
            .mulWadDown(pool.liquidity);

        __hyperTestingContract__.claim(defaultScenario.poolId, tokensOwed, 0);
        uint post = _getBalance(hx(), address(this), (defaultScenario.asset));
        assertEq(post, tokensOwed, "claimed-bal");
    }

    function testClaimGetBalanceReturnsFeeAmount_quote() public {
        basicAllocate();
        basicSwapQuoteIn();

        // Has asset tokens owed

        HyperPosition memory pos = _getPosition(hs(), address(this), defaultScenario.poolId);
        HyperPool memory pool = _getPool(hs(), defaultScenario.poolId);
        uint tokensOwed = Assembly
            .computeCheckpointDistance(pool.feeGrowthGlobalQuote, pos.feeGrowthQuoteLast)
            .mulWadDown(pool.liquidity);

        __hyperTestingContract__.claim(defaultScenario.poolId, 0, tokensOwed);
        uint post = _getBalance(hx(), address(this), defaultScenario.quote);
        assertEq(post, tokensOwed, "claimed-bal");
    }

    // todo: fix test once reward fees logic is updated.
    /* function testClaimGetBalanceReturnsFeeAmount_reward() public {
        // Rewards only accrue to controlled pools
        createControlledPool();

        TestScenario memory scenario = _scenario_controlled;
        assertTrue(
            keccak256(abi.encodePacked(scenario.label)) == keccak256(abi.encodePacked("Controlled")),
            "not controlled?"
        );

        __weth__.deposit{value: 0.01 ether}();
        __weth__.approve(address(__hyperTestingContract__), type(uint256).max);

        _alloc(scenario.poolId);
        // todo: removed stake functionality - update reward fee accrual. __hyperTestingContract__.stake(scenario.poolId, 1 ether);

        // pass some time for staking
        vm.warp(block.timestamp + 1);

        _swap(scenario.poolId); // swapping in controlled pool should increment reward token (weth)

        // Has asset tokens owed

        HyperPosition memory pos = _getPosition(hs(), address(this), scenario.poolId);
        HyperPool memory pool = _getPool(hs(), scenario.poolId);
        uint tokensOwed = Assembly
            .computeCheckpointDistance(pool.feeGrowthGlobalReward, pos.feeGrowthRewardLast)
            .mulWadDown(pool.liquidity);

        __hyperTestingContract__.claim(scenario.poolId, 0, 0);
        uint post = getBalance(address(__hyperTestingContract__), address(this), address(__weth__));
        assertEq(post, tokensOwed, "claimed-bal");
    } */

    function testClaimCreditsAssetBalance() public postTestInvariantChecks {
        basicAllocate();
        basicSwap(); // swaps __asset__ in, so pays fees in asset.

        HyperPool memory pool = defaultPool();
        uint real0 = _getReserve(hx(), defaultScenario.asset);
        uint real1 = _getReserve(hx(), defaultScenario.quote);
        (uint res0, uint res1) = pool.getVirtualReserves();
        uint liquidity = pool.liquidity;

        basicUnallocate();
        maxDraw(); // zero balance to ensure we aren't paying ourself.

        HyperPosition memory pos = defaultPosition();
        pool = defaultPool();
        (uint fee0, uint fee1) = (pos.tokensOwedAsset, pos.tokensOwedQuote);
        assertTrue(fee0 > 0, "fee0-zero");
        assertTrue(pool.liquidity == 0, "non-zero-liquidity");

        uint entitledAssetAmount = real0 - fee0;

        Price.RMM memory rmm = pool.getRMM();
        uint adjustedAmt = entitledAssetAmount.divWadDown(liquidity);
        uint expectedPrice = rmm.getPriceWithX(adjustedAmt);

        // Claim
        uint prevReserve = _getReserve(hx(), defaultScenario.asset);
        uint prevBalance = _getBalance(hx(), address(this), defaultScenario.asset);
        __hyperTestingContract__.claim(defaultScenario.poolId, fee0, fee1);
        uint nextBalance = _getBalance(hx(), address(this), defaultScenario.asset);

        maxDraw(); // clear reserve

        pos = defaultPosition();
        (fee0, ) = (pos.tokensOwedAsset, pos.tokensOwedQuote);
        assertEq(fee0, 0, "unclaimed-fees");

        uint nextReserve = _getReserve(hx(), defaultScenario.asset);
        // todo: fix. Price deviation trick leaves dust, there should be no dust! assertEq(nextReserve, 0, "reserve-not-zero");
        assertTrue(nextBalance > prevBalance, "no fee claimed");
        assertTrue(nextReserve < prevReserve, "no fee removed");
    }

    /// @custom:tob TOB-HYPR-7, Exploit Scenario 1
    function testClaim_small_liquidity_does_not_steal_fees() public {
        uint startLiquidity = 10_000;
        __hyperTestingContract__.allocate(_scenario_18_18.poolId, startLiquidity);

        address eve = address(0x4215);
        deal(address(_scenario_18_18.asset), eve, 10000);
        deal(address(_scenario_18_18.quote), eve, 100000);
        vm.prank(eve);
        _scenario_18_18.asset.approve(address(__hyperTestingContract__), 10000);
        vm.prank(eve);
        _scenario_18_18.quote.approve(address(__hyperTestingContract__), 100000);

        // eve provides minimal liquidity to the pool
        vm.prank(eve);
        __hyperTestingContract__.allocate(_scenario_18_18.poolId, startLiquidity / 5); // 20% of pool, eve = 2000, total = 2000 + 10000

        // eve waits for some swaps to happen. basicSwap will sell assets and increment asset fee growth.
        __hyperTestingContract__.swap(_scenario_18_18.poolId, true, 1500, 1); // trade in 1500 * 1% fee = 15 / 12_000 = 0.00125 fee growth per liquidity

        // save the total fee growth for the asset per liquidity.
        HyperPool memory pool = getPool(address(__hyperTestingContract__), _scenario_18_18.poolId);
        uint totalLiquidity = pool.liquidity; // 12_000
        uint totalFeeAssetPerLiquidity = pool.feeGrowthGlobalAsset; // 0.00125

        // eve claims earned fees, which should be proportional to her share of the liquidity
        vm.prank(eve);
        __hyperTestingContract__.claim(_scenario_18_18.poolId, type(uint256).max, type(uint256).max);

        uint evesShare = startLiquidity / 5; // 2000
        uint evesClaimedFees = _getBalance(hx(), eve, _scenario_18_18.asset); // 2_000 / 12_000 = ~16% of 0.00125 fee growth = 0.0002 in fees

        // check to make sure eve did not receive more than they were entitled to
        assertTrue(evesClaimedFees != 0, "eve-zero-fees");
        assertEq(evesClaimedFees, 2, "unexpected-fees"); // 2_000 * 0.00125 = 2.5, rounded down to integer of 2
        assertEq((evesShare * totalFeeAssetPerLiquidity) / 1 ether, evesClaimedFees, "incorrect-fee");
    }
}
