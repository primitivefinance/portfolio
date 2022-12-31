// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

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

error CastOverflow(uint);

/// @notice reverts if x > type(uint128).max
function toUint128(uint256 x) pure returns (uint128 z) {
    bytes memory revertData = abi.encodeWithSelector(CastOverflow.selector, x);
    uint128 max = type(uint128).max;
    assembly {
        switch iszero(gt(x, max)) // if x > max, if iszero(1) == case = 0, else iszero(0) == case = 1
        case 0 {
            let revertDataSize := mload(revertData)
            revert(add(32, revertData), revertDataSize)
        }
        case 1 {
            z := x
        }
    }
}

function toUint16(uint256 x) pure returns (uint16 z) {
    bytes memory revertData = abi.encodeWithSelector(CastOverflow.selector, x);
    uint16 max = type(uint16).max;
    assembly {
        switch iszero(gt(x, max)) // if x > max, if iszero(1) == case = 0, else iszero(0) == case = 1
        case 0 {
            let revertDataSize := mload(revertData)
            revert(add(32, revertData), revertDataSize)
        }
        case 1 {
            z := x
        }
    }
}

function toUint24(uint256 x) pure returns (uint24 z) {
    bytes memory revertData = abi.encodeWithSelector(CastOverflow.selector, x);
    uint24 max = type(uint24).max;
    assembly {
        switch iszero(gt(x, max)) // if x > max, if iszero(1) == case = 0, else iszero(0) == case = 1
        case 0 {
            let revertDataSize := mload(revertData)
            revert(add(32, revertData), revertDataSize)
        }
        case 1 {
            z := x
        }
    }
}

function toUint32(uint256 x) pure returns (uint32 z) {
    bytes memory revertData = abi.encodeWithSelector(CastOverflow.selector, x);
    uint32 max = type(uint32).max;
    assembly {
        switch iszero(gt(x, max)) // if x > max, if iszero(1) == case = 0, else iszero(0) == case = 1
        case 0 {
            let revertDataSize := mload(revertData)
            revert(add(32, revertData), revertDataSize)
        }
        case 1 {
            z := x
        }
    }
}

function toUint48(uint256 x) pure returns (uint48 z) {
    bytes memory revertData = abi.encodeWithSelector(CastOverflow.selector, x);
    uint48 max = type(uint48).max;
    assembly {
        switch iszero(gt(x, max)) // if x > max, if iszero(1) == case = 0, else iszero(0) == case = 1
        case 0 {
            let revertDataSize := mload(revertData)
            revert(add(32, revertData), revertDataSize)
        }
        case 1 {
            z := x
        }
    }
}

/**
 * todo: verify this is good to go
 */
/* function __computeDelta(uint256 input, int256 delta) pure returns (uint256 output) {
    assembly {
        switch slt(input, 0) // input < 0 ? 1 : 0
        case 0 {
            output := add(input, delta)
        }
        case 1 {
            output := sub(input, delta)
        }
    }
} */

function __computeDelta(uint128 input, int128 delta) pure returns (uint128 output) {
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

function __computeCheckpoint(uint256 liveCheckpoint, uint256 checkpointChange) pure returns (uint256 nextCheckpoint) {
    nextCheckpoint = liveCheckpoint;

    if (checkpointChange != 0) {
        // overflow by design, as these are checkpoints, which can measure the distance even if overflowed.
        assembly {
            nextCheckpoint := add(liveCheckpoint, checkpointChange)
        }
    }
}

function __computeCheckpointDistance(
    uint256 currentCheckpoint,
    uint256 prevCheckpoint
) pure returns (uint256 distance) {
    // overflow by design, as these are checkpoints, which can measure the distance even if overflowed.
    assembly {
        distance := sub(currentCheckpoint, prevCheckpoint)
    }
}

/// @dev           Converts an array of bytes into a byte32
/// @param raw     Array of bytes to convert
/// @return data   Converted data
function toBytes32(bytes memory raw) pure returns (bytes32 data) {
    assembly {
        data := mload(add(raw, 32))
        let shift := mul(sub(32, mload(raw)), 8)
        data := shr(shift, data)
    }
}

/// @dev           Converts an array of bytes into a bytes16.
/// @param raw     Array of bytes to convert.
/// @return data   Converted data.
function toBytes16(bytes memory raw) pure returns (bytes16 data) {
    assembly {
        data := mload(add(raw, 32))
        let shift := mul(sub(16, mload(raw)), 8)
        data := shr(shift, data)
    }
}

using {toUint128, toUint48, toUint32, toUint24, toUint16} for uint;
