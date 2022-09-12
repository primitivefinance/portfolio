pragma solidity 0.8.13;

import "../Hyper.sol";

contract TestHyperTime is Hyper {
    uint256 public timestamp;

    function set(uint256 x) public {
        timestamp = x;
    }

    constructor(address weth) Hyper(weth) {}

    function _blockTimestamp() internal view override returns (uint128) {
        return uint128(timestamp);
    }
}
