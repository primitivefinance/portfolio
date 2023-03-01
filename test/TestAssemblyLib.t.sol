// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "contracts/libraries/AssemblyLib.sol";

contract TestAssemblyLib is Test {
    function test_fromAmount() public {
        {
            (uint8 power, uint128 base) = AssemblyLib.fromAmount(500);
            assertEq(power, 2);
            assertEq(base, 5);
        }
    }
}
