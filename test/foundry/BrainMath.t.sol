// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {UD60x18, fromUD60x18, toUD60x18, ud, wrap, unwrap} from "@prb/math/UD60x18.sol";

import "../../contracts/libraries/BrainMath.sol";

contract TestBrainMath is Test {
    uint256 constant MAX_PERCENT_DELTA = 0.000000001e18;

    function test_sqrtPriceGridBase() public {
        UD60x18 sqrtPriceGridBase = wrap(PRICE_GRID_BASE).sqrt();
        assertEq(unwrap(sqrtPriceGridBase), SQRT_PRICE_GRID_BASE);
    }

    function test_lnSqrtPriceGridBase() public {
        UD60x18 lnSqrtPriceGridBase = wrap(SQRT_PRICE_GRID_BASE).ln();
        assertEq(unwrap(lnSqrtPriceGridBase), LN_SQRT_PRICE_GRID_BASE);
    }

    function test_getSqrtPriceAtSlot_zero() public {
        int128 slotIndex = 0;
        UD60x18 sqrtPrice = _getSqrtPriceAtSlot(slotIndex);
        assertEq(unwrap(sqrtPrice), unwrap(toUD60x18(1)));
    }

    function test_getSqrtPriceAtSlot_positive_index() public {
        int128 slotIndex = 1000;
        UD60x18 sqrtPrice = _getSqrtPriceAtSlot(slotIndex);
        assertApproxEqRel(unwrap(sqrtPrice), 1051268468376662000, MAX_PERCENT_DELTA);
    }

    function test_getSqrtPriceAtSlot_negative_index() public {
        int128 slotIndex = -1000;
        UD60x18 sqrtPrice = _getSqrtPriceAtSlot(slotIndex);
        assertApproxEqRel(unwrap(sqrtPrice), 951231802418815800, MAX_PERCENT_DELTA);
    }

    function test_getSlotAtSqrtPrice_random_price() public {
        UD60x18 sqrtPrice = toUD60x18(1200).sqrt();
        int128 slotIndex = _getSlotAtSqrtPrice(sqrtPrice);
        assertEq(slotIndex, 70904);
    }

    function test_getDeltaAToNextPrice_should_round_up() public {
        int128 currentSlotIndex = 0;

        uint256 deltaA = getDeltaAToNextPrice(
            _getSqrtPriceAtSlot(10),
            _getSqrtPriceAtSlot(currentSlotIndex),
            10,
            Rounding.Up
        );

        assertEq(deltaA, 1);
    }

    function test_getDeltaAToNextPrice_should_round_down() public {
        int128 currentSlotIndex = 0;

        uint256 deltaA = getDeltaAToNextPrice(
            _getSqrtPriceAtSlot(10),
            _getSqrtPriceAtSlot(currentSlotIndex),
            10,
            Rounding.Down
        );

        assertEq(deltaA, 0);
    }
}
