// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "solstat/Invariant.sol";
import {
    PortfolioPool,
    Iteration,
    SwapInputTooSmall,
    AssemblyLib,
    PERCENTAGE
} from "../libraries/PortfolioLib.sol";
import "./BisectionLib.sol";

uint256 constant WAD = 1e18;
uint256 constant SQRT_WAD = 1e9;
uint256 constant YEAR = 31556953 seconds;
uint256 constant BISECTION_EPSILON = 1;
int256 constant BISECTION_ERROR = 2;

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
     * @notice
     * Computes the invariant of the RMM-01 trading function.
     *
     * @dev
     * Re-arranges the trading function to remove the use of Φ (cdf).
     * By removing Φ and only using Φ⁻¹ (inverse cdf), the invariant is at least monotonic but non-strict.
     * While the Φ and Φ⁻¹ are theoretical inverses with strict monotonicity,
     * using these functions in practice requires approximations,
     * which has enough error to potentially lose monotonicity.
     *
     * @custom:math
     * ```
     * Original trading function
     * { 0    KΦ(Φ⁻¹(1-x) - σ√τ) >= y
     * { -∞   otherwise
     *
     * k = y - KΦ(Φ⁻¹(1-x) - σ√τ)
     * y = KΦ(Φ⁻¹(1-x) - σ√τ) - k
     * x = 1 - Φ(Φ⁻¹((y + k)/K) + σ√τ)
     *
     * Adjusted trading function
     * { 0    Φ⁻¹(1-x) - σ√τ >= Φ⁻¹(y/K)
     * { -∞   otherwise
     *
     * k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
     * y = KΦ(Φ⁻¹(1-x) - σ√τ + k)
     * x = 1 - Φ(Φ⁻¹(y/K) + σ√τ - k)
     * ```
     *
     * @param reserveXPerWad    x; Quantity of `asset` reserves scaled to WAD units per WAD of liquidity.
     * @param reserveYPerWad    y; Quantity of `quote` reserves scaled to WAD units per WAD of liquidity.
     * @param strikePriceWad    K; Strike price of the pool, scaled to WAD units.
     * @param volatilityWad     σ; Volatility of the pool, scaled to WAD units.
     * @param timeRemainingSec  τ; Amount of time in seconds until the pool is matured.
     * @return invariant        k; Signed invariant of the pool.
     */
    function tradingFunction(
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec
    ) internal pure returns (int256 invariant) {
        uint256 yearsWad = timeRemainingSec.divWadDown(uint256(YEAR));
        // √τ, √τ is scaled to WAD by multiplying by 1E9.
        uint256 sqrtTauWad = yearsWad.sqrt() * SQRT_WAD;
        // σ√τ
        uint256 volSqrtYearsWad = volatilityWad.mulWadDown(sqrtTauWad);
        // y / K
        uint256 quotientWad = reserveYPerWad.divWadUp(strikePriceWad); // todo: review rounding direction. Avoids scenarios division truncates to 0.
        // Φ⁻¹(y/K)
        int256 inverseCdfQuotient = Gaussian.ppf(int256(quotientWad));
        // 1 - x
        uint256 differenceWad = WAD - reserveXPerWad;
        // Φ⁻¹(1-x)
        int256 inverseCdfDifference = Gaussian.ppf(int256(differenceWad));
        // k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
        invariant =
            inverseCdfQuotient - inverseCdfDifference + int256(volSqrtYearsWad);
    }

    /**
     * @notice
     * Computes the x reserves given y reserves.
     *
     * @dev
     * Uses the adjusted trading function.
     *
     * @custom:math
     * x = 1 - Φ(Φ⁻¹(y/K) + σ√τ - k)
     *
     * @param reserveYPerWad    y; Quantity of `quote` reserves scaled to WAD units per WAD of liquidity.
     * @param strikePriceWad    K; Strike price of the pool, scaled to WAD units.
     * @param volatilityWad     σ; Volatility of the pool, scaled to WAD units.
     * @param timeRemainingSec  τ; Amount of time in seconds until the pool is matured.
     * @param invariant         k; Signed invariant of the pool.
     */
    function getReserveXPerWad(
        uint256 reserveYPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec,
        int256 invariant
    ) internal pure returns (uint256 reserveXPerWad) {
        uint256 yearsWad = timeRemainingSec.divWadDown(uint256(YEAR));
        // √τ, √τ is scaled to WAD by multiplying by 1E9.
        uint256 sqrtTauWad = yearsWad.sqrt() * SQRT_WAD;
        // σ√τ
        uint256 volSqrtYearsWad = volatilityWad.mulWadDown(sqrtTauWad);
        // y / K
        uint256 quotientWad = reserveYPerWad.divWadDown(strikePriceWad);
        // Φ⁻¹(y/K)
        int256 inverseCdfQuotient = Gaussian.ppf(int256(quotientWad));
        // Φ⁻¹(y/K) + σ√τ - k
        int256 independent =
            inverseCdfQuotient + int256(volSqrtYearsWad) - invariant;
        // x = 1 - Φ(Φ⁻¹(y/K) + σ√τ - k)
        reserveXPerWad = WAD - uint256(Gaussian.cdf(independent));
    }

    /**
     * @notice
     * Computes the y reserves given x reserves.
     *
     * @dev
     * Uses the adjusted trading function.
     *
     * @custom:math
     * y = KΦ(Φ⁻¹(1-x) - σ√τ + k)
     *
     * @param reserveXPerWad    x; Quantity of `asset` reserves scaled to WAD units per WAD of liquidity.
     * @param strikePriceWad    K; Strike price of the pool, scaled to WAD units.
     * @param volatilityWad     σ; Volatility of the pool, scaled to WAD units.
     * @param timeRemainingSec  τ; Amount of time in seconds until the pool is matured.
     * @param invariant         k; Signed invariant of the pool. Truncated.
     */
    function getReserveYPerWad(
        uint256 reserveXPerWad,
        uint256 strikePriceWad,
        uint256 volatilityWad,
        uint256 timeRemainingSec,
        int256 invariant
    ) internal pure returns (uint256 reserveYPerWad) {
        uint256 yearsWad = timeRemainingSec.divWadDown(uint256(YEAR));
        // √τ, √τ is scaled to WAD by multiplying by 1E9.
        uint256 sqrtTauWad = yearsWad.sqrt() * SQRT_WAD;
        // σ√τ
        uint256 volSqrtYearsWad = volatilityWad.mulWadDown(sqrtTauWad);
        // 1 - x
        uint256 differenceWad = WAD - reserveXPerWad;
        // Φ⁻¹(1-x)
        int256 inverseCdfDifference = Gaussian.ppf(int256(differenceWad));
        // Φ⁻¹(1-x) - σ√τ + k
        int256 independent =
            inverseCdfDifference - int256(volSqrtYearsWad) + invariant;
        // y = KΦ(Φ⁻¹(1-x) - σ√τ + k)
        reserveYPerWad =
            uint256(Gaussian.cdf(independent)).mulWadDown(strikePriceWad);
    }

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
        uint256 volatilityWad = convertPercentageToWad(self.params.volatility);
        return tradingFunction({
            reserveXPerWad: R_x,
            reserveYPerWad: R_y,
            strikePriceWad: self.params.strikePrice,
            volatilityWad: volatilityWad,
            timeRemainingSec: timeRemainingSec
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
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWad = amountIn.scaleToWad(
            sellAsset ? self.pair.decimalsAsset : self.pair.decimalsQuote
        );

        // Sets data.invariant, data.liquidity, data.feeAmount, and data.input.
        (Iteration memory data, uint256 tau) =
            getSwapData(self, sellAsset, amountInWad, timestamp, swapper);

        // Uses data.invariant, data.liquidity, and data.input to compute next input reserve.
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
     * @notice Fetches the data needed to simulate a swap to compute the output of tokens.
     * @dev Does not consider protocol fees, therefore feeAmount could be overestimated since protocol fees are not subtracted.
     */
    function getSwapData(
        PortfolioPool memory self,
        bool sellAsset,
        uint256 amountInWad,
        uint256 timestamp,
        address swapper
    ) internal pure returns (Iteration memory iteration, uint256 tau) {
        tau = self.computeTau(timestamp);

        iteration.input = amountInWad;
        iteration.liquidity = self.liquidity;
        (iteration.virtualX, iteration.virtualY) = self.getVirtualReservesWad();

        // Computes the existing invariant of the pool with
        // rounded up virtual reserves for the output reserve of a trade.
        // This is to make it advantageous for Portfolio
        // by overestimating the current invariant.
        // Since an invariant must increase in a swap to be a valid trade,
        // this ensures the cost of a swap is rounded to the benefit of liquidity providers.
        uint256 reserveXPerLiquidity;
        uint256 reserveYPerLiquidity;
        if (sellAsset) {
            reserveXPerLiquidity =
                iteration.virtualX.divWadDown(iteration.liquidity);
            reserveYPerLiquidity =
                iteration.virtualY.divWadUp(iteration.liquidity);
        } else {
            reserveXPerLiquidity =
                iteration.virtualX.divWadUp(iteration.liquidity);
            reserveYPerLiquidity =
                iteration.virtualY.divWadDown(iteration.liquidity);
        }

        iteration.prevInvariant = invariantOf({
            self: self,
            R_x: reserveXPerLiquidity,
            R_y: reserveYPerLiquidity,
            timeRemainingSec: tau
        });

        uint256 feePercentage = self.controller == swapper
            ? self.params.priorityFee
            : self.params.fee;

        iteration.feeAmount = (iteration.input * feePercentage) / PERCENTAGE;
        if (iteration.feeAmount == 0) iteration.feeAmount = 1;
    }

    /**
     * @dev Simulates a swap and returns the next dependent reserve, which can be used to compute the output.
     */
    function computeSwapStep(
        PortfolioPool memory self,
        Iteration memory data,
        bool sellAsset,
        uint256 tau
    ) internal pure returns (uint256 prevDep, uint256 nextDep) {
        // Independent reserves are being adjusted with the input amount.
        // Dependent reserves are being adjusted based on the output amount.
        uint256 adjustedIndependentReserve;
        uint256 adjustedDependentReserve;
        if (sellAsset) {
            (adjustedIndependentReserve, prevDep) =
                (data.virtualX, data.virtualY);
        } else {
            (prevDep, adjustedIndependentReserve) =
                (data.virtualX, data.virtualY);
        }

        // 1. Compute the increased independent pool reserve by adding the input amount and subtracting the fee.
        // 2. Compute the independent pool reserve per 1E18 liquidity.
        adjustedIndependentReserve += (data.input - data.feeAmount);
        adjustedIndependentReserve =
            adjustedIndependentReserve.divWadDown(data.liquidity);

        // 3. Compute the approximated dependent pool reserve using the adjusted independent reserve per 1E18 liquidity.
        uint256 volatilityWad = convertPercentageToWad(self.params.volatility);
        if (sellAsset) {
            adjustedDependentReserve = getReserveYPerWad({
                reserveXPerWad: adjustedIndependentReserve,
                strikePriceWad: self.params.strikePrice,
                volatilityWad: volatilityWad,
                timeRemainingSec: tau,
                invariant: data.prevInvariant
            });
        } else {
            adjustedDependentReserve = getReserveXPerWad({
                reserveYPerWad: adjustedIndependentReserve,
                strikePriceWad: self.params.strikePrice,
                volatilityWad: volatilityWad,
                timeRemainingSec: tau,
                invariant: data.prevInvariant
            });
        }

        // Since the dependent reserve is approximated, a bisection method is used to find the precise dependent reserve.
        Bisection memory args;
        args.optimizeQuoteReserve = sellAsset;
        args.terminalPriceWad = self.params.strikePrice;
        args.volatilityWad = volatilityWad;
        args.tauSeconds = tau;
        args.reserveWadPerLiquidity = adjustedIndependentReserve;
        args.prevInvariant = data.prevInvariant;
        // Compute the upper and lower bounds to start the bisection method.
        uint256 lower = adjustedDependentReserve.mulDivDown(98, 100);
        uint256 upper = adjustedDependentReserve.mulDivUp(102, 100);
        // Each reserve has a minimum lower bound of 0.
        // Each reserve has its own upper bound per 1E18 liquidity.
        // The quote reserve is bounded by the max price.
        // The asset reserve is bounded by 1E18.
        uint256 maximum = sellAsset ? args.terminalPriceWad : 1 ether;
        upper = upper > maximum ? maximum : upper;
        // Use bisection to compute the precise dependent reserve which sets the invariant to 0.
        adjustedDependentReserve = bisection(
            args,
            lower,
            upper,
            BISECTION_EPSILON, // Set to 0 to find the exact dependent reserve which sets the invariant to 0.
            256, // Maximum amount of loops to run in bisection.
            optimizeDependentReserve
        );
        // Increase dependent reserve per liquidity by 1 to account for precision loss.
        adjustedDependentReserve++;
        // Return the total adjusted dependent pool reserve for all the liquidity.
        nextDep = adjustedDependentReserve.mulWadDown(data.liquidity);
    }

    /**
     * @dev Optimized function used in the bisection method to compute the precise dependent reserve.
     * @param optimized Dependent reserve in WAD units per 1E18 liquidity.
     */
    function optimizeDependentReserve(
        Bisection memory args,
        uint256 optimized
    ) internal pure returns (int256) {
        return tradingFunction({
            reserveXPerWad: args.optimizeQuoteReserve
                ? args.reserveWadPerLiquidity
                : optimized,
            reserveYPerWad: args.optimizeQuoteReserve
                ? optimized
                : args.reserveWadPerLiquidity,
            strikePriceWad: args.terminalPriceWad,
            volatilityWad: args.volatilityWad,
            timeRemainingSec: args.tauSeconds
        }) - (args.prevInvariant + BISECTION_ERROR);
    }

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
        uint256 terminalPriceWad = self.params.strikePrice;
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
