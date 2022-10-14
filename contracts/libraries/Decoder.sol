// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./Utils.sol";

/// @title    Hyper Decoder Library
/// @dev      Solidity library to decode the calldata bytes received by Hyper
/// @author   Primitive
library Decoder {
    // --- Errors --- //
    error DecodePairBytesLength(uint256 expected, uint256 length);

    // TODO: Update this function
    /// @dev Expects an enigma code, poolId, and trailing run-length encoded amount.
    /// @param data Maximum 1 + 6 + 3 + 3 + 16 = 29 bytes.
    /// | 0x | 1 packed byte useMax Flag - enigma code | 6 byte poolId | 3 byte loTick index | 3 byte hiTick index | 1 byte amount power | amount in amount length bytes |.
    function decodeAddOrRemoveLiquidity(bytes calldata data)
        internal
        pure
        returns (
            bytes1 instruction,
            uint8 useMax,
            uint24 poolId,
            uint16 pairId,
            int24 loTick,
            int24 hiTick,
            uint128 deltaLiquidity
        )
    {
        instruction = bytes1(data[0] & 0x0F);
        useMax = uint8(data[0] >> 4);
        pairId = uint16(bytes2(data[1:3]));
        poolId = uint24(bytes4(data[1:7]));
        loTick = int24(uint24(bytes3(data[7:10])));
        hiTick = int24(uint24(bytes3(data[10:13])));
        deltaLiquidity = uint128(unpackAmount(data[13:]));
    }

    // TODO: Update the NatSpec
    /// @dev Expects a 41-byte length array with two addresses packed into it.
    /// @param data Maximum 1 + 20 + 20 = 41 bytes.
    /// | 0x | 1 byte enigma code | 20 bytes base token | 20 bytes quote token |.
    function decodeCreatePool(bytes calldata data)
        internal
        pure
        returns (
            address token0,
            address token1,
            uint256 amount0,
            uint256 amount1
        )
    {
        // if (data.length != 41) revert DecodePairBytesLength(41, data.length);
        token0 = address(bytes20(data[1:21])); // note: First byte is the create pair ecode.
        token1 = address(bytes20(data[21:]));
        (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
        uint8 pointer = data[13];
        amount0 = uint128(unpackAmount(data[13:pointer]));
        pointer = data[pointer + 1];
        amount1 = uint128(unpackAmount(data[pointer:data.length]));
    }

    /*
    /// @dev Expects a poolId and one left zero padded amount for `price`.
    /// TODO: Update these comments, new encoding is:
    /// | 0x | 1 byte for instruction | 2 bytes for pair Id | 16 bytes for the price |
    /// @param data Maximum 1 + 6 + 16 = 23 bytes.
    /// | 0x | 1 byte enigma code | left-pad 6 bytes poolId | left-pad 16 bytes |
    function decodeCreatePool(bytes calldata data)
        internal
        pure
        returns (
            uint16 pairId,
            uint32 gamma,
            uint32 priorityGamma,
            uint128 price
        )
    {
        pairId = uint16(bytes2(data[1:3]));
        gamma = uint32(bytes4(data[3:7]));
        priorityGamma = uint32(bytes4(data[7:11]));
        price = uint128(bytes16(data[11:27]));
    }
    */

    /// @dev Expects a 6 byte left-pad `poolId`.
    /// @param data Maximum 6 bytes. | 0x | left-pad 6 bytes poolId |
    /// Pool id is a packed pair and curve id: | 0x | left-pad 2 bytes pairId | left-pad 4 bytes curveId |
    function decodePoolId(bytes calldata data)
        internal
        pure
        returns (
            uint48 poolId,
            uint16 pairId,
            uint32 curveId
        )
    {
        poolId = uint48(bytes6(data));
        pairId = uint16(bytes2(data[:2]));
        curveId = uint32(bytes4(data[2:]));
    }

    /// @notice Swap direction: 0 = base token to quote token, 1 = quote token to base token.
    /// @dev Expects standard instructions with the end byte specifying swap direction.
    /// @param data Maximum 1 + 6 + 16 + 1 = 24 bytes.
    /// | 0x | 1 byte packed flag-enigma code | 6 byte poolId | up to 16 byte TRLE amount | 1 byte direction |.
    function decodeSwap(bytes calldata data)
        internal
        pure
        returns (
            uint8 useMax,
            uint48 poolId,
            uint128 input,
            uint128 limit,
            uint8 direction
        )
    {
        useMax = uint8(data[0] >> 4);
        poolId = uint48(bytes6(data[1:7]));
        uint8 pointer = uint8(data[7]);
        input = uint128(unpackAmount(data[8:pointer]));
        limit = uint128(unpackAmount(data[pointer:data.length - 1])); // note: Up to but not including last byte.
        direction = uint8(data[data.length - 1]);
    }

    // TODO: decodeStakePosition and decodeUnstakePosition should be merged together

    /// @dev Expects an enigma code and positionId.
    /// @param data Maximum 1 + 12 = 13 bytes.
    /// | 0x | 1 packed byte useMax Flag - enigma code | 12 byte positionId |.
    function decodeStakingPosition(bytes calldata data) internal pure returns (uint48 poolId, uint96 positionId) {
        poolId = uint48(bytes6(data[1:7]));
        positionId = uint96(bytes12(data[1:13]));
    }

    /// @param data Maximum 1 + 6 + 20 + 8 + 8 = 43 bytes.
    /// | 0x | 1 byte enigma code | 6 byte poolId | 20 bytes winner | 8 byte power | 8 byte amount|.
    function decodeFillPriorityAuction(bytes calldata data)
        internal
        pure
        returns (
            uint48 poolId,
            address priorityOwner,
            uint128 limitOwner
        )
    {
        poolId = uint48(bytes6(data[1:7]));
        priorityOwner = address(bytes20(data[7:27]));
        limitOwner = uint128(unpackAmount(data[28:]));
    }

    /// | 1 byte pointer to next power byte | 1 byte power | ...amount | 1 byte power | ...amount |
    function decodeCollectFees(bytes calldata data)
        internal
        pure
        returns (
            uint96 positionId,
            uint128 amountAssetRequested,
            uint128 amountQuoteRequested
        )
    {
        positionId = uint96(bytes12(data[1:13]));
        uint8 pointer = uint8(data[13]);
        amountAssetRequested = uint128(unpackAmount(data[14:pointer]));
        amountQuoteRequested = uint128(unpackAmount(data[pointer:data.length]));
    }

    // TODO: Should we merge decodeDraw and decodeFund together?

    function decodeDraw(bytes calldata data)
        external
        pure
        returns (
            address to,
            address token,
            uint256 amount
        )
    {
        to = address(bytes20(data[1:21]));
        token = address(bytes20(data[21:41]));
        amount = unpackAmount(data[41:data.length]);
    }

    function decodeFund(bytes calldata data) external pure returns (address token, uint256 amount) {
        token = address(bytes20(data[1:21]));
        amount = unpackAmount(data[21:data.length]);
    }
}
