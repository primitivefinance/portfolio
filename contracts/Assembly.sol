// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

error CastOverflow(uint);

uint constant SECONDS_PER_DAY = 86_400 seconds;
uint8 constant MIN_DECIMALS = 6;
uint8 constant MAX_DECIMALS = 18;

function isBetween(int256 value, int256 lower, int256 upper) pure returns (bool valid) {
    return __between(value, lower, upper);
}

function isBetween(uint256 value, uint256 lower, uint256 upper) pure returns (bool valid) {
    return __between(int256(value), int256(lower), int256(upper));
}

function __between(int256 value, int256 lower, int256 upper) pure returns (bool valid) {
    assembly {
        // Is `val` btwn lo and hi, inclusive?
        function isValid(val, lo, hi) -> btwn {
            btwn := iszero(sgt(mul(sub(val, lo), sub(val, hi)), 0)) // iszero(x > amount ? 1 : 0) ? true : false, (n - a) * (n - b) <= 0, n = amount, a = lower, b = upper
        }

        valid := isValid(value, lower, upper)
    }
}

error InvalidLiquidity();

function addSignedDelta(uint128 input, int128 delta) pure returns (uint128 output) {
    /* assembly {
        switch slt(input, 0) // input < 0 ? 1 : 0
        case 0 {
            output := add(input, delta)
        }
        case 1 {
            output := sub(input, delta)
        }
    } */

    if (delta < 0) {
        output = input - uint128(-delta);
        // liquidity going down, input should be larger
        if (output >= input) revert InvalidLiquidity();
    } else {
        output = input + uint128(delta);
        // liquidity going on, input should be smaller
        if (output < input) revert InvalidLiquidity();
    }
}

function computeCheckpoint(uint256 liveCheckpoint, uint256 checkpointChange) pure returns (uint256 nextCheckpoint) {
    nextCheckpoint = liveCheckpoint;

    if (checkpointChange != 0) {
        // overflow by design, as these are checkpoints, which can measure the distance even if overflowed.
        assembly {
            nextCheckpoint := add(liveCheckpoint, checkpointChange)
        }
    }
}

function computeCheckpointDistance(uint256 currentCheckpoint, uint256 prevCheckpoint) pure returns (uint256 distance) {
    // overflow by design, as these are checkpoints, which can measure the distance even if overflowed.
    assembly {
        distance := sub(currentCheckpoint, prevCheckpoint)
    }
}

function convertDaysToSeconds(uint amountDays) pure returns (uint amountSeconds) {
    assembly {
        amountSeconds := mul(amountDays, SECONDS_PER_DAY)
    }
}

/** @dev Converts an array of bytes into a byte32. */
function toBytes32(bytes memory raw) pure returns (bytes32 data) {
    assembly {
        data := mload(add(raw, 32))
        let shift := mul(sub(32, mload(raw)), 8)
        data := shr(shift, data)
    }
}

/** @dev Converts an array of bytes into a bytes16. */
function toBytes16(bytes memory raw) pure returns (bytes16 data) {
    assembly {
        data := mload(add(raw, 32))
        let shift := mul(sub(16, mload(raw)), 8)
        data := shr(shift, data)
    }
}

function separate(bytes1 data) pure returns (bytes1 upper, bytes1 lower) {
    upper = data >> 4;
    lower = data & 0x0f;
}

function pack(bytes1 upper, bytes1 lower) pure returns (bytes1 data) {
    data = (upper << 4) | lower;
}

/**
 * @dev             Converts an array of bytes into an uint128, the array must adhere
 *                  to the the following format:
 *                  - First byte: Amount of trailing zeros.
 *                  - Rest of the array: A hexadecimal number.
 */
function toAmount(bytes calldata raw) pure returns (uint128 amount) {
    uint8 power = uint8(raw[0]);
    amount = uint128(toBytes16(raw[1:raw.length]));
    if (power != 0) amount = amount * uint128(10 ** power);
}

function computeScalar(uint decimals) pure returns (uint scalar) {
    return 10 ** (MAX_DECIMALS - decimals);
}

function scaleToWad(uint amountDec, uint decimals) pure returns (uint outputWad) {
    uint factor = computeScalar(decimals);
    assembly {
        outputWad := mul(amountDec, factor)
    }
}

function scaleFromWadUp(uint amountWad, uint decimals) pure returns (uint outputDec) {
    uint factor = computeScalar(decimals);
    assembly {
        outputDec := add(div(amountWad, factor), 1)
    }
}

function scaleFromWadDown(uint amountWad, uint decimals) pure returns (uint outputDec) {
    uint factor = computeScalar(decimals);
    assembly {
        outputDec := div(amountWad, factor)
    }
}

function scaleFromWadUpSigned(int amountWad, uint decimals) pure returns (int outputDec) {
    uint factor = computeScalar(decimals);
    assembly {
        outputDec := add(sdiv(amountWad, factor), 1)
    }
}

function scaleFromWadDownSigned(int amountWad, uint decimals) pure returns (int outputDec) {
    uint factor = computeScalar(decimals);
    assembly {
        outputDec := sdiv(amountWad, factor)
    }
}
