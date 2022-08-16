// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "solstat/Gaussian.sol";

/**
 * @dev Comprehensive library to compute all related functions used with swaps.
 */
library HyperSwapLib {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    uint256 public constant UNIT_WAD = 1e18;
    uint256 public constant UNIT_DOUBLE_WAD = 2e18;
    uint256 public constant SQRT_WAD = 1e9;
    uint256 public constant UNIT_YEAR = 31556953;
    uint256 public constant UNIT_PERCENT = 1e4;

    struct Params {
        uint256 strike;
        uint256 sigma;
        uint256 tau;
    }

    /**
     * P(τ - ε) = ( P(τ)^(√(1 - ε/τ)) / K^2 )e^((1/2)(t^2)(√(τ)√(τ- ε) - (τ - ε)))
     */
    function computePriceWithChangeInTau(
        uint256 stk,
        uint256 vol,
        uint256 prc,
        uint256 tau,
        uint256 epsilon
    ) public view returns (uint256) {
        Params memory params = Params(stk, vol, tau);

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
     * @custom:math
     */
    function computeR1WithPrice(
        uint256 prc,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 R1) {}

    // temp: remove with better error
    error CdfErr(int256 cdf);

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
            uint256 sqrtTauSigma = (tauYears.sqrt() * 1e9).mulWadDown(sigmaWad);

            int256 lnOverVol = (ln * Gaussian.ONE + int256(halfSigmaTau)) / int256(sqrtTauSigma);
            int256 cdf = Gaussian.cdf(lnOverVol);
            if (cdf > Gaussian.ONE) revert CdfErr(cdf);
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
    ) internal pure returns (uint256 prc) {}

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
