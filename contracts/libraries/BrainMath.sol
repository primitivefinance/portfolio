// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "@prb/math/contracts/PRBMathUD60x18.sol";

uint256 constant PRICE_GRID_FIXED_POINT = 1000100000000000000; // 1.0001

// TODO: Solve the overloading issue or delete one of these functions
function abs(int256 n) pure returns (uint256) {
    return uint256(n > 0 ? n : ~n + 1);
}

function abs_(int128 n) pure returns (uint128) {
    return uint128(n > 0 ? n : ~n + 1);
}

/// @dev Get the price square root using the slot index
///      $$p(i)=1.0001^i$$
function _getSqrtPriceAtSlot(int128 slotIndex) pure returns (uint256) {
    return
        uint256(
            PRBMathUD60x18.pow(PRICE_GRID_FIXED_POINT, PRBMathUD60x18.div(abs_(slotIndex), 2))
        );
}

/// @dev Get the slot index using price square root
///      $$i = log_{1.0001}p(i)$$
function _getSlotAtSqrtPrice(uint256 sqrtPriceFixedPoint) pure returns (int128) {
    return
        int128(
            uint128(
                PRBMathUD60x18.mul(
                    PRBMathUD60x18.log10(PRBMathUD60x18.sqrt(PRICE_GRID_FIXED_POINT)),
                    PRBMathUD60x18.sqrt(sqrtPriceFixedPoint)
                )
            )
        );
}

function _calculateLiquidityDeltas(
    uint256 liquidityDeltaFixedPoint,
    uint256 sqrtPriceCurrentSlotFixedPoint,
    int128 currentSlotIndex,
    int128 lowerSlotIndex,
    int128 upperSlotIndex
) pure returns (uint256 amountA, uint256 amountB) {
    uint256 sqrtPriceUpperSlotFixedPoint = _getSqrtPriceAtSlot(upperSlotIndex);
    uint256 sqrtPriceLowerSlotFixedPoint = _getSqrtPriceAtSlot(lowerSlotIndex);

    if (currentSlotIndex < lowerSlotIndex) {
        amountA = PRBMathUD60x18.mul(
            liquidityDeltaFixedPoint,
            PRBMathUD60x18.div(PRBMathUD60x18.toUint(1), sqrtPriceLowerSlotFixedPoint) -
                PRBMathUD60x18.div(PRBMathUD60x18.toUint(1), sqrtPriceUpperSlotFixedPoint)
        );
    } else if (currentSlotIndex < upperSlotIndex) {
        amountA = PRBMathUD60x18.mul(
            liquidityDeltaFixedPoint,
            PRBMathUD60x18.div(PRBMathUD60x18.toUint(1), sqrtPriceCurrentSlotFixedPoint) -
                PRBMathUD60x18.div(PRBMathUD60x18.toUint(1), sqrtPriceUpperSlotFixedPoint)
        );

        amountB = PRBMathUD60x18.mul(
            liquidityDeltaFixedPoint,
            sqrtPriceCurrentSlotFixedPoint - sqrtPriceLowerSlotFixedPoint
        );
    } else {
        amountB = PRBMathUD60x18.mul(
            liquidityDeltaFixedPoint,
            sqrtPriceUpperSlotFixedPoint - sqrtPriceLowerSlotFixedPoint
        );
    }
}

function getDeltaXToNextPrice(
    uint256 sqrtPriceCurrentSlotFixedPoint,
    uint256 sqrtPriceNextSlotFixedPoint,
    uint256 liquidity
) pure returns (uint256) {
    return PRBMathUD60x18.div(PRBMathUD60x18.toUint(liquidity), sqrtPriceNextSlotFixedPoint) - PRBMathUD60x18.div(PRBMathUD60x18.toUint(liquidity), sqrtPriceCurrentSlotFixedPoint);
}

function getDeltaYToNextPrice(
    uint256 sqrtPriceCurrentSlotFixedPoint,
    uint256 sqrtPriceNextSlotFixedPoint,
    uint256 liquidity
) pure returns (uint256) {
    return PRBMathUD60x18.mul(PRBMathUD60x18.toUint(liquidity), sqrtPriceNextSlotFixedPoint - sqrtPriceCurrentSlotFixedPoint);
}

function getTargetPriceUsingDeltaX(
    uint256 sqrtPriceCurrentSlotFixedPoint,
    uint256 liquidity,
    uint256 deltaX
) pure returns (uint256) {
    return PRBMathUD60x18.div(
        PRBMathUD60x18.mul(
            sqrtPriceCurrentSlotFixedPoint, PRBMathUD60x18.toUint(liquidity)
        ),
        PRBMathUD60x18.mul(
            deltaX, sqrtPriceCurrentSlotFixedPoint
        ) + PRBMathUD60x18.toUint(liquidity)
    );
}

function getTargetPriceUsingDeltaY(
    uint256 sqrtPriceCurrentSlotFixedPoint,
    uint256 liquidity,
    uint256 deltaY
) pure returns (uint256) {
    return PRBMathUD60x18.div(deltaY, PRBMathUD60x18.toUint(liquidity)) + sqrtPriceCurrentSlotFixedPoint;
}
