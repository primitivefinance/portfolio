// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioChangeParameters is Setup {
    function testFuzz_changeParameters(
        uint16 priorityFee,
        uint16 fee,
        uint16 jit
    ) public defaultControlledConfig isArmed {
        uint64 poolId = ghost().poolId;
        fee = uint16(bound(fee, MIN_FEE, MAX_FEE));
        priorityFee = uint16(bound(priorityFee, 1, fee));
        jit = uint16(bound(jit, 1, JUST_IN_TIME_MAX));

        subject().changeParameters(poolId, priorityFee, fee, jit);
        PortfolioCurve memory actual = ghost().pool().params;
        assertEq(actual.priorityFee, priorityFee, "priorityFee");
        assertEq(actual.fee, fee, "fee");
        assertEq(actual.jit, jit, "jit");
    }

    function test_changeParameters_priority_fee_success()
        public
        defaultControlledConfig
        isArmed
    {
        uint64 poolId = ghost().poolId;
        uint16 prev = ghost().pool().params.priorityFee;
        subject().changeParameters(
            poolId, DEFAULT_PRIORITY_FEE + 10, DEFAULT_FEE + 20, 0
        );
        uint16 post = ghost().pool().params.priorityFee;
        assertEq(post, prev + 10, "priority-fee-change");
    }

    function test_revert_changeParameters_not_controller()
        public
        defaultControlledConfig
        isArmed
    {
        uint64 poolId = ghost().poolId;
        vm.expectRevert(NotController.selector);
        vm.prank(address(0x0006));
        subject().changeParameters(
            poolId, DEFAULT_PRIORITY_FEE, DEFAULT_FEE, DEFAULT_JIT
        );
    }

    function test_revert_changeParameters_invalid_jit()
        public
        defaultControlledConfig
        isArmed
    {
        uint64 poolId = ghost().poolId;
        uint16 failureArg = 10000;
        vm.expectRevert(abi.encodeWithSelector(InvalidJit.selector, failureArg));
        subject().changeParameters(
            poolId, DEFAULT_PRIORITY_FEE, DEFAULT_FEE, failureArg
        );
    }

    function test_revert_changeParameters_priority_fee_above_max()
        public
        defaultControlledConfig
        isArmed
    {
        uint64 poolId = ghost().poolId;
        PortfolioCurve memory curve = PortfolioCurve({
            maxPrice: DEFAULT_STRIKE,
            jit: DEFAULT_JIT,
            fee: 55,
            duration: DEFAULT_DURATION,
            volatility: DEFAULT_VOLATILITY,
            priorityFee: 56,
            createdAt: 100000000
        });
        (, bytes memory revertData) = curve.checkParameters();
        assertEq(
            revertData,
            abi.encodeWithSelector(InvalidFee.selector, curve.priorityFee)
        );
        vm.expectRevert(revertData);
        subject().changeParameters(
            poolId, curve.priorityFee, curve.fee, curve.jit
        );
    }

    function test_revert_changeParameters_invalid_fee()
        public
        defaultControlledConfig
        isArmed
    {
        uint16 failureArg = 2 ** 16 - 10;
        uint64 poolId = ghost().poolId;
        vm.expectRevert(abi.encodeWithSelector(InvalidFee.selector, failureArg));
        subject().changeParameters(poolId, DEFAULT_FEE, failureArg, DEFAULT_JIT);
    }
}
