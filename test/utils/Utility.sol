// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

function safeCastTo16(uint256 x) pure returns (uint16 y) {
    require(x < 1 << 16);

    y = uint16(x);
}
