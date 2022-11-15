// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

// TODO: Check which one is the best to use?
import "@prb/math/contracts/PRBMathSD59x18.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

/// @dev Get the price square root using the slot index
///      $$p(i)=1.0001^i$$
function _getPriceSqrtAtSlot(uint256 aFixedPoint, int128 slotIndex) pure returns (uint256) {
    return uint256(PRBMathUD60x18.pow(aFixedPoint, PRBMathUD60x18.div(uint256(PRBMathSD59x18.abs(slotIndex)), 2)));
}

/// @dev Get the slot index using price square root
///      $$i = log_{1.0001}p(i)$$
function _getSlotAtPriceSqrt(uint256 aFixedPoint, uint256 priceSqrtFixedPoint) pure returns (int128) {
    return
        int128(
            uint128(
                PRBMathUD60x18.mul(
                    PRBMathUD60x18.log10(PRBMathUD60x18.sqrt(aFixedPoint)),
                    PRBMathUD60x18.sqrt(priceSqrtFixedPoint)
                )
            )
        );
}

function _calculateLiquidityDeltas(
    uint256 aFixedPoint,
    uint256 liquidityDeltaFixedPoint,
    uint256 priceSqrtCurrentSlotFixedPoint,
    int128 currentSlotIndex,
    int128 lowerSlotIndex,
    int128 upperSlotIndex
) pure returns (uint256 amountA, uint256 amountB) {
    uint256 priceSqrtUpperSlotFixedPoint = _getPriceSqrtAtSlot(aFixedPoint, upperSlotIndex);
    uint256 priceSqrtLowerSlotFixedPoint = _getPriceSqrtAtSlot(aFixedPoint, lowerSlotIndex);

    if (currentSlotIndex < lowerSlotIndex) {
        amountA = PRBMathUD60x18.mul(
            liquidityDeltaFixedPoint,
            PRBMathUD60x18.div(PRBMathUD60x18.toUint(1), priceSqrtLowerSlotFixedPoint) -
                PRBMathUD60x18.div(PRBMathUD60x18.toUint(1), priceSqrtUpperSlotFixedPoint)
        );
    } else if (currentSlotIndex < upperSlotIndex) {
        amountA = PRBMathUD60x18.mul(
            liquidityDeltaFixedPoint,
            PRBMathUD60x18.div(PRBMathUD60x18.toUint(1), priceSqrtCurrentSlotFixedPoint) -
                PRBMathUD60x18.div(PRBMathUD60x18.toUint(1), priceSqrtUpperSlotFixedPoint)
        );

        amountB = PRBMathUD60x18.mul(
            liquidityDeltaFixedPoint,
            priceSqrtCurrentSlotFixedPoint - priceSqrtLowerSlotFixedPoint
        );
    } else {
        amountB = PRBMathUD60x18.mul(
            liquidityDeltaFixedPoint,
            priceSqrtUpperSlotFixedPoint - priceSqrtLowerSlotFixedPoint
        );
    }
}
