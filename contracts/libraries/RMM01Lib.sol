// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "solstat/Invariant.sol";
import {
    PortfolioPool,
    Iteration,
    SwapInputTooSmall,
    AssemblyLib,
    PERCENTAGE
} from "../PortfolioLib.sol";
import "./BisectionLib.sol";

uint256 constant SQRT_WAD = 1e9;
uint256 constant WAD = 1 ether;
uint256 constant YEAR = 31556953 seconds;
uint256 constant BISECTION_EPSILON = 1;

/**
 * @title   RMM01Lib
 * @author  Primitive™
 * @notice  Implements math for RMM-01 objective.
 */
library RMM01Lib {
    using AssemblyLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    error UndefinedPrice();
    error OverflowWad(int256 wad);

    /**
     * @dev Computes the invariant of the RMM-01 trading function.
     * @param self Pool instance.
     * @param R_x Quantity of `asset` reserves scaled to WAD units per WAD of liquidity.
     * @param R_y Quantity of `quote` reserves scaled to WAD units per WAD of liquidity.
     * @param timeRemainingSec Amount of time in seconds until the `self` PortfolioPool is matured.
     * @return invariantWad Signed invariant denominated in `quote` tokens, scaled to WAD units.
     * @custom:math k = y - KΦ(Φ⁻¹(1-x) - σ√τ)
     * @custom:dependency https://github.com/primitivefinance/solstat
     */
    function invariantOf(
        PortfolioPool memory self,
        uint256 R_x,
        uint256 R_y,
        uint256 timeRemainingSec
    ) internal pure returns (int256 invariantWad) {
        return Invariant.invariant({
            R_y: R_y,
            R_x: R_x,
            stk: self.params.maxPrice,
            vol: convertPercentageToWad(self.params.volatility),
            tau: timeRemainingSec
        });
    }

    /**
     * @dev Approximation of amount out of tokens given a swap `amountIn`.
     * It is not exactly precise to the optimal amount.
     * @param amountIn Quantity of tokens in, units are native token decimals.
     * @param timestamp Timestamp to use to compute the remaining duration in the Portfolio.
     * @custom:error Maximum absolute error of 1e-6.
     */
    function getAmountOut(
        PortfolioPool memory self,
        bool sellAsset,
        uint256 amountIn,
        uint256 timestamp,
        address swapper
    ) internal view returns (uint256 amountOut) {
        // Sets data.invariant, data.liquidity, and data.remainder.
        (Iteration memory data, uint256 tau) =
            getSwapData(self, sellAsset, amountIn, timestamp, swapper); // Declare and assign variables individual to save on gas spent on initializing 0 values.

        // Uses data.invariant, data.liquidity, and data.remainder to compute next input reserve.
        // Uses next input reserve to compute output reserve.
        (uint256 prevDepTotalWad, uint256 nextDepTotalWad) =
            computeSwapStep(self, data, sellAsset, tau);

        // Checks to make sure next reserve decreases and computes the difference in WAD.
        if (nextDepTotalWad > prevDepTotalWad) revert SwapInputTooSmall();
        data.output += prevDepTotalWad - nextDepTotalWad;

        // Scale down amounts from WAD.
        uint256 outputDec =
            sellAsset ? self.pair.decimalsQuote : self.pair.decimalsAsset;
        amountOut = data.output.scaleFromWadDown(outputDec);
    }

    /**
     * @dev Fetches the data needed to simulate a swap to compute the output of tokens.
     */
    function getSwapData(
        PortfolioPool memory self,
        bool sellAsset,
        uint256 amountIn,
        uint256 timestamp,
        address swapper
    ) internal pure returns (Iteration memory, uint256 tau) {
        Iteration memory data;
        uint256 fee = self.controller == swapper
            ? self.params.priorityFee
            : self.params.fee;

        data.liquidity = self.liquidity;
        (data.virtualX, data.virtualY) = self.getVirtualReservesWad();
        tau = self.computeTau(timestamp);

        uint256 R_x;
        uint256 R_y;
        if (sellAsset) {
            R_x = data.virtualX.divWadDown(data.liquidity);
            R_y = data.virtualY.divWadUp(data.liquidity);
        } else {
            R_x = data.virtualX.divWadUp(data.liquidity);
            R_y = data.virtualY.divWadDown(data.liquidity);
        }

        data.prevInvariant =
            invariantOf({self: self, R_x: R_x, R_y: R_y, timeRemainingSec: tau});
        data.remainder = amountIn.scaleToWad(
            sellAsset ? self.pair.decimalsAsset : self.pair.decimalsQuote
        );
        data.feeAmount = (data.remainder * fee) / PERCENTAGE;

        return (data, tau);
    }

    /**
     * @dev Simulates a swap and computes the output tokens given an amount of tokens in.
     */
    function computeSwapStep(
        PortfolioPool memory self,
        Iteration memory data,
        bool sellAsset,
        uint256 tau
    ) internal view returns (uint256 prevDep, uint256 nextDep) {
        uint256 prevInd;
        uint256 nextIndWadPerLiquidity;
        uint256 nextDepWadPerLiquidity;
        uint256 volatilityWad = convertPercentageToWad(self.params.volatility);

        // If sellAsset, ind = x && dep = y, else ind = y && dep = x
        // These are the total reserves of tokens in the pool scaled to WAD decimals.
        if (sellAsset) {
            (prevInd, prevDep) = (data.virtualX, data.virtualY);
        } else {
            (prevDep, prevInd) = (data.virtualX, data.virtualY);
        }

        uint256 deltaInLessFee = data.remainder - data.feeAmount;
        nextIndWadPerLiquidity = prevInd + deltaInLessFee;
        nextIndWadPerLiquidity =
            nextIndWadPerLiquidity.divWadDown(data.liquidity);

        // Compute the output of the swap by computing the difference between the dependent reserves.
        // Uses the next independent reserve in WAD units per 1 WAD of liquidity.
        if (sellAsset) {
            nextDepWadPerLiquidity = Invariant.getY({
                R_x: nextIndWadPerLiquidity,
                stk: self.params.maxPrice,
                vol: volatilityWad,
                tau: tau,
                inv: data.prevInvariant
            });
        } else {
            nextDepWadPerLiquidity = Invariant.getX({
                R_y: nextIndWadPerLiquidity,
                stk: self.params.maxPrice,
                vol: volatilityWad,
                tau: tau,
                inv: data.prevInvariant
            });

            nextDep = uint256(
                bisectionQuote(
                    args,
                    int256(nextDep * 9999 / 10000),
                    int256(nextDep * 10001 / 10000),
                    1,
                    256,
                    optimizeQuote
                )
            );
        }

        Bisection memory args;
        args.optimizeQuoteReserve = sellAsset;
        args.terminalPriceWad = self.params.maxPrice;
        args.volatilityWad = volatilityWad;
        args.tauSeconds = tau;
        args.reserveWadPerLiquidity = nextInd;

        uint256 lower = nextDep.mulDivDown(9999, 10000);
        uint256 upper = nextDep.mulDivUp(10001, 10000);
        // Each reserve has a minimum lower bound of 0.
        // Each reserve has its own upper bound per liquidity unit.
        // The quote reserve is bounded by the max price.
        // The asset reserve is bounded by 1E18.
        uint256 maximum = sellAsset ? args.terminalPriceWad : 1 ether;
        upper = upper > maximum ? maximum : upper;

        // Using the approximated next dependent reserve,
        // optimize around 0.01% error to find the precise dependent reserve.
        nextDep = bisection(
            args,
            lower,
            upper,
            BISECTION_EPSILON,
            256, // todo: potentially expose the max iteration parameter to the Portfolio `getAmountOut` function.
            optimizeDependentReserve
        );

        // Round up the next dependent reserve.
        // Ouput amount is previous - next dependent reserve,
        // so if next is rounded up, output is consequentially rounded down.
        if (nextDep != 0) {
            nextDep++;
        }
    }

    function optimizeDependentReserve(
        Bisection memory args,
        uint256 optimized
    ) internal pure returns (int256) {
        return Invariant.invariant({
            R_y: args.optimizeQuoteReserve ? optimized : args.reserveWadPerLiquidity,
            R_x: args.optimizeQuoteReserve ? args.reserveWadPerLiquidity : optimized,
            stk: args.terminalPriceWad,
            vol: args.volatilityWad,
            tau: args.tauSeconds
        });
    }

    function optimizeQuote(
        Bisection memory args,
        int256 optimized
    ) internal view returns (int256) {
        uint256 y = args.independentReserve;
        uint256 x = uint256(optimized);
        uint256 stk = args.terminalPriceWad;
        uint256 vol = args.volatilityFactorWad;
        uint256 tau = args.timeRemainingSec;

        int256 invariant =
            Invariant.invariant({R_y: y, R_x: x, stk: stk, vol: vol, tau: tau});
        logger.log("Logging x: %s", x);
        logger.log("Logging y: %s", y);
        logger.log("Logging int256 invariant: %s");
        logger.logInt(invariant);
        return invariant;
    }

    /* function optimizeQuoteOut(Bisection memory args)
        internal
        pure
        returns (uint256)
    {
        uint256 y = args.dependentReserve;
        uint256 x = args.independentReserve;
        uint256 stk = args.terminalPriceWad;
        uint256 vol = args.volatilityFactorWad;
        uint256 tau = args.timeRemainingSec;
        uint256 epsilon = 1e6;

        uint256 minimum = epsilon > y ? 0 : y - epsilon;
        uint256 maximum = y + epsilon > stk ? stk : y + epsilon;

        int256 invariant =
            Invariant.invariant({R_y: y, R_x: x, stk: stk, vol: vol, tau: tau});

        int256 minInvariant = Invariant.invariant({
            R_y: minimum,
            R_x: x,
            stk: stk,
            vol: vol,
            tau: tau
        });

        int256 maxInvariant = Invariant.invariant({
            R_y: maximum,
            R_x: x,
            stk: stk,
            vol: vol,
            tau: tau
        });

        int256 root;
        uint256 difference = maximum - minimum;
        uint256 iterations;
        do {
            root = int256((minimum + maximum) / 2);

            int256 invariantRoot = Invariant.invariant({
                R_y: y + root > stk ? stk : y + root,
                R_x: x,
                stk: stk,
                vol: vol,
                tau: tau
            });

            if (invariantRoot == 0) break;

            minInvariant = Invariant.invariant({
                R_y: y + minimum > stk ? stk : y + minimum,
                R_x: x,
                stk: stk,
                vol: vol,
                tau: tau
            });

            int256 product = maxInvariant * minInvariant;
            if (product < 0) {
                minimum = root;
            } else {
                maximum = root;
            }

            unchecked {
                iterations++;
            }
        } while (difference >= epsilon && iterations < 256);
    } */

    /**
     * @dev Computes the amount of `asset` and `quote` tokens scaled to WAD units to track per WAD units of liquidity.
     * @param priceWad Price of `asset` token scaled to WAD units.
     * @param invariantWad Current invariant of the pool in its native WAD units.
     */
    function computeReservesWithPrice(
        PortfolioPool memory self,
        uint256 priceWad,
        int128 invariantWad
    ) internal pure returns (uint256 R_x, uint256 R_y) {
        uint256 terminalPriceWad = self.params.maxPrice;
        uint256 volatilityFactorWad =
            convertPercentageToWad(self.params.volatility);
        uint256 timeRemainingSec = self.lastTau(); // uses self.lastTimestamp, is it set?
        R_x = getXWithPrice({
            prc: priceWad,
            stk: terminalPriceWad,
            vol: self.params.volatility,
            tau: timeRemainingSec
        });
        R_y = Invariant.getY({
            R_x: R_x,
            stk: terminalPriceWad,
            vol: volatilityFactorWad,
            tau: timeRemainingSec,
            inv: invariantWad
        });
    }

    // ===== Raw Functions ===== //

    /**
     * @dev Used in `getVirtualReservesWad` to compute the virtual amount of assets at the self's price.
     * @param prc WAD
     * @param stk WAD
     * @param vol percentage
     * @param tau seconds
     * @return R_x WAD
     * @custom:math R_x = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
     */
    function getXWithPrice(
        uint256 prc,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 R_x) {
        uint256 input = FixedPointMathLib.divWadDown(prc, stk);
        if (input != 0) {
            int256 ln = FixedPointMathLib.lnWad(int256(input));
            uint256 tauYears = convertSecondsToWadYears(tau);

            uint256 sigmaWad = convertPercentageToWad(vol);
            uint256 doubleSigma = (sigmaWad * sigmaWad) / uint256(Gaussian.TWO);
            uint256 halfSigmaTau = doubleSigma * tauYears;
            uint256 sqrtTauSigma =
                (tauYears.sqrt() * SQRT_WAD).mulWadDown(sigmaWad);

            int256 lnOverVol = (ln * Gaussian.ONE + int256(halfSigmaTau))
                / int256(sqrtTauSigma);
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
    function getPriceWithX(
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 prc) {
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

    function convertSecondsToWadYears(uint256 sec)
        internal
        pure
        returns (uint256 yrsWad)
    {
        assembly {
            yrsWad := div(mul(sec, WAD), YEAR)
        }
    }

    function convertPercentageToWad(uint256 pct)
        internal
        pure
        returns (uint256 pctWad)
    {
        assembly {
            pctWad := div(mul(pct, WAD), PERCENTAGE)
        }
    }
}
