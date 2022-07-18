// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

/**
 * @title Safe Cast.
 * @dev Casts from uint256 to uint128, checking for overflows.
 */
library SafeCast {
    /// @notice reverts if x > type(uint128).max
    function toUint128(uint256 x) internal pure returns (uint128 z) {
        uint128 max = type(uint128).max;
        assembly {
            switch iszero(gt(x, max))
            case 0 {
                revert(0, 0)
            }
            case 1 {
                z := x
            }
        }
    }
}
