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
}
