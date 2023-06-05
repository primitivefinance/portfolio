// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

import "../contracts/libraries/PortfolioLib.sol" as PortfolioLib;
import "../contracts/libraries/RMM01Lib.sol";
import "solstat/Gaussian.sol";
import "solstat/Invariant.sol";

uint256 constant MINIMUM_DELTA = 1;
uint256 constant MAXIMUM_RESERVE_X = 1e18 - 1;
uint256 constant MINIMUM_RESERVE_X = 1;
uint256 constant MINIMUM_RESERVE_Y = 1;
uint256 constant BASIS_POINTS_DEN = 10000;

contract TestPortfolioInvariant is Setup {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;
    // Default test case. Returns an invariant close to 0.
    // The result is about 1e-7.

    function test_invariant_initial() public {
        uint256 reserveX = 0.308537538726 ether;
        uint256 reserveY = 0.308537538726 ether;
        uint256 strikePrice = 1 ether;
        uint256 volatilityWad = 1 ether;
        uint256 timeRemainingSec = 31556953;

        int256 result1 = RMM01Lib.tradingFunction(
            reserveX, reserveY, strikePrice, volatilityWad, timeRemainingSec
        );

        int256 result2 = Invariant.invariant({
            R_y: reserveY,
            R_x: reserveX,
            stk: strikePrice,
            vol: volatilityWad,
            tau: timeRemainingSec
        });

        console.logInt(result1);
        console.logInt(result2);
        console.logInt(result1 - result2);
        assertTrue(result2 > result1, "Old invariant larger than new one");
    }

    /// @dev The function:
    /// `0 <= (Φ⁻¹(1-x) - σ√τ) - Φ⁻¹(y/K)`
    /// Taking a closer look at the x part:
    /// `Φ⁻¹(1-x) - σ√τ`
    /// If x -> 1, then Φ⁻¹(1-x) -> Φ⁻¹(0) -> -∞
    /// Therefore, we should fuzz for a positive delta
    /// and make sure the result is smaller than the previous result.
    function test_fuzz_invariant_increasing_x_decreasing_invariant(
        uint256 deltaX,
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec
    ) public {
        // Make sure we add a positive delta!
        vm.assume(deltaX > 0);

        (
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        ) = bound_invariant_arguments(
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        // With an X reserve, we make sure to only use a delta that will not go over the maximum.
        // min delta <= delta <= max - x
        deltaX =
            bound(deltaX, MINIMUM_DELTA, MAXIMUM_RESERVE_X - reserveXPerWad);

        int256 previousResult = RMM01Lib.tradingFunction(
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        int256 result = RMM01Lib.tradingFunction(
            reserveXPerWad + deltaX,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        log_result(
            true,
            int256(deltaX),
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec,
            previousResult,
            result
        );

        assertTrue(result != previousResult, "Invariant not changing");
        assertTrue(result - previousResult < 0, "Invariant not decreasing");
    }

    /// @dev The function:
    /// `0 <= (Φ⁻¹(1-x) - σ√τ) - Φ⁻¹(y/K)`
    /// Taking a closer look at the x part:
    /// `Φ⁻¹(1-x) - σ√τ`
    /// If x -> 0, then Φ⁻¹(1-x) -> Φ⁻¹(1) -> ∞
    /// Therefore, we should fuzz for a positive delta
    /// and make sure the result is larger than the previous result.
    function test_fuzz_invariant_decreasing_x_increasing_invariant(
        uint256 deltaX,
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec
    ) public {
        // Make sure we add a non-zero delta.
        vm.assume(deltaX > 0);

        (
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        ) = bound_invariant_arguments(
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        // Fuzz argument is positive, so we can use the bound function.
        // min delta <= delta <= x - min x
        deltaX =
            bound(deltaX, MINIMUM_DELTA, reserveXPerWad - MINIMUM_RESERVE_X);

        int256 previousResult = RMM01Lib.tradingFunction(
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        int256 result = RMM01Lib.tradingFunction(
            reserveXPerWad - deltaX,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        log_result(
            true,
            -int256(deltaX),
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec,
            previousResult,
            result
        );

        assertTrue(result != previousResult, "Invariant not changing");
        assertTrue(result - previousResult > 0, "Invariant not increasing");
    }

    function bound_invariant_arguments(
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec
    ) internal returns (uint256, uint256, uint256, uint256, uint256) {
        // Need to make sure to bound the arguments to values that will be used.
        // min <= x <= max - delta
        reserveXPerWad = bound(
            reserveXPerWad,
            MINIMUM_RESERVE_X + MINIMUM_DELTA,
            MAXIMUM_RESERVE_X - MINIMUM_DELTA + MINIMUM_RESERVE_X
        );

        // Strike should be greater than the minimum Y reserve.
        // min y + min delta <= strike <= 2^128-1
        strikePriceWad = bound(
            strikePriceWad, MINIMUM_RESERVE_Y + MINIMUM_DELTA, type(uint128).max
        );

        // The Y reserve is bounded between 1 and the strike price less 1.
        // min y <= y <= strike - min delta
        reserveYPerWad = bound(
            reserveYPerWad,
            MINIMUM_RESERVE_Y + MINIMUM_DELTA,
            strikePriceWad - MINIMUM_DELTA + MINIMUM_RESERVE_Y
        );

        // Volatility should be between the Portfolio bounds.
        // Portfolio bounds are in basis points, which must be scaled to percentages then WAD.
        volatilityWad = bound(
            volatilityWad,
            PortfolioLib.MIN_VOLATILITY,
            PortfolioLib.MAX_VOLATILITY
        );
        volatilityWad = volatilityWad * WAD / BASIS_POINTS_DEN;

        // Time remaining should be first bounded by the Portfolio bounds then scaled to the proper units.
        // Porfolio bounds are in days, which must be scaled to seconds.
        timeRemainingSec = bound(
            timeRemainingSec,
            PortfolioLib.MIN_DURATION,
            PortfolioLib.MAX_DURATION
        );
        timeRemainingSec = timeRemainingSec * SECONDS_PER_DAY;

        // Need to make sure the computations in the function are valid.
        uint256 quotient = reserveYPerWad.divWadDown(strikePriceWad);
        uint256 difference = 1 ether - reserveXPerWad;
        vm.assume(quotient > 0 && quotient < 1 ether);
        vm.assume(difference > 0 && difference < 1 ether);

        return (
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );
    }

    function log_result(
        bool applyDeltaToX,
        int256 delta,
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec,
        int256 previousResult,
        int256 result
    ) internal {
        console.log("=== PROFILE ===");
        console.log("reserveXPerWad        : ", reserveXPerWad);
        console.log("reserveYPerWad        : ", reserveYPerWad);
        console.log(
            "delta                 : ",
            delta < 0 ? "-" : "",
            uint256(delta < 0 ? -delta : delta)
        );
        console.log("delta to reserveX     : ", applyDeltaToX);
        console.log("strikePriceWad        : ", strikePriceWad);
        console.log("volatilityWad         : ", volatilityWad);
        console.log("timeRemainingSec      : ", timeRemainingSec);
        console.log("=== RESULT ===");
        console.logInt(previousResult);
        console.logInt(result);
        console.logInt(result - previousResult);
    }
}
