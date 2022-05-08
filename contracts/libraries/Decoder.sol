// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library Decoder {
    function getNibbles(bytes1 data) internal pure returns (uint8 a, uint8 b) {
        a = uint8(data >> 4);
        b = uint8(data << 0x0f);
    }

    function convert(bytes memory raw) external pure returns (bytes32 data) {
        assembly {
            let shift := mul(sub(32, mload(raw)), 8)
            data := mload(add(raw, 32))
            data := shr(shift, data)
        }
    }
}
