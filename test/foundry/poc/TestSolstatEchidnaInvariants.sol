// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solstat/Gaussian.sol";
import {GaussianRef} from "test/foundry/solstat/GaussianRef.sol";
import {Invariant} from "solstat/Invariant.sol";
import "solstat/Units.sol" as Units;
import "contracts/libraries/RMM01Lib.sol";

/// @notice requires editing "lib/forge-std/lib/ds-test/src/test.sol"
///         in order to make `fail()` overridable:
///         `function fail() internal` -> `function fail() internal virtual`.
import "../../E2E/setup/TestEchidnaSolstatHelper.sol";

int256 constant NEG_ONE = -1;
int256 constant E_DOWN = 2_718281828459045235; // floor(e^1)
int256 constant E_UP = 2_718281828459045236; // ceil(e^1)
int256 constant PDF_0_UP = 398942280401432678; // ceil(1 / sqrt(2*pi))
int256 constant EXP_MIN = -42139678854452767551;
int256 constant EXP_MAX = 135305999368893231589;
int256 constant EXP_MIN_SQRT = -6491508212;
int256 constant EXP_MAX_SQRT = 11632110701;

/// @dev need to check that certain assumptions can be made about
///      solmate's implementations, otherwise there's no point in
///      checking for breaking invariants in functions that build on these.
contract TestEchidnaSolmateInvariants is TestEchidnaSolstatHelper {
    function test_expWad_is_bounded(int256 x) public {
        x = bound(x, EXP_MIN, EXP_MAX);

        int256 y = FixedPointMathLib.expWad(x);

        logInt("x", x);
        logInt("y", y);

        assertGte(y, 0);
    }

    function test_expWad_mul_ONE_doesnt_overflow(int256 x) public {
        x = bound(x, EXP_MIN, EXP_MAX);

        int256 y = x * 1e18;

        logInt("x", x);
        logInt("y", y);
    }

    function test_expWad_is_strictly_increasing(int256 x1, int256 x2) public {
        x1 = bound(x1, EXP_MIN, EXP_MAX - 2);
        x2 = bound(x2, x1 + 1, EXP_MAX - 1);

        int256 y1 = FixedPointMathLib.expWad(x1);
        int256 y2 = FixedPointMathLib.expWad(x2);

        logInt("x1", x1);
        logInt("y1", y1);
        logInt("x2", x2);
        logInt("y2", y2);

        assertGte(y2, y1);
    }

    function test_expWad_rounds_down(int256 x1) public {
        x1 = bound(x1, EXP_MIN + 1, EXP_MAX - 1);

        int256 x2 = x1 + 1;

        int256 y1 = FixedPointMathLib.expWad(x1);
        int256 y2 = FixedPointMathLib.expWad(x2);

        logInt("x1", x1);
        logInt("y1", y1);
        logInt("x2", x2);
        logInt("y2", y2);

        // fl(e^(x+1)) <= e^(x+1) = (e^x)e = (fl(e^x) + ∆)e, where 0 <= ∆ < 1
        // fl(e^(x+1)) < (fl(e^x) + 1)ceil(e)
        assertLt(y2, ((y1 + 1) * E_UP) / 1e18);
    }

    function test_expWad_max_error_around_symmetry_0(int256 x) public {
        x = bound(x, EXP_MIN, EXP_MAX - 1);

        int256 y = FixedPointMathLib.expWad(x);

        console.log("\nEXP");
        console.log();
        logInt("x", x);
        logInt("y", y);

        int256 err = x > 0 ? 1e18 - y : y - 1e18;
        int256 maxErr = 0;

        logInt("min. err", err);
        console.log();

        assertLte(err, maxErr * 1e2);
    }

    function test_sqrt_is_increasing(uint256 x1, uint256 x2) public {
        x1 = bound(x1, 0, type(uint256).max - 1);
        x2 = bound(x2, x1 + 1, type(uint256).max);

        uint256 y1 = FixedPointMathLib.sqrt(x1);
        uint256 y2 = FixedPointMathLib.sqrt(x2);

        console.log("x1", x1);
        console.log("y1", y1);
        console.log("x2", x2);
        console.log("y2", y2);

        assertGte(y2, y1);
    }

    function test_sqrt_rounds_down(uint256 x) public {
        uint256 y = FixedPointMathLib.sqrt(x);

        console.log("x", x);
        console.log("y", y);
        console.log("y*y", y * y);

        // fl(√n) <= √n
        // fl(√n)fl(√n) <= n
        assertLte(y * y, x);
        // √n = fl(√n) + ∆, where 0 <= ∆ < 1
        // n = (fl(√n) + ∆)(fl(√n) + ∆)
        // n = fl(√n)fl(√n) + ∆∆ + 2fl(√n)∆
        // n < fl(√n)fl(√n) + 1 + 2fl(√n)
        // n < fl(√n)(fl(√n) + 2) + 1
        assertLt(x, y * (y + 2) + 1);
    }

    function test_sqrt_is_exact_for_squares(uint256 x) public {
        x = bound(x, 0, 340282366920938463463374607431768211455);

        uint256 y = FixedPointMathLib.sqrt(x * x);

        console.log("x", x);
        console.log("y", y);

        assertEq(y, x);
    }
}

contract TestEchidnaSolstatBounds is TestEchidnaSolstatHelper {
    /* ---------------- FAIL ---------------- */

    function test_cdf_is_bounded(int256 x) public {
        // Note: this test seems to pass, however, because `erfc` is
        // being used it is likely that the unbounded values were not
        // triggered/found.
        int256 y = Gaussian.cdf(x);

        logInt("x", x);
        logInt("y", y);

        // NOTE could be argued that it should always round down.
        // which would mean the upper bounds should not be included.
        // This test fails then.
        assertGte(y, 0);
        assertLte(y, 1e18);
    }

    function test_erfc_is_bounded() public {
        test_erfc_is_bounded(-57896044618658097711785492504343953926634992332820282019727663624789469313869);
    }

    function test_erfc_is_bounded(int256 x) public {
        // Note: foundry has a hard time disproving this,
        // but the example above and the test below shows that the values can lie far out of bounds.
        x = bound(x, type(int256).min, type(int256).max);

        int256 y = Gaussian.erfc(x);

        logInt("x", x);
        logInt("y", y);

        assertGte(y, 0);
        assertLt(y, 2e18); // NOTE: should not be inclusive if rounding down.
    }

    function test_pdf_is_bounded(int256 x) public {
        // x = bound(x, 2 * EXP_MIN_SQRT, -2 * EXP_MIN_SQRT);

        int256 y = Gaussian.pdf(x);

        logInt("x", x);
        logInt("y", y);

        // NOTE if consistently rounding down, the upper
        // bound should not be inclusive, i.e.
        // `pdf(0) = ⌊1/sqrt(2*pi)⌋ < PDF_0_UP` should hold,
        // if `pdf(0)` can't be exactly represented as an int in 18 decimals.
        assertGte(y, 0);
        assertLt(y, PDF_0_UP);
    }

    function test_ierfc_should_revert_outside_of_input_domain(int256 x) public {
        if (x > 0) x = bound(x, 2e18, type(int256).max);
        if (x <= 0) x = bound(x, type(int256).min, 0);

        vm.expectRevert();
        int256 y = Gaussian.ierfc(x);

        // NOTE unexpectedly returns values.
        logInt("x", x);
        logInt("y", y);
    }
}

contract TestEchidnaSolstatInvariants is TestEchidnaSolstatHelper {
    /* ---------------- FAIL ---------------- */

    function test_cdf_is_increasing(int256 x1, int256 x2) public {
        x2 = bound(x2, x1, type(int256).max);

        int256 y1 = Gaussian.cdf(x1);
        int256 y2 = Gaussian.cdf(x2);

        assertGte(y2, y1);
    }

    function test_cdf_is_gt_half(int256 x) public {
        int256 y = Gaussian.cdf(x);

        // NOTE very large values suddenly turn to 0.
        // similarly very small values suddenly turn to 1e18.
        if (x > 1e18) assertGte(y, 0.5e18);
        if (x < -1e18) assertLt(y, 0.5e18);
    }

    function test_pdf_is_decreasing(int256 x1, int256 x2) public {
        x1 = bound(x1, 0, type(int256).max);
        x2 = bound(x2, x1, type(int256).max);

        int256 y1 = Gaussian.pdf(x1);
        int256 y2 = Gaussian.pdf(x2);

        logInt("x1", x1);
        logInt("y1", y1);
        logInt("x2", x2);
        logInt("y2", y2);

        assertLte(y2, y1);
    }

    function test_erfc_is_decreasing(int256 x1, int256 x2) public {
        x1 = bound(x1, type(int256).min, type(int256).max);
        x2 = bound(x2, x1, type(int256).max);

        int256 y1 = Gaussian.erfc(x1);
        int256 y2 = Gaussian.erfc(x2);

        logInt("x1", x1);
        logInt("y1", y1);
        logInt("x2", x2);
        logInt("y2", y2);

        assertLte(y2, y1);
    }

    function test_ierfc_is_decreasing(int256 x1, int256 x2) public {
        x1 = bound(x1, 0, 2e18);
        x2 = bound(x2, x1, 2e18);

        int256 y1 = Gaussian.ierfc(x1);
        int256 y2 = Gaussian.ierfc(x2);

        logInt("x1", x1);
        logInt("y1", y1);
        logInt("x2", x2);
        logInt("y2", y2);

        assertLte(y2, y1);
    }

    function test_getY_is_decreasing(uint256 x1, uint256 x2, uint256 stk, uint256 vol, uint256 tau) public {
        x1 = bound(x1, 1, 1e18);
        x2 = bound(x2, x1, 1e18);
        stk = bound(stk, 1, 100_000_000_000e18);
        vol = bound(vol, 0.00001e18, 1e18);
        tau = bound(tau, 1 days, 5 * 365 days);

        uint256 y1 = Invariant.getY(x1, stk, vol, tau, 0);
        uint256 y2 = Invariant.getY(x2, stk, vol, tau, 0);

        console.log("stk", stk);
        console.log("vol", vol);
        console.log("tau", tau);

        console.log("x1", x1);
        console.log("y1", y1);
        console.log("x2", x2);
        console.log("y2", y2);

        assertGte(y1, y2);
    }

    function test_price_should_decrease_when_selling(
        uint256 x2,
        uint256 prc1,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) public {
        stk = bound(stk, 1, 100_000_000e18);
        vol = bound(vol, 0.00001e18, 2.5e18);
        tau = bound(tau, 1 days, 5 * 365 days);
        prc1 = bound(prc1, (stk + 1e18 - 1) / 1e18, 100_000_000e18);

        console.log("stk", stk);
        console.log("vol", vol);
        console.log("tau", tau);

        uint256 x1 = RMM01Lib.getXWithPrice(prc1, stk, (vol * 10_000) / 1e18, tau);
        x2 = bound(x2, x1, 1e18 - 1);
        uint256 prc2 = RMM01Lib.getPriceWithX(x2, stk, (vol * 10_000) / 1e18, tau);

        console.log("x1", x1);
        console.log("prc1", prc1);
        console.log("x2", x2);
        console.log("prc2", prc2);

        assertLte(prc2, prc1);
    }

    function test_reserve_y_should_decrease_when_selling(
        uint256 x,
        uint256 prc1,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) public {
        stk = bound(stk, 1, 100_000_000e18);
        vol = bound(vol, 0.00001e18, 2.5e18);
        tau = bound(tau, 1 days, 5 * 365 days);
        prc1 = bound(prc1, (stk + 1e18 - 1) / 1e18, 100_000_000e18);

        console.log("stk", stk);
        console.log("vol", vol);
        console.log("tau", tau);

        uint256 x1 = RMM01Lib.getXWithPrice(prc1, stk, (vol * 10_000) / 1e18, tau);
        uint256 y1 = RMM01Lib.getYWithX(x1, stk, (vol * 10_000) / 1e18, tau, 0);

        if (x1 == 0) return;

        // Since the actual `x` never gets stored in Hyper.sol,
        // and is always computed by the price, this variable is temporary only.
        x = bound(x, x1, 1e18 - 1);
        uint256 prc2 = RMM01Lib.getPriceWithX(x, stk, (vol * 10_000) / 1e18, tau);

        uint256 x2 = RMM01Lib.getXWithPrice(prc2, stk, (vol * 10_000) / 1e18, tau);
        uint256 y2 = RMM01Lib.getYWithX(x2, stk, (vol * 10_000) / 1e18, tau, 0);

        console.log("x1", x1);
        console.log("y1", y1);
        console.log("prc1", prc1);
        console.log("x2", x2);
        console.log("y2", y2);
        console.log("prc2", prc2);

        assertLte(y2, y1);
    }

    function test_invariant_should_increase_when_selling(
        uint256 x2,
        uint256 y2,
        uint256 prc1,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) public {
        stk = bound(stk, 1, 100_000_000e18);
        vol = bound(vol, 0.00001e18, 2.5e18);
        tau = bound(tau, 1 days, 5 * 365 days);
        prc1 = bound(prc1, (stk + 1e18 - 1) / 1e18, 100_000_000e18);

        console.log("stk", stk);
        console.log("vol", vol);
        console.log("tau", tau);

        uint256 x1 = RMM01Lib.getXWithPrice(prc1, stk, (vol * 10_000) / 1e18, tau);
        uint256 y1 = RMM01Lib.getYWithX(x1, stk, (vol * 10_000) / 1e18, tau, 0);

        if (x1 == 0) return;

        x2 = bound(x2, x1, 1e18 - 1);
        y2 = bound(y2, 1, 1e18 - 1);
        uint256 prc2 = RMM01Lib.getPriceWithX(x2, stk, (vol * 10_000) / 1e18, tau);

        // uint256 x2 = RMM01Lib.getXWithPrice(prc2, stk, vol * 10_000 / 1e18, tau);
        // uint256 y2 = RMM01Lib.getYWithX(x2, stk, vol * 10_000 / 1e18, tau, 0);

        // int256 inv1 = Invariant.invariant(y1, x1, stk, vol, tau);
        // int256 inv2 = Invariant.invariant(y2, x2, stk, vol, tau);
        // Simplifies to:
        int256 inv1 = int256(y1 - y1);
        int256 inv2 = int256(y2 - RMM01Lib.getYWithX(x2, stk, (vol * 10_000) / 1e18, tau, 0));

        console.log("x1", x1);
        console.log("y1", y1);
        console.log("prc1", prc1);
        logInt("inv1", inv1);
        console.log("x2", x2);
        console.log("y2", y2);
        console.log("prc2", prc2);
        logInt("inv2", inv2);

        assertLte(y2, y1);
    }

    function test_sell_invariant_error_margin_with_x(
        uint256 x1,
        uint256 y2,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) public {
        x1 = bound(x1, 1, 1e18 - 1);
        // x2 = bound(x2, x1, 1e18);
        stk = bound(stk, 1, type(uint128).max - 1);
        vol = bound(vol, 0.00001e18, 1e18);
        tau = bound(tau, 1 days, 5 * 365 days);

        uint256 y1 = Invariant.getY(x1, stk, vol, tau, 0);
        if (y1 == 0) return;

        y2 = bound(y2, 0, y1 - 1);

        // note:
        // not sure this tests makes sense, since
        // we're basically computing `inv2 = y2-getY(x1)` = `inv2 = y2-y1`
        // should be testing how much `x` can vary without changing the invariant.
        int256 inv1 = Invariant.invariant(y1, x1, stk, vol, tau);
        int256 inv2 = Invariant.invariant(y2, x1, stk, vol, tau);

        console.log("stk", stk);
        console.log("vol", vol);
        console.log("tau", tau);

        console.log("x1", x1);
        console.log("y1", y1);
        console.log("x2", x1);
        console.log("y2", y2);

        logInt("inv1", inv1);
        logInt("inv2", inv2);

        if (inv2 >= inv1) {
            assertLte(y1 - y2, 1);
        }
    }
}

// TODO: run with echidna's optimization mode
contract TestEchidnaSolstatError is TestEchidnaSolstatHelper {
    /* ---------------- PASS ---------------- */

    function test_pdf_max_error_around_symmetry_0(int256 x) public returns (int256) {
        x = bound(x, -100e18, 100e18);
        int256 y = Gaussian.pdf(x);

        console.log("\nPDF");
        console.log();
        logInt("x", x);
        logInt("y", y);

        int256 err = y - PDF_0_UP;
        int256 maxErr = 0;

        logInt("min. err", err);
        console.log();

        // assertLte(err, maxErr * 1e2);

        return err;
    }

    /* ---------------- FAIL ---------------- */

    function test_cdf_max_error(int256 x1, int256 x2) public returns (int256) {
        x1 = bound(x1, type(int256).min, type(int256).max);
        x2 = bound(x2, x1, type(int256).max);

        int256 y1 = Gaussian.cdf(x1);
        int256 y2 = Gaussian.cdf(x2);

        console.log("\nCDF");
        console.log();
        logInt("x1", x1);
        logInt("y1", y1);
        logInt("x2", x2);
        logInt("y2", y2);

        int256 err = y1 - y2;
        int256 maxErr = 1000000000000000000;

        logInt("min. err", err);
        console.log();

        // assertLte(err, maxErr * 1);

        return err;
    }

    function test_erfc_max_error(int256 x1, int256 x2) public returns (int256) {
        x1 = bound(x1, type(int256).min, type(int256).max);
        x2 = bound(x2, x1, type(int256).max);

        int256 y1 = Gaussian.erfc(x1);
        int256 y2 = Gaussian.erfc(x2);

        console.log("\nERFC");
        console.log();
        logInt("x1", x1);
        logInt("y1", y1);
        logInt("x2", x2);
        logInt("y2", y2);

        int256 err = y2 - y1;
        int256 maxErr = 1357802833179526722082879094576907590950068362211003935840;

        logInt("min. err", err);
        console.log();

        // assertLte(err, maxErr * 1);

        return err;
    }

    function test_erfc_max_error_around_symmetry_0(int256 x) public returns (int256) {
        x = bound(x, -100e18, 100e18);

        int256 y = Gaussian.erfc(x);

        console.log("\nERFC");
        console.log();
        logInt("x", x);
        logInt("y", y);

        int256 err = x > 0 ? y - 1e18 : 1e18 - y;
        int256 maxErr = 2999999047902;

        logInt("min. err", err);
        console.log();

        // assertLte(err, maxErr * 1e2);

        return err;
    }

    function test_ierfc_max_error(int256 x1, int256 x2) public returns (int256) {
        x1 = bound(x1, 1, 2e18 - 1); // Technically should not include the bounds.
        x2 = bound(x2, x1, 2e18 - 1);

        int256 y1 = Gaussian.ierfc(x1);
        int256 y2 = Gaussian.ierfc(x2);

        console.log("\nINVERSE ERFC");
        console.log();
        logInt("x1", x1);
        logInt("y1", y1);
        logInt("x2", x2);
        logInt("y2", y2);

        int256 err = y2 - y1;
        int256 maxErr = 4932577333416;

        logInt("min. err", err);
        console.log();

        // assertLte(err, maxErr * 1e1);

        return err;
    }

    function test_ierfc_max_error_around_symmetry_1(int256 x) public returns (int256) {
        x = bound(x, 1, 2e18 - 1);

        int256 y = Gaussian.ierfc(x);

        console.log("\nINVERSE ERFC");
        console.log();
        logInt("x", x);
        logInt("y", y);

        int256 err = x >= 1e18 ? y : -y;
        int256 maxErr = 0;

        logInt("min. err", int256(abs(err)));
        console.log();

        // assertLte(err, maxErr * 1e1);

        return err;
    }

    function test_pdf_max_error(int256 x1, int256 x2) public returns (int256) {
        x1 = bound(x1, 2 * EXP_MIN_SQRT, 0);
        x2 = bound(x2, 2 * EXP_MIN_SQRT, x1);

        int256 y1 = Gaussian.pdf(x1);
        int256 y2 = Gaussian.pdf(x2);

        console.log("\nPDF");
        console.log();
        logInt("x1", x1);
        logInt("y1", y1);
        logInt("x2", x2);
        logInt("y2", y2);

        int256 err = y2 - y1;
        int256 maxErr = 398942280401432678;

        logInt("min. err", err);
        console.log();

        // assertLte(err, maxErr * 1e1);

        return err;
    }
}

contract TestEchidnaSolstatDifferential is TestEchidnaSolstatHelper {
    /* ---------------- wrapper functions ---------------- */

    function erfc(int256 x) external pure returns (int256 y) {
        y = Gaussian.erfc(x);
    }

    function ierfc(int256 x) external pure returns (int256 y) {
        y = Gaussian.ierfc(x);
    }

    function pdf(int256 x) external pure returns (int256 y) {
        y = Gaussian.pdf(x);
    }

    function ppf(int256 x) external pure returns (int256 y) {
        y = Gaussian.ppf(x);
    }

    function cdf(int256 x) external pure returns (int256 y) {
        y = Gaussian.cdf(x);
    }

    function erfc_solidity(int256 x) external pure returns (int256 y) {
        y = GaussianRef.erfc_solidity(x);
    }

    function ierfc_solidity(int256 x) external pure returns (int256 y) {
        y = GaussianRef.ierfc_solidity(x);
    }

    function pdf_solidity(int256 x) external pure returns (int256 y) {
        y = GaussianRef.pdf_solidity(x);
    }

    function ppf_solidity(int256 x) external pure returns (int256 y) {
        y = GaussianRef.ppf_solidity(x);
    }

    function cdf_solidity(int256 x) external pure returns (int256 y) {
        y = GaussianRef.cdf_solidity(x);
    }

    /* ---------------- functional equivalence ---------------- */

    function test_differential_sign(int256 x) public {
        unchecked {
            int256 z;
            assembly {
                z := mul(x, NEG_ONE)
            }
            assertEq(z, x * -1);
        }
    }

    function test_differential_units_muli(int256 x, int256 y, int256 denominator) public {
        unchecked {
            // If this function doesn't revert, the unchecked result must be the same.
            int256 z = Units.muli(x, y, denominator);
            assertEq(z, (x * y) / denominator);
        }
    }

    function test_differential_units_abs(int256 x) public {
        unchecked {
            uint256 z = Units.abs(x);
            assertEq(z, uint256(x < 0 ? -x : x));
        }
    }

    function test_differential_erfc(int256 x) public {
        bytes memory calldata1 = abi.encodeCall(this.erfc, (x));
        bytes memory calldata2 = abi.encodeCall(this.erfc_solidity, (x));

        // Make sure the functions behave EXACTLY the same in all cases.
        assertEqCall(calldata2, calldata1);
    }

    function test_differential_ierfc(int256 x) public {
        bytes memory calldata1 = abi.encodeCall(this.ierfc, (x));
        bytes memory calldata2 = abi.encodeCall(this.ierfc_solidity, (x));

        assertEqCall(calldata2, calldata1);
    }

    function test_differential_pdf(int256 x) public {
        bytes memory calldata1 = abi.encodeCall(this.pdf, (x));
        bytes memory calldata2 = abi.encodeCall(this.pdf_solidity, (x));

        assertEqCall(calldata2, calldata1);
    }

    function test_differential_ppf(int256 x) public {
        bytes memory calldata1 = abi.encodeCall(this.ppf, (x));
        bytes memory calldata2 = abi.encodeCall(this.ppf_solidity, (x));

        assertEqCall(calldata2, calldata1);
    }

    function test_differential_cdf(int256 x) public {
        bytes memory calldata1 = abi.encodeCall(this.cdf, (x));
        bytes memory calldata2 = abi.encodeCall(this.cdf_solidity, (x));

        assertEqCall(calldata2, calldata1);
    }
}
