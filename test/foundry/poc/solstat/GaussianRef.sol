// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "solmate/utils/FixedPointMathLib.sol";
import "solstat/Units.sol";

/**
 * @title Gaussian Math Library.
 * @author @alexangelj
 *
 * @notice Models the normal distribution using the special Complimentary Error Function.
 *
 * @dev Only implements a distribution with mean (µ) = 0 and variance (σ) = 1.
 * Uses Numerical Recipes as a framework and reference C implemenation.
 * Numerical Recipes cites the original textbook written by Abramowitz and Stegun,
 * "Handbook of Mathematical Functions", which should be read to understand these
 * special functions and the implications of their numerical approximations.
 *
 * @custom:source Handbook of Mathematical Functions https://personal.math.ubc.ca/~cbm/aands/abramowitz_and_stegun.pdf.
 * @custom:source Numerical Recipes https://e-maxx.ru/bookz/files/numerical_recipes.pdf.
 * @custom:source Inspired by https://github.com/errcw/gaussian.
 */
library GaussianRef {
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    error Infinity();
    error NegativeInfinity();

    uint256 internal constant HALF_WAD = 0.5 ether;
    uint256 internal constant PI = 3_141592653589793238;
    int256 internal constant SQRT_2PI = 2_506628274631000502;
    int256 internal constant SIGN = -1;
    int256 internal constant SCALAR = 1e18;
    int256 internal constant HALF_SCALAR = 1e9;
    int256 internal constant SCALAR_SQRD = 1e36;
    int256 internal constant HALF = 5e17;
    int256 internal constant ONE = 1e18;
    int256 internal constant TWO = 2e18;
    int256 internal constant NEGATIVE_TWO = -2e18;
    int256 internal constant SQRT2 = 1_414213562373095048; // √2 with 18 decimals of precision.
    int256 internal constant ERFC_A = 1_265512230000000000;
    int256 internal constant ERFC_B = 1_000023680000000000;
    int256 internal constant ERFC_C = 374091960000000000; // 1e-1
    int256 internal constant ERFC_D = 96784180000000000; // 1e-2
    int256 internal constant ERFC_E = -186288060000000000; // 1e-1
    int256 internal constant ERFC_F = 278868070000000000; // 1e-1
    int256 internal constant ERFC_G = -1_135203980000000000;
    int256 internal constant ERFC_H = 1_488515870000000000;
    int256 internal constant ERFC_I = -822152230000000000; // 1e-1
    int256 internal constant ERFC_J = 170872770000000000; // 1e-1
    int256 internal constant IERFC_A = -707110000000000000; // 1e-1
    int256 internal constant IERFC_B = 2_307530000000000000;
    int256 internal constant IERFC_C = 270610000000000000; // 1e-1
    int256 internal constant IERFC_D = 992290000000000000; // 1e-1
    int256 internal constant IERFC_E = 44810000000000000; // 1e-2
    int256 internal constant IERFC_F = 1_128379167095512570;

    function erfc_solidity(int256 input) internal pure returns (int256 output) {
        unchecked {
            int256 z = int256(abs_solidity(input));
            int256 t = SCALAR_SQRD / (ONE + (z * ONE) / TWO); // 1 / (1 + z / 2).

            int256 step = ERFC_J;
            step = ERFC_I + mulWadUnchecked(t, step);
            step = ERFC_H + mulWadUnchecked(t, step);
            step = ERFC_G + mulWadUnchecked(t, step);
            step = ERFC_F + mulWadUnchecked(t, step);
            step = ERFC_E + mulWadUnchecked(t, step);
            step = ERFC_D + mulWadUnchecked(t, step);
            step = ERFC_C + mulWadUnchecked(t, step);
            step = ERFC_B + mulWadUnchecked(t, step);
            step = mulWadUnchecked(t, step);

            int256 k = step - (mulWadUnchecked(int256(z), int256(z)) + ERFC_A);
            int256 expWad = FixedPointMathLib.expWad(k);
            int256 r = mulWadUnchecked(t, expWad);

            output = input < 0 ? TWO - r : r;
        }
    }

    // function erfc_fixed(int256 input) internal pure returns (int256 output) {
    //     uint256 z = abs(input);
    //     // We can safely cast the result of the division to int256.
    //     int256 t = int256(1e36 / (1e18 + z / 2));

    //     int256 step = ERFC_J;

    //     step = ERFC_I + (t * step / 1e18);
    //     step = ERFC_H + (t * step / 1e18);
    //     step = ERFC_G + (t * step / 1e18);
    //     step = ERFC_F + (t * step / 1e18);
    //     step = ERFC_E + (t * step / 1e18);
    //     step = ERFC_D + (t * step / 1e18);
    //     step = ERFC_C + (t * step / 1e18);
    //     step = ERFC_B + (t * step / 1e18);
    //     step = -ERFC_A + (t * step / 1e18);

    //     // We can safely cast the result to int256.
    //     int256 k = step - int256(z * z / 1e18);
    //     int256 expWad = FixedPointMathLib.expWad(k);
    //     int256 r = t * expWad / 1e18;

    //     output = input < 0 ? TWO - r : r;
    // }

    function mulWadUnchecked(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x * y) / 1e18;
        }
    }

    function divWadUnchecked(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x * 1e18) / y;
        }
    }

    function mulWadDown(int256 x, int256 y) internal pure returns (int256 z) {
        z = x * y;
        unchecked {
            z = z / 1e18;
        }
    }

    function abs_solidity(int256 input) internal pure returns (uint256 output) {
        if (input == type(int256).min) revert Min();
        output = uint256(input < 0 ? -input : input);
    }

    function ierfc_solidity(int256 x) internal pure returns (int256 z) {
        unchecked {
            if (x >= TWO) return z = -100 * SCALAR;
            else if (x <= 0) return z = 100 * SCALAR;

            int256 xx = (x < ONE) ? x : TWO - x;
            int256 logInput = xx / 2;
            if (logInput == 0) revert Infinity();

            int256 ln = FixedPointMathLib.lnWad(logInput);
            int256 t = HALF_SCALAR * int256(uint256((NEGATIVE_TWO * ln) / 1e18).sqrt());

            int256 r1 = IERFC_B + mulWadUnchecked(t, IERFC_C);
            int256 r2 = ONE + mulWadUnchecked(t, IERFC_D + mulWadUnchecked(t, IERFC_E));

            int256 r = (r1 * 1e18) / r2 - t;
            r = mulWadUnchecked(IERFC_A, r);

            // for (uint256 itr; itr < 2; ++itr) {
            int256 err = erfc_solidity(r) - xx;
            int256 input = -mulWadUnchecked(r, r);
            int256 expWad = input.expWad();

            int256 t1 = -mulWadUnchecked(r, err);
            t1 = t1 + mulWadUnchecked(IERFC_F, expWad);
            r = r + (err * 1e18) / t1;

            // r = r + err / (IERFC_F * expWad - r * err);

            // }

            z = (x < ONE) ? r : -r;
        }
    }

    function cdf_solidity(int256 x) internal pure returns (int256 z) {
        unchecked {
            z = erfc_solidity(-((x * ONE) / SQRT2)) / 2;
        }
    }

    function pdf_solidity(int256 x) internal pure returns (int256 z) {
        unchecked {
            x = (-x * x) / 2e18;

            int256 e = FixedPointMathLib.expWad(x);

            z = (e * ONE) / SQRT_2PI;
        }
    }

    // function pdf_fixed(int256 x) internal pure returns (int256 z) {
    //     uint256 absX = abs(x);
    //     uint256 xSquared = absX * absX; // Overflow check in uint256 is required.
    //     unchecked {
    //         // We can safely cast the result of the division to int256, since
    //         // dividing `xSquared` by `2e18` ensures that the result is less than `type(int256).max`.
    //         // The result is an uint256, which means that a check for `type(int256).min`
    //         // can be omitted when negating the result.
    //         x = -int256(xSquared / 2e18);
    //     }
    //     int256 e = FixedPointMathLib.expWad(x);

    //     unchecked {
    //         // The output of `expWad` is such that it can be safely
    //         // multiplied by `1e18` without causing an overflow in int256.
    //         z = e * ONE / (SQRT_2PI + 1); // Note: Adding 1, because we should be rounding down.
    //     }
    // }

    function ppf_solidity(int256 x) internal pure returns (int256 z) {
        unchecked {
            // returns 3.75e-8, but we know it's zero.
            if (x == int256(HALF_WAD)) return int256(0);
            else if (x >= ONE) revert Infinity();
            else if (x == 0) revert NegativeInfinity();

            int256 _ierfc = ierfc_solidity(x * 2);

            z = -mulWadUnchecked(SQRT2, _ierfc);
        }
    }
}
