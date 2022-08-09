// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../libraries/Decoder.sol";

contract TestDecoder {
    function separate(bytes1 data) external pure returns (bytes1 upper, bytes1 lower) {
        return Decoder.separate(data);
    }

    function toBytes32(bytes memory raw) external pure returns (bytes32 data) {
        return Decoder.toBytes32(raw);
    }

    function toAmount(bytes calldata raw) external pure returns (uint256 amount) {
        return Decoder.toAmount(raw);
    }
}
