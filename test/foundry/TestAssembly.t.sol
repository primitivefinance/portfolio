// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../contracts/Assembly.sol" as Assembly;
import "forge-std/Test.sol";

contract AddSignedDelta {
    function addSignedDelta(uint128 input, int128 delta) public pure returns (uint128 output) {
        bytes memory revertData = abi.encodeWithSelector(Assembly.InvalidLiquidity.selector);
        assembly {
            output := add(input, delta)

            if gt(output, 0xffffffffffffffffffffffffffffffff) {
                revert(add(32, revertData), mload(revertData)) // 0x1fff9681
            }
        }
    }

    function addSignedDelta_ref(uint128 input, int128 delta) external pure returns (uint128 output) {
        if (delta < 0) {
            output = input - uint128(-delta);
            if (output >= input) revert Assembly.InvalidLiquidity();
        } else {
            output = input + uint128(delta);
            if (output < input) revert Assembly.InvalidLiquidity();
        }
    }
}

contract TestAssembly is Test {
    AddSignedDelta public target;

    function setUp() public {
        target = new AddSignedDelta();
    }

    function test_addSignedDelta_positive_delta(uint128 input, int128 delta) public {
        vm.assume(delta >= 0);

        if (uint256(input) + uint256(uint128(delta)) <= type(uint128).max) {
            uint128 output = target.addSignedDelta(input, delta);
            assertEq(output, input + uint128(delta));
        } else {
            vm.expectRevert();
            target.addSignedDelta(input, delta);
        }
    }

    function test_addSignedDelta_negative_delta(uint128 input, int128 delta) public {
        vm.assume(delta < 0);
        vm.assume(uint256(-int256(delta)) < 170141183460469231731687303715884105728);

        if (uint256(-int256(delta)) > uint256(input)) {
            vm.expectRevert();
            target.addSignedDelta(input, delta);
        } else {
            uint128 output = target.addSignedDelta(input, delta);
            assertEq(uint256(output), uint256(input) - uint256(int256(-delta)));
        }
    }

    function test_addSignedDelta_should_match(uint128 input, int128 delta) public {
        vm.assume(input > 0);
        vm.assume(delta > 0);
        vm.assume(input >= uint128(delta));
        vm.assume(uint256(input) + uint256(uint128(delta)) <= type(uint128).max);

        assertEq(target.addSignedDelta(input, delta), target.addSignedDelta_ref(input, delta));
    }

    function testAssembly_scaleFromWadUp_rounds_up_conditionally() public {
        uint256 input = 0.01 ether; // 16 decimals
        uint256 decimals = 2;
        uint256 actual = Assembly.scaleFromWadUp(input, decimals); // ((1e16 - 1) / 1e16) + 1 = 1
        uint256 expected = 1;
        assertEq(actual, expected, "unexpected-scale-from-wad-up-result");
    }

    function testAssembly_scaleFromWadUpSigned_rounds_up_conditionally() public {
        int256 input = int256(0.01 ether); // 16 decimals
        uint256 decimals = 2;
        int256 actual = Assembly.scaleFromWadUpSigned(input, decimals); // ((1e16 - 1) / 1e16) + 1 = 1
        int256 expected = 1;
        assertEq(actual, expected, "unexpected-scale-from-wad-up-result");
    }

    // todo: fix this test, it should pass
    /* function testAssembly_scaleFromWadUp_zero_returns_zero() public {
        uint256 input = 0;
        uint256 decimals = 6;
        uint256 actual = Assembly.scaleFromWadUp(input, decimals);
        uint256 expected = 0;
        assertEq(actual, expected, "non-zero-round-up");
    } */

    function testAssembly_scaleFromWadUp_equivalent_returns_input() public {
        uint256 decimals = 6;
        uint256 input = 10 ** (18 - decimals);
        uint256 actual = Assembly.scaleFromWadUp(input, decimals);
        uint256 expected = 1;
        assertEq(actual, expected, "non-equal");
    }

    function testAssembly_isBetween(uint256 value, uint256 lower, uint256 upper) public {
        if (value >= lower && value <= upper) {
            assertTrue(Assembly.isBetween(value, lower, upper));
        } else {
            assertFalse(Assembly.isBetween(value, lower, upper));
        }
    }
}
