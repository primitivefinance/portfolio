// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "solstat/Invariant.sol";
import {HyperPool, Iteration, SwapInputTooSmall, Assembly} from "../HyperLib.sol";

uint256 constant PERCENTAGE = 10_000;
uint256 constant SQRT_WAD = 1e9;
uint256 constant WAD = 1 ether;
uint256 constant YEAR = 31556953 seconds;

/**
 * @dev     Library for RMM to compute reserves, prices, and changes in reserves over time.
 * @notice  Units Glossary:
 *
 *          wad - `1 ether` == 1e18
 *          seconds - `1 seconds` == 1
 *          percentage - 10_000 == 100%
 *
 */
library RMM01Lib {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;
    using {Assembly.scaleFromWadDown, Assembly.scaleToWad, Assembly.scaleFromWadUp} for uint;

    error UndefinedPrice();
    error OverflowWad(int256 wad);

    function invariantOf(HyperPool memory self, uint r1, uint r2, uint timeRemainingSec) internal pure returns (int) {
        return
            Invariant.invariant({
                R_y: r2,
                R_x: r1,
                stk: self.params.maxPrice,
                vol: convertPercentageToWad(self.params.volatility),
                tau: convertSecondsToWadYears(timeRemainingSec)
            });
    }

    /**
     * @dev This is an approximation of the amount out and it is not exactly precise to the optimal amount.
     * @custom:error Maximum absolute error of 1e-6.
     */
    function getAmountOut(
        HyperPool memory self,
        bool direction,
        uint amountIn,
        uint secondsPassed
    ) internal pure returns (uint) {
        // Sets data.invariant, data.liquidity, and data.remainder.
        (Iteration memory data, uint tau) = getSwapData(self, direction, amountIn, secondsPassed); // Declare and assign variables individual to save on gas spent on initializing 0 values.

        // Uses data.invariant, data.liquidity, and data.remainder to compute next input reserve.
        // Uses next input reserve to compute output reserve.
        (uint prevDep, uint nextDep) = computeSwapStep(self, data, direction, tau);

        // Checks to make sure next reserve decreases and computes the difference in WAD.
        if (nextDep > prevDep) revert SwapInputTooSmall();
        data.output += (prevDep - nextDep).mulWadDown(data.liquidity);

        // Scale down amounts from WAD.
        uint256 outputDec = direction ? self.pair.decimalsQuote : self.pair.decimalsAsset;
        data.output = data.output.scaleFromWadDown(outputDec);

        return data.output;
    }

    function getSwapData(
        HyperPool memory self,
        bool direction,
        uint amountIn,
        uint secondsPassed
    ) internal pure returns (Iteration memory, uint tau) {
        uint256 fee = self.controller != address(0) ? self.params.priorityFee : self.params.fee;

        Iteration memory data;
        (data.invariant, tau) = getNextInvariant({self: self, timeSinceUpdate: secondsPassed});
        (data.virtualX, data.virtualY) = self.getAmountsWad();
        data.remainder = amountIn.scaleToWad(direction ? self.pair.decimalsAsset : self.pair.decimalsQuote);
        data.liquidity = self.liquidity;
        data.feeAmount = (data.remainder * fee) / PERCENTAGE;

        return (data, tau);
    }

    function computeSwapStep(
        HyperPool memory self,
        Iteration memory data,
        bool direction,
        uint tau
    ) internal pure returns (uint prevDep, uint nextDep) {
        uint prevInd;
        uint nextInd;
        uint volatilityWad = convertPercentageToWad(self.params.volatility);

        // if sellAsset, ind = x && dep = y, else ind = y && dep = x
        if (direction) {
            (prevInd, prevDep) = (data.virtualX, data.virtualY);
        } else {
            (prevDep, prevInd) = (data.virtualX, data.virtualY);
        }

        nextInd = prevInd + (data.remainder - data.feeAmount).divWadDown(data.liquidity);

        // Compute the output of the swap by computing the difference between the dependent reserves.
        if (direction)
            nextDep = Invariant.getY({
                R_x: nextInd,
                stk: self.params.maxPrice,
                vol: volatilityWad,
                tau: tau,
                inv: data.invariant
            });
        else
            nextDep = Invariant.getX({
                R_y: nextInd,
                stk: self.params.maxPrice,
                vol: volatilityWad,
                tau: tau,
                inv: data.invariant
            });
    }

    function computeReservesWithPrice(
        HyperPool memory self,
        uint priceWad,
        int128 inv
    ) internal pure returns (uint256 R_y, uint256 R_x) {
        uint terminalPriceWad = self.params.maxPrice;
        uint volatilityFactorWad = convertPercentageToWad(self.params.volatility);
        uint timeRemainingSec = self.lastTau(); // uses lastTimestamp of self, is it set?
        R_x = getXWithPrice({prc: priceWad, stk: terminalPriceWad, vol: self.params.volatility, tau: timeRemainingSec});
        R_y = Invariant.getY({
            R_x: R_x,
            stk: terminalPriceWad,
            vol: volatilityFactorWad,
            tau: timeRemainingSec,
            inv: inv
        });
    }

    // ===== Raw Functions ===== //

    /**
     * @dev Used in `getAmounts` to compute the virtual amount of assets at the self's price.
     * @param prc WAD
     * @param stk WAD
     * @param vol percentage
     * @param tau seconds
     * @return R_x WAD
     * @custom:math R_x = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
     */
    function getXWithPrice(uint256 prc, uint256 stk, uint256 vol, uint256 tau) internal pure returns (uint256 R_x) {
        uint256 input = FixedPointMathLib.divWadDown(prc, stk); // todo: clarify + document whats going on here
        if (input != 0) {
            int256 ln = FixedPointMathLib.lnWad(int256(input));
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

    // ===== Swaps ===== //

    function getNextInvariant(
        HyperPool memory self,
        uint256 timeSinceUpdate
    ) internal pure returns (int128 invariant, uint256 tau) {
        tau = self.lastTau();

        tau -= timeSinceUpdate; // update to next curve at new time.
        (uint256 x, uint256 y) = self.getAmountsWad();

        invariant = int128(invariantOf({self: self, r1: x, r2: y, timeRemainingSec: tau})); // todo: fix casting
    }
}
