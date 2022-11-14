// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "solmate/utils/FixedPointMathLib.sol";

function _abs(int256 x) pure returns (uint256) {
    return uint256(~x + 1);
}
