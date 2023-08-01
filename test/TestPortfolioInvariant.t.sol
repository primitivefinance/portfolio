// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

import "../contracts/libraries/PortfolioLib.sol" as PortfolioLib;
import "solstat/Gaussian.sol";
import "solstat/Invariant.sol";

/// todo: Explain the bounds and deltas and min/maxes better.

/// @dev Basis points units are 1e4, percentages are stored in WAD with 1e18 decimals.
uint256 constant BASIS_POINTS_DEN = 10000;

/// @dev Critical constant. Minimum acceptable delta to change x or y by.
/// Setting this to < 3 should fail the tests, since there are cases where the invariant
/// will not change at these small delta values.
uint256 constant MINIMUM_DELTA = 3;

uint256 constant MINIMUM_LIQUIDITY = PortfolioLib.BURNED_LIQUIDITY;
uint256 constant MAXIMUM_RESERVE_X = 1e18 - 1;
uint256 constant MINIMUM_RESERVE_X = 1;
uint256 constant MINIMUM_RESERVE_Y = 1;
uint256 constant MAXIMUM_STRIKE_PRICE = 1e27;

/// @dev Quotient is the ratio of the Y reserve to the strike price.
uint256 constant MAXIMUM_QUOTIENT = 1 ether;
uint256 constant MINIMUM_QUOTIENT_DELTA = 2;

/// @dev Difference is 1 less x reserve.
uint256 constant MAXIMUM_DIFFERENCE = 1 ether;

contract TestPortfolioInvariant is Setup {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    /// Trading function is pure so here's a hack to test the intermediate values.
    /// Make sure this is IDENTICAL to the actual tradingFunction() in NormalStrategyLib.
    function logTradingFunctionIntermediateValues(
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec
    ) internal view returns (int256 invariant) {
        uint256 yearsWad =
            timeRemainingSec.divWadDown(uint256(ConstantsLib.SECONDS_PER_YEAR));
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

    function test_trading_function() public view {
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
    function test_invariant_initial() public view {
        uint256 reserveXPerWad = 0.308537538726 ether;
        uint256 reserveYPerWad = 0.308537538726 ether;
        uint256 strikePriceWad = 1 ether;
        uint256 volatilityWad = 1 ether;
        uint256 timeRemainingSec = 31556953;

        int256 result1 = tradingFunction(
            NormalCurve(
                reserveXPerWad,
                reserveYPerWad,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0 // invariant
            )
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

        uint256 computedY = approximateXGivenY(
            NormalCurve(
                0,
                reserveYPerWad,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0
            )
        );
        uint256 computedX = approximateYGivenX(
            NormalCurve(
                reserveXPerWad,
                0,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0
            )
        );
        console.log("computedX: ", computedX);
        console.log("computedY: ", computedY);
    }

    /// @dev The function:
    /// k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
    /// As x -> 1, Φ⁻¹(1-x) -> Φ⁻¹(0) -> -∞, so k -> ∞
    /// Since this part is subtracted, the resultant `k` increases.
    function test_fuzz_invariant_increasing_x_increasing_invariant_strict(
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

        int256 previousResult = tradingFunction(
            NormalCurve(
                reserveXPerWad,
                reserveYPerWad,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0 // invariant
            )
        );

        int256 result = tradingFunction(
            NormalCurve(
                reserveXPerWad + deltaX,
                reserveYPerWad,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0 // invariant
            )
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
    function test_fuzz_invariant_decreasing_x_decreasing_invariant_strict(
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

        int256 previousResult = tradingFunction(
            NormalCurve(
                reserveXPerWad,
                reserveYPerWad,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0 // invariant
            )
        );

        int256 result = tradingFunction(
            NormalCurve(
                reserveXPerWad - deltaX,
                reserveYPerWad,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0 // invariant
            )
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
    function test_fuzz_invariant_increasing_y_increasing_invariant_strict(
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
        deltaY = bound(deltaY, MINIMUM_DELTA, strikePriceWad - reserveYPerWad);

        uint256 prevQuotient = reserveYPerWad.divWadUp(strikePriceWad);
        uint256 quotient = (reserveYPerWad + deltaY).divWadUp(strikePriceWad);

        vm.assume(
            quotient < MAXIMUM_QUOTIENT
                && quotient >= prevQuotient + MINIMUM_QUOTIENT_DELTA
        );

        int256 previousResult = tradingFunction(
            NormalCurve(
                reserveXPerWad,
                reserveYPerWad,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0 // invariant
            )
        );

        logTradingFunctionIntermediateValues(
            reserveXPerWad,
            reserveYPerWad + deltaY,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        int256 result = tradingFunction(
            NormalCurve(
                reserveXPerWad,
                reserveYPerWad + deltaY,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0 // invariant
            )
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
    function test_fuzz_invariant_decreasing_y_decreasing_invariant_strict(
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

        uint256 prevQuotient = reserveYPerWad.divWadUp(strikePriceWad);
        uint256 quotient = (reserveYPerWad - deltaY).divWadUp(strikePriceWad);
        console.log("prevQuotient: ", prevQuotient);
        console.log("quotient: ", quotient);

        /// Make sure quotient is within bounds and it decreases by at least 2
        vm.assume(prevQuotient >= MINIMUM_QUOTIENT_DELTA);
        vm.assume(
            quotient < MAXIMUM_QUOTIENT
                && prevQuotient - MINIMUM_QUOTIENT_DELTA >= quotient
        );

        int256 previousResult = tradingFunction(
            NormalCurve(
                reserveXPerWad,
                reserveYPerWad,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0 // invariant
            )
        );

        logTradingFunctionIntermediateValues(
            reserveXPerWad,
            reserveYPerWad - deltaY,
            strikePriceWad,
            volatilityWad,
            timeRemainingSec
        );

        int256 result = tradingFunction(
            NormalCurve(
                reserveXPerWad,
                reserveYPerWad - deltaY,
                strikePriceWad,
                volatilityWad,
                timeRemainingSec,
                0 // invariant
            )
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
    ) internal view returns (uint256, uint256, uint256, uint256, uint256) {
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
            MAXIMUM_STRIKE_PRICE
        );

        // The Y reserve is bounded between the min delta and the strike price less min delta.
        // min y <= y <= strike - min delta
        reserveYPerWad = bound(
            reserveYPerWad,
            MINIMUM_RESERVE_Y + MINIMUM_DELTA,
            strikePriceWad - MINIMUM_DELTA + MINIMUM_RESERVE_Y - 1
        );

        // Volatility should be between the Portfolio bounds.
        // Portfolio bounds are in basis points, which must be scaled to percentages then WAD.
        volatilityWad = bound(volatilityWad, MIN_VOLATILITY, MAX_VOLATILITY);
        volatilityWad = volatilityWad * WAD / BASIS_POINTS_DEN;

        // Time remaining should be first bounded by the Portfolio bounds then scaled to the proper units.
        // Porfolio bounds are in days, which must be scaled to seconds.
        timeRemainingSec = bound(timeRemainingSec, MIN_DURATION, MAX_DURATION);

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
    ) internal view {
        uint256 postReserve = applyDeltaToX
            ? uint256(int256(reserveXPerWad) + delta)
            : uint256(int256(reserveYPerWad) + delta);
        console.log("=== PROFILE ===");
        console.log("reserveXPerWad        : ", reserveXPerWad);
        console.log("reserveYPerWad        : ", reserveYPerWad);
        console.log(
            "delta                 : ",
            delta < 0 ? "-" : "",
            uint256(delta < 0 ? -delta : delta)
        );
        console.log("postReserve           : ", postReserve);
        console.log("add delta to reserveX : ", applyDeltaToX);
        console.log("strikePriceWad        : ", strikePriceWad);
        console.log("volatilityWad         : ", volatilityWad);
        console.log("timeRemainingSec      : ", timeRemainingSec);
        console.log(
            "prevQuotient          : ", reserveYPerWad.divWadUp(strikePriceWad)
        );
        console.log(
            "quotient              : ",
            applyDeltaToX
                ? reserveYPerWad.divWadUp(strikePriceWad)
                : postReserve.divWadUp(strikePriceWad)
        );

        console.log("PPFs");
        console.logInt(
            Gaussian.ppf(
                int256(
                    applyDeltaToX
                        ? reserveYPerWad.divWadUp(strikePriceWad)
                        : postReserve.divWadUp(strikePriceWad)
                )
            )
        );
        console.logInt(
            Gaussian.ppf(
                int256(
                    applyDeltaToX
                        ? 1 ether - postReserve
                        : 1 ether - reserveXPerWad
                )
            )
        );
        console.log(
            "stdDevSqrtTau",
            volatilityWad.mulWadDown(
                (timeRemainingSec * WAD / SECONDS_PER_YEAR).sqrt() * SQRT_WAD
            )
        );
        console.log(
            "stdDevSqrtTau computed",
            NormalCurve({
                reserveXPerWad: 0,
                reserveYPerWad: 0,
                standardDeviationWad: volatilityWad,
                strikePriceWad: strikePriceWad,
                timeRemainingSeconds: timeRemainingSec,
                invariant: 0
            }).computeStdDevSqrtTau()
        );
        console.log("END PPFS");

        console.log("prevDifference        : ", 1 ether - reserveXPerWad);
        console.log(
            "difference            : ",
            applyDeltaToX ? 1 ether - postReserve : 1 ether - reserveXPerWad
        );
        console.log("=== RESULT ===");
        console.logInt(previousResult);
        console.logInt(result);
        console.logInt(result - previousResult);
    }
}
