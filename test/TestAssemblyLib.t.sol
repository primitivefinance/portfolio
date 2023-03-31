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

    function testFuzz_isBetween(uint256 value, uint256 lower, uint256 upper) public {
        vm.assume(lower <= upper);
        bool valid = AssemblyLib.isBetween(value, lower, upper);

        if (value >= lower && value <= upper) {
            assertTrue(valid);
        } else {
            assertFalse(valid);
        }
    }

    /*
    FIXME: These tests are not working yet.
    function testFuzz_addSignedDelta(uint128 input, int128 delta) public {
        assertEq(
            AssemblyLib.addSignedDelta(input, delta),
            delta < 0 ? uint128(-delta) : uint128(delta)
        );
    }
    */

    function testFuzz_separate(uint8 a, uint8 b) public {
        vm.assume(a <= 15);
        vm.assume(b <= 15);
        bytes1 data = AssemblyLib.pack(bytes1(a), bytes1(b));
        (bytes1 a_, bytes1 b_) = AssemblyLib.separate(data);
        assertEq(a, uint8(a_));
        assertEq(b, uint8(b_));
    }

    /*
    function test_trimBytes() public {
        bytes memory output = AssemblyLib.trimBytes(abi.encode(2));
        assertEq(output, hex"02");
    }
    */

    function test_pack() public {
        bytes1 output = AssemblyLib.pack(bytes1(0x01), bytes1(0x02));
        assertEq(output, bytes1(0x12));
    }

    function test_pack_dirtyBits() public {
        bytes1 output = AssemblyLib.pack(bytes1(0x11), bytes1(0x22));
        assertEq(output, bytes1(0x12));
    }
}
