// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

import "../contracts/libraries/PortfolioLib.sol" as PortfolioLib;
import "../contracts/libraries/RMM01Lib.sol";
import "solstat/Gaussian.sol";
import "solstat/Invariant.sol";

/// @dev Critical constant. Minimum acceptable delta to change x or y by.
/// Setting this to 1 should fail the tests, since there are cases where the invariant
/// will not change.
/// A minimum delta of 2 will let the x test cases pass.
/// A minimum delta of 4 will let the y test cases pass.
uint256 constant MINIMUM_DELTA = 1e6;

uint256 constant MINIMUM_LIQUIDITY = PortfolioLib.BURNED_LIQUIDITY;
uint256 constant MAXIMUM_RESERVE_X = 1e18 - 1;
uint256 constant MINIMUM_RESERVE_X = 1;
uint256 constant MINIMUM_RESERVE_Y = 1;
uint256 constant BASIS_POINTS_DEN = 10000;

contract TestPortfolioInvariant is Setup {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    /// Trading function is pure so here's a hack to test the intermediate values.
    /// Make sure this is IDENTICAL to the actual tradingFunction() in RMM01Lib.
    function logTradingFunctionIntermediateValues(
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec
    ) internal view returns (int256 invariant) {
        uint256 yearsWad = timeRemainingSec.divWadDown(uint256(YEAR));
        // √τ, √τ is scaled to WAD by multiplying by 1E9.
        uint256 sqrtTauWad = yearsWad.sqrt() * SQRT_WAD;
        // σ√τ
        uint256 volSqrtYearsWad = volatilityWad.mulWadDown(sqrtTauWad);
        // y / K
        uint256 quotientWad = reserveYPerWad.divWadUp(strikePriceWad); // todo: should this round up??
        console2.log(reserveYPerWad, strikePriceWad);
        console2.log("quotientWad", quotientWad);
        // Φ⁻¹(y/K)
        int256 inverseCdfQuotient = Gaussian.ppf(int256(quotientWad));
        console2.log("inverseCdfQuotient");
        console2.logInt(inverseCdfQuotient);
        // 1 - x
        uint256 differenceWad = WAD - reserveXPerWad;
        console2.log("differenceWad", differenceWad);
        // Φ⁻¹(1-x)
        int256 inverseCdfDifference = Gaussian.ppf(int256(differenceWad));
        console2.log("inverseCdfDifference");
        console2.logInt(inverseCdfDifference);
        // k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
        invariant =
            inverseCdfQuotient - inverseCdfDifference + int256(volSqrtYearsWad);
    }

    function test_trading_function() public {
        uint256 reserveXPerWad = 0.308537538726 ether;
        uint256 reserveYPerWad = 0.308537538726 ether;
        uint256 strikePriceWad = 1 ether;
        uint256 volatilityWad = 1 ether;
        uint256 timeRemainingSec = 31556953;

        int256 result1 = logTradingFunctionIntermediateValues(
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        console.logInt(result1);
    }

    /// Sanity check console log. Returns an invariant close to 0.
    /// The result is about 1e-7.
    function test_invariant_initial() public {
        uint256 reserveXPerWad = 0.308537538726 ether;
        uint256 reserveYPerWad = 0.308537538726 ether;
        uint256 strikePriceWad = 1 ether;
        uint256 volatilityWad = 1 ether;
        uint256 timeRemainingSec = 31556953;

        int256 result1 = RMM01Lib.tradingFunction(
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        int256 result2 = Invariant.invariant({
            R_y: reserveYPerWad,
            R_x: reserveXPerWad,
            stk: strikePriceWad,
            vol: volatilityWad,
            tau: timeRemainingSec
        });

        console.logInt(result1);
        console.logInt(result2);
        console.logInt(result1 - result2);

        uint256 computedY = RMM01Lib.getReserveXPerWad(
            reserveYPerWad, strikePriceWad, volatilityWad, timeRemainingSec, 0
        );
        uint256 computedX = RMM01Lib.getReserveYPerWad(
            reserveXPerWad, strikePriceWad, volatilityWad, timeRemainingSec, 0
        );
        console.log("computedX: ", computedX);
        console.log("computedY: ", computedY);
    }

    /// @dev The function:
    /// k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
    /// As x -> 1, Φ⁻¹(1-x) -> Φ⁻¹(0) -> -∞, so k -> ∞
    /// Since this part is subtracted, the resultant `k` increases.
    function test_fuzz_invariant_increasing_x_increasing_invariant(
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

        logTradingFunctionIntermediateValues(
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

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
        assertTrue(result - previousResult > 0, "Invariant not increasing");
    }

    /// @dev The function:
    /// k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
    /// As x -> 0, Φ⁻¹(1-x) -> Φ⁻¹(1) -> ∞, so k -> -∞
    /// Since this part with the x is subtracted from the first part,
    /// the resultant `k` decreases.
    function test_fuzz_invariant_decreasing_x_decreasing_invariant(
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
        assertTrue(result - previousResult < 0, "Invariant not decreasing");
    }

    /// @dev The function:
    /// k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
    /// As y -> K, Φ⁻¹(y/K) -> Φ⁻¹(1) -> ∞, so k -> ∞
    /// Since this is the leading part, it increases k.
    function test_fuzz_invariant_increasing_y_increasing_invariant(
        uint256 deltaY,
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec
    ) public {
        // Make sure we add a positive delta!
        vm.assume(deltaY > 0);

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

        // With a Y reserve, we make sure to only use a delta that will reach the maximum.
        // min delta <= delta <= strike - y
        deltaY = bound(
            deltaY,
            MINIMUM_DELTA,
            strikePriceWad - reserveYPerWad - MINIMUM_RESERVE_Y
        );

        int256 previousResult = RMM01Lib.tradingFunction(
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        logTradingFunctionIntermediateValues(
            reserveXPerWad,
            reserveYPerWad + deltaY,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        int256 result = RMM01Lib.tradingFunction(
            reserveXPerWad,
            reserveYPerWad + deltaY,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        log_result(
            false,
            int256(deltaY),
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

    /// @dev The function:
    /// k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
    /// As y -> 0, Φ⁻¹(y/K) -> Φ⁻¹(0) -> -∞, so k -> -∞
    /// Since this is the leading part, it decreases k.
    function test_fuzz_invariant_decreasing_y_decreasing_invariant(
        uint256 deltaY,
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec
    ) public {
        // Make sure we add a non-zero delta.
        vm.assume(deltaY > 0);

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
        // min delta <= delta <= y - min y
        deltaY =
            bound(deltaY, MINIMUM_DELTA, reserveYPerWad - MINIMUM_RESERVE_Y);

        int256 previousResult = RMM01Lib.tradingFunction(
            reserveXPerWad,
            reserveYPerWad,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        logTradingFunctionIntermediateValues(
            reserveXPerWad,
            reserveYPerWad - deltaY,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        int256 result = RMM01Lib.tradingFunction(
            reserveXPerWad,
            reserveYPerWad - deltaY,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        log_result(
            false,
            -int256(deltaY),
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

    /// @dev Careful with this. We are missing the cases of reserves being very low or
    /// very high with respect to their bounds (i.e. reserve of 1).
    function bound_invariant_arguments(
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec
    ) internal returns (uint256, uint256, uint256, uint256, uint256) {
        // Need to make sure to bound the arguments to values that will be used.
        // min x + min delta <= x <= max - delta + min x - 1
        reserveXPerWad = bound(
            reserveXPerWad,
            MINIMUM_RESERVE_X + MINIMUM_DELTA,
            MAXIMUM_RESERVE_X - MINIMUM_DELTA + MINIMUM_RESERVE_X - 1
        );

        // Strike should be greater than the minimum Y reserve.
        // min y + min delta  + 1 <= strike <= 2^128-1
        strikePriceWad = bound(
            strikePriceWad,
            MINIMUM_RESERVE_Y + MINIMUM_DELTA * 2 + 1,
            type(uint128).max
        );

        // The Y reserve is bounded between the min delta and the strike price less min delta.
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
        uint256 quotient = reserveYPerWad.divWadUp(strikePriceWad);
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
        console.log("add delta to reserveX : ", applyDeltaToX);
        console.log("strikePriceWad        : ", strikePriceWad);
        console.log("volatilityWad         : ", volatilityWad);
        console.log("timeRemainingSec      : ", timeRemainingSec);
        console.log("=== RESULT ===");
        console.logInt(previousResult);
        console.logInt(result);
        console.logInt(result - previousResult);
    }
}
