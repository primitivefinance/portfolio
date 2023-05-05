// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

error InvalidLiquidity();
error InvalidDays();
error DataTooLong();

uint256 constant SECONDS_PER_YEAR = 31556953 seconds;
uint256 constant SECONDS_PER_DAY = 86_400 seconds;
uint8 constant MIN_DECIMALS = 6;
uint8 constant MAX_DECIMALS = 18;

/**
 * @title   AssemblyLib
 * @author  Primitive™
 * @notice  Yul implementations of the most used functions in Portfolio.
 * @dev     Free functions are nice for user-defined types since `using for` can utilize the `global` keyword.
 *          Since this library only implements functions for native solidity types, it's better as a `library`.
 */
library AssemblyLib {
    /**
     * @dev Returns true if `value` is between a range defined by `lower` and `upper` bounds.
     * @param value Value to compare.
     * @param lower Inclusive lower bound of the range.
     * @param upper Inclusive upper bound of the range.
     * @return valid True if the value is between the range.
     * @custom:example
     * ```
     * bool valid = isBetween(50, 0, 100);
     * assertTrue(value);
     * ```
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

    /**
     * @dev Returns the smaller of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to `result = (a < b) ? a : b`
        assembly {
            result := sub(a, mul(sub(a, b), gt(a, b)))
        }
    }

    /**
     * @dev Returns the larger of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to: `result = (a < b) ? b : a`
        assembly {
            result := sub(a, mul(sub(a, b), lt(a, b)))
        }
    }

    /**
     * @dev Adds a signed `delta` to an unsigned `input`.
     * @custom:example
     * ```
     * uint128 output = addSignedDelta(uint128(15), -int128(5));
     * assertEq(output, uint128(10));
     * ```
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

    /**
     * @notice Days units are used in Portfolio because they fit into an unsigned 16-bit integer and they
     * are human readable.
     * @dev Reverts on overflow.
     */
    function convertDaysToSeconds(uint256 amountDays)
        internal
        pure
        returns (uint256 amountSeconds)
    {
        bytes memory revertData = abi.encodeWithSelector(InvalidDays.selector);
        assembly {
            amountSeconds := mul(amountDays, SECONDS_PER_DAY)
            // Reverts on overflow.
            if gt(amountSeconds, 0xffffffffffffffffffffffffffffffff) {
                revert(add(32, revertData), mload(revertData))
            }
        }
    }

    /**
     * @dev Safely casts an unsigned 128-bit integer into a signed 128-bit integer.
     * Reverts on overflow.
     */
    function toInt128(uint128 a) internal pure returns (int128 b) {
        assembly {
            // Reverts on overflow.
            if gt(a, 0x7fffffffffffffffffffffffffffffff) { revert(0, 0) }

            b := a
        }
    }

    /**
     * @dev Scalars are used to convert token amounts between the token's decimal units
     * and WAD (10^18) units.
     */
    function computeScalar(uint256 decimals)
        internal
        pure
        returns (uint256 scalar)
    {
        return 10 ** (MAX_DECIMALS - decimals); // can revert on underflow
    }

    function scaleToWad(
        uint256 amountDec,
        uint256 decimals
    ) internal pure returns (uint256 outputWad) {
        uint256 factor = computeScalar(decimals);
        assembly {
            outputWad := mul(amountDec, factor)
        }
    }

    function scaleFromWadDown(
        uint256 amountWad,
        uint256 decimals
    ) internal pure returns (uint256 outputDec) {
        uint256 factor = computeScalar(decimals);
        assembly {
            outputDec := div(amountWad, factor)
        }
    }

    function scaleFromWadUp(
        uint256 amountWad,
        uint256 decimals
    ) internal pure returns (uint256 outputDec) {
        if (amountWad == 0) return 0;

        uint256 factor = computeScalar(decimals);
        outputDec = (amountWad - 1) / factor + 1; // ((a-1) / b) + 1
    }
}
