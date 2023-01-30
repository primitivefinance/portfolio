// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "solstat/Invariant.sol";

using Price for Price.RMM global;

/**
 * @dev     Library for RMM to compute reserves, prices, and changes in reserves over time.
 * @notice  Units Glossary:
 *
 *          wad - `1 ether` == 1e18
 *          seconds - `1 seconds` == 1
 *          percentage - 10_000 == 100%
 *
 */
library Price {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    struct RMM {
        uint256 strike; // wad
        uint256 sigma; // 10_000 = 100%;
        uint256 tau; // seconds
    }

    error UndefinedPrice();
    error OverflowWad(int256 wad);

    int256 internal constant TICK_BASE = 1_0001e14;
    uint256 internal constant DOUBLE_WAD = 2 ether;
    uint256 internal constant PERCENTAGE = 10_000;
    uint256 internal constant SQRT_WAD = 1e9;
    uint256 internal constant WAD = 1 ether;
    uint256 internal constant YEAR = 31556953 seconds;

    // ===== Class Methods ===== //

    function invariantOf(RMM memory args, uint R_y, uint R_x) internal pure returns (int256) {
        return Invariant.invariant(R_y, R_x, args.strike, convertPercentageToWad(args.sigma), args.tau);
    }

    function getXWithPrice(RMM memory args, uint256 prc) internal pure returns (uint256 R_x) {
        R_x = getXWithPrice(prc, args.strike, args.sigma, args.tau);
    }

    function getPriceWithX(RMM memory args, uint256 R_x) internal pure returns (uint256 prc) {
        prc = getPriceWithX(R_x, args.strike, args.sigma, args.tau);
    }

    function getYWithX(RMM memory args, uint256 R_x, int256 inv) internal pure returns (uint256 R_y) {
        R_y = getYWithX(R_x, args.strike, args.sigma, args.tau, inv);
    }

    function getXWithY(RMM memory args, uint256 R_y, int256 inv) internal pure returns (uint256 R_x) {
        R_x = getXWithY(R_y, args.strike, args.sigma, args.tau, inv);
    }

    function computePriceWithChangeInTau(RMM memory args, uint256 prc, uint256 eps) internal pure returns (uint256) {
        return computePriceWithChangeInTau(args.strike, args.sigma, prc, args.tau, eps);
    }

    function computeReserves(RMM memory args, uint prc, int128 inv) internal pure returns (uint R_y, uint R_x) {
        R_x = getXWithPrice(prc, args.strike, args.sigma, args.tau);
        R_y = getYWithX(R_x, args.strike, args.sigma, args.tau, inv);
    }

    // ===== Raw Functions ===== //

    /**
     * @dev Computes the next price, invariant, and y reserves of a curve after a change in time.
     */
    function computeCurveChanges(
        uint256 stk,
        uint256 vol,
        uint256 tau,
        uint256 prc,
        int256 invariant,
        uint256 epsilon
    ) internal pure returns (uint p_t, int128 i_t, uint t_e) {
        RMM memory curve = RMM(stk, vol, tau);
        p_t = curve.computePriceWithChangeInTau(prc, epsilon);

        uint x_1 = curve.getXWithPrice(prc);
        curve.tau -= epsilon;
        uint256 y_2 = curve.getYWithX(x_1, invariant);

        i_t = int128(curve.invariantOf(y_2, x_1)); // todo: fix cast
        t_e = tau - epsilon;
    }

    /**
     * @dev Computes change in price given a change in time in seconds.
     * @param stk WAD
     * @param vol percentage
     * @param prc WAD
     * @param tau seconds
     * @param epsilon seconds
     * @custom:math P(τ - ε) = ( ( P(τ) / K ) ^ ( √(1 - ε/τ) )) (K) (e^( (1/2) (o^2) ( √(τ) √(τ- ε) - (τ - ε) ) ))
     */
    function computePriceWithChangeInTau(
        uint256 stk,
        uint256 vol,
        uint256 prc,
        uint256 tau,
        uint256 epsilon
    ) internal pure returns (uint256) {
        if (epsilon == 0) return prc;
        if (epsilon > tau) return stk;

        RMM memory params = RMM(stk, vol, tau);

        uint256 tauYears;
        assembly {
            tauYears := sdiv(mul(tau, WAD), YEAR) // tau * WAD / year = time in years scaled to WAD
        }

        uint256 epsilonYears;
        assembly {
            epsilonYears := sdiv(mul(epsilon, WAD), YEAR) // epsilon * WAD / year = epsilon in years scaled to WAD
        }

        uint256 term_0 = WAD - (epsilonYears.divWadUp(tauYears)); // 1 - ε/τ, WAD - ((epsilon * WAD) / tau rounded down), units are WAD - WAD, time units cancel out
        uint256 term_1 = term_0.sqrt(); // √(1 - ε/τ)), this sqrts WAD, so we end up with SQRT_WAD units

        uint256 term_2 = prc.divWadUp(params.strike); // P(t) / K, both units are already WAD
        uint256 term_3 = uint256(int256(term_2).powWad(int256(term_1 * SQRT_WAD))); // ( P(τ) / K ) ^ ( √(1 - ε/τ) ))

        uint256 term_7;
        {
            uint256 currentTau = tauYears - epsilonYears; // (τ- ε), WAD - WAD = WAD
            uint256 tausSqrt = tauYears.sqrt() * (currentTau).sqrt(); // ( √(τ) √(τ- ε) ), sqrt(1e18) = 1e9, so 1e9 * 1e9 = 1e18
            uint256 term_4 = tausSqrt - currentTau; // ( √(τ) √(τ- ε) - (τ - ε) ), WAD - WAD = WAD

            uint256 sigmaWad = convertPercentageToWad(uint256(params.sigma));

            uint256 term_5 = (sigmaWad * sigmaWad) / DOUBLE_WAD; // ( 1 / 2 )(o^2), 1e4 * 1e4 * 1e17 / 1e4 = 1e17, which is half WAD
            uint256 term_6 = uint256((int256(term_5.mulWadDown(term_4))).expWad()); // (e^( (1/2) (o^2) ( √(τ) √(τ- ε) - (τ - ε) ) )), exp(WAD * WAD / WAD)
            term_7 = uint256(params.strike).mulWadDown(term_6); // (K) (e^( (1/2) (o^2) ( √(τ) √(τ- ε) - (τ - ε) ) ), WAD * WAD / WAD
        }

        uint256 price = term_3.mulWadDown(term_7); // WAD * WAD / WAD = WAD
        return price;
    }

    /**
     * @custom:math
     * y(τ - ε) = K phi( 1 / (o * sqrt(t)) * ln(P(t) / K) + 1/2*o^2t - o*sqrt(t-e))
     */
    function computeYWithChangeInTau(
        uint256 stk,
        uint256 vol,
        uint256 prc,
        uint256 tau,
        uint256 epsilon
    ) internal pure returns (uint256 R_y) {
        RMM memory params = RMM(stk, vol, tau);

        uint256 tauYears;
        assembly {
            tauYears := sdiv(mul(tau, WAD), YEAR) // tau * WAD / year = time in years scaled to WAD
        }

        uint256 epsilonYears;
        assembly {
            epsilonYears := sdiv(mul(epsilon, WAD), YEAR) // epsilon * WAD / year = epsilon in years scaled to WAD
        }

        uint256 sigmaWad = convertPercentageToWad(uint256(params.sigma));
        uint part0 = WAD.divWadDown(sigmaWad.mulWadDown(tauYears.sqrt() * 1e9));
        part0 = part0.mulWadDown(uint(int256(prc.divWadDown(params.strike)).lnWad()));

        uint part1 = (sigmaWad * sigmaWad) / DOUBLE_WAD;
        part1 = part1.mulWadDown(tauYears);

        uint part2 = sigmaWad.mulWadDown((tauYears - epsilonYears).sqrt() * 1e9);

        R_y = params.strike.mulWadDown(uint(Gaussian.cdf(int(part0 + part1 - part2))));
    }

    /**
     * @dev R_y = tradingFunction(R_x, ...)
     * @param R_x WAD
     * @param stk WAD
     * @param vol percentage
     * @param tau seconds
     * @param inv WAD
     * @return R_y WAD
     */
    function getYWithX(
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau,
        int256 inv
    ) internal pure returns (uint256 R_y) {
        R_y = Invariant.getY(R_x, stk, convertPercentageToWad(vol), tau, inv);
    }

    /**
     * @dev R_x = tradingFunction(R_y, ...)
     * @param R_y WAD
     * @param stk WAD
     * @param vol percentage
     * @param tau seconds
     * @param inv WAD
     * @return R_x WAD
     */
    function getXWithY(
        uint256 R_y,
        uint256 stk,
        uint256 vol,
        uint256 tau,
        int256 inv
    ) internal pure returns (uint256 R_x) {
        R_x = Invariant.getX(R_y, stk, convertPercentageToWad(vol), tau, inv);
    }

    /**
     * @dev Used in `getAmounts` to compute the virtual amount of assets at the pool's price.
     * @param prc WAD
     * @param stk WAD
     * @param vol percentage
     * @param tau seconds
     * @return R_x WAD
     * @custom:math R_x = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
     */
    function getXWithPrice(uint256 prc, uint256 stk, uint256 vol, uint256 tau) internal pure returns (uint256 R_x) {
        if (prc != 0) {
            int256 ln = FixedPointMathLib.lnWad(int256(FixedPointMathLib.divWadDown(prc, stk)));
            uint256 tauYears = convertSecondsToWadYears(tau);

            uint256 sigmaWad = convertPercentageToWad(vol);
            uint256 doubleSigma = (sigmaWad * sigmaWad) / uint256(Gaussian.TWO);
            uint256 halfSigmaTau = doubleSigma * tauYears;
            uint256 sqrtTauSigma = (tauYears.sqrt() * SQRT_WAD).mulWadDown(sigmaWad);

            int256 lnOverVol = (ln * Gaussian.ONE + int256(halfSigmaTau)) / int256(sqrtTauSigma);
            int256 cdf = Gaussian.cdf(lnOverVol);
            if (cdf > Gaussian.ONE) revert OverflowWad(cdf);
            R_x = uint256(Gaussian.ONE - cdf);
        }
    }

    /**
     * @dev price(R_x) = Ke^(Φ^-1(1 - R_x)σ√τ - 1/2σ^2τ)
     *      As lim_x->0, S(x) = +infinity for all tau > 0 and vol > 0.
     *      As lim_x->1, S(x) = 0 for all tau > 0 and vol > 0.
     *      If tau or vol is zero, price is equal to strike.
     * @param R_x WAD
     * @param stk WAD
     * @param vol percentage
     * @param tau seconds
     * @return prc WAD
     */
    function getPriceWithX(uint256 R_x, uint256 stk, uint256 vol, uint256 tau) internal pure returns (uint256 prc) {
        uint256 tauYears = convertSecondsToWadYears(tau);
        uint256 volWad = convertPercentageToWad(vol);

        if (uint256(Gaussian.ONE) < R_x) revert OverflowWad(int256(R_x));
        if (R_x == 0) revert UndefinedPrice(); // As lim_x->0, S(x) = +infinity.
        if (tauYears == 0 || volWad == 0) return stk; // Ke^(0 - 0) = K.
        if (R_x == uint256(Gaussian.ONE)) return stk; // As lim_x->1, S(x) = 0 for all tau > 0 and vol > 0.

        int256 input = Gaussian.ONE - int256(R_x);
        int256 ppf = Gaussian.ppf(input);
        uint256 sqrtTauSigma = (tauYears.sqrt() * SQRT_WAD).mulWadDown(volWad);
        int256 first = (ppf * int256(sqrtTauSigma)) / Gaussian.ONE; // Φ^-1(1 - R_x)σ√τ
        uint256 doubleSigma = (volWad * volWad) / uint256(Gaussian.TWO);
        int256 halfSigmaTau = int256(doubleSigma * tauYears) / Gaussian.ONE; // 1/2σ^2τ

        int256 exponent = first - halfSigmaTau;
        int256 exp = exponent.expWad();
        prc = uint256(exp).mulWadDown(stk);
    }

    // ===== Tick Math ===== //

    /**
     * @dev Computes a price value from a tick key.
     *
     * @custom:math price = e^(ln(1.0001) * tick)
     *
     * @param tick Key of a slot in a price/liquidity grid.
     * @return price WAD Value on a key (tick) value pair of a price grid.
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
     * @param price WAD Value on a key (tick) value pair of a price grid.
     * @return tick Key of a slot in a price/liquidity grid.
     */
    function computeTickWithPrice(uint256 price) internal pure returns (int24 tick) {
        uint256 numerator = uint256(int256(price).lnWad());
        uint256 denominator = uint256(TICK_BASE.lnWad());
        tick = int24(int256((numerator)) / int256(denominator) + 1);
    }

    // ===== Utils ===== //

    function convertSecondsToWadYears(uint256 sec) internal pure returns (uint256 yrsWad) {
        assembly {
            yrsWad := div(mul(sec, WAD), YEAR)
        }
    }

    function convertPercentageToWad(uint256 pct) internal pure returns (uint256 pctWad) {
        assembly {
            pctWad := div(mul(pct, WAD), PERCENTAGE)
        }
    }
}
