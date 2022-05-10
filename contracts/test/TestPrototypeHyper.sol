pragma solidity ^0.8.11;

import "../PrototypeHyper.sol";

contract TestPrototypeHyper is PrototypeHyper {
    function testDecodeAmountInfo(bytes calldata data)
        public
        view
        returns (
            bytes1 max,
            bytes1 ord,
            bytes1 len,
            bytes1 dec,
            bytes1 end,
            bytes32 amt
        )
    {
        bytes memory data_ = data;
        return decodeAmountInfo(data_);
    }

    function testDecodeAmount(bytes calldata data)
        public
        view
        returns (uint256 decoded)
    {
        bytes1 info = bytes1(data[1]);
        bytes1 firstBit = info >> 4;
        bytes1 secondBit = info & 0x0f;
        bytes32 v = bytes32(data) << uint8(firstBit);
        console.logBytes32(v);

        /* bytes1 firstBit = 0x0c;
        bytes1 secondBit = 0x03; */

        /*  {
            bytes memory test = toBytes(uint256(15000000000000555));
            console.logBytes(test);
        } */

        //console.logBytes1(info);
        //console.logBytes1(firstBitMasked);

        bytes memory amount = data[2:data.length - 1];
        /* bytes memory amount2 = amount;

        bytes32 amt2;
        assembly {
            amt := mload(add(add(amount, 0x03), 0x00))
        }
        assembly {
            amt2 := mload(add(amount2, add(0x20, 0x00)))
        } */
        // should be 0xc3354a6ba7a1822b
        /* console.log(toUint256(amount, 64)); */
        /* console.logBytes32(bytes32(amount));
        console.logBytes32(bytes32(amount) >> (256 - 56));
        console.logBytes(amount);
        console.logBytes(amount2);
        console.log(amount.length);
        console.log(amount2.length);
        console.log(uint256(amt));
        console.log(uint256(amt2)); */

        //bytes32 adjusted = bytes32(amount) >> (256 - (uint8(firstBit) * 4 + 8));
        bytes32 adjusted = bytes32(amount) >> ((32 - uint8(amount.length)) * 8);
        uint256 testAmt = uint256(adjusted) * 10**uint8(secondBit);
        console.logBytes32(adjusted);
        console.log(testAmt);
        decoded = testAmt;

        //decoded = uint256(bytes32(amount) >> (256 - 56)) * 10**uint8(secondBit);
    }

    function parseInt(bytes memory _bytesValue)
        public
        pure
        returns (uint256 _ret)
    {
        uint256 j = 1;
        for (
            uint256 i = _bytesValue.length - 1;
            i >= 0 && i < _bytesValue.length;
            i--
        ) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48) * j;
            j *= 10;
        }
    }

    function toBytes(uint256 _base) internal pure returns (bytes memory _ret) {
        assembly {
            let m_alloc := add(msize(), 0x1)
            _ret := mload(m_alloc)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _base)
        }
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
}
