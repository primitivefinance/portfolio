// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {UD60x18, fromUD60x18, toUD60x18, ud, wrap, unwrap} from "@prb/math/UD60x18.sol";

import "../../contracts/libraries/BrainMath.sol";

contract TestCalculateLiquidityUnderlying is Test {
    uint256 constant MAX_PERCENT_DELTA = 0.000000001e18;

    function test_calculateLiquidityUnderlying_should_round_up() public {
        int128 currentSlotIndex = 70904;

        (uint256 amountA, uint256 amountB) = _calculateLiquidityUnderlying(
            10000,
            _getSqrtPriceAtSlot(currentSlotIndex),
            10000,
            20000,
            Rounding.Up
        );

        assertEq(amountA, 0);
        assertEq(amountB, 10695);
    }

    function test_calculateLiquidityUnderlying_should_round_down() public {
        int128 currentSlotIndex = 70904;

        (uint256 amountA, uint256 amountB) = _calculateLiquidityUnderlying(
            10000,
            _getSqrtPriceAtSlot(currentSlotIndex),
            10000,
            20000,
            Rounding.Down
        );

        assertEq(amountA, 0);
        assertEq(amountB, 10694);
    }

    function test_calculateLiquidityUnderlying_current_slot_equals_lower_slot() public {
        int128 currentSlotIndex = 10000;

        (uint256 amountA, uint256 amountB) = _calculateLiquidityUnderlying(
            10000,
            _getSqrtPriceAtSlot(currentSlotIndex),
            10000,
            20000,
            Rounding.Down
        );

        assertEq(amountA, 2386);
        assertEq(amountB, 0);
    }

    function test_calculateLiquidityUnderlying_current_slot_between_slots() public {
        int128 currentSlotIndex = 15000;

        (uint256 amountA, uint256 amountB) = _calculateLiquidityUnderlying(
            10000,
            _getSqrtPriceAtSlot(currentSlotIndex),
            10000,
            20000,
            Rounding.Down
        );

        assertEq(amountA, 1044);
        assertEq(amountB, 4682);
    }

    function test_calculateLiquidityUnderlying_current_slot_above_upper_slot() public {
        int128 currentSlotIndex = 25000;

        (uint256 amountA, uint256 amountB) = _calculateLiquidityUnderlying(
            10000,
            _getSqrtPriceAtSlot(currentSlotIndex),
            10000,
            20000,
            Rounding.Down
        );

        assertEq(amountA, 0);
        assertEq(amountB, 10694);
    }
}
