// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/**
 * -------------
 *
 *   This is called the FVM, it's an alternative ABI.
 *   Originally, it was designed to compress calldata and therefore
 *   save gas on optimistic rollup networks.
 *
 *   There are levels to the optimizations that can be made for it,
 *   but this one focuses on the alternative multicall: jump process.
 *
 *   Multicalls will pad all calls to a full bytes32.
 *   This means two calls are at least 64 bytes.
 *   This alternative multicall can process over 10 calls in the same 64 bytes.
 *   The smallest bytes provided by a call is for allocate and deallocate, at 11 bytes.
 *
 *   Multicalls also process transactions sequentially.
 *   State cannot be carried over transiently between transactions.
 *   With FVM, we can transiently set state (only specific state),
 *   and use it across "instructions".
 *
 *   Without jump instruction, this alternative encoding is overkill.
 *
 *   Data is delivered via the `multiprocess` function in Portfolio.
 *
 *   -------------
 *
 *   Primitive™
 */

import "./AssemblyLib.sol";

uint8 constant JUMP_PROCESS_START_POINTER = 2;
bytes1 constant UNKNOWN = 0x00;
bytes1 constant ALLOCATE = 0x01;
bytes1 constant UNSET02 = 0x02;
bytes1 constant DEALLOCATE = 0x03;
bytes1 constant CLAIM = 0x04;
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

/**
 * @dev Expects a serialized encoding of instructions.
 *      Serialized byte array -> [Jump Instruction Opcode,Total Amount of Instructions, Length of instruction[0], Data of instruction[0], Length of instruction[1],...]
 *
 * Motivation
 *      This serialization is intentional because it enables the use of a dynamic array for instructions.
 *      A fixed instruction array would pad unfilled array data with zeroes, wasting potentially a lot of bytes.
 *      On optimistic rollups, these bytes are the most expensive (in gas) bytes!
 *
 * Simple Guide
 *      First, information is added about the set of instructions that will be processed.
 *          - The jump instruction code, to signal we want to process multiple instructions.
 *          - The amount of instructions we want to process.
 *          - The length of the next instruction.
 *          - The instruction data.
 *          - The length of the next instruction.
 *          - Etc...
 *      Since we want to process multiple instructions that are in one big string,
 *      the encoding has to put information at the beginning of the instruction to say
 *      "this instruction is 22 bytes long".
 *      Then when it's decoded using the assumption "so the next instruction starts after 22 bytes".
 *
 * Glossary
 * | Term | Description | Size |
 * ---------------------------------
 * | Pointer | Index of the jump calldata that holds the length of an instruction. | 1 byte |
 * | Instruction Code | FVM "op code" to signal which operation to execute | 1 byte |
 * | Total Instructions | Amount of instructions to be executed | 1 byte |
 *
 * Conclusion
 *      To summarize, the calldata can be sliced to get the length of the instruction, e.g. `data[3:4]`.
 *      The `pointer` is initialized as this value. The pointer acts as an accumulator that moves across the bytes string.
 *      This accumulated value is the byte index of the last byte of the instruction.
 *
 * Example
 * | Byte Index                 | Data               |
 * ----------------------------------------------------------
 * | bytes[0]                   | 0xAA Instruction code     |
 * | bytes[1]                   | Amount of Instructions    |
 * | bytes[2]                   | ptr[0] := Length of instruction[0]
 * | bytes[2:ptr[0] + 1]        | Data of instruction[0]. Calldata slice does not include end index.   |
 * | bytes[ptr[0] + 1]          | ptr[1] := Length of instruction[1] |
 * | ...                        | Repeats in a loop for each instruction. |
 */
function _jumpProcess(bytes calldata data, function(bytes calldata) _process) {
    // Encoded `data`:| 0x | opcode | amount instructions | instruction length | instruction |
    uint8 totalInstructions = uint8(data[1]);
    // The "pointer" is pointing to the first byte of an instruction,
    // which holds the data for the instruction's length in bytes.
    uint256 idxPtr = JUMP_PROCESS_START_POINTER;
    // As the instructions are processed,
    // the pointer moves from the end to the start.
    uint256 idxInstructionStart;
    uint256 idxInstructionEnd;
    // For each instruction set...
    for (uint256 i; i != totalInstructions; ++i) {
        // Start the instruction where the pointer is.
        idxInstructionStart = idxPtr;
        // Compute the index of the next pointer by summing
        // the current pointer value, the length of the instruction,
        // and the amount of bytes the instruction length takes (which is 1 byte).
        idxInstructionEnd =
            idxInstructionStart + uint8(bytes1(data[idxInstructionStart])) + 1;
        // Make sure the pointer is not out of bounds.
        if (idxInstructionEnd > data.length) {
            revert InvalidJump(idxInstructionEnd);
        }
        // Calldata slicing EXCLUDES the `idxInstructionEnd` byte.
        bytes calldata instruction = data[idxInstructionStart:idxInstructionEnd];
        // Move the pointer to the EXCLUDED `idxInstructionEnd` byte.
        // This byte holds the data for the index of byte with the next instruction's length.
        idxPtr = idxInstructionEnd;
        // Process the instruction after removing the instruction length,
        // so only instruction data is passed to `_process`.
        _process(instruction[1:]);
    }
}

/**
 * @dev Serializes an array of instructions by appending the length of the instruction to each instruction packet.
 * Adds the INSTRUCTION_JUMP opcode and total instructions quantity to the front of the `bytes` array.
 * @param instructions Dynamically sized array of FVM encoded instructions.
 */
function encodeJumpInstruction(bytes[] memory instructions)
    pure
    returns (bytes memory)
{
    uint8 totalInstructions = uint8(instructions.length);
    bytes memory payload =
        bytes.concat(INSTRUCTION_JUMP, bytes1(totalInstructions));

    // for each instruction set...
    for (uint256 i; i != totalInstructions; ++i) {
        bytes memory instruction = instructions[i];
        // Amount of bytes of data for this instruction.
        uint8 instructionLength = uint8(instruction.length);
        // Appends pointer to next instruction to the beginning of this instruction.
        bytes memory edited =
            bytes.concat(bytes1(instructionLength), instruction);
        // Concats the serialized bytes data with this edited instruction.
        payload = bytes.concat(payload, edited);
    }

    return payload;
}

function decodePairIdFromPoolId(uint64 poolId) pure returns (uint24) {
    return uint24(poolId >> 40);
}

/**
 * @dev Returns the pool id given some pool parameters
 * @param pairId Id of the pair of asset / quote tokens
 * @param isMutable True if the pool is mutable
 * @param poolNonce Current pool nonce of the Portfolio contract
 * @return Corresponding encoded pool id
 * @custom:example
 * ```
 * uint64 poolId = encodePoolId(0, true, 1);
 * ```
 */
function encodePoolId(
    uint24 pairId,
    bool isMutable,
    uint32 poolNonce
) pure returns (uint64) {
    return uint64(
        bytes8(
            abi.encodePacked(pairId, isMutable ? uint8(1) : uint8(0), poolNonce)
        )
    );
}

function decodePoolId(bytes calldata data)
    pure
    returns (uint64 poolId, uint24 pairId, uint8 isMutable, uint32 poolNonce)
{
    if (data.length != 8) revert InvalidBytesLength(8, data.length);
    poolId = uint64(bytes8(data));
    pairId = uint16(bytes2(data[:3]));
    isMutable = uint8(bytes1(data[3:4]));
    poolNonce = uint32(bytes4(data[4:]));
}

function encodeCreatePair(
    address token0,
    address token1
) pure returns (bytes memory data) {
    data = abi.encodePacked(CREATE_PAIR, token0, token1);
}

function decodeCreatePair(bytes calldata data)
    pure
    returns (address tokenAsset, address tokenQuote)
{
    if (data.length != 41) revert InvalidBytesLength(41, data.length);
    tokenAsset = address(bytes20(data[1:21]));
    tokenQuote = address(bytes20(data[21:]));
}

/**
 * @dev Encodes a claim operation.
 * FIXME: This function is not optimized! Using `encodePacked` is not ideal
 * because it preserves all the trailing zeros for each type. An improved version
 * should be made to reduce the calldata size by removing the extra zeros.
 */
function encodeClaim(
    uint64 poolId,
    uint128 fee0,
    uint128 fee1
) pure returns (bytes memory data) {
    (uint8 powerFee0, uint128 baseFee0) = AssemblyLib.fromAmount(fee0);
    (uint8 powerFee1, uint128 baseFee1) = AssemblyLib.fromAmount(fee1);

    return abi.encodePacked(
        CLAIM,
        uint8(10), // pointer to pointer1
        poolId,
        uint8(28), // pointer to fee1
        powerFee0,
        baseFee0,
        powerFee1,
        baseFee1
    );
}

/**
 * @dev Decodes a claim operation
 */
function decodeClaim(bytes calldata data)
    pure
    returns (uint64 poolId, uint128 fee0, uint128 fee1)
{
    uint8 pointer0 = uint8(bytes1(data[1]));
    poolId = uint64(AssemblyLib.toBytes8(data[2:pointer0]));
    uint8 pointer1 = uint8(bytes1(data[pointer0]));
    fee0 = AssemblyLib.toAmount(data[pointer0 + 1:pointer1]);
    fee1 = AssemblyLib.toAmount(data[pointer1:data.length]);
}

/**
 * @dev Encodes a create pool operation.
 * FIXME: Same issue as `encodeClaim`... This function is not optimized!
 */
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
    (uint8 power0, uint128 base0) = AssemblyLib.fromAmount(maxPrice);
    (uint8 power1, uint128 base1) = AssemblyLib.fromAmount(price);

    data = abi.encodePacked(
        CREATE_POOL,
        pairId,
        controller,
        priorityFee,
        fee,
        vol,
        dur,
        jit,
        uint8(52),
        power0,
        base0,
        power1,
        base1
    );
}

function decodeCreatePool(bytes calldata data)
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
    // if (data.length != 66) revert InvalidBytesLength(66, data.length);
    pairId = uint24(bytes3(data[1:4]));
    controller = address(bytes20(data[4:24]));
    priorityFee = uint16(bytes2(data[24:26]));
    fee = uint16(bytes2(data[26:28]));
    vol = uint16(bytes2(data[28:30]));
    dur = uint16(bytes2(data[30:32]));
    jit = uint16(bytes2(data[32:34]));
    uint8 pointer0 = uint8(bytes1(data[34]));
    maxPrice = AssemblyLib.toAmount(data[35:pointer0]);
    price = AssemblyLib.toAmount(data[pointer0:]);
}

/**
 * @dev Encodes a allocate operation.
 * FIXME: Same issue as `encodeClaim`... This function is not optimized!
 */
function encodeAllocate(
    uint8 useMax,
    uint64 poolId,
    uint128 deltaLiquidity
) pure returns (bytes memory data) {
    (uint8 power, uint128 base) = AssemblyLib.fromAmount(deltaLiquidity);
    data = abi.encodePacked(
        AssemblyLib.pack(bytes1(useMax), ALLOCATE), poolId, power, base
    );
}

function decodeAllocate(bytes calldata data)
    pure
    returns (uint8 useMax, uint64 poolId, uint128 deltaLiquidity)
{
    if (data.length < 9) revert InvalidBytesLength(9, data.length);
    (bytes1 maxFlag,) = AssemblyLib.separate(data[0]);
    useMax = uint8(maxFlag);
    poolId = uint64(bytes8(data[1:9]));
    deltaLiquidity = AssemblyLib.toAmount(data[9:]);
}

/**
 * @dev Encodes a deallocate operation.
 * FIXME: Same issue as `encodeClaim`... This function is not optimized!
 */
function encodeDeallocate(
    uint8 useMax,
    uint64 poolId,
    uint128 deltaLiquidity
) pure returns (bytes memory data) {
    (uint8 power, uint128 base) = AssemblyLib.fromAmount(deltaLiquidity);
    data = abi.encodePacked(
        AssemblyLib.pack(bytes1(useMax), DEALLOCATE), poolId, power, base
    );
}

function decodeDeallocate(bytes calldata data)
    pure
    returns (uint8 useMax, uint64 poolId, uint128 deltaLiquidity)
{
    if (data.length < 9) revert InvalidBytesLength(9, data.length);
    useMax = uint8(data[0] >> 4);
    poolId = uint64(bytes8(data[1:9]));
    deltaLiquidity = AssemblyLib.toAmount(data[9:]);
}

/**
 * @dev Encodes a swap operation
 * FIXME: Same issue as `encodeClaim`... This function is not optimized!
 */
function encodeSwap(
    uint8 useMax,
    uint64 poolId,
    uint128 amount0,
    uint128 amount1,
    uint8 sellAsset
) pure returns (bytes memory data) {
    (uint8 power0, uint128 base0) = AssemblyLib.fromAmount(amount0);
    (uint8 power1, uint128 base1) = AssemblyLib.fromAmount(amount1);

    data = abi.encodePacked(
        AssemblyLib.pack(bytes1(useMax), SWAP),
        sellAsset,
        uint8(11), // pointer to pointer1
        poolId,
        uint8(29),
        power0,
        base0,
        power1,
        base1
    );
}

/**
 * @dev Decodes a swap operation.
 */
function decodeSwap(bytes calldata data)
    pure
    returns (
        uint8 useMax,
        uint64 poolId,
        uint128 input,
        uint128 output,
        uint8 sellAsset
    )
{
    useMax = uint8(data[0] >> 4);
    sellAsset = uint8(data[1]);
    uint8 pointer0 = uint8(data[2]);
    poolId = uint64(AssemblyLib.toBytes8(data[3:pointer0]));
    uint8 pointer1 = uint8(data[pointer0]);
    input = AssemblyLib.toAmount(data[pointer0 + 1:pointer1]);
    output = AssemblyLib.toAmount(data[pointer1:data.length]);
}
