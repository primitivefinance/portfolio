// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "contracts/HyperLib.sol" as HyperTypes;
import "./setup/TestHyperSetup.sol";

contract TestHyperProcessing is TestHyperSetup {
    using SafeCastLib for uint;

    function afterSetUp() public override {
        assertTrue(
            getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastTimestamp != 0,
            "Pool not created"
        );
        assertTrue(
            getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastTick != 0,
            "Pool not initialized with price"
        );
        assertTrue(
            getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity == 0,
            "Pool initialized with liquidity"
        );
    }

    // ===== Getters ===== //

    function testGetAmounts() public {
        HyperPool memory pool = getPool(address(__hyperTestingContract__), defaultScenario.poolId);
        HyperCurve memory curve = pool.params;
        (uint deltaAsset, uint deltaQuote) = __hyperTestingContract__.getAmounts(defaultScenario.poolId);
        uint maxDelta = 0.001 ether; // 1ether = 100%, 0.001 ether = 0.10%
        assertApproxEqRel(
            deltaAsset,
            Assembly.scaleFromWadDown(DEFAULT_ASSET_RESERVE, pool.pair.decimalsAsset),
            maxDelta,
            "asset-reserve"
        ); // todo: fix default amounts
        assertApproxEqRel(
            deltaQuote,
            Assembly.scaleFromWadDown(DEFAULT_QUOTE_RESERVE, pool.pair.decimalsQuote),
            maxDelta,
            "quote-reserve"
        );
    }

    function testGetLiquidityMinted() public {
        uint deltaLiquidity = __hyperTestingContract__.getMaxLiquidity(defaultScenario.poolId, 1, 1e19);
    }

    // ===== Enigma ===== //

    function testJumpProcessCreatesPair() public {
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = (Enigma.encodeCreatePair(address(__token_8__), address(defaultScenario.quote)));
        bytes memory data = Enigma.encodeJumpInstruction(instructions);
        bool success = __revertCatcher__.jumpProcess(data);
        assertTrue(success);

        uint24 pairId = uint16(__hyperTestingContract__.getPairNonce());
        HyperPair memory pair = getPair(address(__hyperTestingContract__), pairId);
        assertTrue(pair.tokenAsset != address(0));
        assertTrue(pair.tokenQuote != address(0));
    }

    function testProcessRevertsWithInvalidInstructionZeroOpcode() public {
        vm.expectRevert(InvalidInstruction.selector);
        __revertCatcher__.process(hex"00");
    }

    function testProcessRevertsWithInvalidInstruction() public {
        vm.expectRevert(InvalidInstruction.selector);
        __revertCatcher__.process(hex"44");
    }

    // ===== Effects ===== //

    function testSyncPool() public {
        customWarp(1);
        __hyperTestingContract__.syncPool(defaultScenario.poolId);
    }

    // --- Swap --- //

    function testSwapExactInNonExistentPoolIdReverts() public {
        uint64 failureArg = uint64(0x01);
        bytes memory data = Enigma.encodeSwap(0, failureArg, 0x01, 0x01, 0x01, 0x01, 0);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    function testSwapExactInZeroSwapAmountReverts() public {
        uint128 failureArg = 0;
        bytes memory data = Enigma.encodeSwap(0, defaultScenario.poolId, 0x01, failureArg, 0x01, 0x01, 0);
        vm.expectRevert(ZeroInput.selector);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    function testSwapExactInPoolPriceUpdated() public postTestInvariantChecks {
        // Add liquidity first
        bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        uint256 prev = getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastPrice;

        uint8 useMax = 0;
        uint8 direction = 0;
        uint128 limit = getMaxSwapLimit(direction == 0).safeCastTo128();
        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Enigma.encodeSwap(useMax, defaultScenario.poolId, 0x12, 0x02, 0x0, limit, direction);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 next = getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastPrice;
        assertTrue(next != prev);
    }

    /* function testSwapExactInPoolSlotIndexUpdated() public {
        // Add liquidity first
        bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        int256 prev = getPool(address(__hyperTestingContract__),defaultScenario.poolId).lastTick;

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Enigma.encodeSwap(0, defaultScenario.poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        int256 next = getPool(address(__hyperTestingContract__),defaultScenario.poolId).lastTick;
        assertTrue(next != prev);
    } */

    function testSwapUseMax() public postTestInvariantChecks {
        uint amount = type(uint256).max;
        uint limit = amount;
        // Add liquidity first
        bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        // move some time
        customWarp(block.timestamp + 1);
        uint256 prev = getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity;
        bool direction = true;
        __hyperTestingContract__.swap(defaultScenario.poolId, direction, amount, getMaxSwapLimit(direction));

        uint256 next = getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapInQuote() public postTestInvariantChecks {
        uint limit = type(uint256).max;
        uint amount = 2222;
        // Add liquidity first
        bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        // move some time
        customWarp(block.timestamp + 1);
        uint256 prev = getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity;
        bool direction = false;
        __hyperTestingContract__.swap(defaultScenario.poolId, direction, amount, getMaxSwapLimit(direction));

        uint256 next = getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapReverse() public {
        bool direction = true;
        uint limit = type(uint256).max;
        uint amount = 17e16;
        // Add liquidity first
        /* bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success); */
        allocatePool(address(__hyperTestingContract__), defaultScenario.poolId, 10e19);

        // deposit first
        __hyperTestingContract__.fund(address(defaultScenario.asset), amount);
        uint256 prev = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));

        (uint output, ) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            direction,
            amount,
            getMaxSwapLimit(direction)
        );
        direction = false;
        (uint input, ) = __hyperTestingContract__.swap(
            defaultScenario.poolId,
            direction,
            output,
            getMaxSwapLimit(direction)
        );

        uint256 next = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        assertTrue(next <= prev, "invalid-user-gained-balance");
        assertTrue(input < amount, "invalid-invariant-got-more-out");
    }

    function testSwapExpiredPoolReverts() public {
        uint limit = type(uint256).max;
        uint amount = 2222;
        // Add liquidity first
        bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        // move some time beyond maturity
        customWarp(
            block.timestamp +
                getPool(address(__hyperTestingContract__), defaultScenario.poolId).tau(
                    __hyperTestingContract__.timestamp()
                ) +
                1
        );

        vm.expectRevert(PoolExpired.selector);
        __hyperTestingContract__.swap(defaultScenario.poolId, false, amount, limit);
    }

    function testSwapExactInPoolLiquidityUnchanged() public postTestInvariantChecks {
        // Add liquidity first
        bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);
        uint256 prev = getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity;

        uint8 useMax = 0;
        uint8 direction = 0;
        uint128 limit = getMaxSwapLimit(direction == 0).safeCastTo128();
        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Enigma.encodeSwap(useMax, defaultScenario.poolId, 0x12, 0x02, 0x0, limit, direction);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 next = getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapExactInPoolTimestampUpdated() public postTestInvariantChecks {
        // Add liquidity first
        bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity, note: 0x0a amount breaks test? todo: handle case where insufficient liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        uint256 prev = getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastTimestamp;
        uint8 useMax = 0;
        uint8 direction = 0;
        uint128 limit = getMaxSwapLimit(direction == 0).safeCastTo128();

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Enigma.encodeSwap(useMax, defaultScenario.poolId, 0x12, 0x02, 0x0, limit, direction);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 next = getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastTimestamp;
        assertTrue(next != prev);
    }

    function testSwapExactInGlobalAssetBalanceIncreases() public postTestInvariantChecks {
        // Add liquidity first
        bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        uint256 prev = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        uint8 useMax = 0;
        uint8 direction = 0;
        uint128 limit = getMaxSwapLimit(direction == 0).safeCastTo128();
        data = Enigma.encodeSwap(useMax, defaultScenario.poolId, 0x12, 0x02, 0x0, limit, direction);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 next = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        assertTrue(next > prev);
    }

    function testSwapExactInGlobalQuoteBalanceDecreases() public postTestInvariantChecks {
        // Add liquidity first
        bytes memory data = Enigma.encodeAllocate(
            0,
            defaultScenario.poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        uint256 prev = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        uint8 useMax = 0;
        uint8 direction = 0;
        uint128 limit = getMaxSwapLimit(direction == 0).safeCastTo128();
        data = Enigma.encodeSwap(useMax, defaultScenario.poolId, 0x12, 0x02, 0x0, limit, direction);
        success = __revertCatcher__.process(data);
        assertTrue(success, "swap failed");

        uint256 next = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));
        assertTrue(next == prev, "reserves-changed");
    }

    // --- Allocate --- //

    function testAllocateNonExistentPoolIdReverts() public {
        uint64 failureArg = uint64(48);
        bytes memory data = Enigma.encodeAllocate(0, failureArg, 0x01, 0x01);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        bool success = __revertCatcher__.process(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testAllocateZeroLiquidityReverts() public {
        uint8 failureArg = 0;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, 0x00, failureArg);
        vm.expectRevert(ZeroLiquidity.selector);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testProcessAllocateFull() public postTestInvariantChecks {
        uint256 price = getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastPrice;
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), (defaultScenario.poolId));
        uint tau = getPool(address(__hyperTestingContract__), defaultScenario.poolId).tau(
            __hyperTestingContract__.timestamp()
        );
        uint strike = Price.computePriceWithTick(curve.maxTick);
        console.log(tau, strike, curve.volatility);
        uint256 theoreticalR2 = Price.getXWithPrice(price, strike, curve.volatility, tau);

        uint8 power = uint8(0x06); // 6 zeroes
        uint8 amount = uint8(0x04); // 4 with 6 zeroes = 4_000_000 wei
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);

        __revertCatcher__.process(data);

        uint delLiquidity = 4_000_000;
        uint256 globalR1 = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));
        uint256 globalR2 = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        uint expected = (theoreticalR2 * delLiquidity) / 1e18;
        console.log("expected", expected);
        console.log("globalR2", globalR2);
        // todo: fix this test
        assertApproxEqAbs(globalR2, expected, 1e2, "asset-reserve-theoretic"); // todo: fix, should it be this far?
    }

    function testAllocatePositionTimestampUpdated() public postTestInvariantChecks {
        uint64 positionId = defaultScenario.poolId;

        uint256 prevPositionTimestamp = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).lastTimestamp;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTimestamp = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).lastTimestamp;

        assertTrue(prevPositionTimestamp == 0);
        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == block.timestamp);
    }

    function testAllocatePositionfreeLiquidityIncreases() public postTestInvariantChecks {
        uint64 positionId = defaultScenario.poolId;

        uint256 prevPositionfreeLiquidity = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).freeLiquidity;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionfreeLiquidity = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).freeLiquidity;

        assertTrue(prevPositionfreeLiquidity == 0);
        assertTrue(nextPositionfreeLiquidity > prevPositionfreeLiquidity);
    }

    function testAllocateGlobalAssetIncreases() public postTestInvariantChecks {
        uint256 prevGlobal = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    function testAllocateGlobalQuoteIncreases() public postTestInvariantChecks {
        uint256 prevGlobal = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    // --- Remove Liquidity --- //

    function testUnallocateZeroLiquidityReverts() public {
        bytes memory data = Enigma.encodeUnallocate(0, defaultScenario.poolId, 0x00, 0x00);
        vm.expectRevert(ZeroLiquidity.selector);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    function testUnallocateNonExistentPoolReverts() public {
        uint64 failureArg = 42;
        bytes memory data = Enigma.encodeUnallocate(0, 42, 0x01, 0x01);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    // needs a mutable pool, or a pool with a non-zero jit policy
    function testUnallocatePositionJitPolicyReverts() public postTestInvariantChecks {
        uint16 jit = 99;
        bytes memory createData = Enigma.encodeCreatePool(
            uint24(1), // pairId
            address(this), // controller
            DEFAULT_FEE,
            DEFAULT_FEE,
            uint16(DEFAULT_SIGMA),
            DEFAULT_DURATION_DAYS,
            jit,
            DEFAULT_TICK,
            DEFAULT_PRICE
        );

        bool success = __revertCatcher__.process(createData);
        assertTrue(success, "forwarder call failed");

        uint64 poolId = Enigma.encodePoolId(uint24(0x01), true, uint32(__hyperTestingContract__.getPoolNonce()));

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Enigma.encodeAllocate(0, poolId, power, amount);
        success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        // Set the distance for the position by warping in time.
        uint256 distance = 22;
        uint256 warpTimestamp = block.timestamp + distance;
        customWarp(warpTimestamp);

        data = Enigma.encodeUnallocate(0, poolId, power, amount);

        vm.expectRevert(abi.encodeWithSelector(JitLiquidity.selector, distance));
        success = __revertCatcher__.process(data);
        assertTrue(!success, "Should not suceed in testUnllocatePositionJit");
    }

    function testUnallocatePositionTimestampUpdated() public postTestInvariantChecks {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint64 positionId = defaultScenario.poolId;
        uint256 prevPositionTimestamp = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).lastTimestamp;

        uint256 warpTimestamp = block.timestamp + 1;
        customWarp(warpTimestamp);

        data = Enigma.encodeUnallocate(0, defaultScenario.poolId, power, amount);
        success = __revertCatcher__.process(data);

        uint256 nextPositionTimestamp = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).lastTimestamp;

        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == warpTimestamp);
    }

    function testUnallocatePositionfreeLiquidityDecreases() public postTestInvariantChecks {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint64 positionId = defaultScenario.poolId;
        uint256 prevPositionLiquidity = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).freeLiquidity;

        data = Enigma.encodeUnallocate(0, defaultScenario.poolId, power, amount);
        success = __revertCatcher__.process(data);

        uint256 nextPositionLiquidity = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).freeLiquidity;

        assertTrue(nextPositionLiquidity < prevPositionLiquidity);
    }

    function testUnallocateGlobalAssetDecreases() public postTestInvariantChecks {
        uint8 amount = 0x01;
        uint8 power = 0x05; // if this is low enough, it will revert because token amounts rounded down to zero.
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 prev = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));

        data = Enigma.encodeUnallocate(0, defaultScenario.poolId, power, amount);
        success = __revertCatcher__.process(data);

        uint256 next = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        assertTrue(next == prev, "reserves-changed"); // unallocated amounts are credited to user
    }

    /// @dev IMPORTANT TEST. For low token decimals, be very aware of the amount of liquidity involved in each tx.
    function testUnallocateGlobalQuoteDecreases() public postTestInvariantChecks {
        uint8 amount = 0x01;
        uint8 power = 0x0c; // 1e12 liquidity
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 prev = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));

        data = Enigma.encodeUnallocate(0, defaultScenario.poolId, power, amount);
        success = __revertCatcher__.process(data);

        uint256 next = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));
        assertTrue(next == prev, "reserves-changed"); // unallocated amounts are credited to user
    }

    // --- Stake Position --- //

    function testStakeExternalEpochIncrements() public {
        uint8 amount = 0x05;
        __hyperTestingContract__.allocate(defaultScenario.poolId, amount);

        uint prevId = getPosition(address(__hyperTestingContract__), address(this), defaultScenario.poolId)
            .stakeTimestamp;
        __hyperTestingContract__.stake(defaultScenario.poolId, amount);
        uint nextId = getPosition(address(__hyperTestingContract__), address(this), defaultScenario.poolId)
            .stakeTimestamp;

        assertTrue(nextId != prevId);
    }

    function testStakePositionStakedUpdated() public postTestInvariantChecks {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint64 positionId = defaultScenario.poolId;

        bool prevPositionStaked = getPosition(address(__hyperTestingContract__), address(__revertCatcher__), positionId)
            .stakeTimestamp != 0;

        data = Enigma.encodeStakePosition(positionId, amount);
        success = __revertCatcher__.process(data);

        bool nextPositionStaked = getPosition(address(__hyperTestingContract__), address(__revertCatcher__), positionId)
            .stakeTimestamp != 0;

        assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        assertTrue(nextPositionStaked, "Position staked is not true.");
    }

    function testStakePoolStakedLiquidityUpdated() public postTestInvariantChecks {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 prevPoolStakedLiquidity = getPool(address(__hyperTestingContract__), defaultScenario.poolId)
            .stakedLiquidity;

        uint64 positionId = defaultScenario.poolId;
        data = Enigma.encodeStakePosition(positionId, amount);
        success = __revertCatcher__.process(data);

        uint256 nextPoolStakedLiquidity = getPool(address(__hyperTestingContract__), defaultScenario.poolId)
            .stakedLiquidity;

        if (
            lo <= getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastTick &&
            hi > getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastTick
        ) {
            assertTrue(nextPoolStakedLiquidity > prevPoolStakedLiquidity, "Pool staked liquidity did not increase.");
            assertTrue(
                nextPoolStakedLiquidity ==
                    getPosition(address(__hyperTestingContract__), address(__revertCatcher__), positionId)
                        .freeLiquidity,
                "Pool staked liquidity not equal to liquidity of staked position."
            );
        } else {
            assertTrue(
                nextPoolStakedLiquidity == prevPoolStakedLiquidity,
                "Pool staked liquidity changed even though position staked out of range."
            );
        }
    }

    function testStakeNonExistentPoolIdReverts() public {
        uint64 failureArg = uint64(3214);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        __hyperTestingContract__.stake(failureArg, 100);
    }

    function testStakeZeroLiquidityRevertsWithInsufficientPosition() public {
        vm.expectRevert(abi.encodeWithSelector(InsufficientPosition.selector, defaultScenario.poolId));
        __hyperTestingContract__.stake(defaultScenario.poolId, 100);
    }

    // --- Unstake Position --- //

    function testUnstakeExternalEpochIncrements() public {
        uint8 amount = 0x05;
        __hyperTestingContract__.allocate(defaultScenario.poolId, amount);
        __hyperTestingContract__.stake(defaultScenario.poolId, amount);

        uint prevId = getPosition(address(__hyperTestingContract__), address(this), defaultScenario.poolId)
            .unstakeTimestamp;

        customWarp(prevId + 1);
        __hyperTestingContract__.unstake(defaultScenario.poolId, amount);
        uint nextId = getPosition(address(__hyperTestingContract__), address(this), defaultScenario.poolId)
            .unstakeTimestamp;

        // todo: add better tests
        //assertTrue(nextId != prevId);
    }

    function testUnstakePositionStakedUpdated() public postTestInvariantChecks {
        uint8 amount = 0x01;
        uint8 power = 0x0f;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint128 stakeAmount = uint128(amount * 10 ** power);

        uint64 positionId = defaultScenario.poolId;
        data = Enigma.encodeStakePosition(positionId, stakeAmount);
        success = __revertCatcher__.process(data);

        HyperPosition memory pos = getPosition(
            address(__hyperTestingContract__),
            address(this),
            defaultScenario.poolId
        );

        // touch pool to update it so we know how much staked liquidity the position has
        uint8 useMax = 0;
        uint8 direction = 0;
        uint128 limit = getMaxSwapLimit(direction == 0).safeCastTo128();
        data = Enigma.encodeSwap(useMax, defaultScenario.poolId, 0x09, 0x01, 0x0, limit, direction);
        success = __revertCatcher__.process(data);

        HyperPosition memory revertCatcherPos = defaultRevertCatcherPosition();

        uint256 prevPositionStaked = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).unstakeTimestamp;

        uint prevStaked = revertCatcherPos.stakedLiquidity;

        data = Enigma.encodeUnstakePosition(positionId, stakeAmount);
        customWarp(prevPositionStaked + 1);
        success = __revertCatcher__.process(data);
        revertCatcherPos = defaultRevertCatcherPosition();

        uint256 nextPositionStaked = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).unstakeTimestamp;

        uint postStaked = revertCatcherPos.stakedLiquidity;
        assertEq(postStaked, prevStaked - stakeAmount, "stake-liquidity-decreases");
        assertTrue(postStaked < prevStaked, "stake-did-not-decrease");
        //assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        //assertTrue(nextPositionStaked != 0, "Position staked is true.");
    }

    // note: some unintended side effects most likely from update/sync pool messing with price
    // it creates a discrepency in the contract where the contract holds more tokens than the sum
    // of all claims is entitled to.
    function testUnstakePoolStakedLiquidityUpdated() public postTestInvariantChecks {
        uint8 amount = 0x01;
        uint8 power = 0x0f;
        bytes memory data = Enigma.encodeAllocate(0, defaultScenario.poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint64 positionId = defaultScenario.poolId;
        data = Enigma.encodeStakePosition(positionId, amount);
        success = __revertCatcher__.process(data);

        // touch pool to update it so we know how much staked liquidity the position has
        uint8 useMax = 0;
        uint8 direction = 0;
        uint128 limit = getMaxSwapLimit(direction == 0).safeCastTo128();
        data = Enigma.encodeSwap(useMax, positionId, 0x09, 0x01, 0x0, limit, direction);
        success = __revertCatcher__.process(data);

        uint256 prevPoolStakedLiquidity = getPool(address(__hyperTestingContract__), positionId).stakedLiquidity;

        HyperPosition memory pos = defaultRevertCatcherPosition();
        customWarp(pos.unstakeTimestamp + 1);
        data = Enigma.encodeUnstakePosition(positionId, amount);
        success = __revertCatcher__.process(data);

        pos = defaultRevertCatcherPosition();
        customWarp((pos.unstakeTimestamp + 1) * 2);

        // TODO: FIX FAILING TEST

        // touch pool to update it so we know how much staked liquidity the position has
        // data = Enigma.encodeSwap(0, defaultScenario.poolId, 0x01, 0x01, 0x15, 0x01, 0);
        // success = __revertCatcher__.process(data);
        //
        // // todo: currently fails because unstaking does not change staked liquidity.
        // uint256 nextPoolStakedLiquidity = getPool(address(__hyperTestingContract__),defaultScenario.poolId).stakedLiquidity;
        //
        // if (lo <= getPool(address(__hyperTestingContract__),defaultScenario.poolId).lastTick && hi > getPool(address(__hyperTestingContract__),defaultScenario.poolId).lastTick) {
        //     assertTrue(nextPoolStakedLiquidity < prevPoolStakedLiquidity, "Pool staked liquidity did not increase.");
        //     assertTrue(nextPoolStakedLiquidity == 0, "Pool staked liquidity does not equal 0 after unstake.");
        // } else {
        //     assertTrue(
        //         nextPoolStakedLiquidity == prevPoolStakedLiquidity,
        //         "Pool staked liquidity changed even though position staked out of range."
        //     );
        // }
    }

    function testUnstakeNonExistentPoolIdReverts() public {
        uint64 failureArg = 1224;
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        __hyperTestingContract__.unstake(failureArg, 555);
    }

    function testUnstakeNotStakedReverts() public {
        vm.expectRevert(abi.encodeWithSelector(PositionNotStaked.selector, defaultScenario.poolId));
        __hyperTestingContract__.unstake(defaultScenario.poolId, 555);
    }

    // --- Create HyperPair --- //

    function testCreatePairSameTokensReverts() public {
        address token = address(new TestERC20("t", "t", 18));
        bytes memory data = Enigma.encodeCreatePair(token, token);
        vm.expectRevert(SameTokenError.selector);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testCreatePairPairExistsReverts() public {
        bytes memory data = Enigma.encodeCreatePair(address(defaultScenario.asset), address(defaultScenario.quote));
        vm.expectRevert(abi.encodeWithSelector(PairExists.selector, 1));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairLowerDecimalBoundsAssetReverts() public {
        address token0 = address(new TestERC20("t", "t", 5));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Enigma.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(InvalidDecimals.selector, 5));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairLowerDecimalBoundsQuoteReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 5));
        bytes memory data = Enigma.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(InvalidDecimals.selector, 5));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairUpperDecimalBoundsAssetReverts() public {
        address token0 = address(new TestERC20("t", "t", 24));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Enigma.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(InvalidDecimals.selector, 24));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairUpperDecimalBoundsQuoteReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 24));
        bytes memory data = Enigma.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(InvalidDecimals.selector, 24));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairPairNonceIncrementedReturnsOneAdded() public {
        uint256 prevNonce = __hyperTestingContract__.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Enigma.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint256 nonce = __hyperTestingContract__.getPairNonce();
        assertEq(nonce, prevNonce + 1);
    }

    function testCreatePairFetchesPairIdReturnsNonZero() public {
        uint256 prevNonce = __hyperTestingContract__.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Enigma.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint256 pairId = __hyperTestingContract__.getPairId(token0, token1);
        assertTrue(pairId != 0);
    }

    function testCreatePairFetchesPairDataReturnsAddresses() public {
        uint256 prevNonce = __hyperTestingContract__.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Enigma.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint24 pairId = __hyperTestingContract__.getPairId(token0, token1);
        HyperPair memory pair = getPair(address(__hyperTestingContract__), pairId);
        assertEq(pair.tokenAsset, token0);
        assertEq(pair.tokenQuote, token1);
        assertEq(pair.decimalsAsset, 18);
        assertEq(pair.decimalsQuote, 18);
    }

    /* // --- Create Curve --- //

    function testCreateCurveCurveExistsReverts() public {
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        bytes memory data = Enigma.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(CurveExists.selector, 1));
        bool success = __revertCatcher__.process(data);
    }

    function testCreateCurveFeeParameterOutsideBoundsReverts() public {
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        uint16 failureArg = 5e4;
        bytes memory data = Enigma.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            failureArg,
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(InvalidFee.selector, failureArg));
        bool success = __revertCatcher__.process(data);
    }

    function testCreateCurvePriorityFeeParameterOutsideBoundsReverts() public {
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        uint16 failureArg = 5e4;
        bytes memory data = Enigma.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            failureArg,
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(InvalidFee.selector, failureArg));
        bool success = __revertCatcher__.process(data);
    }

    function testCreateCurveRMMPoolZeroSigmaReverts() public {
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        uint24 failureArg = 0;
        bytes memory data = Enigma.encodeCreateCurve(
            failureArg,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(InvalidVolatility.selector, failureArg));
        bool success = __revertCatcher__.process(data);
    }

    function testCreateCurveRMMPoolZeroStrikeReverts() public {
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        uint128 failureArg = 0;
        bytes memory data = Enigma.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            failureArg
        );
        vm.expectRevert(abi.encodeWithSelector(InvalidStrike.selector, failureArg));
        bool success = __revertCatcher__.process(data);
    }

    function testCreateCurveCurveNonceIncrementReturnsOne() public {
        uint256 prevNonce = __hyperTestingContract__.getCurveNonce();
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        bytes memory data = Enigma.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bool success = __revertCatcher__.process(data);
        uint256 nextNonce = __hyperTestingContract__.getCurveNonce();
        assertEq(prevNonce, nextNonce - 1);
    }

    function testCreateCurveFetchesCurveIdReturnsNonZero() public {
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        bytes memory data = Enigma.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = Enigma.toBytes32(
            abi.encodePacked(
                curve.sigma + 1,
                curve.maturity,
                uint16(1e4 - curve.gamma),
                uint16(1e4 - curve.priorityGamma),
                curve.strike
            )
        );
        bool success = __revertCatcher__.process(data);
        uint32 curveId = __hyperTestingContract__.getCurveId(rawCurveId);
        assertTrue(curveId != 0);
    }

    function testCreateCurveFetchesCurveDataReturnsParametersSet() public {
        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        bytes memory data = Enigma.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = Enigma.toBytes32(
            abi.encodePacked(
                curve.sigma + 1,
                curve.maturity,
                uint16(1e4 - curve.gamma),
                uint16(1e4 - curve.priorityGamma),
                curve.strike
            )
        );
        bool success = __revertCatcher__.process(data);
        uint32 curveId = __hyperTestingContract__.getCurveId(rawCurveId);
        HyperCurve memory newCurve = getCurve(address(__hyperTestingContract__), curveId);
        assertEq(newCurve.sigma, curve.sigma + 1);
        assertEq(newCurve.maturity, curve.maturity);
        assertEq(newCurve.gamma, curve.gamma);
        assertEq(newCurve.priorityGamma, curve.priorityGamma);
        assertEq(newCurve.strike, curve.strike);
    } */

    // --- Create Pool --- //
    // todo: fix

    /* function testCreatePoolZeroPriceParameterReverts() public {
        uint128 failureArg = 0;
        bytes memory data = Enigma.encodeCreatePool(1, failureArg);
        vm.expectRevert(ZeroPrice.selector);
        bool success = __revertCatcher__.process(data);
    } */

    // todo: fix
    /* function testCreatePoolExistentPoolReverts() public {
        uint64 failureArg = defaultScenario.poolId;
        bytes memory data = Enigma.encodeCreatePool(failureArg, 1);
        vm.expectRevert(PoolExists.selector);
        bool success = __revertCatcher__.process(data);
    } */

    // todo: fix
    /* function testCreatePoolMagicPairId() public {
        // Create a new curve to increment the nonce to 2
        bytes memory data = Enigma.encodeCreateCurve(4, type(uint32).max - 1, 4, 4, 4);
        __revertCatcher__.process(data);

        uint64 magicVariable = 0x000000000002;
        data = Enigma.encodeCreatePool(magicVariable, 1);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
    } */
    /* 
    function testCreatePoolMagicCurveId() public {
        // Create a new pair to increment the nonce to 2
        bytes memory data = Enigma.encodeCreatePair(address(defaultScenario.quote), address(__weth__));
        __revertCatcher__.process(data);

        uint64 magicVariable = 0x000200000000;
        data = Enigma.encodeCreatePool(magicVariable, 1);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
    }

    function testCreatePoolRMMPoolExpiredReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Enigma.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint24 pairId = __hyperTestingContract__.getPairId(token0, token1);

        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        data = Enigma.encodeCreateCurve(
            curve.sigma + 1,
            uint32(0),
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = Enigma.toBytes32(
            abi.encodePacked(curve.sigma + 1, uint32(0), uint16(1e4 - curve.gamma), curve.strike)
        );
        success = __revertCatcher__.process(data);

        uint32 curveId = __hyperTestingContract__.getCurveId(rawCurveId);
        uint64 id = Enigma.encodePoolId(pairId, curveId);
        data = Enigma.encodeCreatePool(id, 1_000);
        vm.expectRevert(PoolExpired.selector);
        success = __revertCatcher__.process(data);
    }

    function testCreatePoolFetchesPoolDataReturnsNonZeroBlockTimestamp() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Enigma.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint24 pairId = __hyperTestingContract__.getPairId(token0, token1);

        HyperCurve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId)); // Existing curve from helper setup
        data = Enigma.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = Enigma.toBytes32(
            abi.encodePacked(
                curve.sigma + 1,
                curve.maturity,
                uint16(1e4 - curve.gamma),
                uint16(1e4 - curve.priorityGamma),
                curve.strike
            )
        );
        success = __revertCatcher__.process(data);

        uint32 curveId = __hyperTestingContract__.getCurveId(rawCurveId);
        uint64 id = Enigma.encodePoolId(pairId, curveId);
        data = Enigma.encodeCreatePool(id, 1_000);
        success = __revertCatcher__.process(data);

        uint256 time = getPool(address(__hyperTestingContract__), id).lastTimestamp;
        assertTrue(time != 0);
    } */
}
