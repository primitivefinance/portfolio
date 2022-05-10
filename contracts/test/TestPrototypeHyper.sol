pragma solidity ^0.8.11;

import "../PrototypeHyper.sol";

contract TestPrototypeHyper is PrototypeHyper {
    function testDecodeInfo(bytes calldata data)
        public
        view
        returns (
            bytes1 max,
            bytes1 ord,
            bytes1 len,
            bytes1 dec,
            bytes1 end,
            uint256 amt
        )
    {
        return Decoder.decodeArgs(data);
    }

    function testDecodeAmount(bytes calldata data) public pure returns (uint256 decoded) {
        decoded = Decoder.encodedBytesToAmount(data);
    }

    function decodeArgs(bytes calldata data)
        public
        pure
        returns (
            bytes1 max,
            bytes1 ord,
            bytes1 len,
            bytes1 dec,
            bytes1 end,
            uint256 amt
        )
    {
        return Decoder.decodeArgs(data);
    }
}
