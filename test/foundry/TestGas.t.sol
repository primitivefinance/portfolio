// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";
import "forge-std/Test.sol";

contract TestGas is TestHyperSetup {
    function testGasAllocateExternal() public {
        __hyperTestingContract__.allocate(defaultScenario.poolId, 1 ether);
    }

    function testGasAllocateInternalBalance() public {
        __hyperTestingContract__.fund(address(defaultScenario.asset), 10 ether);
        __hyperTestingContract__.fund(address(defaultScenario.quote), 10 ether);
        __hyperTestingContract__.allocate(defaultScenario.poolId, 1 ether);
    }

    function testGasAllocateProcess() public {
        bytes memory data = Enigma.encodeAllocate(uint8(0), defaultScenario.poolId, 0x12, 0x01); // 1 ether
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "call failed");
    }

    function testGasAllocateProcessInternalBalance() public {
        __hyperTestingContract__.fund(address(defaultScenario.asset), 10 ether);
        __hyperTestingContract__.fund(address(defaultScenario.quote), 10 ether);
        bytes memory data = Enigma.encodeAllocate(uint8(0), defaultScenario.poolId, 0x12, 0x01); // 1 ether
        bool success = __revertCatcher__.process(data);
        assertTrue(success, "call failed");
    }
}
