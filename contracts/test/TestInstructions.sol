pragma solidity ^0.8.0;

import "../libraries/Instructions.sol";

contract TestInstructions {
    function testDecodePoolId(bytes calldata data)
        public
        view
        returns (
            uint48,
            uint16,
            uint32
        )
    {
        return Instructions.decodePoolId(data);
    }

    /// @dev First byte is the enigma instruction.
    function testDecodeCreatePair(bytes calldata data) public view returns (address, address) {
        return Instructions.decodeCreatePair(data[1:]);
    }

    /// @dev First byte is the enigma instruction.
    function testDecodeCreateCurve(bytes calldata data)
        public
        view
        returns (
            uint24,
            uint32,
            uint16,
            uint128
        )
    {
        return Instructions.decodeCreateCurve(data[1:]);
    }

    /// @dev First byte is the enigma instruction.
    function testDecodeCreatePool(bytes calldata data)
        public
        view
        returns (
            uint48,
            uint16,
            uint32,
            uint128,
            uint128
        )
    {
        return Instructions.decodeCreatePool(data[1:]);
    }

    /// @dev First byte is the enigma instruction.
    function testDecodeRemoveLiquidity(bytes calldata data)
        public
        view
        returns (
            uint8,
            uint48,
            uint16,
            uint128
        )
    {
        return Instructions.decodeRemoveLiquidity(data);
    }

    function testDecodeAddLiquidity(bytes calldata data)
        public
        view
        returns (
            uint8 useMax,
            uint48 poolId,
            uint128 deltaBase,
            uint128 deltaQuote
        )
    {
        return Instructions.decodeAddLiquidity(data);
    }

    function testDecodeAddLiquidityGas(bytes calldata data)
        public
        returns (
            uint8 useMax,
            uint48 poolId,
            uint128 deltaBase,
            uint128 deltaQuote
        )
    {
        return Instructions.decodeAddLiquidity(data);
    }

    function testDecodeSwapExactTokens(bytes calldata data)
        public
        view
        returns (
            uint8 useMax,
            uint48 poolId,
            uint128 deltaIn,
            uint8 direction
        )
    {
        return Instructions.decodeSwapExactTokens(data);
    }

    function testDecodeSwapExactTokensGas(bytes calldata data)
        public
        returns (
            uint8 useMax,
            uint48 poolId,
            uint128 deltaIn,
            uint8 direction
        )
    {
        return Instructions.decodeSwapExactTokens(data);
    }
}
