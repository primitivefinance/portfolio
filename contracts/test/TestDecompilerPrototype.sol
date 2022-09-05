pragma solidity 0.8.13;

import "../prototype/DecompilerPrototype.sol";

contract TestDecompilerPrototype is DecompilerPrototype {
    constructor(address weth) DecompilerPrototype(weth) {}

    uint256 public timestamp;

    function set(uint256 time) public {
        timestamp = time;
    }

    function _blockTimestamp() internal view override returns (uint128) {
        return uint128(timestamp);
    }
}
