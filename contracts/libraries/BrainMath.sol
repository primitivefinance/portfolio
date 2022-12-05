// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import {UD60x18, fromUD60x18, toUD60x18, wrap as wrapUD60x18, unwrap as unwrapUD60x18} from "@prb/math/UD60x18.sol";
import {SD59x18, fromSD59x18, toSD59x18, wrap as wrapSD59x18, unwrap as unwrapSD59x18} from "@prb/math/SD59x18.sol";

uint256 constant PRICE_GRID_BASE = 1000100000000000000; // 1.0001e18
uint256 constant SQRT_PRICE_GRID_BASE = 1000049998750062496; // 60x18 value for 1.0001.sqrt()
uint256 constant LN_SQRT_PRICE_GRID_BASE = 49997500166647; // 60x18 value for 1.0001.sqrt().ln()

// TODO: Solve the overloading issue or delete one of these functions
function abs(int256 n) pure returns (uint256) {
    return uint256(n > 0 ? n : ~n + 1);
}

function abs_(int128 n) pure returns (uint128) {
    return uint128(n > 0 ? n : ~n + 1);
}

/// @dev Get the price square root using the slot index
///      $$\sqrt_p(i)=sqrt(1.0001)^{i}$$
function _getSqrtPriceAtSlot(int128 slotIndex) pure returns (UD60x18 sqrtPrice) {
    if (slotIndex == 0) {
        sqrtPrice = toUD60x18(1);
    } else {
        sqrtPrice = wrapUD60x18(SQRT_PRICE_GRID_BASE).pow(toUD60x18(abs_(slotIndex)));
        if (slotIndex < 0) {
            sqrtPrice = sqrtPrice.inv();
        }
    }
}

/// @dev Get the slot index using price square root
///      $$i = ln(sqrtPrice) / ln(sqrt(1.0001))$$
function _getSlotAtSqrtPrice(UD60x18 sqrtPrice) pure returns (int128 slotIndex) {
    // convert to SD59x18 in order to get signed slot indexes
    SD59x18 _sqrtPrice = wrapSD59x18(int256(unwrapUD60x18(sqrtPrice)));
    SD59x18 _lnSqrtPriceGridBase = wrapSD59x18(int256(LN_SQRT_PRICE_GRID_BASE));
    // if slotIndex is positive like 1.3, we want to round down to 1
    // if slotIndex is negative like -1.3, we want to round down to -2
    slotIndex = int128(fromSD59x18(_sqrtPrice.ln().div(_lnSqrtPriceGridBase).floor()));
}

function _calculateLiquidityUnderlying(
    uint256 liquidity,
    UD60x18 sqrtPriceCurrentSlot,
    int128 currentSlotIndex,
    int128 lowerSlotIndex,
    int128 upperSlotIndex
) pure returns (uint256 amountA, uint256 amountB) {
    UD60x18 sqrtPriceUpperSlot = _getSqrtPriceAtSlot(upperSlotIndex);
    UD60x18 sqrtPriceLowerSlot = _getSqrtPriceAtSlot(lowerSlotIndex);

    if (currentSlotIndex < lowerSlotIndex) {
        amountA = fromUD60x18(toUD60x18(liquidity).mul(sqrtPriceLowerSlot.inv().sub(sqrtPriceUpperSlot.inv())));
    } else if (currentSlotIndex < upperSlotIndex) {
        amountA = fromUD60x18(toUD60x18(liquidity).mul(sqrtPriceCurrentSlot.inv().sub(sqrtPriceUpperSlot.inv())));
        amountB = fromUD60x18(toUD60x18(liquidity).mul(sqrtPriceCurrentSlot.sub(sqrtPriceLowerSlot)));
    } else {
        amountB = fromUD60x18(toUD60x18(liquidity).mul(sqrtPriceUpperSlot.sub(sqrtPriceLowerSlot)));
    }
}

function getDeltaXToNextPrice(
    UD60x18 sqrtPriceCurrentSlot,
    UD60x18 sqrtPriceNextSlot,
    uint256 liquidity
) pure returns (uint256) {
    return fromUD60x18(toUD60x18(liquidity).div(sqrtPriceNextSlot).sub(toUD60x18(liquidity).div(sqrtPriceCurrentSlot)));
}

function getDeltaYToNextPrice(
    UD60x18 sqrtPriceCurrentSlot,
    UD60x18 sqrtPriceNextSlot,
    uint256 liquidity
) pure returns (uint256) {
    return fromUD60x18(toUD60x18(liquidity).mul(sqrtPriceNextSlot.sub(sqrtPriceCurrentSlot)));
}

function getTargetPriceUsingDeltaX(
    UD60x18 sqrtPriceCurrentSlot,
    uint256 liquidity,
    uint256 deltaX
) pure returns (UD60x18) {
    return
        toUD60x18(liquidity).mul(sqrtPriceCurrentSlot).div(
            toUD60x18(deltaX).mul(sqrtPriceCurrentSlot).add(toUD60x18(liquidity))
        );
}

function getTargetPriceUsingDeltaY(
    UD60x18 sqrtPriceCurrentSlot,
    uint256 liquidity,
    uint256 deltaY
) pure returns (UD60x18) {
    return toUD60x18(deltaY).div(toUD60x18(liquidity)).add(sqrtPriceCurrentSlot);
}
