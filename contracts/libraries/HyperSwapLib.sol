// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./Invariant.sol";

/**
 * @dev Comprehensive library to compute all related functions used with swaps.
 */
library HyperSwapLib {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    int256 internal constant TICK_BASE = 1_0001e14;
    uint256 internal constant UNIT_WAD = 1e18;
    uint256 internal constant UNIT_DOUBLE_WAD = 2e18;
    uint256 internal constant SQRT_WAD = 1e9;
    uint256 internal constant UNIT_YEAR = 31556953;
    uint256 internal constant UNIT_PERCENT = 1e4;

    /// @dev Thrown if value is greater than 1e18.
    error AboveWAD(int256 cdf);

    /**
     * @notice Packaged data structure to easily compute single values from a set of parameters.
     */
    struct Expiring {
        uint256 strike;
        uint256 sigma;
        uint256 tau;
    }

    // --- Class Methods --- //

    function computeR1WithPrice(Expiring memory args, uint256 price) internal view returns (uint256 R1) {
        R1 = computeR1WithPrice(price, args.strike, args.sigma, args.tau);
    }

    function computeR2WithPrice(Expiring memory args, uint256 price) internal view returns (uint256 R2) {
        R2 = computeR2WithPrice(price, args.strike, args.sigma, args.tau);
    }

    function computePriceWithR1(Expiring memory args, uint256 R1) internal view returns (uint256 price) {
        price = computePriceWithR1(R1, args.strike, args.sigma, args.tau);
    }

    function computePriceWithR2(Expiring memory args, uint256 R2) internal view returns (uint256 price) {
        price = computePriceWithR2(R2, args.strike, args.sigma, args.tau);
    }

    function computeR1WithR2(
        Expiring memory args,
        uint256 R2,
        uint256 price,
        int256 invariant
    ) internal view returns (uint256 R1) {
        R1 = computeR1WithR2(R2, args.strike, args.sigma, args.tau, price, invariant);
    }

    function computeR2WithR1(
        Expiring memory args,
        uint256 R1,
        uint256 price,
        int256 invariant
    ) internal view returns (uint256 R2) {
        R2 = computeR2WithR1(R1, args.strike, args.sigma, args.tau, price, invariant);
    }

    function computePriceWithChangeInTau(
        Expiring memory args,
        uint256 prc,
        uint256 epsilon
    ) internal view returns (uint256) {
        return computePriceWithChangeInTau(args.strike, args.sigma, prc, args.tau, epsilon);
    }

    function computeReservesWithTick(Expiring memory args, int24 tick)
        internal
        returns (
            uint256 price,
            uint256 R1,
            uint256 R2
        )
    {
        price = computePriceWithTick(tick);
        R1 = computeR1WithPrice(price, args.strike, args.sigma, args.tau);
        R2 = computeR2WithPrice(price, args.strike, args.sigma, args.tau);
    }

    // --- Raw Functions --- //

    /**
     * P(τ - ε) = ( P(τ)^(√(1 - ε/τ)) / K^2 )e^((1/2)(t^2)(√(τ)√(τ- ε) - (τ - ε)))
     */
    function computePriceWithChangeInTau(
        uint256 stk,
        uint256 vol,
        uint256 prc,
        uint256 tau,
        uint256 epsilon
    ) internal view returns (uint256) {
        if (epsilon == 0) return prc;

        Expiring memory params = Expiring(stk, vol, tau);

        uint256 tauYears;
        assembly {
            tauYears := sdiv(mul(tau, UNIT_WAD), UNIT_YEAR) // tau * WAD / year = time in years scaled to WAD
        }

        uint256 epsilonYears;
        assembly {
            epsilonYears := sdiv(mul(epsilon, UNIT_WAD), UNIT_YEAR) // epsilon * WAD / year = epsilon in years scaled to WAD
        }

        uint256 term_0 = UNIT_WAD - (epsilonYears.divWadUp(tauYears)); // WAD - ((epsilon * WAD) / tau rounded down), units are WAD - WAD, time units cancel out
        uint256 term_1 = term_0.sqrt(); // this sqrts WAD, so we end up with SQRT_WAD units

        uint256 term_2 = prc.divWadUp(params.strike); // p(t) / K, both units are already WAD
        uint256 term_3 = uint256(int256(term_2).powWad(int256(term_1 * SQRT_WAD)));

        // -- other section -- //

        uint256 term_7;
        {
            uint256 currentTau = tauYears - epsilonYears; // WAD - WAD = WAD
            uint256 tausSqrt = tauYears.sqrt() * (currentTau).sqrt(); // sqrt(1e18) = 1e9, so 1e9 * 1e9 = 1e18
            uint256 term_4 = tausSqrt - currentTau; // WAD - WAD = WAD

            uint256 sigmaWad = (uint256(params.sigma) * UNIT_WAD) / 1e4;

            uint256 term_5 = (sigmaWad * sigmaWad) / UNIT_DOUBLE_WAD; // 1e4 * 1e4 * 1e17 / 1e4 = 1e17, which is half WAD

            uint256 term_6 = uint256((int256(term_5.mulWadDown(term_4))).expWad()); // exp(WAD * WAD / WAD)
            term_7 = uint256(params.strike).mulWadDown(term_6); // WAD * WAD / WAD
        }

        uint256 price = term_3.mulWadDown(term_7); // WAD * WAD / WAD = WAD
        return price;
    }

    /**
     * @notice Computes the R1 reserve given the R2 reserve and a price.
     *
     * @custom:math R1 / price(hiSlotIndex) = tradingFunction(...)
     */
    function computeR1WithR2(
        uint256 R2,
        uint256 strike,
        uint256 sigma,
        uint256 tau,
        uint256 price,
        int256 invariant
    ) internal view returns (uint256 R1) {
        R1 = Invariant.getY(R2, strike, sigma, tau, invariant); // todo: use price for concentrated curve
    }

    /**
     * @notice Computes the R1 reserve given the R2 reserve and a price.
     *
     * @custom:math R1 / price(hiSlotIndex) = tradingFunction(...)
     */
    function computeR2WithR1(
        uint256 R1,
        uint256 strike,
        uint256 sigma,
        uint256 tau,
        uint256 price,
        int256 invariant
    ) internal view returns (uint256 R2) {
        R2 = Invariant.getX(R1, strike, sigma, tau, invariant); // todo: use price for concentrated curve
    }

    /**
     * @custom:math R1 = KΦ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
     */
    function computeR1WithPrice(
        uint256 prc,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal view returns (uint256 R1) {
        // todo: handle price when above strike.
        if (prc != 0) {
            int256 ln = FixedPointMathLib.lnWad(int256(FixedPointMathLib.divWadDown(prc, stk)));
            uint256 tauYears = convertSecondsToWadYears(tau);

            uint256 sigmaWad = convertPercentageToWad(vol);
            uint256 doubleSigma = (sigmaWad * sigmaWad) / uint256(Gaussian.TWO);
            uint256 halfSigmaTau = doubleSigma * tauYears; // todo: verify, might be Wad^2 ?
            uint256 sqrtTauSigma = (tauYears.sqrt() * 1e9).mulWadDown(sigmaWad);

            int256 lnOverVol = (ln * Gaussian.ONE + int256(halfSigmaTau)) / int256(sqrtTauSigma);
            int256 cdf = Gaussian.cdf(lnOverVol);
            if (cdf > Gaussian.ONE) revert AboveWAD(cdf);
            R1 = stk.mulWadDown(uint256(cdf));
        }
    }

    /**
     * @custom:math R2 = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
     */
    function computeR2WithPrice(
        uint256 prc,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal view returns (uint256 R2) {
        // todo: handle price when above strike.
        if (prc != 0) {
            int256 ln = FixedPointMathLib.lnWad(int256(FixedPointMathLib.divWadDown(prc, stk)));
            uint256 tauYears = convertSecondsToWadYears(tau);

            uint256 sigmaWad = convertPercentageToWad(vol);
            uint256 doubleSigma = (sigmaWad * sigmaWad) / uint256(Gaussian.TWO);
            uint256 halfSigmaTau = doubleSigma * tauYears;
            uint256 sqrtTauSigma = (tauYears.sqrt() * SQRT_WAD).mulWadDown(sigmaWad);

            int256 lnOverVol = (ln * Gaussian.ONE + int256(halfSigmaTau)) / int256(sqrtTauSigma);
            int256 cdf = Gaussian.cdf(lnOverVol);
            if (cdf > Gaussian.ONE) revert AboveWAD(cdf);
            R2 = uint256(Gaussian.ONE - cdf);
        }
    }

    /**
     * @custom:math
     */
    function computePriceWithR1(
        uint256 R1,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 prc) {}

    /**
     * @custom:math price(R2) = Ke^(Φ^-1(1 - R2)σ√τ - 1/2σ^2τ)
     */
    function computePriceWithR2(
        uint256 R2,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal view returns (uint256 prc) {
        uint256 tauYears = convertSecondsToWadYears(tau);
        uint256 volWad = convertPercentageToWad(vol);

        if (uint256(Gaussian.ONE) < R2) revert AboveWAD(int256(R2));
        int256 input = Gaussian.ONE - int256(R2);
        int256 ppf = Gaussian.ppf(input);
        uint256 sqrtTauSigma = (tauYears.sqrt() * SQRT_WAD).mulWadDown(volWad);
        int256 first = (ppf * int256(sqrtTauSigma)) / Gaussian.ONE; // Φ^-1(1 - R2)σ√τ
        uint256 doubleSigma = (volWad * volWad) / uint256(Gaussian.TWO);
        int256 halfSigmaTau = int256(doubleSigma * tauYears) / Gaussian.ONE; // 1/2σ^2τ

        int256 exponent = first - halfSigmaTau;
        int256 exp = exponent.expWad();
        prc = uint256(exp).mulWadDown(stk);
    }

    // --- Tick Math --- //

    /**
     * @dev Computes a price value from a tick key.
     *
     * @custom:math price = e^(ln(1.0001) * tick)
     *
     * @param tick Key of a slot in a price/liquidity grid.
     * @return price Value on a key (tick) value pair of a price grid.
     */
    function computePriceWithTick(int24 tick) internal pure returns (uint256 price) {
        int256 tickWad = int256(tick) * int256(FixedPointMathLib.WAD);
        price = uint256(FixedPointMathLib.powWad(TICK_BASE, tickWad));
    }

    /**
     * @dev Computes a tick value from the price.
     *
     * @custom:math tick = ln(price) / ln(1.0001)
     *
     * @param price Value on a key (tick) value pair of a price grid.
     * @return tick Key of a slot in a price/liquidity grid.
     */
    function computeTickWithPrice(uint256 price) internal pure returns (int24 tick) {
        uint256 numerator = uint256(int256(price).lnWad());
        uint256 denominator = uint256(TICK_BASE.lnWad());
        uint256 val = numerator / denominator + 1; // Values are in Fixed Point Q.96 format. Rounds up.
        tick = int24(int256((numerator)) / int256(denominator) + 1);
    }

    // --- Utils --- //

    /**
     * @notice Changes seconds into WAD units then divides by the amount of seconds in a year.
     */
    function convertSecondsToWadYears(uint256 sec) internal pure returns (uint256 yrsWad) {
        assembly {
            yrsWad := div(mul(sec, UNIT_WAD), UNIT_YEAR)
        }
    }

    /**
     * @notice Changes percentage into WAD units then cancels the percentage units.
     */
    function convertPercentageToWad(uint256 pct) internal pure returns (uint256 pctWad) {
        assembly {
            pctWad := div(mul(pct, UNIT_WAD), UNIT_PERCENT)
        }
    }
}
