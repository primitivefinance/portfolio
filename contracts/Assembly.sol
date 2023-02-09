// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/**

  -------------

  Using yul to handle low-level conversions
  can easily be a foot shotgun.

  We like the gas reductions.

  -------------

  Primitive™

 */

error InvalidLiquidity();

uint constant SECONDS_PER_DAY = 86_400 seconds;
uint8 constant MIN_DECIMALS = 6;
uint8 constant MAX_DECIMALS = 18;

/**
 * @dev Returns true if `value` is between a range defined by `lower` and `upper` bounds
 * @param value Value to compare
 * @param lower Lower bound of the range
 * @param upper Upper bound of the range
 * @return valid True if the value is between the range
 * @custom:example
 * ```
 * bool valid = isBetween(50, 0, 100);
 * ```
 */
function isBetween(uint256 value, uint256 lower, uint256 upper) pure returns (bool valid) {
    assembly {
        valid := and(or(eq(value, lower), gt(value, lower)), or(eq(value, upper), lt(value, upper)))
    }
}

/**

    @dev Reference:

    if (delta < 0) {
        output = input - uint128(-delta);
        if (output >= input) revert InvalidLiquidity();
    } else {
        output = input + uint128(delta);
        if (output < input) revert InvalidLiquidity();
    }
*/
function addSignedDelta(uint128 input, int128 delta) pure returns (uint128 output) {
    bytes memory revertData = abi.encodeWithSelector(InvalidLiquidity.selector);
    assembly {
        output := add(input, delta)

        if gt(output, 0xffffffffffffffffffffffffffffffff) {
            revert(add(32, revertData), mload(revertData)) // 0x1fff9681
        }
    }
}

function computeCheckpoint(uint256 present, uint256 delta) pure returns (uint256 checkpoint) {
    checkpoint = present;

    if (delta != 0) {
        // overflow by design, as these are checkpoints, which can measure the distance even if overflowed.
        assembly {
            checkpoint := add(present, delta)
        }
    }
}

function computeCheckpointDistance(uint256 present, uint256 past) pure returns (uint256 distance) {
    // overflow by design, as these are checkpoints, which can measure the distance even if overflowed.
    assembly {
        distance := sub(present, past)
    }
}

function convertDaysToSeconds(uint amountDays) pure returns (uint amountSeconds) {
    assembly {
        amountSeconds := mul(amountDays, SECONDS_PER_DAY)
    }
}

function toBytes32(bytes memory raw) pure returns (bytes32 data) {
    assembly {
        data := mload(add(raw, 32))
        let shift := mul(sub(32, mload(raw)), 8)
        data := shr(shift, data)
    }
}

function toBytes16(bytes memory raw) pure returns (bytes16 data) {
    assembly {
        data := mload(add(raw, 32))
        let shift := mul(sub(16, mload(raw)), 8)
        data := shr(shift, data)
    }
}

/// @dev Separates the upper and lower bits of a byte
/// @param data Byte to separate
/// @return upper Upper bit of the byte
/// @return lower Lower bit of the byte
/// @custom:example
/// ```
/// (bytes1 upper, bytes1 lower) = separate(0x12);
/// ```
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
    return 10 ** (MAX_DECIMALS - decimals); // can revert on underflow
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
        outputDec := add(div(sub(amountWad, 1), factor), 1) // ((a-1) / b) + 1
    }
}

function scaleFromWadDown(uint amountWad, uint decimals) pure returns (uint outputDec) {
    uint factor = computeScalar(decimals);
    assembly {
        outputDec := div(amountWad, factor)
    }
}

function scaleFromWadUpSigned(int amountWad, uint decimals) pure returns (int outputDec) {
    int factor = int(computeScalar(decimals));
    assembly {
        outputDec := add(sdiv(sub(amountWad, 1), factor), 1) // ((a-1) / b) + 1
    }
}

function scaleFromWadDownSigned(int amountWad, uint decimals) pure returns (int outputDec) {
    int factor = int(computeScalar(decimals));
    assembly {
        outputDec := sdiv(amountWad, factor)
    }
}
