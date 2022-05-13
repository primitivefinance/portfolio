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

    function testDecodeCreatePair(bytes calldata data) public view returns (address, address) {
        return Instructions.decodeCreatePair(data);
    }

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
        return Instructions.decodeCreateCurve(data);
    }

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
        return Instructions.decodeCreatePool(data);
    }
}
