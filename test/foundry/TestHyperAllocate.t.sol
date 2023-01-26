// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {HyperPool, JUST_IN_TIME_LIQUIDITY_POLICY, HyperPair} from "contracts/HyperLib.sol";
import "./setup/TestHyperSetup.sol";

struct Amounts {
    uint expectedDelta0;
    uint expectedDelta1;
    uint computedDelta0;
    uint computedDelta1;
    uint prevReserve0;
    uint prevReserve1;
    uint postReserve0;
    uint postReserve1;
}

contract TestHyperAllocate is TestHyperSetup {
    using SafeCastLib for uint;

    Amounts _amounts;

    modifier afterTest() {
        _;
        delete _amounts;
    }

    function testAllocateNonStandardDecimals() public postTestInvariantChecks afterTest {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        assertTrue(pool.lastTimestamp != 0, "pool-created");

        HyperPair memory pair = getPair(address(__hyperTestingContract__), uint24(defaultScenario.poolId >> 40));

        address hyper = address(__hyperTestingContract__);
        uint64 poolId = defaultScenario.poolId;

        uint128 liquidity = DEFAULT_LIQUIDITY;
        (_amounts.computedDelta0, _amounts.computedDelta1) = pool.getAmountsWad(); // one liquidity wad

        (_amounts.expectedDelta0, _amounts.expectedDelta1) = (
            Assembly.scaleFromWadDown(_amounts.computedDelta0, pair.decimalsAsset),
            Assembly.scaleFromWadDown(_amounts.computedDelta1, pair.decimalsQuote)
        );

        (_amounts.prevReserve0, _amounts.prevReserve1) = (
            getReserve(hyper, pair.tokenAsset),
            getReserve(hyper, pair.tokenQuote)
        );

        __hyperTestingContract__.allocate(poolId, liquidity);

        (_amounts.postReserve0, _amounts.postReserve1) = (
            getReserve(hyper, pair.tokenAsset),
            getReserve(hyper, pair.tokenQuote)
        );

        assertEq(_amounts.postReserve0, _amounts.prevReserve0 + _amounts.expectedDelta0, "asset-reserves");
        assertEq(_amounts.postReserve1, _amounts.prevReserve1 + _amounts.expectedDelta1, "quote-reserves");
    }

    function testAllocateFull() public postTestInvariantChecks {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        assertTrue(pool.lastTimestamp != 0, "pool-created");

        uint256 price = pool.lastPrice;
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId));
        HyperPair memory pair = getPair(address(__hyperTestingContract__), uint24(defaultScenario.poolId >> 40));

        uint tau = pool.lastTau(); // seconds

        uint256 theoreticalR2 = Price.getXWithPrice(price, pool.params.maxPrice, pool.params.volatility, tau);

        uint delLiquidity = 4_000_000;
        __hyperTestingContract__.allocate(defaultScenario.poolId, delLiquidity);

        uint256 globalR1 = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));
        uint256 globalR2 = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        assertApproxEqAbs(globalR2, (theoreticalR2 * delLiquidity) / 1e18, 1, "asset-reserve-theoretic");
    }

    function testAllocateUseMax() public postTestInvariantChecks {
        uint assetBalance = defaultScenario.asset.balanceOf(address(this));
        uint quoteBalance = defaultScenario.quote.balanceOf(address(this));
        uint maxLiquidity = __hyperTestingContract__.getMaxLiquidity(
            defaultScenario.poolId,
            assetBalance,
            quoteBalance
        );

        (address asset, address quote) = (address(defaultScenario.asset), address(defaultScenario.quote));

        __hyperTestingContract__.fund(asset, assetBalance);
        __hyperTestingContract__.fund(quote, quoteBalance);

        assetBalance = getBalance(address(__hyperTestingContract__), address(this), asset);
        quoteBalance = getBalance(address(__hyperTestingContract__), address(this), quote);
        maxLiquidity = __hyperTestingContract__.getMaxLiquidity(defaultScenario.poolId, assetBalance, quoteBalance);

        (uint deltaAsset, uint deltaQuote) = __hyperTestingContract__.getLiquidityDeltas(
            defaultScenario.poolId,
            -int128(maxLiquidity.safeCastTo128()) // negative delta rounds output amounts down
        );

        __hyperTestingContract__.allocate(defaultScenario.poolId, type(uint256).max);

        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        assetBalance = getBalance(address(__hyperTestingContract__), address(this), asset);
        quoteBalance = getBalance(address(__hyperTestingContract__), address(this), quote);
        (uint128 reserveAsset, uint128 reserveQuote) = pool.getVirtualReserves();

        assertEq(deltaAsset, reserveAsset, "delta-asset");
        assertEq(deltaQuote, reserveQuote, "delta-quote");
        assertEq(maxLiquidity, pool.liquidity, "delta-liquidity");
        assertEq(
            assetBalance,
            getReserve(address(__hyperTestingContract__), asset) - (deltaAsset + 1), // round up
            "asset-balance"
        );
        assertEq(
            quoteBalance,
            getReserve(address(__hyperTestingContract__), quote) - (deltaQuote + 1), // round up
            "quote-balance"
        );
    }

    /**
     * note: Found an interesting overflow bug!
     * 170141183460469231731687303715884105728 is equal to 2^127.
     * Values between 2^127 and 2^128 will break allocate, because of the implicit conversion
     * from uint128 to int128 causing an overflow.
     */
    function testFuzzAllocateUnallocateSuccessful(uint128 deltaLiquidity) public postTestInvariantChecks {
        vm.assume(deltaLiquidity != 0);
        vm.assume(deltaLiquidity < (2 ** 126 - 1e36)); // note: if its 2^127, it could still overflow since liquidity is multiplied against token amounts in getLiquidityDeltas.
        // TODO: Add use max flag support.
        _assertAllocate(deltaLiquidity);
    }

    function testAllocate_zero_amounts_in_reverts() public postTestInvariantChecks {
        // create a pool wtih two low decimal tokens, so that 1 wei of liquidity will round token amounts to zero.
        address small_decimal_asset = address(new TestERC20("small decimals", "DEC6", 6));

        bytes memory data = createPool(
            small_decimal_asset,
            address(__usdc__),
            address(0),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(DEFAULT_SIGMA),
            uint16(DEFAULT_DURATION_DAYS),
            DEFAULT_JIT,
            DEFAULT_STRIKE,
            DEFAULT_PRICE * 100
        );

        bool success = __revertCatcher__.jumpProcess(data);
        assertTrue(success, "__revertCatcher__ call failed");

        // assumes above pool is not using an existing pair
        uint64 poolId = Enigma.encodePoolId(
            __hyperTestingContract__.getPairNonce(),
            false,
            __hyperTestingContract__.getPoolNonce()
        );

        uint delLiquidity = 1;
        vm.expectRevert(bytes4(keccak256("ZeroAmounts()")));
        __hyperTestingContract__.allocate(poolId, delLiquidity);
    }

    /** @dev ALlocates then asserts the invariants. */
    function _assertAllocate(uint128 deltaLiquidity) internal {
        // Preconditions
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        assertTrue(pool.lastTimestamp != 0, "Pool not initialized");
        assertTrue(pool.lastPrice != 0, "Pool not created with a price");

        (uint expectedDeltaAsset, uint expectedDeltaQuote) = __hyperTestingContract__.getLiquidityDeltas(
            defaultScenario.poolId,
            int128(deltaLiquidity)
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

        // remove all credits, since unallocate will increase this amount.
        __hyperTestingContract__.draw(
            address(defaultScenario.asset),
            __hyperTestingContract__.getBalance(address(this), address(defaultScenario.asset)),
            address(this)
        );
        __hyperTestingContract__.draw(
            address(defaultScenario.quote),
            __hyperTestingContract__.getBalance(address(this), address(defaultScenario.quote)),
            address(this)
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
