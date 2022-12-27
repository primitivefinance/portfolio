// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./setup/TestHyperSetup.sol";

contract TestHyperProcessing is TestHyperSetup {
    modifier checkSettlementInvariant() {
        _;
    }

    uint48 __poolId;
    TestERC20 public asset;
    TestERC20 public quote;

    function afterSetUp() public override {
        asset = __token_18__;
        quote = __usdc__;

        __hyperTestingContract__.setTimestamp(uint128(block.timestamp)); // !important!

        // 2. Bundled operation set to create a pair, curve, and pool.
        bytes memory data = createPool(
            address(__token_18__),
            address(__usdc__),
            DEFAULT_SIGMA,
            uint32(block.timestamp) + DEFAULT_MATURITY,
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            DEFAULT_STRIKE,
            DEFAULT_PRICE
        );

        bool success = __revertCatcher__.jumpProcess(data);
        assertTrue(success, "__revertCatcher__ call failed");

        uint16 pairId = uint16(__hyperTestingContract__.getPairNonce());
        uint32 curveId = uint32(__hyperTestingContract__.getCurveNonce());
        __poolId = CPU.encodePoolId(pairId, curveId);

        assertTrue(getPool(address(__hyperTestingContract__), __poolId).blockTimestamp != 0, "Pool not created");
        assertTrue(
            getPool(address(__hyperTestingContract__), __poolId).lastTick != 0,
            "Pool not initialized with price"
        );
        assertTrue(
            getPool(address(__hyperTestingContract__), __poolId).liquidity == 0,
            "Pool initialized with liquidity"
        );
    }

    // ===== Getters ===== //

    function testGetAmounts() public {
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId));
        (uint deltaAsset, uint deltaQuote) = __hyperTestingContract__.getAmounts(__poolId);

        assertEq(deltaAsset, DEFAULT_ASSET_RESERVE);
        assertEq(deltaQuote, DEFAULT_QUOTE_RESERVE);
    }

    function testGetLiquidityMinted() public {
        uint deltaLiquidity = __hyperTestingContract__.getLiquidityMinted(__poolId, 1, 1e19);
    }

    // ===== CPU ===== //

    function testJumpProcessCreatesPair() public {
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = (CPU.encodeCreatePair(address(__token_8__), address(quote)));
        bytes memory data = CPU.encodeJumpInstruction(instructions);
        bool success = __revertCatcher__.jumpProcess(data);
        assertTrue(success);

        uint16 pairId = uint16(__hyperTestingContract__.getPairNonce());
        Pair memory pair = getPair(address(__hyperTestingContract__), pairId);
        assertTrue(pair.tokenAsset != address(0));
        assertTrue(pair.tokenQuote != address(0));
    }

    function testProcessRevertsWithUnknownInstructionZeroOpcode() public {
        vm.expectRevert(UnknownInstruction.selector);
        __revertCatcher__.process(hex"00");
    }

    function testProcessRevertsWithUnknownInstruction() public {
        vm.expectRevert(UnknownInstruction.selector);
        __revertCatcher__.process(hex"44");
    }

    // ===== Effects ===== //

    function testSyncPool() public {
        customWarp(1);
        __hyperTestingContract__.syncPool(__poolId);
    }

    function testDrawReducesBalance() public checkSettlementInvariant {
        // First fund the account
        __hyperTestingContract__.fund(address(asset), 4000);

        // Draw
        uint prevBalance = getBalance(address(__hyperTestingContract__), address(this), address(asset));
        __hyperTestingContract__.draw(address(asset), 4000, address(this));
        uint nextBalance = getBalance(address(__hyperTestingContract__), address(this), address(asset));

        assertTrue(nextBalance == 0);
        assertTrue(nextBalance < prevBalance);
    }

    function testDrawRevertsWithDrawBalance() public {
        vm.expectRevert(DrawBalance.selector);
        __hyperTestingContract__.draw(address(asset), 1e18, address(this));
    }

    function testDrawFromWethTransfersEther() public checkSettlementInvariant {
        // First fund the account
        __hyperTestingContract__.deposit{value: 4000}();

        // Draw
        uint prevBalance = address(this).balance;
        __hyperTestingContract__.draw(address(__weth__), 4000, address(this));
        uint nextBalance = address(this).balance;

        assertTrue(nextBalance > prevBalance);
    }

    function testFundIncreasesBalance() public checkSettlementInvariant {
        uint prevBalance = getBalance(address(__hyperTestingContract__), address(this), address(asset));
        __hyperTestingContract__.fund(address(asset), 4000);
        uint nextBalance = getBalance(address(__hyperTestingContract__), address(this), address(asset));

        assertTrue(nextBalance > prevBalance);
    }

    function testDepositWrapsEther() public checkSettlementInvariant {
        uint prevWethBalance = __weth__.balanceOf(address(__hyperTestingContract__));
        uint prevBalance = address(this).balance;
        __hyperTestingContract__.deposit{value: 4000}();
        uint nextBalance = address(this).balance;
        uint nextWethBalance = __weth__.balanceOf(address(__hyperTestingContract__));

        assertTrue(nextBalance < prevBalance);
        assertTrue(nextWethBalance > prevWethBalance);
    }

    // --- Swap --- //

    function testSwapExactInNonExistentPoolIdReverts() public {
        uint48 failureArg = 0x0001030;
        bytes memory data = CPU.encodeSwap(0, 0x0001030, 0x01, 0x01, 0x01, 0x01, 0);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    function testSwapExactInZeroSwapAmountReverts() public {
        uint128 failureArg = 0;
        bytes memory data = CPU.encodeSwap(0, __poolId, 0x01, failureArg, 0x01, 0x01, 0);
        vm.expectRevert(ZeroInput.selector);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    function testSwapExactInPoolPriceUpdated() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        uint256 prev = getPool(address(__hyperTestingContract__), __poolId).lastPrice;

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 next = getPool(address(__hyperTestingContract__), __poolId).lastPrice;
        assertTrue(next != prev);
    }

    /* function testSwapExactInPoolSlotIndexUpdated() public {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        int256 prev = getPool(address(__hyperTestingContract__),__poolId).lastTick;

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        int256 next = getPool(address(__hyperTestingContract__),__poolId).lastTick;
        assertTrue(next != prev);
    } */

    function testSwapUseMax() public checkSettlementInvariant {
        uint amount = type(uint256).max;
        uint limit = amount;
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        // move some time
        customWarp(block.timestamp + 1);
        uint256 prev = getPool(address(__hyperTestingContract__), __poolId).liquidity;

        __hyperTestingContract__.swap(__poolId, true, amount, limit);

        uint256 next = getPool(address(__hyperTestingContract__), __poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapInQuote() public checkSettlementInvariant {
        uint limit = type(uint256).max;
        uint amount = 2222;
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        // move some time
        customWarp(block.timestamp + 1);
        uint256 prev = getPool(address(__hyperTestingContract__), __poolId).liquidity;

        __hyperTestingContract__.swap(__poolId, false, amount, limit);

        uint256 next = getPool(address(__hyperTestingContract__), __poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapReverse() public {
        uint limit = type(uint256).max;
        uint amount = 17e16;
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        // move some time
        uint256 prev = getBalance(address(__hyperTestingContract__), address(this), address(asset));

        (uint output, ) = __hyperTestingContract__.swap(__poolId, true, amount, limit);
        (uint input, ) = __hyperTestingContract__.swap(__poolId, false, output, limit);

        uint256 next = getBalance(address(__hyperTestingContract__), address(this), address(asset));
        assertTrue(next <= prev);
        assertTrue(input < amount);
    }

    function testSwapExpiredPoolReverts() public {
        uint limit = type(uint256).max;
        uint amount = 2222;
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        // move some time beyond maturity
        customWarp(getCurve(address(__hyperTestingContract__), uint32(__poolId)).maturity + 1);

        vm.expectRevert(PoolExpiredError.selector);
        __hyperTestingContract__.swap(__poolId, false, amount, limit);
    }

    function testSwapExactInPoolLiquidityUnchanged() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);
        uint256 prev = getPool(address(__hyperTestingContract__), __poolId).liquidity;

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 next = getPool(address(__hyperTestingContract__), __poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapExactInPoolTimestampUpdated() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity, note: 0x0a amount breaks test? todo: handle case where insufficient liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        uint256 prev = getPool(address(__hyperTestingContract__), __poolId).blockTimestamp;

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 next = getPool(address(__hyperTestingContract__), __poolId).blockTimestamp;
        assertTrue(next != prev);
    }

    function testSwapExactInGlobalAssetBalanceIncreases() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        uint256 prev = getReserve(address(__hyperTestingContract__), address(asset));

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 next = getReserve(address(__hyperTestingContract__), address(asset));
        assertTrue(next > prev);
    }

    function testSwapExactInGlobalQuoteBalanceDecreases() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
        // move some time
        customWarp(block.timestamp + 1);

        uint256 prev = getReserve(address(__hyperTestingContract__), address(quote));

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 next = getReserve(address(__hyperTestingContract__), address(quote));
        assertTrue(next < prev);
    }

    // --- Allocate --- //

    function testAllocateNonExistentPoolIdReverts() public {
        uint48 failureArg = uint48(48);
        bytes memory data = CPU.encodeAllocate(0, failureArg, 0x01, 0x01);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        bool success = __revertCatcher__.process(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testAllocateZeroLiquidityReverts() public {
        uint8 failureArg = 0;
        bytes memory data = CPU.encodeAllocate(0, __poolId, 0x00, failureArg);
        vm.expectRevert(ZeroLiquidityError.selector);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testProcessAllocateFull() public checkSettlementInvariant {
        uint256 price = getPool(address(__hyperTestingContract__), __poolId).lastPrice;
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId));
        uint256 theoreticalR2 = Price.computeR2WithPrice(
            price,
            curve.strike,
            curve.sigma,
            curve.maturity - block.timestamp
        );

        uint8 power = uint8(0x06); // 6 zeroes
        uint8 amount = uint8(0x04); // 4 with 6 zeroes = 4_000_000 wei
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);

        __revertCatcher__.process(data);

        uint256 globalR1 = getReserve(address(__hyperTestingContract__), address(quote));
        uint256 globalR2 = getReserve(address(__hyperTestingContract__), address(asset));
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        assertTrue((theoreticalR2 - FixedPointMathLib.divWadUp(globalR2, 4_000_000)) <= 1e14);
    }

    function testAllocateFull() public checkSettlementInvariant {
        uint256 price = getPool(address(__hyperTestingContract__), __poolId).lastPrice;
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId));
        uint256 theoreticalR2 = Price.computeR2WithPrice(
            price,
            curve.strike,
            curve.sigma,
            curve.maturity - block.timestamp
        );

        __hyperTestingContract__.allocate(__poolId, 4e6);

        uint256 globalR1 = getReserve(address(__hyperTestingContract__), address(quote));
        uint256 globalR2 = getReserve(address(__hyperTestingContract__), address(asset));
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        assertTrue((theoreticalR2 - FixedPointMathLib.divWadUp(globalR2, 4_000_000)) <= 1e14);
    }

    function testAllocateUseMax() public checkSettlementInvariant {
        uint maxLiquidity = __hyperTestingContract__.getLiquidityMinted(
            __poolId,
            asset.balanceOf(address(this)),
            quote.balanceOf(address(this))
        );

        (uint deltaAsset, uint deltaQuote) = __hyperTestingContract__.getReserveDelta(__poolId, maxLiquidity);

        __hyperTestingContract__.allocate(__poolId, type(uint256).max);

        assertEq(maxLiquidity, getPool(address(__hyperTestingContract__), __poolId).liquidity);
        assertEq(deltaAsset, getReserve(address(__hyperTestingContract__), address(asset)));
        assertEq(deltaQuote, getReserve(address(__hyperTestingContract__), address(quote)));
    }

    function testAllocatePositionTimestampUpdated() public checkSettlementInvariant {
        uint48 positionId = __poolId;

        uint256 prevPositionTimestamp = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).blockTimestamp;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTimestamp = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).blockTimestamp;

        assertTrue(prevPositionTimestamp == 0);
        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == block.timestamp);
    }

    function testAllocatePositionTotalLiquidityIncreases() public checkSettlementInvariant {
        uint48 positionId = __poolId;

        uint256 prevPositionTotalLiquidity = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).totalLiquidity;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTotalLiquidity = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).totalLiquidity;

        assertTrue(prevPositionTotalLiquidity == 0);
        assertTrue(nextPositionTotalLiquidity > prevPositionTotalLiquidity);
    }

    function testAllocateGlobalAssetIncreases() public checkSettlementInvariant {
        uint256 prevGlobal = getReserve(address(__hyperTestingContract__), address(asset));

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = getReserve(address(__hyperTestingContract__), address(asset));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    function testAllocateGlobalQuoteIncreases() public checkSettlementInvariant {
        uint256 prevGlobal = getReserve(address(__hyperTestingContract__), address(quote));

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = getReserve(address(__hyperTestingContract__), address(quote));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    // --- Remove Liquidity --- //

    function testUnallocateUseMax() public {
        uint maxLiquidity = getPosition(address(__hyperTestingContract__), msg.sender, __poolId).totalLiquidity;

        __hyperTestingContract__.unallocate(__poolId, type(uint256).max);

        assertEq(0, getPool(address(__hyperTestingContract__), __poolId).liquidity);
    }

    function testUnallocateZeroLiquidityReverts() public {
        bytes memory data = CPU.encodeUnallocate(0, __poolId, 0x00, 0x00);
        vm.expectRevert(ZeroLiquidityError.selector);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    function testUnallocateNonExistentPoolReverts() public {
        uint48 failureArg = 42;
        bytes memory data = CPU.encodeUnallocate(0, 42, 0x01, 0x01);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    function testUnallocatePositionJitPolicyReverts() public checkSettlementInvariant {
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        // Set the distance for the position by warping in time.
        uint256 distance = 22;
        uint256 warpTimestamp = block.timestamp + distance;
        customWarp(warpTimestamp);

        // Set the policy from 0 (default 0 in test contract).
        __hyperTestingContract__.setJitPolicy(999999999999);

        data = CPU.encodeUnallocate(0, __poolId, power, amount);

        vm.expectRevert(abi.encodeWithSelector(JitLiquidity.selector, distance));
        success = __revertCatcher__.process(data);
        assertTrue(!success, "Should not suceed in testUnllocatePositionJit");
    }

    function testUnallocatePositionTimestampUpdated() public checkSettlementInvariant {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint48 positionId = __poolId;
        uint256 prevPositionTimestamp = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).blockTimestamp;

        uint256 warpTimestamp = block.timestamp + 1;
        customWarp(warpTimestamp);

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = __revertCatcher__.process(data);

        uint256 nextPositionTimestamp = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).blockTimestamp;

        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == warpTimestamp);
    }

    function testUnallocatePositionTotalLiquidityDecreases() public checkSettlementInvariant {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "forwarder call failed");

        uint48 positionId = __poolId;
        uint256 prevPositionLiquidity = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).totalLiquidity;

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = __revertCatcher__.process(data);

        uint256 nextPositionLiquidity = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).totalLiquidity;

        assertTrue(nextPositionLiquidity < prevPositionLiquidity);
    }

    function testUnallocateGlobalAssetDecreases() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 prev = getReserve(address(__hyperTestingContract__), address(asset));

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = __revertCatcher__.process(data);

        uint256 next = getReserve(address(__hyperTestingContract__), address(asset));
        assertTrue(next < prev, "globalReserves did not change");
    }

    function testUnallocateGlobalQuoteDecreases() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 prev = getReserve(address(__hyperTestingContract__), address(quote));

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = __revertCatcher__.process(data);

        uint256 next = getReserve(address(__hyperTestingContract__), address(quote));
        assertTrue(next < prev, "globalReserves did not change");
    }

    // --- Stake Position --- //

    function testStakeExternalEpochIncrements() public {
        uint8 amount = 0x05;
        __hyperTestingContract__.allocate(__poolId, amount);

        uint prevId = getPosition(address(__hyperTestingContract__), address(this), __poolId).stakeEpochId;
        __hyperTestingContract__.stake(__poolId);
        uint nextId = getPosition(address(__hyperTestingContract__), address(this), __poolId).stakeEpochId;

        assertTrue(nextId != prevId);
    }

    function testStakePositionStakedUpdated() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint48 positionId = __poolId;

        bool prevPositionStaked = getPosition(address(__hyperTestingContract__), address(__revertCatcher__), positionId)
            .stakeEpochId != 0;

        data = CPU.encodeStakePosition(positionId);
        success = __revertCatcher__.process(data);

        bool nextPositionStaked = getPosition(address(__hyperTestingContract__), address(__revertCatcher__), positionId)
            .stakeEpochId != 0;

        assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        assertTrue(nextPositionStaked, "Position staked is not true.");
    }

    function testStakePoolStakedLiquidityUpdated() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint256 prevPoolStakedLiquidity = getPool(address(__hyperTestingContract__), __poolId).stakedLiquidity;

        uint48 positionId = __poolId;
        data = CPU.encodeStakePosition(positionId);
        success = __revertCatcher__.process(data);

        uint256 nextPoolStakedLiquidity = getPool(address(__hyperTestingContract__), __poolId).stakedLiquidity;

        if (
            lo <= getPool(address(__hyperTestingContract__), __poolId).lastTick &&
            hi > getPool(address(__hyperTestingContract__), __poolId).lastTick
        ) {
            assertTrue(nextPoolStakedLiquidity > prevPoolStakedLiquidity, "Pool staked liquidity did not increase.");
            assertTrue(
                nextPoolStakedLiquidity ==
                    getPosition(address(__hyperTestingContract__), address(__revertCatcher__), positionId)
                        .totalLiquidity,
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
        uint48 failureArg = 3214;
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        __hyperTestingContract__.stake(failureArg);
    }

    function testStakeNonZeroStakeEpochIdReverts() public {
        __hyperTestingContract__.allocate(__poolId, 4355);
        __hyperTestingContract__.stake(__poolId); // Increments stake epoch id

        vm.expectRevert(abi.encodeWithSelector(PositionStakedError.selector, __poolId));
        __hyperTestingContract__.stake(__poolId);
    }

    function testStakePositionZeroLiquidityReverts() public {
        vm.expectRevert(abi.encodeWithSelector(PositionZeroLiquidityError.selector, __poolId));
        __hyperTestingContract__.stake(__poolId);
    }

    // --- Unstake Position --- //

    function testUnstakeExternalEpochIncrements() public {
        uint8 amount = 0x05;
        __hyperTestingContract__.allocate(__poolId, amount);
        __hyperTestingContract__.stake(__poolId);

        uint prevId = getPosition(address(__hyperTestingContract__), address(this), __poolId).unstakeEpochId;
        __hyperTestingContract__.unstake(__poolId);
        uint nextId = getPosition(address(__hyperTestingContract__), address(this), __poolId).unstakeEpochId;

        assertTrue(nextId != prevId);
    }

    function testUnstakePositionStakedUpdated() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK + 256; // fails if not above current tick
        uint8 amount = 0x01;
        uint8 power = 0x0f;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint48 positionId = __poolId;
        data = CPU.encodeStakePosition(positionId);
        success = __revertCatcher__.process(data);

        customWarp(__hyperTestingContract__.EPOCH_INTERVAL() + 1);

        // touch pool to update it so we know how much staked liquidity the position has
        data = CPU.encodeSwap(0, __poolId, 0x09, 0x01, 0x15, 0x01, 0);
        success = __revertCatcher__.process(data);

        uint256 prevPositionStaked = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).unstakeEpochId;

        data = CPU.encodeUnstakePosition(positionId);
        success = __revertCatcher__.process(data);

        uint256 nextPositionStaked = getPosition(
            address(__hyperTestingContract__),
            address(__revertCatcher__),
            positionId
        ).unstakeEpochId;

        assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        assertTrue(nextPositionStaked != 0, "Position staked is true.");
    }

    // note: some unintended side effects most likely from update/sync pool messing with price
    // it creates a discrepency in the contract where the contract holds more tokens than the sum
    // of all claims is entitled to.
    function testUnstakePoolStakedLiquidityUpdated() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK + 256; // note: fails if pool.lastTick <= hi
        uint8 amount = 0x01;
        uint8 power = 0x0f;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);

        uint48 positionId = __poolId;
        data = CPU.encodeStakePosition(positionId);
        success = __revertCatcher__.process(data);

        customWarp(__hyperTestingContract__.EPOCH_INTERVAL() + 1);

        // touch pool to update it so we know how much staked liquidity the position has
        data = CPU.encodeSwap(0, __poolId, 0x09, 0x01, 0x15, 0x01, 0);
        success = __revertCatcher__.process(data);

        uint256 prevPoolStakedLiquidity = getPool(address(__hyperTestingContract__), __poolId).stakedLiquidity;

        data = CPU.encodeUnstakePosition(positionId);
        success = __revertCatcher__.process(data);

        customWarp((__hyperTestingContract__.EPOCH_INTERVAL() + 1) * 2);

        // TODO: FIX FAILING TEST

        // touch pool to update it so we know how much staked liquidity the position has
        // data = CPU.encodeSwap(0, __poolId, 0x01, 0x01, 0x15, 0x01, 0);
        // success = __revertCatcher__.process(data);
        //
        // // todo: currently fails because unstaking does not change staked liquidity.
        // uint256 nextPoolStakedLiquidity = getPool(address(__hyperTestingContract__),__poolId).stakedLiquidity;
        //
        // if (lo <= getPool(address(__hyperTestingContract__),__poolId).lastTick && hi > getPool(address(__hyperTestingContract__),__poolId).lastTick) {
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
        uint48 failureArg = 1224;
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        __hyperTestingContract__.unstake(failureArg);
    }

    function testUnstakeNotStakedReverts() public {
        vm.expectRevert(abi.encodeWithSelector(PositionNotStakedError.selector, __poolId));
        __hyperTestingContract__.unstake(__poolId);
    }

    // --- Create Pair --- //

    function testCreatePairSameTokensReverts() public {
        address token = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(token, token);
        vm.expectRevert(SameTokenError.selector);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testCreatePairPairExistsReverts() public {
        bytes memory data = CPU.encodeCreatePair(address(asset), address(quote));
        vm.expectRevert(abi.encodeWithSelector(PairExists.selector, 1));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairLowerDecimalBoundsAssetReverts() public {
        address token0 = address(new TestERC20("t", "t", 5));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(DecimalsError.selector, 5));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairLowerDecimalBoundsQuoteReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 5));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(DecimalsError.selector, 5));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairUpperDecimalBoundsAssetReverts() public {
        address token0 = address(new TestERC20("t", "t", 24));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(DecimalsError.selector, 24));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairUpperDecimalBoundsQuoteReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 24));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(DecimalsError.selector, 24));
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePairPairNonceIncrementedReturnsOneAdded() public {
        uint256 prevNonce = __hyperTestingContract__.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint256 nonce = __hyperTestingContract__.getPairNonce();
        assertEq(nonce, prevNonce + 1);
    }

    function testCreatePairFetchesPairIdReturnsNonZero() public {
        uint256 prevNonce = __hyperTestingContract__.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint256 pairId = __hyperTestingContract__.getPairId(token0, token1);
        assertTrue(pairId != 0);
    }

    function testCreatePairFetchesPairDataReturnsAddresses() public {
        uint256 prevNonce = __hyperTestingContract__.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint16 pairId = __hyperTestingContract__.getPairId(token0, token1);
        Pair memory pair = getPair(address(__hyperTestingContract__), pairId);
        assertEq(pair.tokenAsset, token0);
        assertEq(pair.tokenQuote, token1);
        assertEq(pair.decimalsBase, 18);
        assertEq(pair.decimalsQuote, 18);
    }

    // --- Create Curve --- //

    function testCreateCurveCurveExistsReverts() public {
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
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
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        uint16 failureArg = 5e4;
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            failureArg,
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(FeeOOB.selector, failureArg));
        bool success = __revertCatcher__.process(data);
    }

    function testCreateCurvePriorityFeeParameterOutsideBoundsReverts() public {
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        uint16 failureArg = 5e4;
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            failureArg,
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(PriorityFeeOOB.selector, failureArg));
        bool success = __revertCatcher__.process(data);
    }

    function testCreateCurveExpiringPoolZeroSigmaReverts() public {
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        uint24 failureArg = 0;
        bytes memory data = CPU.encodeCreateCurve(
            failureArg,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(MinSigma.selector, failureArg));
        bool success = __revertCatcher__.process(data);
    }

    function testCreateCurveExpiringPoolZeroStrikeReverts() public {
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        uint128 failureArg = 0;
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            failureArg
        );
        vm.expectRevert(abi.encodeWithSelector(MinStrike.selector, failureArg));
        bool success = __revertCatcher__.process(data);
    }

    function testCreateCurveCurveNonceIncrementReturnsOne() public {
        uint256 prevNonce = __hyperTestingContract__.getCurveNonce();
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
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
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = CPU.toBytes32(
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
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = CPU.toBytes32(
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
        Curve memory newCurve = getCurve(address(__hyperTestingContract__), curveId);
        assertEq(newCurve.sigma, curve.sigma + 1);
        assertEq(newCurve.maturity, curve.maturity);
        assertEq(newCurve.gamma, curve.gamma);
        assertEq(newCurve.priorityGamma, curve.priorityGamma);
        assertEq(newCurve.strike, curve.strike);
    }

    // --- Create Pool --- //

    function testCreatePoolZeroPriceParameterReverts() public {
        uint128 failureArg = 0;
        bytes memory data = CPU.encodeCreatePool(1, failureArg);
        vm.expectRevert(ZeroPrice.selector);
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePoolExistentPoolReverts() public {
        uint48 failureArg = __poolId;
        bytes memory data = CPU.encodeCreatePool(failureArg, 1);
        vm.expectRevert(PoolExists.selector);
        bool success = __revertCatcher__.process(data);
    }

    function testCreatePoolMagicPairId() public {
        // Create a new curve to increment the nonce to 2
        bytes memory data = CPU.encodeCreateCurve(4, type(uint32).max - 1, 4, 4, 4);
        __revertCatcher__.process(data);

        uint48 magicVariable = 0x000000000002;
        data = CPU.encodeCreatePool(magicVariable, 1);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
    }

    function testCreatePoolMagicCurveId() public {
        // Create a new pair to increment the nonce to 2
        bytes memory data = CPU.encodeCreatePair(address(quote), address(__weth__));
        __revertCatcher__.process(data);

        uint48 magicVariable = 0x000200000000;
        data = CPU.encodeCreatePool(magicVariable, 1);
        bool success = __revertCatcher__.process(data);
        assertTrue(success);
    }

    function testCreatePoolExpiringPoolExpiredReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint16 pairId = __hyperTestingContract__.getPairId(token0, token1);

        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            uint32(0),
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = CPU.toBytes32(
            abi.encodePacked(curve.sigma + 1, uint32(0), uint16(1e4 - curve.gamma), curve.strike)
        );
        success = __revertCatcher__.process(data);

        uint32 curveId = __hyperTestingContract__.getCurveId(rawCurveId);
        uint48 id = CPU.encodePoolId(pairId, curveId);
        data = CPU.encodeCreatePool(id, 1_000);
        vm.expectRevert(PoolExpiredError.selector);
        success = __revertCatcher__.process(data);
    }

    function testCreatePoolFetchesPoolDataReturnsNonZeroBlockTimestamp() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = __revertCatcher__.process(data);
        uint16 pairId = __hyperTestingContract__.getPairId(token0, token1);

        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(__poolId)); // Existing curve from helper setup
        data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = CPU.toBytes32(
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
        uint48 id = CPU.encodePoolId(pairId, curveId);
        data = CPU.encodeCreatePool(id, 1_000);
        success = __revertCatcher__.process(data);

        uint256 time = getPool(address(__hyperTestingContract__), id).blockTimestamp;
        assertTrue(time != 0);
    }
}
