// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import {JumpError} from "./EnigmaTypes.sol";

// --- Instructions --- //
bytes1 constant UNKNOWN = 0x00;
bytes1 constant ALLOCATE = 0x01;
bytes1 constant UNSET00 = 0x02;
bytes1 constant UNALLOCATE = 0x03;
bytes1 constant UNSET01 = 0x04;
bytes1 constant SWAP = 0x05;
bytes1 constant STAKE_POSITION = 0x06;
bytes1 constant UNSTAKE_POSITION = 0x07;
bytes1 constant UNSET02 = 0x08;
bytes1 constant UNSET03 = 0x09;
bytes1 constant CREATE_POOL = 0x0B;
bytes1 constant CREATE_PAIR = 0x0C;
bytes1 constant CREATE_CURVE = 0x0D;
bytes1 constant INSTRUCTION_JUMP = 0xAA;

/// @dev Used as the first pointer for the jump process.
uint8 constant JUMP_PROCESS_START_POINTER = 2;

/** @dev Be careful. Main entry point to start processing instructions. */
// ignore-prettier
function __startProcess__(function(bytes calldata) _process) {
    if (msg.data[0] != INSTRUCTION_JUMP) _process(msg.data);
    else _jumpProcess(msg.data, _process);
}

// ignore-prettier
function _jumpProcess(bytes calldata data, function(bytes calldata) _process) {
    uint8 length = uint8(data[1]);
    uint8 pointer = JUMP_PROCESS_START_POINTER; // note: [opcode, length, pointer, ...instruction, pointer, ...etc]
    uint256 start;
    // For each instruction set...
    for (uint256 i; i != length; ++i) {
        // Start at the index of the first byte of the next instruction.
        start = pointer;
        // Set the new pointer to the next instruction, located at the pointer.
        pointer = uint8(data[pointer]);
        // The `start:` includes the pointer byte, while the `:end` `pointer` is excluded.
        if (pointer > data.length) revert JumpError(pointer);
        bytes calldata instruction = data[start:pointer];
        // Process the instruction.
        _process(instruction[1:]); // note: Removes the pointer to the next instruction.
    }
}

/* /// @notice First byte should always be the INSTRUCTION_JUMP Enigma code.
/// @dev Expects a special encoding method for multiple instructions.
/// @param data Includes opcode as byte at index 0. First byte should point to next instruction.
/// @custom:security Critical. Processes multiple instructions. Data must be encoded perfectly. */

// --- Compiler & Decompiler --- //

// --- Errors --- //
error DecodePairBytesLength(uint256 expected, uint256 length);

// --- Encoding & Decoding --- //

function encodeJumpInstruction(bytes[] memory instructions) pure returns (bytes memory) {
    uint8 len = uint8(instructions.length);

    uint8 nextPointer;
    bytes memory payload = bytes.concat(INSTRUCTION_JUMP, bytes1(len));

    // for each instruction set...
    for (uint i; i != len; ++i) {
        bytes memory instruction = instructions[i];
        uint8 size = uint8(instruction.length);

        // Using instruction and index of instruction in list, we create a new array with a pointer to the next instruction in front of the instruction payload.
        if (i == 0) {
            nextPointer = size + 3; // [added0, instruction, added1, nextPointer]
        } else {
            nextPointer = nextPointer + size + 1; // [currentPointer, instruction, nextPointer]
        }

        bytes memory edited = bytes.concat(bytes1(nextPointer), instruction);
        payload = bytes.concat(payload, edited);
    }

    return payload;
}

function encodePoolId(uint16 pairId, uint32 curveId) pure returns (uint48 poolId) {
    bytes memory data = abi.encodePacked(pairId, curveId);
    poolId = uint48(bytes6(data));
}

/// @dev Expects a 6 byte left-pad `poolId`.
/// @param data Maximum 6 bytes. | 0x | left-pad 6 bytes poolId |
/// Pool id is a packed pair and curve id: | 0x | left-pad 2 bytes pairId | left-pad 4 bytes curveId |
function decodePoolId(bytes calldata data) pure returns (uint48 poolId, uint16 pairId, uint32 curveId) {
    poolId = uint48(bytes6(data));
    pairId = uint16(bytes2(data[:2]));
    curveId = uint32(bytes4(data[2:]));
}

/// @dev Encodes the arugments for the CREATE_CURVE instruction.
function encodeCreateCurve(
    uint24 sigma,
    uint32 maturity,
    uint16 fee,
    uint16 priorityFee,
    uint128 strike
) pure returns (bytes memory data) {
    data = abi.encodePacked(CREATE_CURVE, sigma, maturity, fee, priorityFee, strike);
}

/// @notice The pool swap fee is a parameter, which is store and then used to calculate `gamma`.
/// @dev Expects a 27 length byte array of left padded parameters.
/// @param data Maximum 1 + 3 + 4 + 2 + 2 + 16 = 28 bytes.
/// | 0x | 1 byte enigma code | 3 bytes sigma | 4 bytes maturity | 2 bytes fee | 2 bytes priority fee | 16 bytes strike |
function decodeCreateCurve(
    bytes calldata data
) pure returns (uint24 sigma, uint32 maturity, uint16 fee, uint16 priorityFee, uint128 strike) {
    require(data.length < 32, "Curve data too long");
    sigma = uint24(bytes3(data[1:4])); // note: First byte is the create pair ecode.
    maturity = uint32(bytes4(data[4:8]));
    fee = uint16(bytes2(data[8:10]));
    priorityFee = uint16(bytes2(data[10:12]));
    strike = uint128(bytes16(data[12:]));
}

/// @dev Encodes the arguments for the CREATE_PAIR instruction.
function encodeCreatePair(address token0, address token1) pure returns (bytes memory data) {
    data = abi.encodePacked(CREATE_PAIR, token0, token1);
}

/// @dev Expects a 41-byte length array with two addresses packed into it.
/// @param data Maximum 1 + 20 + 20 = 41 bytes.
/// | 0x | 1 byte enigma code | 20 bytes base token | 20 bytes quote token |.
function decodeCreatePair(bytes calldata data) pure returns (address tokenBase, address tokenQuote) {
    if (data.length != 41) revert DecodePairBytesLength(41, data.length);
    tokenBase = address(bytes20(data[1:21])); // note: First byte is the create pair ecode.
    tokenQuote = address(bytes20(data[21:]));
}

/// @dev Encodes the arguments for the CREATE_POOL instruction.
function encodeCreatePool(uint48 poolId, uint128 price) pure returns (bytes memory data) {
    data = abi.encodePacked(CREATE_POOL, poolId, price);
}

/// @dev Expects a poolId and one left zero padded amount for `price`.
/// @param data Maximum 1 + 6 + 16 = 23 bytes.
/// | 0x | 1 byte enigma code | left-pad 6 bytes poolId | left-pad 16 bytes |
function decodeCreatePool(
    bytes calldata data
) pure returns (uint48 poolId, uint16 pairId, uint32 curveId, uint128 price) {
    poolId = uint48(bytes6(data[1:7])); // note: First byte is the create pool ecode.
    pairId = uint16(bytes2(data[1:3]));
    curveId = uint32(bytes4(data[3:7]));
    price = uint128(bytes16(data[7:23]));
}

function encodeAllocate(uint8 useMax, uint48 poolId, uint8 power, uint8 amount) pure returns (bytes memory data) {
    data = abi.encodePacked(pack(bytes1(useMax), ALLOCATE), poolId, power, amount);
}

/// @dev Expects the standard instruction with two trailing run-length encoded amounts.
/// @param data Maximum 8 + 3 + 3 + 16 + 16 = 46 bytes.
/// | 0x | 1 packed byte useMax Flag - enigma code | 6 byte poolId | 3 byte loTick | 3 byte hiTick | 1 byte pointer to next power byte | 1 byte power | ...amount | 1 byte power | ...amount |
function decodeAllocate(bytes calldata data) pure returns (uint8 useMax, uint48 poolId, uint128 deltaLiquidity) {
    (bytes1 maxFlag, ) = separate(data[0]);
    useMax = uint8(maxFlag);
    poolId = uint48(bytes6(data[1:7]));
    deltaLiquidity = toAmount(data[7:]);
    //uint8 pointer = uint8(data[13]);
    //deltaBase = toAmount(data[14:pointer]);
    //deltaQuote = toAmount(data[pointer:]);
}

function encodeUnallocate(uint8 useMax, uint48 poolId, uint8 power, uint8 amount) pure returns (bytes memory data) {
    data = abi.encodePacked(pack(bytes1(useMax), UNALLOCATE), poolId, power, amount);
}

/// @dev Expects an enigma code, poolId, and trailing run-length encoded amount.
/// @param data Maximum 1 + 6 + 3 + 3 + 16 = 29 bytes.
/// | 0x | 1 packed byte useMax Flag - enigma code | 6 byte poolId | 3 byte loTick index | 3 byte hiTick index | 1 byte amount power | amount in amount length bytes |.
function decodeUnallocate(
    bytes calldata data
) pure returns (uint8 useMax, uint48 poolId, uint16 pairId, uint128 deltaLiquidity) {
    useMax = uint8(data[0] >> 4);
    pairId = uint16(bytes2(data[1:3]));
    poolId = uint48(bytes6(data[1:7]));
    deltaLiquidity = uint128(toAmount(data[7:]));
}

function encodeSwap(
    uint8 useMax,
    uint48 poolId,
    uint8 power0,
    uint8 amount0,
    uint8 power1,
    uint8 amount1,
    uint8 direction
) returns (bytes memory data) {
    uint8 pointer = 0x0a;
    data = abi.encodePacked(pack(bytes1(useMax), SWAP), poolId, pointer, power0, amount0, power1, amount1, direction);
}

/// @notice Swap direction: 0 = base token to quote token, 1 = quote token to base token.
/// @dev Expects standard instructions with the end byte specifying swap direction.
/// @param data Maximum 1 + 6 + 16 + 1 = 24 bytes.
/// | 0x | 1 byte packed flag-enigma code | 6 byte poolId | up to 16 byte TRLE amount | 1 byte direction |.
function decodeSwap(
    bytes calldata data
) pure returns (uint8 useMax, uint48 poolId, uint128 input, uint128 limit, uint8 direction) {
    useMax = uint8(data[0] >> 4);
    poolId = uint48(bytes6(data[1:7]));
    uint8 pointer = uint8(data[7]);
    input = uint128(toAmount(data[8:pointer]));
    limit = uint128(toAmount(data[pointer:data.length - 1])); // note: Up to but not including last byte.
    direction = uint8(data[data.length - 1]);
}

function encodeStakePosition(uint48 positionId) pure returns (bytes memory data) {
    data = abi.encodePacked(STAKE_POSITION, positionId);
}

/// @dev Expects an enigma code and positionId.
/// @param data Maximum 1 + 12 = 13 bytes.
/// | 0x | 1 packed byte useMax Flag - enigma code | 12 byte positionId |.
function decodeStakePosition(bytes calldata data) pure returns (uint48 poolId) {
    poolId = uint48(bytes6(data[1:7]));
}

function encodeUnstakePosition(uint48 positionId) pure returns (bytes memory data) {
    data = abi.encodePacked(UNSTAKE_POSITION, positionId);
}

/// @dev Expects an enigma code and positionId.
/// @param data Maximum 1 + 12 = 13 bytes.
/// | 0x | 1 packed byte useMax Flag - enigma code | 12 byte positionId |.
function decodeUnstakePosition(bytes calldata data) pure returns (uint48 poolId) {
    poolId = uint48(bytes6(data[1:7]));
}

// --- Utility --- //

function separate(bytes1 data) pure returns (bytes1 upper, bytes1 lower) {
    upper = data >> 4;
    lower = data & 0x0f;
}

function pack(bytes1 upper, bytes1 lower) pure returns (bytes1 data) {
    data = (upper << 4) | lower;
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

/// @dev             Converts an array of bytes into an uint128, the array must adhere
///                  to the the following format:
///                  - First byte: Amount of trailing zeros.
///                  - Rest of the array: A hexadecimal number.
/// @param raw       Array of bytes to convert.
/// @return amount   Converted amount.
function toAmount(bytes calldata raw) pure returns (uint128 amount) {
    uint8 power = uint8(raw[0]);
    amount = uint128(toBytes16(raw[1:raw.length]));
    amount = amount * uint128(10 ** power);
}
