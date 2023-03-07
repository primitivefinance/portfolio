// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";
import "../contracts/libraries/AssemblyLib.sol";

//import "solmate/utils/SafeCast.sol";

contract TestPortfolioClaim is Setup {
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;

    function test_revert_claim_no_position() public defaultConfig useActor isArmed {
        vm.expectRevert(abi.encodeWithSelector(NonExistentPosition.selector, actor(), ghost().poolId));
        subject().multiprocess(FVMLib.encodeClaim(ghost().poolId, 0, 0));
    }

    function test_claim_position_owed_amounts_returns_zero()
        public
        defaultConfig
        usePairTokens(10 ether)
        allocateSome(1 ether)
        swapSome(0.1 ether, true)
        useActor
        isArmed
    {
        PortfolioPosition memory pos = ghost().position(actor());
        PortfolioPool memory pool = ghost().pool();
        uint128 tokensOwed = AssemblyLib.computeCheckpointDistance(pool.feeGrowthGlobalAsset, pos.feeGrowthAssetLast)
            .mulWadDown(pool.liquidity).safeCastTo128();

        uint256 pre = ghost().balance(actor(), ghost().asset().to_addr());
        subject().multiprocess(FVMLib.encodeClaim(ghost().poolId, tokensOwed, 0));
        uint256 post = ghost().balance(actor(), ghost().asset().to_addr());

        pos = ghost().position(actor());

        assertEq(post, pre + tokensOwed, "delta");
        assertEq(post, tokensOwed, "claimed-bal");
        assertEq(pos.tokensOwedAsset, 0, "zero-claim");
    }

    function test_claim_get_balance_returns_fee_amount_asset()
        public
        defaultConfig
        usePairTokens(10 ether)
        allocateSome(1 ether)
        swapSome(0.1 ether, true)
        useActor
        isArmed
    {
        PortfolioPosition memory pos = ghost().position(actor());
        PortfolioPool memory pool = ghost().pool();
        uint128 tokensOwed = AssemblyLib.computeCheckpointDistance(pool.feeGrowthGlobalAsset, pos.feeGrowthAssetLast)
            .mulWadDown(pool.liquidity).safeCastTo128();

        subject().multiprocess(FVMLib.encodeClaim(ghost().poolId, tokensOwed, 0));
        uint256 post = ghost().balance(actor(), ghost().asset().to_addr());
        assertEq(post, tokensOwed, "claimed-bal");
    }

    function test_claim_get_balance_returns_fee_amount_quote()
        public
        defaultConfig
        usePairTokens(10 ether)
        allocateSome(1 ether)
        swapSome(0.1 ether, false)
        useActor
        isArmed
    {
        // Has asset tokens owed

        PortfolioPosition memory pos = ghost().position(actor());
        PortfolioPool memory pool = ghost().pool();
        uint128 tokensOwed = AssemblyLib.computeCheckpointDistance(pool.feeGrowthGlobalQuote, pos.feeGrowthQuoteLast)
            .mulWadDown(pool.liquidity).safeCastTo128();

        subject().multiprocess(FVMLib.encodeClaim(ghost().poolId, 0, tokensOwed));
        uint256 post = ghost().balance(actor(), ghost().quote().to_addr());
        assertEq(post, tokensOwed, "claimed-bal");
    }

    function test_claim_credits_balance_asset()
        public
        noJit // no jit so we can remove liquidity without vm.warp
        defaultConfig // default config on non-controlled pool
        useActor
        usePairTokens(10 ether) // mint and approve tokens to default actor()
        allocateSome(1 ether) // allocate some liquidity from actor()
        swapSomeGetOut(0.1 ether, -int256(10), true) // Swapping a little less than optimal amount to trigger positive
            // invariant growth!
        deallocateSome(1 ether) // remove all liquidity from actor
        isArmed
    {
        // Draw all the tokens from our account.
        subject().draw(ghost().asset().to_addr(), type(uint256).max, actor());
        subject().draw(ghost().quote().to_addr(), type(uint256).max, actor());

        PortfolioPosition memory pos = ghost().position(actor());
        PortfolioPool memory pool = ghost().pool();
        (uint128 fee0, uint128 fee1) = (uint128(pos.tokensOwedAsset), uint128(pos.tokensOwedQuote));
        assertTrue(fee0 > 0, "fee0-zero");
        assertTrue(pool.liquidity == 0, "non-zero-liquidity");

        // Claim
        uint256 prevReserve = ghost().reserve(ghost().asset().to_addr());
        uint256 prevBalance = ghost().balance(actor(), ghost().asset().to_addr());
        subject().multiprocess(FVMLib.encodeClaim(ghost().poolId, fee0, fee1));
        uint256 nextReserve = ghost().reserve(ghost().asset().to_addr());
        uint256 nextBalance = ghost().balance(actor(), ghost().asset().to_addr());

        console.log("post reserve bal", nextReserve);
        console.log("next user bal---", nextBalance);
        console.logInt(int256(nextBalance) - int256(nextReserve));
        assertTrue(nextReserve >= nextBalance, "invalid-virtual-reserve-state");

        // Clear reserves by drawing tokens out again.
        subject().draw(ghost().asset().to_addr(), type(uint256).max, actor());
        subject().draw(ghost().quote().to_addr(), type(uint256).max, actor());

        pos = ghost().position(actor());
        (fee0,) = (uint128(pos.tokensOwedAsset), pos.tokensOwedQuote);
        assertEq(fee0, 0, "unclaimed-fees");

        nextReserve = ghost().reserve(ghost().asset().to_addr());
        // todo: fix. RMM01Lib deviation trick leaves dust, there should be no dust! assertEq(nextReserve, 0,
        // "reserve-not-zero");
        assertTrue(nextBalance > prevBalance, "no fee claimed");
        assertTrue(nextReserve < prevReserve, "no fee removed");
    }

    /// @custom:tob TOB-HYPR-7, Exploit Scenario 1
    function test_claim_small_liquidity_does_not_steal_fees()
        public
        noJit
        defaultConfig
        usePairTokens(10 ether)
        allocateSome(10_000)
        setActor(address(0x4215))
        useActor
        isArmed
    {
        uint256 startLiquidity = 10_000;
        address eve = address(0x4215);
        deal(address(ghost().asset().to_addr()), eve, 10000);
        deal(address(ghost().quote().to_addr()), eve, 100000);
        ghost().asset().to_token().approve(address(subject()), 10000);
        ghost().quote().to_token().approve(address(subject()), 100000);

        // eve provides minimal liquidity to the pool
        subject().multiprocess(FVMLib.encodeAllocate(uint8(0), ghost().poolId, uint128(startLiquidity / 5))); // 20%
            // of pool, eve = 2000, total = 2000 + 10000

        // eve waits for some swaps to happen. basicSwap will sell assets and increment asset fee growth.
        uint128 amountIn = 1500;
        uint128 amountOut = (subject().getAmountOut(ghost().poolId, true, amountIn) - 10).safeCastTo128(); // Subtract
            // small amount to get positive invariant growth (not an optimal trade).
        subject().multiprocess(FVMLib.encodeSwap(uint8(0), ghost().poolId, amountIn, amountOut, uint8(1))); // trade
            // in 1500 * 1% fee = 15 / 12_000 = 0.00125 fee growth per liquidity

        // save the total fee growth for the asset per liquidity.
        PortfolioPool memory pool = ghost().pool();
        // uint256 totalLiquidity = pool.liquidity; // 12_000
        uint256 totalFeeAssetPerLiquidity = pool.feeGrowthGlobalAsset; // 0.00125

        // eve claims earned fees, which should be proportional to her share of the liquidity
        subject().multiprocess(FVMLib.encodeClaim(ghost().poolId, type(uint128).max, type(uint128).max));

        uint256 evesShare = startLiquidity / 5; // 2000
        uint256 evesClaimedFees = ghost().balance(eve, ghost().asset().to_addr()); // 2_000 / 12_000 = ~16% of 0.00125
            // fee growth = 0.0002 in fees

        // check to make sure eve did not receive more than they were entitled to
        assertTrue(evesClaimedFees != 0, "eve-zero-fees");
        assertEq(evesClaimedFees, 2, "unexpected-fees"); // 2_000 * 0.00125 = 2.5, rounded down to integer of 2
        assertEq((evesShare * totalFeeAssetPerLiquidity) / 1 ether, evesClaimedFees, "incorrect-fee");
    }

    function test_claim_succeeds() public noJit defaultConfig usePairTokens(10 ether) useActor isArmed {
        // add a tiny amount of liquidity so we can test easier
        uint128 delLiquidity = 100_000 wei; // with the pool params, asset reserves will be about 300 wei.
        subject().multiprocess(FVMLib.encodeAllocate(uint8(0), ghost().poolId, delLiquidity));

        // swap a small amount so we generate fees
        uint128 amountIn = 10_000 wei; // 1% fees will generate 100 wei of asset fee growth
        uint128 amountOut = (subject().getAmountOut(ghost().poolId, true, amountIn) - 10).safeCastTo128(); // Subtract
            // small amount to get positive invariant growth (not an optimal trade).
        subject().multiprocess(FVMLib.encodeSwap(uint8(0), ghost().poolId, amountIn, amountOut, uint8(1)));

        // withdraw all the liquidity after the swap, to sync fees.
        subject().multiprocess(FVMLib.encodeDeallocate(uint8(0), ghost().poolId, 0x0, delLiquidity));

        // withdraw all internal balances
        uint256 bal0 = ghost().balance(actor(), ghost().asset().to_addr());
        uint256 bal1 = ghost().balance(actor(), ghost().quote().to_addr());
        subject().draw(ghost().asset().to_addr(), bal0, actor());
        subject().draw(ghost().quote().to_addr(), bal1, actor());

        // finally, do the claim and check the differences in reserves
        uint256 prev = ghost().balance(actor(), ghost().asset().to_addr());
        subject().multiprocess(FVMLib.encodeClaim(ghost().poolId, type(uint128).max, type(uint128).max));
        uint256 post = ghost().balance(actor(), ghost().asset().to_addr());

        assertEq(post, (amountIn * 100) / 10_000, "expected-fees-claimed");
        assertTrue(post > prev, "no-asset-fees-claimed");
    }
}
