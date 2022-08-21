// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

/// @title    Decoder Library
/// @dev      Solidity library to manipulate and covert bytes
/// @author   Primitive
library Decoder {
    /// @dev            Separates the nibbles of a byte into two bytes
    /// @param data     Byte to separate
    /// @return upper   Upper nibble
    /// @return lower   Lower nibble
    function separate(bytes1 data) internal pure returns (bytes1 upper, bytes1 lower) {
        upper = data >> 4;
        lower = data & 0x0f;
    }

    function pack(bytes1 upper, bytes1 lower) internal pure returns (bytes1 data) {
        data = (upper << 4) | lower;
    }

    /// @dev           Converts an array of bytes into a byte32
    /// @param raw     Array of bytes to convert
    /// @return data   Converted data
    function toBytes32(bytes memory raw) internal pure returns (bytes32 data) {
        assembly {
            data := mload(add(raw, 32))
            let shift := mul(sub(32, mload(raw)), 8)
            data := shr(shift, data)
        }
    }

    /// @dev           Converts an array of bytes into a bytes16.
    /// @param raw     Array of bytes to convert.
    /// @return data   Converted data.
    function toBytes16(bytes memory raw) internal pure returns (bytes16 data) {
        assembly {
            data := mload(add(raw, 32))
            let shift := mul(sub(16, mload(raw)), 8)
            data := shr(shift, data)
        }
    }

    /// @dev             Converts an array of bytes into an uint128, the array must adhere
    ///                  to the the following format:
    ///                  - First byte: Amount of trailing zeros.
    ///                  - Rest of the array: A hexadecimal number.
    /// @param raw       Array of bytes to convert.
    /// @return amount   Converted amount.
    function toAmount(bytes calldata raw) internal pure returns (uint128 amount) {
        uint8 power = uint8(raw[0]);
        amount = uint128(toBytes16(raw[1:raw.length]));
        amount = amount * uint128(10**power);
    }

    function runLengthEncode(uint256 amount) internal pure returns (uint256 encoded) {
        encoded = (countEndZeroes(amount));
    }

    function countEndZeroes(uint256 amount) internal pure returns (uint256) {
        uint256 n;

        while (amount % 10 == 0) {
            n++;
            amount = amount / 10;
        }

        return n;
    }

    function removeZeroes(uint256 amount) internal pure returns (uint256) {
        while (amount % 10 == 0) {
            amount /= 10;
        }

        return amount;
    }
}
