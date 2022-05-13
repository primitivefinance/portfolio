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

    function decodeAddLiquidity(bytes calldata data) internal pure returns (uint256) {}

    function decodeSwapExactETH(bytes calldata data) internal pure returns (uint256) {}
}
