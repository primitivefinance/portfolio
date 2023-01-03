// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperClaim is TestHyperSetup {
    using FixedPointMathLib for uint;

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

    function testClaimGetBalanceReturnsFeeAmount_reward() public {
        // Rewards only accrue to controlled pools
        createControlledPool();

        TestScenario memory scenario = scenarios[1]; // assumes it was the second one...
        assertTrue(
            keccak256(abi.encodePacked(scenario.label)) == keccak256(abi.encodePacked("Controlled")),
            "not controlled?"
        );

        __weth__.deposit{value: 0.01 ether}();
        __weth__.approve(address(__hyperTestingContract__), type(uint256).max);

        _alloc(scenario.poolId);
        __hyperTestingContract__.stake(scenario.poolId, 1 ether);

        // pass some time for staking
        customWarp(__hyperTestingContract__.timestamp() + 1);

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
    }

    function testClaimCreditsAssetBalance() public postTestInvariantChecks {
        basicAllocate();
        basicSwap(); // swaps __asset__ in, so pays fees in asset.

        HyperPool memory pool = defaultPool();
        uint real0 = _getReserve(hx(), defaultScenario.asset);
        uint real1 = _getReserve(hx(), defaultScenario.quote);
        (uint res0, uint res1) = pool.getVirtualReserves();

        basicUnallocate();
        maxDraw(); // zero balance to ensure we aren't paying ourself.

        HyperPosition memory pos = defaultPosition();
        pool = defaultPool();
        (uint fee0, uint fee1) = (pos.tokensOwedAsset, pos.tokensOwedQuote);
        assertTrue(fee0 > 0, "fee0-zero");
        assertTrue(pool.liquidity == 0, "non-zero-liquidity");

        // Claim
        uint prevReserve = _getReserve(hx(), defaultScenario.asset);
        uint prevBalance = _getBalance(hx(), address(this), defaultScenario.asset);
        __hyperTestingContract__.claim(defaultScenario.poolId, fee0, fee1);
        uint nextBalance = _getBalance(hx(), address(this), defaultScenario.asset);

        maxDraw(); // clear reserve

        uint nextReserve = _getReserve(hx(), defaultScenario.asset);
        assertTrue(nextBalance > prevBalance, "no fee claimed");
        assertTrue(nextReserve < prevReserve, "no fee removed");
    }
}
