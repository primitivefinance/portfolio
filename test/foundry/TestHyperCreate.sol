// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Vm.sol";
import "./setup/TestHyperSetup.sol";

contract TestHyperDeposit is TestHyperSetup {
    function testChangeParametersInvalidFeeReverts() public {
        uint16 failureArg = 2 ** 16 - 10;
        // create a mutable pool
        uint24 pairId = uint24(1);
        bytes memory createData = CPU.encodeCreatePool(
            pairId, // assumes first pair is created
            address(this),
            DEFAULT_FEE,
            DEFAULT_FEE,
            uint16(DEFAULT_SIGMA),
            DEFAULT_DURATION_DAYS,
            DEFAULT_JIT,
            DEFAULT_TICK,
            DEFAULT_PRICE
        );

        bool success = __revertCatcher__.process(createData);
        uint64 poolId = CPU.encodePoolId(pairId, true, uint32(__hyperTestingContract__.getPoolNonce()));

        vm.expectRevert(abi.encodeWithSelector(InvalidFee.selector, failureArg));
        __hyperTestingContract__.changeParameters(
            poolId,
            DEFAULT_FEE,
            failureArg,
            uint16(DEFAULT_SIGMA),
            DEFAULT_DURATION_DAYS,
            DEFAULT_JIT,
            DEFAULT_TICK
        );
    }
}
