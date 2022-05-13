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
            uint128 strike,
            uint32 sigma,
            uint32 maturity,
            uint32 gamma
        )
    {}

    function decodePoolId(bytes calldata data)
        internal
        pure
        returns (
            uint128 strike,
            uint32 sigma,
            uint32 maturity,
            uint32 gamma
        )
    {}

    /// @dev Encoded calldata is packed without zeros.
    function decodeCreateCurve(bytes calldata data)
        internal
        pure
        returns (
            uint128 strike,
            uint24 sigma,
            uint32 maturity,
            uint16 fee
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
