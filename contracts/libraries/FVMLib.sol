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
 * @dev  [jump instruction, instructions.length, pointer, ...instruction, pointer, ...etc]
 */
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
    for (uint256 i; i != len; ++i) {
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

/**
 * @dev Decodes the `pair id` from a `pool id`.
 * @param poolId Pool id to use for the decoding
 * @return pairId Corresponding pair id
 * @custom:example
 * ```
 * uint24 pairId = decodePairIdFromPoolId(46183783333895);
 * ```
 */
function decodePairIdFromPoolId(uint64 poolId) pure returns (uint24 pairId) {
    assembly {
        pairId := shr(40, poolId)
    }
}

/**
 * @dev Returns the pool id given specific pool parameters.
 * @param pairId Id of the pair of asset / quote tokens
 * @param isMutable True if the pool is mutable
 * @param poolNonce Current pool nonce of the Portfolio contract
 * @return Corresponding encoded pool id
 * @custom:example
 * ```
 * uint64 poolId = encodePoolId(7, true, 42);
 * ```
 */
function encodePoolId(uint24 pairId, bool isMutable, uint32 poolNonce) pure returns (uint64) {
    return uint64(bytes8(abi.encodePacked(pairId, isMutable ? uint8(1) : uint8(0), poolNonce)));
}

function decodePoolId(bytes calldata data)
    pure
    returns (uint64 poolId, uint24 pairId, uint8 isMutable, uint32 poolNonce)
{
    if (data.length != 8) revert InvalidBytesLength(8, data.length);

    assembly {
        let value := calldataload(data.offset)
        poolId := shr(192, value)
        pairId := shr(232, value)
        isMutable := shr(248, shl(24, value))
        poolNonce := shr(224, shl(32, value))
    }
}

function encodeCreatePair(address token0, address token1) pure returns (bytes memory data) {
    data = abi.encodePacked(CREATE_PAIR, token0, token1);
}

function decodeCreatePair(bytes calldata data) pure returns (address tokenAsset, address tokenQuote) {
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
function encodeClaim(uint64 poolId, uint128 fee0, uint128 fee1) pure returns (bytes memory data) {
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
function decodeClaim(bytes calldata data) pure returns (uint64 poolId, uint128 fee0, uint128 fee1) {
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
function encodeAllocate(uint8 useMax, uint64 poolId, uint128 deltaLiquidity) pure returns (bytes memory data) {
    (uint8 power, uint128 base) = AssemblyLib.fromAmount(deltaLiquidity);
    data = abi.encodePacked(AssemblyLib.pack(bytes1(useMax), ALLOCATE), poolId, power, base);
}

function decodeAllocate(bytes calldata data) pure returns (uint8 useMax, uint64 poolId, uint128 deltaLiquidity) {
    // Looks like using Solidity or Assembly is the same in terms of gas cost.
    if (data.length < 11) revert InvalidBytesLength(11, data.length);

    assembly {
        let value := calldataload(data.offset)
        useMax := shr(252, value)
        poolId := shr(192, shl(8, value))
        let power := shr(248, shl(72, value))
        let base := shr(sub(256, mul(8, sub(data.length, 10))), shl(80, value))
        deltaLiquidity := mul(base, exp(10, power))
    }
}

/**
 * @dev Encodes a deallocate operation.
 * FIXME: Same issue as `encodeClaim`... This function is not optimized!
 */
function encodeDeallocate(uint8 useMax, uint64 poolId, uint128 deltaLiquidity) pure returns (bytes memory data) {
    (uint8 power, uint128 base) = AssemblyLib.fromAmount(deltaLiquidity);
    data = abi.encodePacked(AssemblyLib.pack(bytes1(useMax), DEALLOCATE), poolId, power, base);
}

function decodeDeallocate(bytes calldata data) pure returns (uint8 useMax, uint64 poolId, uint128 deltaLiquidity) {
    if (data.length < 11) revert InvalidBytesLength(11, data.length);

    assembly {
        let value := calldataload(data.offset)
        useMax := shr(252, value)
        poolId := shr(192, shl(8, value))
        let power := shr(248, shl(72, value))
        let base := shr(sub(256, mul(8, sub(data.length, 10))), shl(80, value))
        deltaLiquidity := mul(base, exp(10, power))
    }
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
    returns (uint8 useMax, uint64 poolId, uint128 input, uint128 output, uint8 sellAsset)
{
    assembly {
        let value := calldataload(data.offset)
        useMax := shr(252, value)
        sellAsset := shr(248, shl(4, value))
        let pointer0 := shr(248, shl(72, value))
        poolId := shr(192, shl(8, value))
        let pointer1 := shr(248, shl(72, value))
        let power0 := shr(248, shl(72, value))
        let base0 := shr(sub(256, mul(8, sub(data.length, 10))), shl(80, value))
        let power1 := shr(248, shl(72, value))
        let base1 := shr(sub(256, mul(8, sub(data.length, 10))), shl(80, value))
        input := mul(base0, exp(10, power0))
        output := mul(base1, exp(10, power1))
    }

    useMax = uint8(data[0] >> 4);
    sellAsset = uint8(data[1]);
    uint8 pointer0 = uint8(data[2]);
    poolId = uint64(AssemblyLib.toBytes8(data[3:pointer0]));
    uint8 pointer1 = uint8(data[pointer0]);
    input = AssemblyLib.toAmount(data[pointer0 + 1:pointer1]);
    output = AssemblyLib.toAmount(data[pointer1:data.length]);
}
