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
        assertApproxEqRel(
            unwrap(sqrtPrice),
            1051268468376662000,
            MAX_PERCENT_DELTA
        );
    }

    function test_getSqrtPriceAtSlot_negative_index() public {
        int128 slotIndex = -1000;
        UD60x18 sqrtPrice = _getSqrtPriceAtSlot(slotIndex);
        assertApproxEqRel(
            unwrap(sqrtPrice),
            951231802418815800,
            MAX_PERCENT_DELTA
        );
    }

    function test_getSlotAtSqrtPrice_random_price() public {
        UD60x18 sqrtPrice = toUD60x18(1200).sqrt();
        int128 slotIndex = _getSlotAtSqrtPrice(sqrtPrice);
        assertEq(slotIndex, 70904);
    }

    function test_getDeltaXToNextPrice_should_round_up() public {
        int128 currentSlotIndex = 0;

        (uint256 deltaX) = getDeltaXToNextPrice(
            _getSqrtPriceAtSlot(10),
            _getSqrtPriceAtSlot(currentSlotIndex),
            10,
            true
        );

        assertEq(deltaX, 1);
    }

    function test_getDeltaXToNextPrice_should_round_down() public {
        int128 currentSlotIndex = 0;

        (uint256 deltaX) = getDeltaXToNextPrice(
            _getSqrtPriceAtSlot(10),
            _getSqrtPriceAtSlot(currentSlotIndex),
            10,
            false
        );

        assertEq(deltaX, 0);
    }

    function test_getDeltaXToNextPrice_higher_next_price() public {
        int128 currentSlotIndex = 20000;

        (uint256 deltaX) = getDeltaXToNextPrice(
            _getSqrtPriceAtSlot(20100),
            _getSqrtPriceAtSlot(currentSlotIndex),
            1000000000,
            true
        );

        assertEq(deltaX, 1834807);
    }

    function test_getDeltaXToNextPrice_lower_next_price() public {
        int128 currentSlotIndex = 20100;

        (uint256 deltaX) = getDeltaXToNextPrice(
            _getSqrtPriceAtSlot(20000),
            _getSqrtPriceAtSlot(currentSlotIndex),
            1000000000,
            true
        );

        assertEq(deltaX, 1834807);
    }

    function test_getDeltaYToNextPrice_should_round_up() public {
        int128 currentSlotIndex = 0;

        (uint256 deltaY) = getDeltaYToNextPrice(
            _getSqrtPriceAtSlot(10),
            _getSqrtPriceAtSlot(currentSlotIndex),
            10,
            true
        );

        assertEq(deltaY, 1);
    }

    function test_getDeltaYToNextPrice_should_round_down() public {
        int128 currentSlotIndex = 0;

        (uint256 deltaY) = getDeltaYToNextPrice(
            _getSqrtPriceAtSlot(10),
            _getSqrtPriceAtSlot(currentSlotIndex),
            10,
            false
        );

        assertEq(deltaY, 0);
    }

    function test_getDeltaYToNextPrice_higher_next_price() public {
        int128 currentSlotIndex = 20000;

        (uint256 deltaY) = getDeltaYToNextPrice(
            _getSqrtPriceAtSlot(20100),
            _getSqrtPriceAtSlot(currentSlotIndex),
            1000000000,
            true
        );

        assertEq(deltaY, 13624081);
    }

    function test_getDeltaYToNextPrice_lower_next_price() public {
        int128 currentSlotIndex = 20100;

        (uint256 deltaY) = getDeltaYToNextPrice(
            _getSqrtPriceAtSlot(20000),
            _getSqrtPriceAtSlot(currentSlotIndex),
            1000000000,
            true
        );

        assertEq(deltaY, 13624081);
    }

    function test_getTargetPriceUsingDeltaX_should() public {
        UD60x18 targetPrice = getTargetPriceUsingDeltaX(
            _getSqrtPriceAtSlot(20000),
            1000000000000000000000000000,
            10000000000
        );

        assertApproxEqRel(unwrap(targetPrice), 2718145926819817600, MAX_PERCENT_DELTA);
    }

    function test_getTargetPriceUsingDeltaY_should() public {
        UD60x18 targetPrice = getTargetPriceUsingDeltaY(
            _getSqrtPriceAtSlot(20000),
            1000000000000000000000000000,
            10000000000
        );

        assertApproxEqRel(unwrap(targetPrice), 2718145926819817600, MAX_PERCENT_DELTA);
    }
}
