// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

// TODO: Check which one is the best to use?
import "@prb/math/contracts/PRBMathSD59x18.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

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

function _calculateDeltaX(
    uint256 liquidityDeltaFixedPoint,
    uint256 priceSqrtAFixedPoint,
    uint256 priceSqrtBFixedPoint
) pure returns (uint256) {
    (priceSqrtAFixedPoint, priceSqrtBFixedPoint) = priceSqrtAFixedPoint < priceSqrtBFixedPoint
        ? (priceSqrtAFixedPoint, priceSqrtBFixedPoint)
        : (priceSqrtBFixedPoint, priceSqrtAFixedPoint);

    return
        PRBMathUD60x18.div(
            PRBMathUD60x18.mul(liquidityDeltaFixedPoint, priceSqrtBFixedPoint - priceSqrtAFixedPoint),
            PRBMathUD60x18.mul(priceSqrtBFixedPoint, priceSqrtAFixedPoint)
        );
}

function _calculateDeltaY(
    uint256 liquidityDeltaFixedPoint,
    uint256 priceSqrtAFixedPoint,
    uint256 priceSqrtBFixedPoint
) pure returns (uint256) {
    (priceSqrtAFixedPoint, priceSqrtBFixedPoint) = priceSqrtAFixedPoint < priceSqrtBFixedPoint
        ? (priceSqrtAFixedPoint, priceSqrtBFixedPoint)
        : (priceSqrtBFixedPoint, priceSqrtAFixedPoint);

    return PRBMathUD60x18.mul(liquidityDeltaFixedPoint, priceSqrtBFixedPoint - priceSqrtAFixedPoint);
}
