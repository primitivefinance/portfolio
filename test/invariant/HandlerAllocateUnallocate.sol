// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./setup/HandlerBase.sol";

struct AccountingState {
    uint256 reserveAsset; // getReserve
    uint256 reserveQuote; // getReserve
    uint256 physicalBalanceAsset; // balanceOf
    uint256 physicalBalanceQuote; // balanceOf
    uint256 totalBalanceAsset; // sum of all balances from getBalance
    uint256 totalBalanceQuote; // sum of all balances from getBalance
    uint256 totalPositionLiquidity; // sum of all position liquidity
    uint256 callerPositionLiquidity; // position.freeLiquidity
    uint256 totalPoolLiquidity; // pool.liquidity
    uint256 feeGrowthAssetPool; // getPool
    uint256 feeGrowthQuotePool; // getPool
    uint256 feeGrowthAssetPosition; // getPosition
    uint256 feeGrowthQuotePosition; // getPosition
}

contract HandlerAllocateUnallocate is HandlerBase {
    function fetchAccountingState() internal view returns (AccountingState memory) {
        HyperPosition memory position = ctx.ghost().position(ctx.actor());
        HyperPool memory pool = ctx.ghost().pool();
        HyperPair memory pair = pool.pair;

        address asset = pair.tokenAsset;
        address quote = pair.tokenQuote;

        AccountingState memory state = AccountingState(
            ctx.ghost().reserve(asset),
            ctx.ghost().reserve(quote),
            ctx.ghost().asset().to_token().balanceOf(address(ctx.subject())),
            ctx.ghost().quote().to_token().balanceOf(address(ctx.subject())),
            ctx.getBalanceSum(asset),
            ctx.getBalanceSum(quote),
            ctx.getPositionsLiquiditySum(),
            position.freeLiquidity,
            pool.liquidity,
            pool.feeGrowthGlobalAsset,
            pool.feeGrowthGlobalQuote,
            position.feeGrowthAssetLast,
            position.feeGrowthQuoteLast
        );

        return state;
    }

    function allocate(uint256 deltaLiquidity, uint256 actorSeed) public createActor useActor(actorSeed) {
        deltaLiquidity = bound(deltaLiquidity, 1, 2 ** 126);

        // Allocate to a random pool.
        // VERY IMPORTANT
        ctx.setGhostPoolId(ctx.getRandomPoolId(actorSeed));

        _assertAllocate(deltaLiquidity);
    }

    // avoid stack too deep
    uint256 expectedDeltaAsset;
    uint256 expectedDeltaQuote;
    bool transferAssetIn;
    bool transferQuoteIn;
    int256 assetCredit;
    int256 quoteCredit;
    uint256 deltaAsset;
    uint256 deltaQuote;
    uint256 userAssetBalance;
    uint256 userQuoteBalance;
    uint256 physicalAssetPayment;
    uint256 physicalQuotePayment;

    AccountingState prev;
    AccountingState post;

    function _assertAllocate(uint256 deltaLiquidity) internal {
        // TODO: cleanup reset of these
        transferAssetIn = true;
        transferQuoteIn = true;

        // Preconditions
        HyperPool memory pool = ctx.ghost().pool();
        uint256 lowerDecimals = pool.pair.decimalsAsset > pool.pair.decimalsQuote
            ? pool.pair.decimalsQuote
            : pool.pair.decimalsAsset;
        uint256 minLiquidity = 10 ** (18 - lowerDecimals);
        vm.assume(deltaLiquidity > minLiquidity);
        assertTrue(pool.lastTimestamp != 0, "Pool not initialized");
        // todo: fix assertTrue(pool.lastPrice != 0, "Pool not created with a price");

        // Amounts of tokens that will be allocated to pool.
        (expectedDeltaAsset, expectedDeltaQuote) = ctx.subject().getLiquidityDeltas(
            ctx.ghost().poolId,
            int128(uint128(deltaLiquidity))
        );

        // If net balance > 0, there are tokens in the contract which are not in a pool or balance.
        // They will be credited to the msg.sender of the next call.
        assetCredit = ctx.subject().getNetBalance(ctx.ghost().asset().to_addr());
        quoteCredit = ctx.subject().getNetBalance(ctx.ghost().quote().to_addr());

        // Net balances should always be positive outside of execution.
        assertTrue(assetCredit >= 0, "negative-net-asset-tokens");
        assertTrue(quoteCredit >= 0, "negative-net-quote-tokens");

        // Internal balance of tokens spendable by user.
        userAssetBalance = ctx.ghost().balance(address(ctx.actor()), ctx.ghost().asset().to_addr());
        userQuoteBalance = ctx.ghost().balance(address(ctx.actor()), ctx.ghost().quote().to_addr());

        // If there is a net balance, user can use it to pay their cost.
        // Total payment the user must make.
        physicalAssetPayment = uint256(assetCredit) > expectedDeltaAsset
            ? 0
            : expectedDeltaAsset - uint256(assetCredit);
        physicalQuotePayment = uint256(quoteCredit) > expectedDeltaQuote
            ? 0
            : expectedDeltaQuote - uint256(quoteCredit);

        physicalAssetPayment = uint256(userAssetBalance) > physicalAssetPayment
            ? 0
            : physicalAssetPayment - uint256(userAssetBalance);
        physicalQuotePayment = uint256(userQuoteBalance) > physicalQuotePayment
            ? 0
            : physicalQuotePayment - uint256(userQuoteBalance);

        // If user can pay for the allocate using their internal balance of tokens, don't need to transfer tokens in.
        // Won't need to transfer in tokens if user payment is zero.
        if (physicalAssetPayment == 0) transferAssetIn = false;
        if (physicalQuotePayment == 0) transferQuoteIn = false;

        // If the user has to pay externally, give them tokens.
        if (transferAssetIn) ctx.ghost().asset().to_token().mint(address(this), physicalAssetPayment);
        if (transferQuoteIn) ctx.ghost().quote().to_token().mint(address(this), physicalQuotePayment);

        // Execution
        prev = fetchAccountingState();
        // todo: fix (deltaAsset, deltaQuote) = ctx.subject().allocate(ctx.ghost().poolId, deltaLiquidity);
        post = fetchAccountingState();

        // Postconditions

        assertEq(deltaAsset, expectedDeltaAsset, "pool-delta-asset");
        assertEq(deltaQuote, expectedDeltaQuote, "pool-delta-quote");
        assertEq(post.totalPoolLiquidity, prev.totalPoolLiquidity + deltaLiquidity, "pool-total-liquidity");
        assertTrue(post.totalPoolLiquidity > prev.totalPoolLiquidity, "pool-liquidity-increases");
        assertEq(
            post.callerPositionLiquidity,
            prev.callerPositionLiquidity + deltaLiquidity,
            "position-liquidity-increases"
        );

        assertEq(post.reserveAsset, prev.reserveAsset + physicalAssetPayment + uint256(assetCredit), "reserve-asset");
        assertEq(post.reserveQuote, prev.reserveQuote + physicalQuotePayment + uint256(quoteCredit), "reserve-quote");
        assertEq(post.physicalBalanceAsset, prev.physicalBalanceAsset + physicalAssetPayment, "physical-asset");
        assertEq(post.physicalBalanceQuote, prev.physicalBalanceQuote + physicalQuotePayment, "physical-quote");

        uint256 feeDelta0 = post.feeGrowthAssetPosition - prev.feeGrowthAssetPosition;
        uint256 feeDelta1 = post.feeGrowthAssetPool - prev.feeGrowthAssetPool;
        assertTrue(feeDelta0 == feeDelta1, "asset-growth");

        uint256 feeDelta2 = post.feeGrowthQuotePosition - prev.feeGrowthQuotePosition;
        uint256 feeDelta3 = post.feeGrowthQuotePool - prev.feeGrowthQuotePool;
        assertTrue(feeDelta2 == feeDelta3, "quote-growth");

        emit FinishedCall("Allocate");

        checkVirtualInvariant();
    }

    event FinishedCall(string);

    function unallocate(uint256 deltaLiquidity, uint256 actorSeed) external createActor useActor(actorSeed) {
        deltaLiquidity = bound(deltaLiquidity, 1, 2 ** 126);

        // Unallocate from a random pool.
        // VERY IMPORTANT
        ctx.setGhostPoolId(ctx.getRandomPoolId(actorSeed));

        _assertUnallocate(deltaLiquidity);
    }

    function _assertUnallocate(uint256 deltaLiquidity) internal {
        // TODO: Add use max flag support.

        // Get some liquidity.
        HyperPosition memory pos = ctx.ghost().position(address(this));
        require(pos.freeLiquidity >= deltaLiquidity, "Not enough liquidity");

        if (pos.freeLiquidity >= deltaLiquidity) {
            // Preconditions
            HyperPool memory pool = ctx.ghost().pool();
            assertTrue(pool.lastTimestamp != 0, "Pool not initialized");
            // todo: fix assertTrue(pool.lastPrice != 0, "Pool not created with a price");

            // Unallocate
            uint256 timestamp = block.timestamp + 4; // todo: fix default jit policy
            vm.warp(timestamp);

            (expectedDeltaAsset, expectedDeltaQuote) = ctx.subject().getLiquidityDeltas(
                ctx.ghost().poolId,
                -int128(uint128(deltaLiquidity))
            );
            prev = fetchAccountingState();
            uint256 unallocatedAsset;
            uint256 unallocatedQuote;
            // todo: fix (uint256 unallocatedAsset, uint256 unallocatedQuote) = ctx.subject().unallocate(ctx.ghost().poolId, deltaLiquidity);
            AccountingState memory end = fetchAccountingState();

            assertEq(unallocatedAsset, expectedDeltaAsset, "asset-delta");
            assertEq(unallocatedQuote, expectedDeltaQuote, "quote-delta");
            assertEq(end.reserveAsset, prev.reserveAsset - unallocatedAsset, "reserve-asset");
            assertEq(end.reserveQuote, prev.reserveQuote - unallocatedQuote, "reserve-quote");
            assertEq(end.totalPoolLiquidity, prev.totalPoolLiquidity - deltaLiquidity, "total-liquidity");
            assertTrue(prev.totalPositionLiquidity >= deltaLiquidity, "total-pos-liq-underflow");
            assertTrue(prev.callerPositionLiquidity >= deltaLiquidity, "caller-pos-liq-underflow");
            assertEq(
                end.totalPositionLiquidity,
                prev.totalPositionLiquidity - deltaLiquidity,
                "total-position-liquidity"
            );
            assertEq(
                end.callerPositionLiquidity,
                prev.callerPositionLiquidity - deltaLiquidity,
                "caller-position-liquidity"
            );
        }
        emit FinishedCall("Unallocate");

        checkVirtualInvariant();
    }

    function checkVirtualInvariant() internal {
        // HyperPool memory pool = ctx.ghost().pool();
        // TODO: Breaks when we call this function on a pool with zero liquidity...
        (uint256 dAsset, uint256 dQuote) = ctx.subject().getReserves(ctx.ghost().poolId);
        emit log("dAsset", dAsset);
        emit log("dQuote", dQuote);

        uint256 bAsset = ctx.ghost().asset().to_token().balanceOf(address(ctx.subject()));
        uint256 bQuote = ctx.ghost().quote().to_token().balanceOf(address(ctx.subject()));

        emit log("bAsset", bAsset);
        emit log("bQuote", bQuote);

        int256 diffAsset = int256(bAsset) - int256(dAsset);
        int256 diffQuote = int256(bQuote) - int256(dQuote);
        emit log("diffAsset", diffAsset);
        emit log("diffQuote", diffQuote);

        assertTrue(bAsset >= dAsset, "invariant-virtual-reserves-asset");
        assertTrue(bQuote >= dQuote, "invariant-virtual-reserves-quote");

        emit FinishedCall("Check Virtual Invariant");
    }

    event log(string, uint256);
    event log(string, int256);
}
