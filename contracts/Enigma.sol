// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/**

  -------------

  This is called the Enigma, it's an alternative ABI.
  Originally, it was designed to compress calldata and therefore
  save gas on optimistic rollup networks.

  There are levels to the optimizations that can be made for it,
  but this one focuses on the alternative multicall: jump process.

  Multicalls will pad all calls to a full bytes32.
  This means two calls are at least 64 bytes.
  This alternative multicall can process over 10 calls in the same 64 bytes.
  The smallest bytes provided by a call is for allocate and unallocate, at 11 bytes.

  Multicalls also process transactions sequentially.
  State cannot be carried over transiently between transactions.
  With Enigma, we can transiently set state (only specific state),
  and use it across "instructions".

  Without jump instruction, this alternative encoding is overkill.

  Be aware of function selector hash collisions.
  Data is delivered via the `fallback` function.

  -------------

  Primitive™

 */

import "./Assembly.sol" as Assembly;

uint8 constant JUMP_PROCESS_START_POINTER = 2;
bytes1 constant UNKNOWN = 0x00;
bytes1 constant ALLOCATE = 0x01;
bytes1 constant UNSET02 = 0x02;
bytes1 constant UNALLOCATE = 0x03;
bytes1 constant UNSET04 = 0x04;
bytes1 constant SWAP = 0x05;
bytes1 constant UNSET06 = 0x06;
bytes1 constant UNSET07 = 0x07;
bytes1 constant UNSET08 = 0x08;
bytes1 constant UNSET09 = 0x09;
bytes1 constant CREATE_POOL = 0x0B;
bytes1 constant CREATE_PAIR = 0x0C;
bytes1 constant UNSET0D = 0x0D;
bytes1 constant INSTRUCTION_JUMP = 0xAA;

error InvalidJump(uint256 pointer); // 0x80f63bd1
error InvalidBytesLength(uint256 expected, uint256 length); // 0xe19dc95e

function __startProcess__(function(bytes calldata) _process) {
    if (msg.data[0] != INSTRUCTION_JUMP) _process(msg.data);
    else _jumpProcess(msg.data, _process);
}

/** @dev  [jump instruction, instructions.length, pointer, ...instruction, pointer, ...etc] */
function _jumpProcess(bytes calldata data, function(bytes calldata) _process) {
    uint8 length = uint8(data[1]);
    uint8 pointer = JUMP_PROCESS_START_POINTER;
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
    uint8 nextPointer;
    uint8 len = uint8(instructions.length);
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

function decodePairIdFromPoolId(uint64 poolId) pure returns (uint24) {
    return uint24(poolId >> 40);
}

/// @dev Returns the pool id given some pool parameters
/// @param pairId Id of the pair of asset / quote tokens
/// @param isMutable True if the pool is mutable
/// @param poolNonce Current pool nonce of the Hyper contract
/// @return Corresponding encoded pool id
/// @custom:example
/// ```
/// // Gets the pool id given some parameters
/// uint64 poolId = encodePoolId(0, true, 1);
/// ```
function encodePoolId(uint24 pairId, bool isMutable, uint32 poolNonce) pure returns (uint64) {
    return uint64(bytes8(abi.encodePacked(pairId, isMutable ? uint8(1) : uint8(0), poolNonce)));
}

function decodePoolId(
    bytes calldata data
) pure returns (uint64 poolId, uint24 pairId, uint8 isMutable, uint32 poolNonce) {
    if (data.length != 8) revert InvalidBytesLength(8, data.length);
    poolId = uint64(bytes8(data));
    pairId = uint16(bytes2(data[:3]));
    isMutable = uint8(bytes1(data[3:4]));
    poolNonce = uint32(bytes4(data[4:]));
}

function encodeCreatePair(address token0, address token1) pure returns (bytes memory data) {
    data = abi.encodePacked(CREATE_PAIR, token0, token1);
}

function decodeCreatePair(bytes calldata data) pure returns (address tokenAsset, address tokenQuote) {
    if (data.length != 41) revert InvalidBytesLength(41, data.length);
    tokenAsset = address(bytes20(data[1:21]));
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
    uint128 maxPrice,
    uint128 price
) pure returns (bytes memory data) {
    data = abi.encodePacked(CREATE_POOL, pairId, controller, priorityFee, fee, vol, dur, jit, maxPrice, price);
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
        uint128 maxPrice,
        uint128 price
    )
{
    if (data.length != 66) revert InvalidBytesLength(66, data.length);
    pairId = uint24(bytes3(data[1:4]));
    controller = address(bytes20(data[4:24]));
    priorityFee = uint16(bytes2(data[24:26]));
    fee = uint16(bytes2(data[26:28]));
    vol = uint16(bytes2(data[28:30]));
    dur = uint16(bytes2(data[30:32]));
    jit = uint16(bytes2(data[32:34]));
    maxPrice = uint128(bytes16(data[34:50]));
    price = uint128(bytes16(data[50:]));
}

function encodeAllocate(uint8 useMax, uint64 poolId, uint8 power, uint128 amount) pure returns (bytes memory data) {
    data = abi.encodePacked(Assembly.pack(bytes1(useMax), ALLOCATE), poolId, power, amount);
}

function decodeAllocate(bytes calldata data) pure returns (uint8 useMax, uint64 poolId, uint128 deltaLiquidity) {
    if (data.length < 9) revert InvalidBytesLength(9, data.length);
    (bytes1 maxFlag, ) = Assembly.separate(data[0]);
    useMax = uint8(maxFlag);
    poolId = uint64(bytes8(data[1:9]));
    deltaLiquidity = Assembly.toAmount(data[9:]);
}

function encodeUnallocate(uint8 useMax, uint64 poolId, uint8 power, uint128 amount) pure returns (bytes memory data) {
    data = abi.encodePacked(Assembly.pack(bytes1(useMax), UNALLOCATE), poolId, power, amount);
}

function decodeUnallocate(bytes calldata data) pure returns (uint8 useMax, uint64 poolId, uint128 deltaLiquidity) {
    if (data.length < 9) revert InvalidBytesLength(9, data.length);
    useMax = uint8(data[0] >> 4);
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
    //    pointerToAmount1 = instruction, poolId, pointer, power0, amount0, power1 {pointer}->
    uint8 pointerToAmount1 = 0x01 + 0x08 + 0x01 + 0x10 + 0x01;
    data = abi.encodePacked(
        Assembly.pack(bytes1(useMax), SWAP),
        poolId,
        pointerToAmount1,
        power0,
        amount0,
        power1,
        amount1,
        direction
    );
}

function decodeSwap(
    bytes calldata data
) pure returns (uint8 useMax, uint64 poolId, uint128 input, uint128 output, uint8 direction) {
    useMax = uint8(data[0] >> 4);
    poolId = uint64(bytes8(data[1:9]));
    uint8 pointer = uint8(data[9]);
    input = uint128(Assembly.toAmount(data[10:pointer]));
    output = uint128(Assembly.toAmount(data[pointer:data.length - 1]));
    direction = uint8(data[data.length - 1]);
}
