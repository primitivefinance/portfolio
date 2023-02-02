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

    // todo: price moves to 4118355366381035960, but it should be 4118355366381035960 + 3540.
    // https://keisan.casio.com/calculator
    // inputs: K: 10, x: 0.650840964589078473, t: .999336025883107282, v: 1
    // output price: 4.118355305540121976745
    // actual price: 4_118355366381035960
    // actual, non error price: 4_118355366381039500, diff: 3540
    // actaul computed x:          0.6507457154641188644249
    // actual computed x w/ error: 0.6507457154641185463956, diff:
    function testClaimCreditsAssetBalance() public postTestInvariantChecks {
        basicAllocate();

        HyperPool memory pool = defaultPool();
        (uint virtualAsset0, ) = pool.getVirtualReserves();
        basicSwap(); // swaps __asset__ in, so pays fees in asset.
        pool = defaultPool();
        (uint virtualAsset1, ) = pool.getVirtualReserves();
        console.log("diff", virtualAsset0, virtualAsset1);

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
        uint nextReserve = _getReserve(hx(), defaultScenario.asset);
        uint nextBalance = _getBalance(hx(), address(this), defaultScenario.asset);

        console.log("post reserve bal", nextReserve);
        console.log("next user bal---", nextBalance);
        console.logInt(int(nextBalance) - int(nextReserve));
        assertTrue(nextReserve >= nextBalance, "invalid-virtual-reserve-state");

        maxDraw(); // clear reserve

        pos = defaultPosition();
        (fee0, ) = (pos.tokensOwedAsset, pos.tokensOwedQuote);
        assertEq(fee0, 0, "unclaimed-fees");

        nextReserve = _getReserve(hx(), defaultScenario.asset);
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

    function testClaim_succeeds_withdraw() public {
        // create a new 18 decimal pair pool with standard variables.
        address token0 = address(new TestERC20("18A", "18A", 18));
        address token1 = address(new TestERC20("18Q", "18Q", 18));
        vm.label(token0, "asset 18 decimals");
        vm.label(token1, "quote 18 decimals");

        // mint some tokens and do approvals
        deal(token0, address(this), 100 ether);
        deal(token1, address(this), 100 ether);
        TestERC20(token0).approve(address(__hyperTestingContract__), type(uint).max);
        TestERC20(token1).approve(address(__hyperTestingContract__), type(uint).max);

        uint16 duration = uint16(365 days / Assembly.SECONDS_PER_DAY);

        // create the pool
        bytes memory data = createPool({
            token0: token0,
            token1: token1,
            controller: address(0),
            priorityFee: 0,
            fee: 100, // 1% fee
            volatility: 1e4, // 100% volatility
            duration: duration,
            jit: 0, // jit
            maxPrice: 10 ether,
            price: 10 ether
        });
        bool success = __revertCatcher__.jumpProcess(data);
        assertTrue(success, "create-failed");

        // grab the latest poolId
        uint64 poolId = Enigma.encodePoolId(
            __hyperTestingContract__.getPairNonce(),
            false,
            __hyperTestingContract__.getPoolNonce()
        );

        // add a tiny amount of liquidity so we can test easier
        uint delLiquidity = 100_000 wei; // with the pool params, asset reserves will be about 300 wei.
        __hyperTestingContract__.allocate(poolId, delLiquidity);

        // swap a small amount so we generate fees
        uint amountIn = 10_000 wei; // 1% fees will generate 100 wei of asset fee growth
        __hyperTestingContract__.swap(poolId, true, amountIn, 0);

        // withdraw all the liquidity after the swap, to sync fees.
        __hyperTestingContract__.unallocate(poolId, delLiquidity);

        // withdraw all internal balances
        uint bal0 = __hyperTestingContract__.getBalance(address(this), token0);
        uint bal1 = __hyperTestingContract__.getBalance(address(this), token1);
        __hyperTestingContract__.draw(token0, bal0, address(this));
        __hyperTestingContract__.draw(token1, bal1, address(this));

        // finally, do the claim and check the differences in reserves
        uint prev = __hyperTestingContract__.getBalance(address(this), token0);
        __hyperTestingContract__.claim(poolId, type(uint).max, type(uint).max);
        uint post = __hyperTestingContract__.getBalance(address(this), token0);

        assertEq(post, (amountIn * 100) / 10_000, "expected-fees-claimed");
        assertTrue(post > prev, "no-asset-fees-claimed");
    }
}
