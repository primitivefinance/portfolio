pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {UD60x18, fromUD60x18, toUD60x18, ud, wrap, unwrap} from "@prb/math/UD60x18.sol";

import "../../contracts/libraries/BrainMath.sol";

contract TestBrainMath is Test {
    function test_sqrtPriceGridBase() public {
        UD60x18 sqrtPriceGridBase = wrap(PRICE_GRID_BASE).sqrt();
        assertEq(unwrap(sqrtPriceGridBase), SQRT_PRICE_GRID_BASE);
    }

    function test_lnSqrtPriceGridBase() public {
        UD60x18 lnSqrtPriceGridBase = wrap(SQRT_PRICE_GRID_BASE).ln();
        assertEq(unwrap(lnSqrtPriceGridBase), LN_SQRT_PRICE_GRID_BASE);
    }

    function test_sqrtPriceAtSlotZero() public {
        int128 slotIndex = 0;
        UD60x18 sqrtPrice = _getSqrtPriceAtSlot(slotIndex);
        assertEq(unwrap(sqrtPrice), unwrap(toUD60x18(1)));
        assertEq(unwrap(sqrtPrice), 1e18);
    }

    function test_sqrtPriceAtSlotPositiveIndex() public {
        int128 slotIndex = 1000;
        UD60x18 sqrtPrice = _getSqrtPriceAtSlot(slotIndex);
        emit log_uint(unwrap(sqrtPrice));
    }
}
