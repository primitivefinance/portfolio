// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

function isBetween(int256 value, int256 lower, int256 upper) pure returns (bool valid) {
    return _between(value, lower, upper);
}

function isBetween(uint256 value, uint256 lower, uint256 upper) pure returns (bool valid) {
    return _between(int256(value), int256(lower), int256(upper));
}

function _between(int256 value, int256 lower, int256 upper) pure returns (bool valid) {
    assembly {
        // Is `val` btwn lo and hi, inclusive?
        function isValid(val, lo, hi) -> btwn {
            btwn := iszero(sgt(mul(sub(val, lo), sub(val, hi)), 0)) // iszero(x > amount ? 1 : 0) ? true : false, (n - a) * (n - b) <= 0, n = amount, a = lower, b = upper
        }

        valid := isValid(value, lower, upper)
    }
}

/// @notice reverts if x > type(uint128).max
function toUint128(uint256 x) pure returns (uint128 z) {
    uint128 max = type(uint128).max;
    assembly {
        switch iszero(gt(x, max))
        case 0 {
            revert(0, 0)
        }
        case 1 {
            z := x
        }
    }
}

/**
 * todo: verify this is good to go
 */
function __computeDelta(uint256 input, int256 delta) pure returns (uint256 output) {
    assembly {
        switch slt(input, 0) // input < 0 ? 1 : 0
        case 0 {
            output := add(input, delta)
        }
        case 1 {
            output := sub(input, delta)
        }
    }
}

using {toUint128} for uint;
