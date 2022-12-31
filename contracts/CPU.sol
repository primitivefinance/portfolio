// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./Assembly.sol" as Assembly;

/// @dev Used as the first pointer for the jump process.
uint8 constant JUMP_PROCESS_START_POINTER = 2;

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

error InvalidJump(uint256 pointer);
error InvalidPairBytes(uint256 expected, uint256 length);

function __startProcess__(function(bytes calldata) _process) {
    if (msg.data[0] != INSTRUCTION_JUMP) _process(msg.data);
    else _jumpProcess(msg.data, _process);
}

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
        if (pointer > data.length) revert InvalidJump(pointer);
        bytes calldata instruction = data[start:pointer];
        // Process the instruction.
        _process(instruction[1:]); // note: Removes the pointer to the next instruction.
    }
}

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

function encodePoolId(uint24 pairId, bool isMutable, uint32 poolNonce) pure returns (uint64) {
    return uint64(bytes8(abi.encodePacked(pairId, isMutable ? uint8(1) : uint8(0), poolNonce)));
}

/** @dev [0x 3 bytes 1 byte 4 bytes] == [0x pairId isMutable poolNonce]. */
function decodePoolId(
    bytes calldata data
) pure returns (uint64 poolId, uint24 pairId, uint8 isMutable, uint32 poolNonce) {
    poolId = uint64(bytes8(data));
    pairId = uint16(bytes2(data[:3]));
    isMutable = uint8(bytes1(data[3:4]));
    poolNonce = uint32(bytes4(data[4:]));
}

function encodeCreatePair(address token0, address token1) pure returns (bytes memory data) {
    data = abi.encodePacked(CREATE_PAIR, token0, token1);
}

/** @dev [0x 00 3 bytes 1 byte 4 bytes] == [0x instruction token0 token1]. */
function decodeCreatePair(bytes calldata data) pure returns (address tokenAsset, address tokenQuote) {
    if (data.length != 41) revert InvalidPairBytes(41, data.length);
    tokenAsset = address(bytes20(data[1:21])); // note: First byte is the create pair ecode.
    tokenQuote = address(bytes20(data[21:]));
}

function encodeCreatePool(
    uint24 pairId,
    address controller,
    uint16 priorityFee,
    uint16 fee,
    uint16 vol,
    uint16 dur,
    uint16 jit,
    int24 max,
    uint128 price
) pure returns (bytes memory data) {
    data = abi.encodePacked(CREATE_POOL, pairId, controller, priorityFee, fee, vol, dur, jit, max, price);
}

function decodeCreatePool(
    bytes calldata data
)
    pure
    returns (
        uint24 pairId,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 vol,
        uint16 dur,
        uint16 jit,
        int24 max,
        uint128 price
    )
{
    pairId = uint24(bytes3(data[1:4]));
    controller = address(bytes20(data[4:24]));
    priorityFee = uint16(bytes2(data[24:26]));
    fee = uint16(bytes2(data[26:28]));
    vol = uint16(bytes2(data[28:30]));
    dur = uint16(bytes2(data[30:32]));
    jit = uint16(bytes2(data[32:34]));
    max = int24(uint24(bytes3(data[34:37]))); // todo: fix, can overflow
    price = uint128(bytes16(data[37:48]));
}

function encodeAllocate(uint8 useMax, uint64 poolId, uint8 power, uint128 amount) pure returns (bytes memory data) {
    data = abi.encodePacked(Assembly.pack(bytes1(useMax), ALLOCATE), poolId, power, amount);
}

/** @dev [0x 1 byte 8 bytes 16 bytes] = [0x instruction+useMax poolId deltaLiquidity] */
function decodeAllocate(bytes calldata data) pure returns (uint8 useMax, uint64 poolId, uint128 deltaLiquidity) {
    (bytes1 maxFlag, ) = Assembly.separate(data[0]);
    useMax = uint8(maxFlag);
    poolId = uint64(bytes8(data[1:9]));
    deltaLiquidity = Assembly.toAmount(data[9:]);
}

function encodeUnallocate(uint8 useMax, uint64 poolId, uint8 power, uint128 amount) pure returns (bytes memory data) {
    data = abi.encodePacked(Assembly.pack(bytes1(useMax), UNALLOCATE), poolId, power, amount);
}

/** @dev [0x 1 byte 8 bytes 16 bytes] = [0x instruction+useMax poolId=[pairId + 5 bytes] deltaLiquidity] */
function decodeUnallocate(
    bytes calldata data
) pure returns (uint8 useMax, uint64 poolId, uint24 pairId, uint128 deltaLiquidity) {
    useMax = uint8(data[0] >> 4);
    pairId = uint16(bytes2(data[1:4]));
    poolId = uint64(bytes8(data[1:9]));
    deltaLiquidity = uint128(Assembly.toAmount(data[9:]));
}

function encodeSwap(
    uint8 useMax,
    uint64 poolId,
    uint8 power0,
    uint128 amount0,
    uint8 power1,
    uint128 amount1,
    uint8 direction
) pure returns (bytes memory data) {
    uint8 pointer = 0x0a + 0x0f + 0x02; // temp: fix: 0x02 for two additional poolId bytes // pointer of the second amount, pointer -> [power0, amount0, -> power1, amount1]
    data = abi.encodePacked(
        Assembly.pack(bytes1(useMax), SWAP),
        poolId,
        pointer,
        power0,
        amount0,
        power1,
        amount1,
        direction
    );
}

/** @dev Swap direction: 0 = base token to quote token, 1 = quote token to base token. */
function decodeSwap(
    bytes calldata data
) pure returns (uint8 useMax, uint64 poolId, uint128 input, uint128 limit, uint8 direction) {
    useMax = uint8(data[0] >> 4);
    poolId = uint64(bytes8(data[1:9]));
    uint8 pointer = uint8(data[9]);
    input = uint128(Assembly.toAmount(data[10:pointer]));
    limit = uint128(Assembly.toAmount(data[pointer:data.length - 1])); // note: Up to but not including last byte.
    direction = uint8(data[data.length - 1]);
}

function encodeStakePosition(uint64 positionId) pure returns (bytes memory data) {
    data = abi.encodePacked(STAKE_POSITION, positionId);
}

function decodeStakePosition(bytes calldata data) pure returns (uint64 poolId) {
    poolId = uint64(bytes8(data[1:9]));
}

function encodeUnstakePosition(uint64 positionId) pure returns (bytes memory data) {
    data = abi.encodePacked(UNSTAKE_POSITION, positionId);
}

function decodeUnstakePosition(bytes calldata data) pure returns (uint64 poolId) {
    poolId = uint64(bytes8(data[1:9]));
}
