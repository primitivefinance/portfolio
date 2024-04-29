// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import { BASIS_POINT_DIVISOR, MAX_DECIMALS, WAD } from "./ConstantsLib.sol";

/**
 * @title
 * AssemblyLib
 *
 * @author
 * Primitive™
 *
 * @notice
 * Yul implementations of the most used functions in Portfolio.
 *
 * @dev
 * Free functions are nice for user-defined types since `using for` can utilize the `global` keyword.
 * Since this library only implements functions for native solidity types, it's better as a `library`.
 */
library AssemblyLib {
    /**
     * @dev
     * Returns true if `value` is between a range defined by `lower` and `upper` bounds.
     *
     * @custom:example
     * ```
     * bool valid = isBetween(50, 0, 100);
     * assertTrue(value);
     * ```
     *
     * @param value Value to compare.
     * @param lower Inclusive lower bound of the range.
     * @param upper Inclusive upper bound of the range.
     * @return valid True if the value is between the range.
     */
    function isBetween(
        uint256 value,
        uint256 lower,
        uint256 upper
    ) internal pure returns (bool valid) {
        assembly {
            valid :=
                and(
                    or(eq(value, lower), gt(value, lower)),
                    or(eq(value, upper), lt(value, upper))
                )
        }
    }

    /// @dev Returns the smaller of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to `result = (a < b) ? a : b`
        assembly {
            result := sub(a, mul(sub(a, b), gt(a, b)))
        }
    }

    /// @dev Returns the larger of two numbers.
    function max(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to: `result = (a < b) ? b : a`
        assembly {
            result := sub(a, mul(sub(a, b), lt(a, b)))
        }
    }

    /**
     * @dev
     * Adds a signed `delta` to an unsigned `input`.
     *
     * @custom:example
     * ```
     * uint128 output = addSignedDelta(uint128(15), -int128(5));
     * assertEq(output, uint128(10));
     * ```
     *
     * @return output The result of the signed addition.
     */
    function addSignedDelta(
        uint128 input,
        int128 delta
    ) internal pure returns (uint128 output) {
        if (delta > 0) {
            output = input + uint128(delta);
        } else {
            output = input - uint128(-delta);
        }
    }

    /// @dev Safely casts an unsigned 128-bit integer into a signed 128-bit integer.
    function toInt128(uint128 a) internal pure returns (int128 b) {
        assembly {
            // Reverts on overflow.
            if gt(a, 0x7fffffffffffffffffffffffffffffff) { revert(0, 0) }

            b := a
        }
    }

    /// @dev Used as a scalar to convert between units of native token decimals and WAD.
    function computeScalar(uint256 decimals)
        internal
        pure
        returns (uint256 scalar)
    {
        return 10 ** (MAX_DECIMALS - decimals); // can revert on underflow
    }

    /// @dev Converts a value in native token decimals to WAD units.
    function scaleToWad(
        uint256 amountDec,
        uint256 decimals
    ) internal pure returns (uint256 outputWad) {
        uint256 factor = computeScalar(decimals);
        assembly {
            outputWad := mul(amountDec, factor)
        }
    }

    /// @dev Converts a value in WAD units to native token decimals, rounded down.
    function scaleFromWadDown(
        uint256 amountWad,
        uint256 decimals
    ) internal pure returns (uint256 outputDec) {
        uint256 factor = computeScalar(decimals);
        assembly {
            outputDec := div(amountWad, factor)
        }
    }

    /// @dev Converts a value in WAD units to native token decimals, rounded up.
    function scaleFromWadUp(
        uint256 amountWad,
        uint256 decimals
    ) internal pure returns (uint256 outputDec) {
        if (amountWad == 0) return 0;

        uint256 factor = computeScalar(decimals);
        outputDec = (amountWad - 1) / factor + 1; // ((a-1) / b) + 1
    }

    /// @dev Converts basis points (1 = 0.01%) to percentages in WAD units (1E18 = 100%).
    function bpsToPercentWad(uint256 bps)
        internal
        pure
        returns (uint256 percentage)
    {
        assembly {
            percentage := div(mul(bps, WAD), BASIS_POINT_DIVISOR)
        }
    }

    /// @dev Reverts if `x` cannot fit inside a uint16.
    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    /// @dev Packs 4 bits into the upper and lower sections of a byte (8-bits).
    function pack(
        bytes1 upper,
        bytes1 lower
    ) internal pure returns (bytes1 data) {
        data = upper << 4 | (lower & 0x0F);
    }

    /// @dev Separates the upper 4 and lower 4 bits of a byte (8-bits).
    function separate(bytes1 data)
        internal
        pure
        returns (bytes1 upper, bytes1 lower)
    {
        upper = data >> 4;
        lower = data & 0x0f;
    }

    /**
     * @notice Computes the difference between two checkpoints.
     * @dev Underflows.
     * @custom:example
     * ```
     * uint256 distance = computeCheckpointDistance(50, 25);
     * assertEq(distance, 25);
     * ```
     */
    function computeCheckpointDistance(
        uint256 present,
        uint256 past
    ) internal pure returns (uint256 distance) {
        // Underflow by design, as these are checkpoints which can measure the distance even if underflowed.
        assembly {
            distance := sub(present, past)
        }
    }
}
