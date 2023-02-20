// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "contracts/libraries/RMM01Lib.sol";
import "contracts/test/RMM01ExtendedLib.sol";
import "test/helpers/HelperHyperProfiles.sol";

contract TestRMM01Lib is HelperHyperProfiles, Test {
    using RMM01Lib for RMM01Lib.RMM;
    using RMM01ExtendedLib for RMM01Lib.RMM;
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    RMM01Lib.RMM[] cases;

    function setUp() public {
        addTestCase(DEFAULT_STRIKE, DEFAULT_SIGMA, DEFAULT_MATURITY);
    }

    function addTestCase(uint256 strike, uint256 sigma, uint256 tau) internal returns (RMM01Lib.RMM memory) {
        RMM01Lib.RMM memory info = RMM01Lib.RMM(strike, sigma, tau);
        cases.push(info);
        return info;
    }

    function test_getPriceWithX_defaults_return_expected_price() public {
        uint256 actual = cases[0].getPriceWithX(DEFAULT_ASSET_RESERVE);
        assertApproxEqAbs(actual, DEFAULT_PRICE, 1e4, "price-mismatch");
    }

    /// todo: check this out further... error compounds
    function testFuzz_getXWithPrice_reverses_approx(uint64 p_1) public {
        vm.assume(p_1 > 0);
        vm.assume(p_1 < ((type(uint256).max - 1) / WAD));
        uint256 x_1 = cases[0].getXWithPrice(p_1);
        vm.assume(x_1 > 0);
        vm.assume(x_1 < WAD);

        uint256 p_2 = cases[0].getPriceWithX(x_1);
        assertTrue(p_2 > 0, "output-price-zero");

        uint256 x_2 = cases[0].getXWithPrice(p_2);
        assertApproxEqRel(p_2, p_1, 1e18, "price-mismatch");
        assertApproxEqRel(x_2, x_1, 1e18, "x_1-mismatch");
    }

    // ===== Raw ===== //

    function test_computePriceWithChangeInTau_zero_tau_returns_price() public {
        uint256 price = DEFAULT_PRICE;
        uint256 actual = cases[0].computePriceWithChangeInTau(price, 0);
        assertEq(actual, price);
    }

    function test_computePriceWithChangeInTau_epsilon_tau_returns_strike() public {
        RMM01Lib.RMM memory info = cases[0];
        uint256 price = DEFAULT_PRICE;
        uint256 epsilon = info.tau;
        uint256 actual = info.computePriceWithChangeInTau(price, epsilon);
        assertEq(actual, info.strike);
    }

    function testFuzz_computePriceWithChangeInTau(uint32 epsilon) public {
        RMM01Lib.RMM memory info = cases[0];
        // Fuzzing Filters
        vm.assume(epsilon > 0); // Fuzzing non-zero test cases only.
        vm.assume(epsilon < info.tau); // Epsilon > tau is the same as epsilon == tau.

        // Behavior: as epsilon gets larger, tau gets smaller, price increases, reaches inflection, price tends to strike after inflection point.
        uint256 price = DEFAULT_PRICE;
        uint256 actual = info.computePriceWithChangeInTau(price, epsilon);
        uint256 actualDiff = actual - info.strike;
        uint256 expectedDiff = price - info.strike;
        assertTrue(actualDiff > expectedDiff); // maybe? As tau gets smaller, price should increase until epsilon >= tau.
    }

    // testing

    uint256 internal constant RAY = 1e36;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant YEAR = 31556953;
    uint256 internal constant PERCENTAGE = 1e4;

    /* function testFuzz_exponent(uint256 x) public {
        x = bound(x, 691462483081398177 - 244, 691462483081398177);
        int256 actual = Gaussian.ppf(int256(x));
        console.log("input: 691462483081397933");
        console.logInt(actual);
        console.log("-244");
        console.logInt(Gaussian.ppf(int256(691462483081398177 - 244)));
        console.log("-245");
        console.logInt(Gaussian.ppf(int256(691462483081398177 - 245)));
        console.log("expected input: ", 691462483081398177 - 244);
        assertTrue(actual != int256(0.5 ether), "found value!");
        assertTrue(false);
    } */

    function testFuzz_getXWithPrice_succeeds() public {
        uint256 price = 10 ether;
        uint256 actual = cases[0].getXWithPrice(price);
        uint256 expected = 1 ether - 691462483081397933;

        console.log("==ln of 1==");
        console.logInt(FixedPointMathLib.lnWad(1 ether));

        {
            (uint256 prc, uint256 stk, uint256 vol, uint256 tau) = (
                price,
                cases[0].strike,
                cases[0].sigma,
                cases[0].tau
            );
            uint256 input = (prc * RAY) / stk;
            int256 ln = FixedPointMathLib.lnWad(int256(input / WAD));
            uint256 tauYears;
            uint256 volRay;

            assembly {
                tauYears := div(mul(tau, RAY), YEAR)
                volRay := div(mul(vol, RAY), PERCENTAGE)
            }
            uint256 doubleSigma = (volRay * volRay) / uint256(2e36);
            uint256 halfSigmaTau = doubleSigma * tauYears; // units^2, 1e72
            uint256 sqrtTauSigma = ((tauYears.sqrt() * WAD) * volRay) / RAY; // 1e18 * 1e18 * 1e36 / 1e36 = 1e36

            int256 lnOverVol = (ln * Gaussian.ONE * int256(RAY) + int256(halfSigmaTau)) /
                int256(sqrtTauSigma) /
                Gaussian.ONE; // 1e18
            console.log("==lnOverVol==");
            console.logInt(lnOverVol);
            int256 cdf = Gaussian.cdf(lnOverVol);
            console.log("==cdf==");
            console.logInt(cdf);
            uint256 R_x = uint256(Gaussian.ONE - cdf);
            console.log("==x==", R_x);
        }

        assertApproxEqAbs(actual, expected, 1e5, "expected-mismatch");
        assertApproxEqAbs(1 ether - actual, 1 ether - expected, 1e5, "expected-mismatch-less");
    }

    /* function test_exponent() public {
        uint256 price = 10 ether;
        uint256 R_x = cases[0].getXWithPrice(price);
        uint256 stk = cases[0].strike;
        uint256 vol = cases[0].sigma;
        uint256 tau = cases[0].tau;
        {
            uint256 tauYears;
            uint256 volRay;

            uint256 RAY = 1 ether;
            assembly {
                tauYears := div(mul(tau, RAY), 31556953)
                volRay := div(mul(vol, RAY), 10000)
            }

            int256 input = Gaussian.ONE - int256(R_x);
            int256 ppf = Gaussian.ppf(input);
            uint256 sqrtTauSigma = (tauYears.sqrt() * 1e9).mulWadDown(volRay);
            int256 first = (ppf * int256(sqrtTauSigma)) / Gaussian.ONE; // Φ^-1(1 - R_x)σ√τ
            uint256 doubleSigma = (volRay * volRay) / uint256(Gaussian.TWO);
            int256 halfSigmaTau = int256(doubleSigma * tauYears) / Gaussian.ONE; // 1/2σ^2τ

            console.logInt(input);
            console.logInt(ppf);
            console.log(sqrtTauSigma);
            console.logInt(first);
            console.logInt(halfSigmaTau);
            int256 exponent = first - halfSigmaTau;
            int256 exp = exponent.expWad();
            console.logInt(exponent);
            console.logInt(exp);
            //uint256 prc = FixedPointMathLib.mulWadDown(uint256(exp), stk);
        }
    } */

    /* function testFuzzComputedPrice(uint256 x) public {
        x = bound(x, 308537538725986896 - 220e8, 308537538725986896 - 210e8);
        uint256 actual = cases[0].getPriceWithX(x);
        console.log("input", x);
        console.log("price", actual);
        console.log(cases[0].getXWithPrice(10 ether));
        //assertApproxEqAbs(actual, 10 ether, 1e10, "found-answer");
        console.log(cases[0].getPriceWithX(308537516918601823));
        assertTrue(actual != 10 ether, "found the bug");
        assertTrue(!((actual <= 10 ether + 1191e3) && (actual >= 10 ether - 1191e3)), "found value!");
    } */

    function testComputedAssetReserveWithDefaultPrice() public {
        uint256 actual = cases[0].getXWithPrice(DEFAULT_PRICE);
        assertEq(actual, DEFAULT_ASSET_RESERVE);
    }

    function testComputedQuoteReserveWithDefaultAssetReserve() public {
        uint256 actual = cases[0].getYWithX(DEFAULT_ASSET_RESERVE, 0);
        assertEq(actual, DEFAULT_QUOTE_RESERVE);
    }

    function testComputedAssetReserveWithDefaultQuoteReserve() public {
        uint256 actual = cases[0].getXWithY(DEFAULT_QUOTE_RESERVE, 0);
        assertEq(actual, DEFAULT_ASSET_RESERVE);
    }

    function testComputedReservesWithDefaultPrice() public {
        (uint256 actualQuoteReserve, uint256 actualAssetReserve) = cases[0].computeReserves(DEFAULT_PRICE, 0);
        assertEq(actualQuoteReserve, DEFAULT_QUOTE_RESERVE);
        assertEq(actualAssetReserve, DEFAULT_ASSET_RESERVE);
    }

    function testFuzz_computeReserves_no_reverts(uint256 price) public pure {
        vm.assume(price > 0);
        vm.assume(price < type(uint128).max);
        // (uint256 y, uint256 x) = cases[0].computeReserves(price, 0);
    }

    function testConvertPercentageReturnsOne() public {
        uint256 percentage = PERCENTAGE;
        uint256 expected = WAD;
        uint256 converted = RMM01Lib.convertPercentageToWad(percentage);
        assertEq(converted, expected);
    }

    function testFuzzConvertPercentageReturnsComputedValue(uint256 percentage) public {
        vm.assume(percentage < type(uint64).max);
        uint256 expected = (percentage * WAD) / PERCENTAGE;
        uint256 converted = RMM01Lib.convertPercentageToWad(percentage);
        assertEq(converted, expected);
    }

    function testInvariantReturnsZeroWithDefaultPool() public {
        int256 actual = cases[0].invariantOf(DEFAULT_QUOTE_RESERVE, DEFAULT_ASSET_RESERVE);
        assertEq(actual, 0);
    }
}
