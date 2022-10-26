// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "solmate/utils/FixedPointMathLib.sol";

library BrainMath {
    /**
     * @dev Returns the slot index associated with a price
     * @param price Price associated with the slot (with 10^18 precision)
     * @param a Tick spacing (with 10^18 precision)
     * @return Associated slot index (with 10^18 precision)
     */
    function getSlotFromPrice(int256 price, int256 a) internal pure returns (uint256) {
        return (FixedPointMathLib.divWadDown(
            uint256(FixedPointMathLib.lnWad(price)),
            uint256(FixedPointMathLib.lnWad(a))
        ) + 500000000000000000);
    }
}
