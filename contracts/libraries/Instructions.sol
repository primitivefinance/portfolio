pragma solidity ^0.8.0;

import "./Decoder.sol";

library Instructions {
    error DecodePairBytesLength(uint256 length);

    function encodeCreatePair(address token0, address token1) internal pure returns (bytes memory data) {
        data = abi.encodePacked(token0, token1);
    }

    function encodeCreateCurve(
        uint24 sigma,
        uint32 maturity,
        uint16 fee,
        uint128 strike
    ) internal pure returns (bytes memory data) {
        data = abi.encodePacked(sigma, maturity, fee, strike);
    }

    /// @dev Expects a 40-byte length array with two addresses packed into it.
    /// @param data Maximum 20 + 20 = 40 bytes.
    /// | 0x | 20 bytes base token | 20 bytes quote token |.
    function decodeCreatePair(bytes calldata data) internal pure returns (address tokenBase, address tokenQuote) {
        if (data.length < 40) revert DecodePairBytesLength(data.length);
        tokenBase = address(bytes20(data[:20]));
        tokenQuote = address(bytes20(data[20:]));
    }

    /// @dev Expects a poolId and two left zero padded amounts for `basePerLiquidity` and `deltaLiquidity`.
    /// @param data Maximum 6 + 16 + 16 = 38 bytes.
    /// | 0x | left-pad 6 bytes poolId | left-pad 16 bytes | left padded 16 bytes |
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
        poolId = uint48(bytes6(data[:6]));
        pairId = uint16(bytes2(data[:2]));
        curveId = uint32(bytes4(data[2:6]));
        basePerLiquidity = uint128(bytes16(data[6:22]));
        deltaLiquidity = uint128(bytes16(data[22:]));
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

    /// @notice The pool swap fee is a parameter, which is store and then used to calculate `gamma`.
    /// @dev Expects a 25 length byte array of left padded parameters.
    /// @param data Maximum 3 + 4 + 2 + 16 = 25 bytes.
    /// | 0x | 3 bytes sigma | 4 bytes maturity | 2 bytes fee | 16 bytes strike |
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
        sigma = uint24(bytes3(data[:3]));
        maturity = uint32(bytes4(data[3:7]));
        fee = uint16(bytes2(data[7:9]));
        strike = uint128(bytes16(data[9:]));
    }

    /// @dev Expects an opcode, poolId, and trailing run-length encoded amount.
    /// @param data Maximum 1 + 6 + 16 = 23 bytes.
    /// | 0x | 1 packed byte useMax Flag - opcode | 6 byte poolId | 1 packed byte amount length - amount power | amount in amount length bytes |.
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
        useMax = uint8((bytes1(data[0]) & 0xf0) >> 4);
        poolId = uint48(bytes6(data[1:7]));
        pairId = uint16(bytes2(data[1:3]));
        deltaLiquidity = uint128(Decoder.bytesToSingleAmount(data[7:])); // note: does not use higher bits length data, only decimals.
    }

    /// @dev Expects the standard instruction with two trailing run-length encoded amounts.
    /// @param data Maximum 8 + 16 + 16 = 40 bytes.
    /// | 0x | 1 packed byte useMax Flag - opcode | 6 byte poolId | 1 packed len-power amount0 | amount0 | amount1 | 1 packed len-power amount1 |.
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
        useMax = uint8((bytes1(data[0]) & 0xf0) >> 4);
        poolId = uint48(bytes6(data[1:7]));
        uint8 basePower = uint8(bytes1(data[7]) & 0x0f);
        uint8 baseLen = uint8((bytes1(data[7]) & 0xf0) >> 4);
        uint8 quotePower = uint8(bytes1(data[data.length - 1]) & 0x0f);
        uint8 quoteLen = uint8((bytes1(data[data.length - 1]) & 0xf0) >> 4);
        bytes memory base = data[8:8 + baseLen];
        bytes memory quote = data[baseLen + 8:baseLen + 8 + quoteLen];
        deltaBase = uint128(uint128(bytes16(base) >> ((16 - uint8(base.length)) * 8)) * 10**basePower);
        deltaQuote = uint128(uint128(bytes16(quote) >> ((16 - uint8(quote.length)) * 8)) * 10**quotePower);
    }

    /// @notice Swap direction: 0 = base token to quote token, 1 = quote token to base token.
    /// @dev Expects standard instructions with the end byte specifying swap direction.
    /// @param data Maximum 1 + 6 + 16 + 1 = 24 bytes.
    /// | 0x | 1 byte packed flag-opcode | 6 byte poolId | up to 16 byte TRLE amount | 1 byte direction |.
    function decodeSwapExactTokens(bytes calldata data)
        internal
        pure
        returns (
            uint8 useMax,
            uint48 poolId,
            uint128 deltaIn,
            uint8 direction
        )
    {
        useMax = uint8((bytes1(data[0]) & 0xf0) >> 4);
        poolId = uint48(bytes6(data[1:7]));
        deltaIn = uint128(Decoder.bytesToSingleAmount(data[7:data.length - 1])); // note: does not use higher bits length data, only decimals.
        direction = uint8(data[data.length - 1]);
    }

    function decodeSwapExactETH(bytes calldata data) internal pure returns (uint256) {}
}
