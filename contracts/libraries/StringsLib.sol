// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Math } from "openzeppelin/utils/math/Math.sol";

/**
 * @dev Modified version of:
 * OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)
 *
 * Some of these functions are not really optimized, but since they are not
 * supposed to be used onchain it doesn't really matter.
 */
library StringsLib {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    function toHexColor(bytes3 value) internal pure returns (string memory) {
        bytes memory result = new bytes(6);

        for (uint256 i = 0; i < 3; i++) {
            result[i * 2] = _SYMBOLS[uint8(value[i] >> 4)];
            result[i * 2 + 1] = _SYMBOLS[uint8(value[i] & 0x0F)];
        }

        return string.concat("#", string(result));
    }

    function toCountdown(uint256 deadline)
        internal
        view
        returns (string memory)
    {
        uint256 timeLeft = deadline - block.timestamp;
        uint256 daysLeft = timeLeft / 86400;
        uint256 hoursLeft = (timeLeft % 86400) / 3600;
        uint256 minutesLeft = (timeLeft % 3600) / 60;
        uint256 secondsLeft = timeLeft % 60;

        // TODO: Fix the plurals
        if (daysLeft >= 1) {
            return (string.concat("Expires in ", toString(daysLeft), " days"));
        }

        if (hoursLeft >= 1) {
            return (string.concat("Expires in ", toString(hoursLeft), " hours"));
        }

        if (minutesLeft >= 1) {
            return (
                string.concat("Expires in ", toString(minutesLeft), " minutes")
            );
        }

        return (string.concat("Expires in ", toString(secondsLeft), " seconds"));
    }
}
