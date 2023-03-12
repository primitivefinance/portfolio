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

uint8 constant INSTRUCTION_CODE_SIZE_BYTES = 1;
uint8 constant INSTRUCTION_POINTER_SIZE_BYTES = 2;
uint8 constant INSTRUCTIONS_ARRAY_SIZE_BYTES = 1;
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
 * @dev Expects a serialized encoding of instructions that is delimited by pointers to the next instruction.
 *
 * Motivation
 *      This serialization is intentional because it enables the use of a dynamic array for instructions.
 *      A fixed instruction array would pad unfilled array data with zeroes, wasting potentially a lot of bytes.
 *
 * Simple Guide
 *      First, information is added about the set of instructions that will be processed.
 *          - The jump instruction code, to signal we want to process multiple instructions.
 *          - The amount of instructions we want to process.
 *          - The starting index of the next instruction in the string of bytes `data`, i.e. a "pointer".
 *      Since we want to process multiple instructions that are in one big string,
 *      the encoding has to put information at the beginning of the instruction to say
 *      "this instruction is 22 bytes long, so the next instruction data starts after 22 bytes".
 *      All instructions have pointer information appended to the front of the instruction for
 *      jump processing. These pointers are two bytes long, which means a 22 byte instruction will have 24 total bytes.
 *      This repeats in a loop until all the instructions have been processed.
 *
 * Glossary
 * | Term | Description | Size |
 * ---------------------------------
 * | Pointer | Index value with data for the next pointer's start location in the calldata. | 2 bytes |
 * | Instruction Code | FVM "op code" to signal which operation to execute | 1 byte |
 * | Instructions length | Amount of instructions to be executed | 1 byte |
 *
 * Conclusion
 *      To summarize, the calldata can be sliced to get a pointer, e.g. `data[3:5]`.
 *      Then using that pointer as the start index to the `data`,
 *      we can get the next pointer, e.g. `data[data[3:5]:data[3:5] + `INSTRUCTION_POINTER_SIZE_BYTES`]`.
 *      Pointers are two bytes which means the end index (slicing calldata EXCLUDES the byte at the `:end` pointer)
 *      is computed by summing the start index and `INSTRUCTION_POINTER_SIZE_BYTES` in bytes.
 *
 * Example
 * | Byte Index                 | Data               |
 * ----------------------------------------------------------
 * | bytes[0]                   | 0xAA Instruction code     |
 * | bytes[1]                   | Amount of Instructions    |
 * | bytes[2:2+ptr length]        | ptr[0] := Pointer to instruction at index `1` of the instructions array to be executed.
 * | bytes[2+ptr length:ptr[0]]   | Instruction data at index `0` of the instructions array.
 * | bytes[ptr[0]:ptr[0] + ptr length]   | ptr[1] := Pointer to instruction at index `2`.
 * | ...                        | Repeats in a loop for each instruction. |
 */
function _jumpProcess(bytes calldata data, function(bytes calldata) _process) {
    uint8 length = uint8(data[INSTRUCTIONS_ARRAY_SIZE_BYTES]);
    uint16 pointer = JUMP_PROCESS_START_POINTER; // First pointer data is at index `JUMP_PROCESS_START_POINTER`.
    uint256 start;
    // For each instruction set...
    for (uint256 i; i != length; ++i) {
        // Start at the index of the first byte of the next instruction.
        start = pointer;
        // Set the new pointer to the next instruction, located at data at the index equal to the pointer.
        pointer = uint16(
            bytes2(data[pointer:pointer + INSTRUCTION_POINTER_SIZE_BYTES])
        );
        // The `start:` includes the pointer bytes, while the `:end` `pointer` is excluded.
        if (pointer > data.length) revert InvalidJump(pointer);
        bytes calldata instruction = data[start:pointer];
        // Process the instruction.
        _process(instruction[INSTRUCTION_POINTER_SIZE_BYTES:]); // note: Removes the pointer to the next instruction.
    }
}

/**
 * @dev Serializes an array of instructions into a `pointer` delimited string of instructions, led by JUMP_PROCESS FVM code.
 *
 * For this table, ptrs[0] is not a thing, just a way to describe the order of pointers.
 * E.g. ptrs[0] = First pointer; pointer to instruction at index 1 of the instructions array.
 * The actual code overwrites the `nextPointer` variable for each pointer and concats it to the bytes string.
 *
 * @param instructions Dynamically sized array of FVM encoded instructions.
 *
 * Byte index   : Description of what fills the space.
 * ---------------------------------------------------
 * 0            : JUMP Instruction Code (0xAA)
 * 1            : Amount of instructions = Length of instructions array.
 * 2            : ptrs[0] := Pointer to instructions[1] = Instruction code (1 byte) + Amt Instructions (1 byte) + ptrs[0] (2 bytes) + instructions[0].length.
 * 3...(ptrs[0] - 1)  : instructions[0]
 * ptrs[0]      : ptrs[1] := Pointer to instructions[2] = ptrs[0] (2 bytes) + instructions[1].length + ptrs[1] (2 bytes).
 * (ptrs[0] + 1)...(ptrs[1] - 1): instructions[1]
 * ptrs[1]      : ptrs[2] := Pointer to instructions[3]
 * etc..
 */
function encodeJumpInstruction(bytes[] memory instructions)
    pure
    returns (bytes memory)
{
    uint16 nextPointer;
    uint8 len = uint8(instructions.length);
    bytes memory payload = bytes.concat(INSTRUCTION_JUMP, bytes1(len));

    // for each instruction set...
    for (uint256 i; i != len; ++i) {
        bytes memory instruction = instructions[i];
        // Amount of bytes of data for this instruction.
        uint8 size = uint8(instruction.length);

        // Using instruction and index of instruction in list, we create a new array with a pointer to the next instruction in front of the instruction payload.
        // i == 0 only happens once so we short circuit via opposite case.
        if (i != 0) {
            nextPointer = nextPointer + size + INSTRUCTION_POINTER_SIZE_BYTES; // [currentPointer, instruction, nextPointer]
        } else {
            nextPointer = INSTRUCTION_CODE_SIZE_BYTES
                + INSTRUCTIONS_ARRAY_SIZE_BYTES + INSTRUCTION_POINTER_SIZE_BYTES
                + size;
        }

        // Appends pointer to next instruction to the beginning of this instruction.
        bytes memory edited = bytes.concat(bytes2(nextPointer), instruction);
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
