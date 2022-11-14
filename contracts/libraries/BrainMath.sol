// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "@prb/math/contracts/PRBMathSD59x18.sol";

/// @dev Get the price square root using the slot index
///      $$p(i)=1.0001^i$$
function _getPriceSqrtAtSlot(int256 aFixedPoint, int128 slotIndex) pure returns (uint256) {
    return uint256(PRBMathSD59x18.pow(aFixedPoint, int256(PRBMathSD59x18.div(PRBMathSD59x18.abs(slotIndex), 2))));
}

/// @dev Get the slot index using price square root
///      $$i = log_{1.0001}p(i)$$
function _getSlotAtPriceSqrt(uint256 aFixedPoint, uint256 priceSqrtFixedPoint) pure returns (int128) {
    return
        int128(
            PRBMathSD59x18.mul(
                PRBMathSD59x18.log10(PRBMathSD59x18.sqrt(int256(aFixedPoint))),
                PRBMathSD59x18.sqrt(int256(priceSqrtFixedPoint))
            )
        );
}
