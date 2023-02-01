// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestPriceSetup.sol";

contract TestPriceComputePrice is TestPriceSetup {
    using Price for Price.RMM;
    using FixedPointMathLib for uint;
    using FixedPointMathLib for int;

    function test_getPriceWithX_defaults_return_expected_price() public {
        uint actual = cases[0].getPriceWithX(DEFAULT_ASSET_RESERVE);
        assertEq(actual, DEFAULT_PRICE, "price-mismatch");
    }

    function test_getXWithPrice_reverses_exact() public {
        uint price = 10 ether;
        uint x = cases[0].getXWithPrice(price);
        assertTrue(x != 1e36);
        uint p = cases[0].getPriceWithX(x);
        uint x_2 = cases[0].getXWithPrice(p);
        console.log("x_1", x);
        console.log("x_2", x_2);
        console.log("p_1", p);
        assertEq(p, price, "price-mismatch");
        assertEq(x_2, x, "x-mismatch");
    }

    function testFuzz_getXWithPrice_reverses_exact(uint p_1) public {
        uint x_1 = cases[0].getXWithPrice(p_1);
        assertTrue(x_1 != WAD);

        uint p_2 = cases[0].getPriceWithX(x_1);
        uint x_2 = cases[0].getXWithPrice(p_2);
        assertEq(p_2, p_1, "price-mismatch");
        assertEq(x_2, x_1, "x_1-mismatch");
    }

    // ===== Raw ===== //

    function test_computePriceWithChangeInTau_zero_tau_returns_price() public {
        uint price = DEFAULT_PRICE;
        uint actual = cases[0].computePriceWithChangeInTau(price, 0);
        assertEq(actual, price);
    }

    function test_computePriceWithChangeInTau_epsilon_tau_returns_strike() public {
        Price.RMM memory info = cases[0];
        uint price = DEFAULT_PRICE;
        uint epsilon = info.tau;
        uint actual = info.computePriceWithChangeInTau(price, epsilon);
        assertEq(actual, info.strike);
    }

    function testFuzz_computePriceWithChangeInTau(uint32 epsilon) public {
        Price.RMM memory info = cases[0];
        // Fuzzing Filters
        vm.assume(epsilon > 0); // Fuzzing non-zero test cases only.
        vm.assume(epsilon < info.tau); // Epsilon > tau is the same as epsilon == tau.

        // Behavior: as epsilon gets larger, tau gets smaller, price increases, reaches inflection, price tends to strike after inflection point.
        uint price = DEFAULT_PRICE;
        uint actual = info.computePriceWithChangeInTau(price, epsilon);
        uint actualDiff = actual - info.strike;
        uint expectedDiff = price - info.strike;
        assertTrue(actualDiff > expectedDiff); // maybe? As tau gets smaller, price should increase until epsilon >= tau.
    }

    // testing

    uint internal constant RAY = 1e36;
    uint internal constant WAD = 1e18;
    uint internal constant YEAR = 31556953;
    uint internal constant PERCENTAGE = 1e4;

    function testFuzz_exponent(uint x) public {
        x = bound(x, 691462483081398177 - 244, 691462483081398177);
        int actual = Gaussian.ppf(int(x));
        console.log("input: 691462483081397933");
        console.logInt(actual);
        console.log("-244");
        console.logInt(Gaussian.ppf(int(691462483081398177 - 244)));
        console.log("-245");
        console.logInt(Gaussian.ppf(int(691462483081398177 - 245)));
        console.log("expected input: ", 691462483081398177 - 244);
        assertTrue(actual != int(0.5 ether), "found value!");
        assertTrue(false);
    }

    function testFuzz_getXWithPrice_succeeds() public {
        uint price = 10 ether;
        uint actual = cases[0].getXWithPrice(price);
        uint expected = 1 ether - 691462483081397933;

        console.log("==ln of 1==");
        console.logInt(FixedPointMathLib.lnWad(1 ether));

        {
            (uint256 prc, uint256 stk, uint256 vol, uint256 tau) = (
                price,
                cases[0].strike,
                cases[0].sigma,
                cases[0].tau
            );
            uint input = (prc * RAY) / stk;
            int256 ln = FixedPointMathLib.lnWad(int256(input / WAD));
            uint tauYears;
            uint volRay;

            assembly {
                tauYears := div(mul(tau, RAY), YEAR)
                volRay := div(mul(vol, RAY), PERCENTAGE)
            }
            uint256 doubleSigma = (volRay * volRay) / uint256(2e36);
            uint256 halfSigmaTau = doubleSigma * tauYears; // units^2, 1e72
            uint256 sqrtTauSigma = ((tauYears.sqrt() * WAD) * volRay) / RAY; // 1e18 * 1e18 * 1e36 / 1e36 = 1e36

            int256 lnOverVol = (ln * Gaussian.ONE * int(RAY) + int256(halfSigmaTau)) /
                int256(sqrtTauSigma) /
                Gaussian.ONE; // 1e18
            console.log("==lnOverVol==");
            console.logInt(lnOverVol);
            int256 cdf = Gaussian.cdf(lnOverVol);
            console.log("==cdf==");
            console.logInt(cdf);
            uint R_x = uint256(Gaussian.ONE - cdf);
            console.log("==x==", R_x);
        }

        assertEq(actual, expected, "expected-mismatch");
        assertEq(1 ether - actual, 1 ether - expected, "expected-mismatch-less");
    }

    function test_exponent() public {
        uint price = 10 ether;
        uint R_x = cases[0].getXWithPrice(price);
        uint stk = cases[0].strike;
        uint vol = cases[0].sigma;
        uint tau = cases[0].tau;
        {
            uint tauYears;
            uint volRay;

            uint RAY = 1 ether;
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
            //uint prc = FixedPointMathLib.mulWadDown(uint256(exp), stk);
        }
    }

    function testFuzzComputedPrice(uint x) public {
        x = bound(x, 308537538725986896 - 220e8, 308537538725986896 - 210e8);
        uint actual = cases[0].getPriceWithX(x);
        console.log("input", x);
        console.log("price", actual);
        console.log(cases[0].getXWithPrice(10 ether));
        //assertApproxEqAbs(actual, 10 ether, 1e10, "found-answer");
        console.log(cases[0].getPriceWithX(308537516918601823));
        assertTrue(actual != 10 ether, "found the bug");
        assertTrue(!((actual <= 10 ether + 1191e3) && (actual >= 10 ether - 1191e3)), "found value!");
    }
}
