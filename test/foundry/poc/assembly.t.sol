// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract AssemblyTest is Test {
    function addSignedDelta(uint128 input, int128 delta) public pure returns (uint128 output) {
        bytes memory revertData = abi.encodeWithSelector("abcd");
        assembly {
            switch slt(delta, 0) // delta < 0 ? 1 : 0
            // negative delta
            case 1 {
                output := sub(input, add(not(delta), 1))
                switch lt(output, input) // output < input ? 1 : 0
                case 0 {
                    // not less than
                    revert(add(32, revertData), mload(revertData)) // 0x1fff9681
                }
            }
            // position delta
            case 0 {
                output := add(input, delta)
                switch lt(output, input) // (output < input ? 1 : 0) == 0 ? 1 : 0
                case 1 {
                    // less than
                    revert(add(32, revertData), mload(revertData)) // 0x1fff9681
                }
            }
        }
    }

    function test_slt() public {
        int128 intMax = type(int128).max;
        uint128 max = uint128(type(int128).max);
        uint128 uintMax = type(uint128).max;
        assertEq(addSignedDelta(0, 1), 1);
        assertEq(addSignedDelta(1, 10), 11);
        assertEq(addSignedDelta(11, -1), 10);
        assertEq(addSignedDelta(10, -10), 0);
        assertEq(addSignedDelta(0, intMax), max);

        // should not through because of overflow
        uint256 maxCheck = uint256(uintMax) + uint256(max);

        //vm.expectRevert();
        //addSignedDelta(0, -1);

        //vm.expectRevert();
        //addSignedDelta(uintMax, 2);
    }

    function toBytes32(bytes memory raw) public pure returns (bytes32 data) {
        assembly {
            data := mload(add(raw, 32))
            let shift := mul(sub(32, mload(raw)), 8)
            data := shr(shift, data)
        }
    }

    function test_bytes32() public {
        bytes memory value = abi.encodePacked("Checking if the length of bytes is more than 32 then above funtion returns 0 bytes or not");
        bytes memory small = abi.encodePacked("Checking");
        bytes32 r = toBytes32(value);
        console.logBytes(value);
        console.logBytes32(r);

        bytes32 rs = toBytes32(small);
        console.logBytes(small);
        console.logBytes32(rs);
    }

    function pack(bytes1 upper, bytes1 lower) public pure returns (bytes1 data) {
        data = (upper << 4) | lower;
    }

    function test_pack() public {
        bytes1 u = 0xab;
        bytes1 l = 0xcd;

        bytes1 packed = pack(u, l);
        console.logBytes1(packed);
    }

    function toBytes16(bytes memory raw) public pure returns (bytes16 data) {
        assembly {
            data := mload(add(raw, 32))
            let shift := mul(sub(16, mload(raw)), 8)
            data := shr(shift, data)
        }
    }

    function toAmount(bytes calldata raw) public pure returns (uint128 amount) {
        uint8 power = uint8(raw[0]);
        amount = uint128(toBytes16(raw[1:raw.length]));
        if (power != 0) amount = amount * uint128(10 ** power);
    }

    function test_amount() public {
        bytes memory encoded = abi.encodePacked(uint8(0), type(uint128).max);
        uint128 amount = this.toAmount(encoded);
        console.log("Value returned by the toAmount: %s", amount);
    }

    function scaleFromWadDownSigned(int amountWad) public pure returns (int outputDec) {
        uint factor = 10**12;
        assembly {
            outputDec := sdiv(amountWad, factor)
        }
    }

    event Value(int256 amount);

    function test_scale() public {
        int256 wad = -10**18;
        int256 dec = scaleFromWadDownSigned(wad);
        emit Value(dec);
    }
}
