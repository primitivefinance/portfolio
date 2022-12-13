// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

function isBetween(
    int256 value,
    int256 lower,
    int256 upper
) pure returns (bool valid) {
    return _between(value, lower, upper);
}

function isBetween(
    uint256 value,
    uint256 lower,
    uint256 upper
) pure returns (bool valid) {
    return _between(int256(value), int256(lower), int256(upper));
}

function _between(
    int256 value,
    int256 lower,
    int256 upper
) pure returns (bool valid) {
    assembly {
        // Is `val` btwn lo and hi, inclusive?
        function isValid(val, lo, hi) -> btwn {
            btwn := iszero(sgt(mul(sub(val, lo), sub(val, hi)), 0)) // iszero(x > amount ? 1 : 0) ? true : false, (n - a) * (n - b) <= 0, n = amount, a = lower, b = upper
        }

        valid := isValid(value, lower, upper)
    }
}
