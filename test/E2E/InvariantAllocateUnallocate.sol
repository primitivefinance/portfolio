// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/InvariantTargetContract.sol";

contract InvariantAllocateUnallocate is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    function allocate(uint deltaLiquidity, uint index) public {
        deltaLiquidity = bound(deltaLiquidity, 1, 2 ** 126);

        // Allocate to a random pool.
        ctx.setPoolId(ctx.getRandomPoolId(index));

        _assertAllocate(deltaLiquidity);
    }

    // avoid stack too deep
    uint expectedDeltaAsset;
    uint expectedDeltaQuote;
    bool transferAssetIn;
    bool transferQuoteIn;
    int netAssetBalance;
    int netQuoteBalance;
    uint deltaAsset;
    uint deltaQuote;
    uint userAssetBalance;
    uint userQuoteBalance;
    uint physicalAssetPayment;
    uint physicalQuotePayment;

    HyperState prev;
    HyperState post;

    function _assertAllocate(uint deltaLiquidity) internal {
        // TODO: cleanup reset of these
        transferAssetIn = true;
        transferQuoteIn = true;

        // Preconditions
        HyperPool memory pool = getPool(address(__hyper__), __poolId__);
        assertTrue(pool.blockTimestamp != 0, "Pool not initialized");
        assertTrue(pool.lastPrice != 0, "Pool not created with a price");

        // Amounts of tokens that will be allocated to pool.
        (expectedDeltaAsset, expectedDeltaQuote) = __hyper__.getAllocateAmounts(__poolId__, deltaLiquidity);

        // If net balance > 0, there are tokens in the contract which are not in a pool or balance.
        // They will be credited to the msg.sender of the next call.
        netAssetBalance = __hyper__.getNetBalance(address(__asset__));
        netQuoteBalance = __hyper__.getNetBalance(address(__quote__));

        // Net balances should always be positive outside of execution.
        assertTrue(netAssetBalance >= 0, "negative-net-asset-tokens");
        assertTrue(netQuoteBalance >= 0, "negative-net-quote-tokens");

        // Internal balance of tokens spendable by user.
        userAssetBalance = getBalance(address(__hyper__), address(this), address(__asset__));
        userQuoteBalance = getBalance(address(__hyper__), address(this), address(__quote__));

        // If there is a net balance, user can use it to pay their cost.
        // Total payment the user must make.
        physicalAssetPayment = uint(netAssetBalance) > expectedDeltaAsset
            ? 0
            : expectedDeltaAsset - uint(netAssetBalance);
        physicalQuotePayment = uint(netQuoteBalance) > expectedDeltaQuote
            ? 0
            : expectedDeltaQuote - uint(netQuoteBalance);

        // If user can pay for the allocate using their internal balance of tokens, don't need to transfer tokens in.
        // Won't need to transfer in tokens if user payment is zero.
        if (userAssetBalance >= physicalAssetPayment) transferAssetIn = false;
        if (userQuoteBalance >= physicalQuotePayment) transferQuoteIn = false;

        // If the user has to pay externally, give them tokens.
        if (transferAssetIn) __asset__.mint(address(this), physicalAssetPayment);
        if (transferQuoteIn) __quote__.mint(address(this), physicalQuotePayment);

        // Execution
        prev = getState();
        (deltaAsset, deltaQuote) = __hyper__.allocate(__poolId__, deltaLiquidity);
        post = getState();

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

        assertEq(post.reserveAsset, prev.reserveAsset + expectedDeltaAsset, "reserve-asset");
        assertEq(post.reserveQuote, prev.reserveQuote + expectedDeltaQuote, "reserve-quote");
        assertEq(post.physicalBalanceAsset, prev.physicalBalanceAsset + physicalAssetPayment, "physical-asset");
        assertEq(post.physicalBalanceQuote, prev.physicalBalanceQuote + physicalQuotePayment, "physical-quote");

        uint feeDelta0 = post.feeGrowthAssetPosition - prev.feeGrowthAssetPosition;
        uint feeDelta1 = post.feeGrowthAssetPool - prev.feeGrowthAssetPool;
        assertTrue(feeDelta0 == feeDelta1, "asset-growth");

        uint feeDelta2 = post.feeGrowthQuotePosition - prev.feeGrowthQuotePosition;
        uint feeDelta3 = post.feeGrowthQuotePool - prev.feeGrowthQuotePool;
        assertTrue(feeDelta2 == feeDelta3, "quote-growth");

        emit FinishedCall("Allocate");

        checkVirtualInvariant();
    }

    event FinishedCall(string);

    function unallocate(uint deltaLiquidity, uint index) external {
        deltaLiquidity = bound(deltaLiquidity, 1, 2 ** 126);

        // Unallocate from a random pool.
        ctx.setPoolId(ctx.getRandomPoolId(index));

        _assertUnallocate(deltaLiquidity);
    }

    function _assertUnallocate(uint deltaLiquidity) internal {
        // TODO: Add use max flag support.

        // Get some liquidity.
        HyperPosition memory pos = getPosition(address(__hyper__), address(this), __poolId__);
        require(pos.totalLiquidity >= deltaLiquidity, "Not enough liquidity");

        if (pos.totalLiquidity >= deltaLiquidity) {
            // Preconditions
            HyperPool memory pool = getPool(address(__hyper__), __poolId__);
            assertTrue(pool.blockTimestamp != 0, "Pool not initialized");
            assertTrue(pool.lastPrice != 0, "Pool not created with a price");

            // Unallocate
            uint timestamp = block.timestamp + __hyper__.JUST_IN_TIME_LIQUIDITY_POLICY();
            vm.warp(timestamp);
            __hyper__.setTimestamp(uint128(timestamp));

            (expectedDeltaAsset, expectedDeltaQuote) = __hyper__.getUnallocateAmounts(__poolId__, deltaLiquidity);
            prev = getState();
            (uint unallocatedAsset, uint unallocatedQuote) = __hyper__.unallocate(__poolId__, deltaLiquidity);
            HyperState memory end = getState();

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
        (uint dAsset, uint dQuote) = __hyper__.getVirtualReserves(__poolId__);
        emit log("dAsset", dAsset);
        emit log("dQuote", dQuote);

        uint bAsset = getPhysicalBalance(address(__hyper__), address(__asset__));
        uint bQuote = getPhysicalBalance(address(__hyper__), address(__quote__));

        emit log("bAsset", bAsset);
        emit log("bQuote", bQuote);

        int diffAsset = int(bAsset) - int(dAsset);
        int diffQuote = int(bQuote) - int(dQuote);
        emit log("diffAsset", diffAsset);
        emit log("diffQuote", diffQuote);

        assertTrue(bAsset >= dAsset, "invariant-virtual-reserves-asset");
        assertTrue(bQuote >= dQuote, "invariant-virtual-reserves-quote");
    }

    event log(string, uint);
    event log(string, int);
}
