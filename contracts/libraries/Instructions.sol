pragma solidity ^0.8.0;
import "hardhat/console.sol";

library Instructions {
    function decodeCreatePair(bytes calldata data) internal pure returns (address tokenBase, address tokenQuote) {
        tokenBase = address(bytes20(data[:20]));
        tokenQuote = address(bytes20(data[20:]));
    }

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

    /// @dev Encoded calldata is packed without zeros.
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
        uint8 power = uint8(bytes1(data[7]));
        bytes memory value = data[8:];
        deltaLiquidity = uint128(uint128(bytes16(value) >> ((16 - uint8(value.length)) * 8)) * 10**power);
    }

    function decodeAddLiquidity(bytes calldata data)
        internal
        view
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

    function decodeSwapExactETH(bytes calldata data) internal pure returns (uint256) {}
}
