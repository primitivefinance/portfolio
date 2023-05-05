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

error InvalidBytesLength(uint256 expected, uint256 length); // 0xe19dc95e

/**
 * @dev Returns an encoded pool id given specific pool parameters.
 * The encoding is simply packing the different parameters together.
 * @param pairId Id of the pair of asset / quote tokens
 * @param isMutable True if the pool is mutable
 * @param poolNonce Current pool nonce of the Portfolio contract
 * @return poolId Corresponding encoded pool id
 * @custom:example
 * ```
 * uint64 poolId = encodePoolId(7, true, 42);
 * ```
 */
function encodePoolId(
    uint24 pairId,
    bool isMutable,
    uint32 poolNonce
) pure returns (uint64 poolId) {
    assembly {
        poolId := or(or(shl(40, pairId), shl(32, isMutable)), poolNonce)
    }
}

/**
 * @dev Decodes the parameters of a pool given its id.
 * The pool id is expected to be encoded using the following format:\
 * `0x | pairId (3 bytes) | isMutable (1 byte) | poolNonce (4 bytes)`
 * @param data Encoded pool id
 * @return poolId Pool id converted from bytes to uint64
 * @return pairId Pair id of the pool
 * @return isMutable True if the pool is mutable
 * @return poolNonce Pool nonce of the pool
 * @custom:example
 * ```
 * (uint64 poolId, uint24 pairId, uint8 isMutable, uint32 poolNonce)
 *     = decodePoolId(0x000007010000002a);
 * ```
 */
function decodePoolId(bytes calldata data)
    pure
    returns (uint64 poolId, uint24 pairId, uint8 isMutable, uint32 poolNonce)
{
    // Using Solidity here doesn't impact the gas cost.
    if (data.length != 8) revert InvalidBytesLength(8, data.length);

    assembly {
        // For some reason not using calldataload all the time helps reducing
        // the gas cost. I think it might be linked to going too deep into the
        // stack.
        let value := calldataload(data.offset)
        poolId := shr(192, calldataload(data.offset))
        pairId := shr(232, calldataload(data.offset))
        isMutable := shr(248, calldataload(add(3, data.offset)))
        poolNonce := shr(224, shl(32, value))
    }
}
