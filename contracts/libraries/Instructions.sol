// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Decoder.sol";

library Instructions {
    error DecodePairBytesLength(uint256 expected, uint256 length);

    /// @dev Encodes the arugments for the CREATE_CURVE instruction.
    function encodeCreateCurve(
        uint24 sigma,
        uint32 maturity,
        uint16 fee,
        uint128 strike
    ) internal pure returns (bytes memory data) {
        uint8 ecode = 0x0D;
        data = abi.encodePacked(ecode, sigma, maturity, fee, strike);
    }

    /// @dev Encodes the arguments for the CREATE_PAIR instruction.
    function encodeCreatePair(address token0, address token1) internal pure returns (bytes memory data) {
        uint8 ecode = 0x0C;
        data = abi.encodePacked(ecode, token0, token1);
    }

    /// @dev Encodes the arguments for the CREATE_POOL instruction.
    function encodeCreatePool(
        uint48 poolId,
        uint128 basePerLiquidity,
        uint128 deltaLiquidity
    ) internal pure returns (bytes memory data) {
        uint8 ecode = 0x0B;
        data = abi.encodePacked(ecode, poolId, basePerLiquidity, deltaLiquidity);
    }

    /// @dev Expects the standard instruction with two trailing run-length encoded amounts.
    /// @param data Maximum 8 + 16 + 16 = 40 bytes.
    /// | 0x | 1 packed byte useMax Flag - enigma code | 6 byte poolId | 1 byte pointer to next power byte | 1 byte power | ...amount | 1 byte power | ...amount |
    function decodeAddLiquidity(bytes calldata data)
        internal
        pure
        returns (
            uint8 useMax,
            uint48 poolId,
            uint128 deltaBase,
            uint128 deltaQuote
        )
    {
        (bytes1 maxFlag, ) = Decoder.separate(data[0]);
        useMax = uint8(maxFlag);
        poolId = uint48(bytes6(data[1:7]));
        uint8 pointer = uint8(data[7]);
        deltaBase = Decoder.toAmount(data[8:pointer]);
        deltaQuote = Decoder.toAmount(data[pointer:]);
    }

    /// @notice The pool swap fee is a parameter, which is store and then used to calculate `gamma`.
    /// @dev Expects a 25 length byte array of left padded parameters.
    /// @param data Maximum 1 + 3 + 4 + 2 + 16 = 26 bytes.
    /// | 0x | 1 byte enigma code | 3 bytes sigma | 4 bytes maturity | 2 bytes fee | 16 bytes strike |
    function decodeCreateCurve(bytes calldata data)
        internal
        pure
        returns (
            uint24 sigma,
            uint32 maturity,
            uint16 fee,
            uint128 strike
        )
    {
        require(data.length < 32, "Curve data too long");
        sigma = uint24(bytes3(data[1:4])); // note: First byte is the create pair ecode.
        maturity = uint32(bytes4(data[4:8]));
        fee = uint16(bytes2(data[8:10]));
        strike = uint128(bytes16(data[10:]));
    }

    /// @dev Expects a 41-byte length array with two addresses packed into it.
    /// @param data Maximum 1 + 20 + 20 = 41 bytes.
    /// | 0x | 1 byte enigma code | 20 bytes base token | 20 bytes quote token |.
    function decodeCreatePair(bytes calldata data) internal pure returns (address tokenBase, address tokenQuote) {
        if (data.length != 41) revert DecodePairBytesLength(41, data.length);
        tokenBase = address(bytes20(data[1:21])); // note: First byte is the create pair ecode.
        tokenQuote = address(bytes20(data[21:]));
    }

    /// @dev Expects a poolId and two left zero padded amounts for `basePerLiquidity` and `deltaLiquidity`.
    /// @param data Maximum 1 + 6 + 16 + 16 = 39 bytes.
    /// | 0x | 1 byte enigma code | left-pad 6 bytes poolId | left-pad 16 bytes | left padded 16 bytes |
    function decodeCreatePool(bytes calldata data)
        internal
        pure
        returns (
            uint48 poolId,
            uint16 pairId,
            uint32 curveId,
            uint128 basePerLiquidity,
            uint128 deltaLiquidity
        )
    {
        poolId = uint48(bytes6(data[1:7])); // note: First byte is the create pool ecode.
        pairId = uint16(bytes2(data[1:3]));
        curveId = uint32(bytes4(data[3:7]));
        basePerLiquidity = uint128(bytes16(data[7:23]));
        deltaLiquidity = uint128(bytes16(data[23:]));
    }

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

    /// @dev Expects an enigma code, poolId, and trailing run-length encoded amount.
    /// @param data Maximum 1 + 6 + 16 = 23 bytes.
    /// | 0x | 1 packed byte useMax Flag - enigma code | 6 byte poolId | 1 byte amount power | amount in amount length bytes |.
    function decodeRemoveLiquidity(bytes calldata data)
        internal
        pure
        returns (
            uint8 useMax,
            uint48 poolId,
            uint16 pairId,
            uint128 deltaLiquidity
        )
    {
        useMax = uint8(data[0] >> 4);
        poolId = uint48(bytes6(data[1:7]));
        pairId = uint16(bytes2(data[1:3]));
        deltaLiquidity = uint128(Decoder.toAmount(data[7:]));
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
            uint128 deltaIn,
            uint128 deltaOut,
            uint8 direction
        )
    {
        useMax = uint8(data[0] >> 4);
        poolId = uint48(bytes6(data[1:7]));
        uint8 pointer = uint8(data[7]);
        deltaIn = uint128(Decoder.toAmount(data[8:pointer]));
        deltaOut = uint128(Decoder.toAmount(data[pointer:data.length - 1])); // note: Up to but not including last byte.
        direction = uint8(data[data.length - 1]);
    }
}
