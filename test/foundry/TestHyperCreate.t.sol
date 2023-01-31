// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Vm.sol";
import "./setup/TestHyperSetup.sol";

contract TestHyperCreate is TestHyperSetup {
    function testFuzzCreatePoolExternal(
        uint16 priorityFee,
        uint16 fee,
        uint16 jit,
        uint16 duration,
        uint16 volatility,
        int24 maxTick,
        uint128 price
    ) public {
        fee = uint16(bound(fee, MIN_FEE, MAX_FEE));
        priorityFee = uint16(bound(priorityFee, 1, fee));
        jit = uint16(bound(jit, 1, JUST_IN_TIME_MAX));
        duration = uint16(bound(duration, MIN_DURATION, MAX_DURATION));
        volatility = uint16(bound(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
        maxTick = int24(bound(maxTick, -MAX_TICK, MAX_TICK));
        vm.assume(price > 0);
        vm.assume(maxTick != 0); // todo: fix once maxTick fixes check for 0 tick.

        uint64 poolId = __hyperTestingContract__.createPool(
            uint24(1),
            address(this),
            priorityFee,
            fee,
            volatility,
            duration,
            jit,
            maxTick,
            price
        );

        HyperPool memory pool = _getPool(hs(), poolId);
        HyperCurve memory actual = pool.params;

        assertEq(pool.controller, address(this), "controller");
        assertEq(actual.priorityFee, priorityFee, "priorityFee");
        assertEq(actual.fee, fee, "fee");
        assertEq(actual.volatility, volatility, "volatility");
        assertEq(actual.duration, duration, "duration");
        assertEq(actual.jit, jit, "jit");
        assertEq(actual.maxTick, maxTick, "maxTick");
    }

    function testFuzzCreatePol(
        uint16 priorityFee,
        uint16 fee,
        uint16 jit,
        uint16 duration,
        uint16 volatility,
        int24 maxTick,
        uint128 price
    ) public {
        fee = uint16(bound(fee, MIN_FEE, MAX_FEE));
        priorityFee = uint16(bound(priorityFee, 1, fee));
        jit = uint16(bound(jit, 1, JUST_IN_TIME_MAX));
        duration = uint16(bound(duration, MIN_DURATION, MAX_DURATION));
        volatility = uint16(bound(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
        maxTick = int24(bound(maxTick, -MAX_TICK, MAX_TICK));
        vm.assume(price > 0);
        vm.assume(maxTick != 0); // todo: fix once maxTick fixes check for 0 tick.
        bytes memory data = Enigma.encodeCreatePool(
            uint24(1),
            address(this),
            priorityFee,
            fee,
            volatility,
            duration,
            jit,
            maxTick,
            price
        );
        bool success = __revertCatcher__.process(data);
        uint64 poolId = Enigma.encodePoolId(uint24(1), true, uint32(__hyperTestingContract__.getPoolNonce()));

        HyperPool memory pool = _getPool(hs(), poolId);
        HyperCurve memory actual = pool.params;

        assertTrue(success, "fuzz create pool failed");
        assertEq(pool.controller, address(this), "controller");
        assertEq(actual.priorityFee, priorityFee, "priorityFee");
        assertEq(actual.fee, fee, "fee");
        assertEq(actual.volatility, volatility, "volatility");
        assertEq(actual.duration, duration, "duration");
        assertEq(actual.jit, jit, "jit");
        assertEq(actual.maxTick, maxTick, "maxTick");
    }

    function testCreatePoolNonControlledHasDefaultJit() public {
        __hyperTestingContract__.setJitPolicy(JUST_IN_TIME_LIQUIDITY_POLICY); // for assertion below.
        bytes memory data = Enigma.encodeCreatePool(uint24(1), address(0), 1, 100, 100, 100, 100, 100, 100);
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "create failed");
        uint64 poolId = Enigma.encodePoolId(uint24(1), false, uint32(__hyperTestingContract__.getPoolNonce()));
        assertEq(_getPool(hs(), poolId).params.jit, JUST_IN_TIME_LIQUIDITY_POLICY);
    }

    function testCreatePoolZeroPriceReverts() public {
        bytes memory data = Enigma.encodeCreatePool(uint24(1), address(this), 1, 1, 1, 1, 1, 1, 0);
        vm.expectRevert(ZeroPrice.selector);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    function testCreatePoolPriorityFeeInvalidFeeReverts() public {
        bytes memory data = Enigma.encodeCreatePool(uint24(1), address(this), 0, 1, 1, 1, 1, 1, 1);
        vm.expectRevert(abi.encodeWithSelector(InvalidFee.selector, 0));
        bool success = __revertCatcher__.process(data);
        assertTrue(!success);
    }

    function testFuzzChangeParameters(
        uint16 priorityFee,
        uint16 fee,
        uint16 jit,
        uint16 duration,
        uint16 volatility,
        int24 maxTick
    ) public {
        uint64 poolId = _createDefaultPool();
        fee = uint16(bound(fee, MIN_FEE, MAX_FEE));
        priorityFee = uint16(bound(priorityFee, 1, fee));
        jit = uint16(bound(jit, 1, JUST_IN_TIME_MAX));
        duration = uint16(bound(duration, MIN_DURATION, MAX_DURATION));
        volatility = uint16(bound(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
        maxTick = int24(bound(maxTick, -MAX_TICK, MAX_TICK));
        vm.assume(maxTick != 0); // todo: fix once maxTick fixes check for 0 tick.

        __hyperTestingContract__.changeParameters(poolId, priorityFee, fee, volatility, duration, jit, maxTick);
        HyperCurve memory actual = _getPool(hs(), poolId).params;
        assertEq(actual.priorityFee, priorityFee, "priorityFee");
        assertEq(actual.fee, fee, "fee");
        assertEq(actual.volatility, volatility, "volatility");
        assertEq(actual.duration, duration, "duration");
        assertEq(actual.jit, jit, "jit");
        assertEq(actual.maxTick, maxTick, "maxTick");
    }

    function testChangeParametersPriorityFeeSuccess() public {
        uint64 poolId = _createDefaultPool();
        uint16 prev = _getPool(hs(), poolId).params.priorityFee;
        __hyperTestingContract__.changeParameters(poolId, DEFAULT_FEE + 10, DEFAULT_FEE + 20, 0, 0, 0, 0);
        uint16 post = _getPool(hs(), poolId).params.priorityFee;
        assertEq(post, prev + 10, "priority-fee-change");
    }

    function testChangeParametersSuccessKeepsPoolSolvency() public {
        uint64 poolId = _createDefaultPool();
        (uint prev0, uint prev1) = __hyperTestingContract__.getVirtualReserves(poolId);
        __hyperTestingContract__.changeParameters(
            poolId,
            0,
            0,
            DEFAULT_VOLATILITY * 2,
            DEFAULT_DURATION + 30,
            0,
            DEFAULT_TICK + 500
        );
        (uint post0, uint post1) = __hyperTestingContract__.getVirtualReserves(poolId);
        assertEq(post0, prev0, "virtual-asset-balance-altered");
        assertEq(post1, prev1, "virtual-quote-balance-altered");
    }

    function testChangeParametersNotControllerReverts() public {
        uint64 poolId = _createDefaultPool();
        uint16 failureArg = 1;
        vm.expectRevert(NotController.selector);
        vm.prank(address(0x0006));
        __hyperTestingContract__.changeParameters(
            poolId,
            DEFAULT_FEE,
            DEFAULT_FEE,
            DEFAULT_VOLATILITY,
            DEFAULT_DURATION,
            DEFAULT_JIT,
            DEFAULT_TICK
        );
    }

    function testChangeParametersInvalidVolatilityReverts() public {
        uint64 poolId = _createDefaultPool();
        uint16 failureArg = 1;
        vm.expectRevert(abi.encodeWithSelector(InvalidVolatility.selector, failureArg));
        __hyperTestingContract__.changeParameters(
            poolId,
            DEFAULT_FEE,
            DEFAULT_FEE,
            1,
            DEFAULT_DURATION,
            DEFAULT_JIT,
            DEFAULT_TICK
        );
    }

    function testChangeParametersInvalidDurationReverts() public {
        uint64 poolId = _createDefaultPool();
        uint16 failureArg = 5000;
        vm.expectRevert(abi.encodeWithSelector(InvalidDuration.selector, failureArg));
        __hyperTestingContract__.changeParameters(
            poolId,
            DEFAULT_FEE,
            DEFAULT_FEE,
            DEFAULT_VOLATILITY,
            5000,
            DEFAULT_JIT,
            DEFAULT_TICK
        );
    }

    function testChangeParametersInvalidTickReverts() public {
        uint64 poolId = _createDefaultPool();
        int24 failureArg = 1000000;
        vm.expectRevert(abi.encodeWithSelector(InvalidTick.selector, uint24(failureArg)));
        __hyperTestingContract__.changeParameters(
            poolId,
            DEFAULT_FEE,
            DEFAULT_FEE,
            DEFAULT_VOLATILITY,
            DEFAULT_DURATION,
            DEFAULT_JIT,
            failureArg
        );
    }

    function testChangeParametersInvalidJitReverts() public {
        uint64 poolId = _createDefaultPool();
        uint16 failureArg = 10000;
        vm.expectRevert(abi.encodeWithSelector(InvalidJit.selector, failureArg));
        __hyperTestingContract__.changeParameters(
            poolId,
            DEFAULT_FEE,
            DEFAULT_FEE,
            DEFAULT_VOLATILITY,
            DEFAULT_DURATION,
            failureArg,
            DEFAULT_TICK
        );
    }

    function testChangeParametersPriorityFeeAboveFeeReverts() public {
        uint64 poolId = _createDefaultPool();
        HyperCurve memory curve = HyperCurve({
            maxTick: DEFAULT_TICK,
            jit: DEFAULT_JIT,
            fee: 55,
            duration: DEFAULT_DURATION,
            volatility: DEFAULT_VOLATILITY,
            priorityFee: 56,
            createdAt: 100000000
        });
        (, bytes memory revertData) = curve.checkParameters();
        assertEq(revertData, abi.encodeWithSelector(InvalidFee.selector, curve.priorityFee));
        vm.expectRevert(revertData);
        __hyperTestingContract__.changeParameters(
            poolId,
            curve.priorityFee,
            curve.fee,
            curve.volatility,
            curve.duration,
            curve.jit,
            curve.maxTick
        );
    }

    function testChangeParametersInvalidFeeReverts() public {
        uint16 failureArg = 2 ** 16 - 10;
        uint64 poolId = _createDefaultPool();
        vm.expectRevert(abi.encodeWithSelector(InvalidFee.selector, failureArg));
        __hyperTestingContract__.changeParameters(
            poolId,
            DEFAULT_FEE,
            failureArg,
            DEFAULT_VOLATILITY,
            DEFAULT_DURATION,
            DEFAULT_JIT,
            DEFAULT_TICK
        );
    }

    function _createDefaultPool() internal returns (uint64 poolId) {
        uint24 pairId = uint24(1);
        bytes memory createData = Enigma.encodeCreatePool(
            pairId, // assumes first pair is created
            address(this),
            DEFAULT_FEE,
            DEFAULT_FEE,
            DEFAULT_VOLATILITY,
            DEFAULT_DURATION,
            DEFAULT_JIT,
            DEFAULT_TICK,
            DEFAULT_PRICE
        );
        bool success = __revertCatcher__.process(createData);
        assertTrue(success, "did not create pool");

        poolId = Enigma.encodePoolId(pairId, true, uint32(__hyperTestingContract__.getPoolNonce()));
    }

    bytes arithmeticError = abi.encodeWithSelector(0x4e487b71, 0x11); // 0x4e487b71 is Panic(uint256), and 0x11 is the panic code for arithmetic overflow.

    function testCreateAboveMaxPairs_Reverts() public {
        bytes32 slot = bytes32(uint(5)); // slot is packed so has the pair + pool nonces.
        vm.store(address(__hyperTestingContract__), slot, bytes32(type(uint256).max)); // just set the whole slot of 0xf...
        assertEq(__hyperTestingContract__.getPairNonce(), type(uint24).max, "not set to max value");
        address token = address(new TestERC20("t", "t", 18));
        bytes memory payload = Enigma.encodeCreatePair(address(defaultScenario.asset), token);
        vm.expectRevert(arithmeticError);
        bool success = __revertCatcher__.process(payload);
        assertTrue(!success, "created a pair at max pairId");
    }

    function testCreateAboveMaxPools_Reverts() public {
        bytes32 slot = bytes32(uint(5)); // slot is packed so has the pair + pool nonces.
        vm.store(address(__hyperTestingContract__), slot, bytes32(type(uint256).max)); // just set the whole slot of 0xf...
        assertEq(__hyperTestingContract__.getPoolNonce(), type(uint32).max, "not set to max value");

        address token = address(new TestERC20("t", "t", 18));
        bytes memory data = Enigma.encodeCreatePool(uint24(1), address(0), 1, 100, 100, 100, 100, 100, 100);

        vm.expectRevert(arithmeticError);
        bool success = __revertCatcher__.process(data);
        assertTrue(!success, "created a pool at max poolId");
    }
}
