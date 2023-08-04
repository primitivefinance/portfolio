// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import "solstat/Gaussian.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "solmate/utils/SafeCastLib.sol";
import "../libraries/AssemblyLib.sol";
import "../libraries/BisectionLib.sol";
import { PortfolioPool } from "../libraries/PoolLib.sol";
import { Order } from "../libraries/SwapLib.sol";
import {
    SQRT_WAD,
    SECONDS_PER_YEAR,
    SECONDS_PER_DAY,
    DOUBLE_WAD
} from "../libraries/ConstantsLib.sol";

using FixedPointMathLib for uint256;
using FixedPointMathLib for uint128;
using FixedPointMathLib for int256;
using AssemblyLib for uint256;
using AssemblyLib for uint32;
using AssemblyLib for uint128;
using SafeCastLib for uint256;

using {
    approximatePriceGivenX,
    approximateReservesGivenPrice,
    approximateXGivenY,
    approximateYGivenX,
    computeStdDevSqrtTau,
    getReserveXBounds,
    getReserveYBounds,
    tradingFunction
} for NormalCurve global;

using {
    computeTau,
    encode,
    getMaturity,
    modify,
    transform
} for PortfolioConfig global;

/// @dev Enforces minimum positive invariant growth for swaps in pools using this strategy.
int256 constant INFINITY = type(int256).max;
int256 constant NEGATIVE_INFINITY = type(int256).min;
int256 constant MINIMUM_INVARIANT_DELTA = 1;
uint256 constant MIN_STRIKE_PRICE = 1; // 1 wei
uint256 constant MAX_STRIKE_PRICE = type(uint128).max;
uint256 constant MIN_VOLATILITY = 1; // 0.01%
uint256 constant MAX_VOLATILITY = 25_000; // 250%
uint256 constant MIN_DURATION = SECONDS_PER_DAY; // Miniumum duration is one day.
uint256 constant MAX_DURATION = SECONDS_PER_YEAR * 3; // Maximum duration is three years.
uint256 constant STRATEGY_ARGS_LENGTH = 32 * 5; // Not packed, 5 words total = 32 * 5 = 160 bytes.
uint256 constant BISECTION_EPSILON = 1;
uint256 constant BISECTION_MAX_ITER = 256;

error NormalStrategyLib_ConfigExists();
error NormalStrategyLib_NonExpiringPool();
error NormalStrategyLib_InvalidDuration();
error NormalStrategyLib_InvalidStrategyArgs();
error NormalStrategyLib_InvalidStrikePrice();
error NormalStrategyLib_InvalidVolatility();

/**
 * @notice
 * Arguments for computing the Normal curve.
 *
 * @dev
 * Used to configure the normal curve liquidity distrubtion strategy for a pool in Portfolio.
 * The parameters are based on the Black-Scholes model.
 */
struct NormalCurve {
    uint256 reserveXPerWad;
    uint256 reserveYPerWad;
    uint256 strikePriceWad;
    uint256 standardDeviationWad;
    uint256 timeRemainingSeconds;
    int256 invariant;
}

/// @dev Gets the exclusive bounds of the x reserves.
function getReserveXBounds(NormalCurve memory self)
    pure
    returns (uint256 upperBound, uint256 lowerBound)
{
    upperBound = WAD;
    lowerBound = 0;
}

/// @dev Gets the exclusive bounds of the y reserves.
function getReserveYBounds(NormalCurve memory self)
    pure
    returns (uint256 upperBound, uint256 lowerBound)
{
    upperBound = self.strikePriceWad;
    lowerBound = 0;
}

/// @dev Computes the commonly used term σ√τ using the correct units.
function computeStdDevSqrtTau(NormalCurve memory self) pure returns (uint256) {
    // Convert time remaining seconds to time remaining in years, in WAD units.
    uint256 timeRemainingYearsWad =
        self.timeRemainingSeconds.divWadDown(SECONDS_PER_YEAR);
    // √τ, √τ is scaled to WAD by multiplying by 1E9.
    uint256 sqrtTauWad = timeRemainingYearsWad.sqrt() * SQRT_WAD;
    // σ√τ
    uint256 stdDevSqrtTau = self.standardDeviationWad.mulWadDown(sqrtTauWad);
    return stdDevSqrtTau;
}

/**
 * @notice
 * Computes the invariant of the RMM-01 trading function.
 *
 * @dev For developers:
 * Re-arranges the trading function to remove the use of Φ (cdf).
 * By removing Φ and only using Φ⁻¹ (inverse cdf), the invariant is at least monotonic but non-strict.
 * While the Φ and Φ⁻¹ are theoretical inverses with strict monotonicity,
 * using these functions in practice requires approximations,
 * which has enough error to potentially lose monotonicity.
 *
 * @custom:math
 * ```
 * Where,
 *        Φ   = Gaussian.cdf
 *        Φ⁻¹ = Gaussian.ppf
 *        K   = strikePriceWad
 *        σ   = standardDeviationWad
 *        τ   = timeRemainingSeconds
 *        x   = reserveXPerWad
 *        y   = reserveYPerWad
 *
 * Original trading function
 * { 0    KΦ(Φ⁻¹(1-x) - σ√τ) >= y
 * { -∞   otherwise
 *
 * k = y - KΦ(Φ⁻¹(1-x) - σ√τ)
 * y = KΦ(Φ⁻¹(1-x) - σ√τ) + k
 * x = 1 - Φ(Φ⁻¹((y - k)/K) + σ√τ)
 *
 * Adjusted trading function
 * { 0    Φ⁻¹(1-x) - σ√τ >= Φ⁻¹(y/K)
 * { -∞   otherwise
 *
 * k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
 *  -> Φ⁻¹(y/K) = Φ⁻¹(1-x) - σ√τ + k
 *      -> y/K = Φ(Φ⁻¹(1-x) - σ√τ + k)
 *          -> y = KΦ(Φ⁻¹(1-x) - σ√τ + k)
 *  -> Φ⁻¹(1-x) = Φ⁻¹(y/K) + σ√τ - k
 *      -> 1-x = Φ(Φ⁻¹(y/K) + σ√τ - k)
 *          -> x = 1 - Φ(Φ⁻¹(y/K) + σ√τ - k)
 * ```
 *
 * # Special Boundary Properties
 *
 * The Φ⁻¹(y/K) term is denoted as `invariantTermY`
 * The Φ⁻¹(1-x) term is denoted as `invariantTermX`.
 *
 * As y approaches its upper bound of K, Φ⁻¹(y/K) approaches +∞.
 * As y approaches its lower bound of 0, Φ⁻¹(y/K) approaches -∞.
 * As x approaches its upper bound of 1, Φ⁻¹(1-x) approaches -∞.
 * As x approaches its lower bound of 0, Φ⁻¹(1-x) approaches +∞.
 *
 * Theoretically, if both x and y are at opposite bounds, they cancel eachother out.
 * Pragmatically, it's a lot messier because infinity does not exist.
 *
 * To handle this special property, the x and y reserves are checked for exceeding their bounds.
 * If they do exceed a bound, they are overwritten to be at the bound minus 1.
 * This prevents reverts that would happen if inputting values outside the theoretically and
 * practial domain of the `Gaussian.ppf` function, i.e. inputs of 0 or 1.
 *
 * By setting either or both the x and y to their bounds minus 1, each term will
 * return the `ppf`'s effective minimum and maximum output.
 *
 * The maximum output of Φ⁻¹(1E18 - 1) = 8710427241990476442 [~8.71e18]. In wad units.
 * The minimum output of Φ⁻¹(0 + 1)   = -8710427241990476442 [~-8.71e18]. In wad units.
 *
 * It's likely that the x and y reserves will reach opposite bounds,
 * in which case the invariant terms completely cancel out, returning `k = σ√τ`.
 *
 * In the case only one bound is reached, the invariant term for the bound will
 * be either the min or max output of the ppf. This will require the other term
 * to be very close to the min or max output of the ppf in order to cancel out.
 *
 * note Assumes maximum values are from valid pools created via this strategy in Portfolio.
 *
 * ## Example
 * The maximum value of σ√τ, where σ_max = 25_000 and τ_max = 94670859, is 4330127017500000000 [4.33e18].
 * The minimum value of σ√τ is 0.
 *
 * If all y tokens are removed, Φ⁻¹(0/K) -> Φ⁻¹(1e-18) = `invariantTermY` = -8710427241990476442.
 * For the swap to pass, the invariant needs to grow by at least 1.
 * Assuming we started at k = 0, we need to find the `invariantTermX` that solves this:
 *      -> 1 = -8710427241990476442 - invariantTermX + σ√τ.
 * We need the σ√τ term to help us, so we can set it to its maximum value. Now we have:
 *      -> 1 = -8710427241990476442 - invariantTermX + 4330127017500000000.
 *      -> invariantTermX <= -8710427241990476442 + 4330127017500000000 - 1.
 *      -> invariantTermX <= -4380300224490476443 [~-4.38e18].
 *      -> Φ⁻¹(1-x) <= -4.380300224490476443. (not in wad anymore...)
 *      -> 1 - x <= Φ(-4.380300224490476443).
 *      -> x >= 1 - Φ(-4.380300224490476443).
 *      -> x >= ~0.999999218479338350565045237958.
 * In conclusion, to take all y reserves, the x reserves must be __very close__ to its upper bound.
 *
 *
 * If all x tokens are removed, `invariantTermX` = 8710427241990476442.
 * For the swap to pass, the invariant needs to grow by at least 1.
 *     -> 1 = invariantTermY - 8710427241990476442 + σ√τ.
 * We can use the σ√τ to help us, so we can set it to its maximum value. Now we have:
 *    -> 1 = invariantTermY - 8710427241990476442 + 4330127017500000000.
 *    -> invariantTermY >= 8710427241990476442 - 4330127017500000000 + 1.
 *    -> invariantTermY >= 4380300224490476443 [~4.38e18].
 *    -> Φ⁻¹(y/K) >= 4.380300224490476443. (not in wad anymore...)
 *    -> y/K >= Φ(4.380300224490476443).
 *    -> y >= KΦ(4.380300224490476443).
 *    -> y >= K * ~0.999994074204725119575460221025.
 * However, since the `invariantTermX` will be subtracted from `invariantTermY` first, it will
 * revert the transaction with an arithemtic underflow unless the `invariantTermX` is equal
 * to it's maximum value of 8710427241990476442, which is when the y reserves are at their
 * upper bound of y = k.
 * In conclusion, to take all x reserves, the y reserves __must__ be at its upper bound.
 *
 * This overwrite of "infinity" effectively makes the trading function return an actual value
 * at the bounds, instead of reverting. This is important for pools which might have accrued
 * enough fees to push one of it's reserves over the bounds. Additionally, a maximum and minimum
 * price are effectively enforced at these boundaries.
 *
 *
 * note Adjusted trading function's invariant != original trading function's invariant.
 *
 * @return invariant        k; Signed invariant of the pool.
 */
function tradingFunction(NormalCurve memory self)
    pure
    returns (int256 invariant)
{
    // σ√τ
    uint256 stdDevSqrtTau = self.computeStdDevSqrtTau();

    // Get the bounds and check if one of the reserves has reached the bounds.
    (uint256 upperBoundX, uint256 lowerBoundX) = self.getReserveXBounds();

    // Overwrite the reserves to be as close to its bounds as possible, to avoid reverting.
    uint256 invariantTermXInput; // x - 1
    if (self.reserveXPerWad >= upperBoundX) {
        // As x -> 1E18, 1E18 - x -> 0, Φ⁻¹(0) = -∞, therefore bound invariantTermXInput to 1E18 - 1E18 + 1.
        invariantTermXInput = 1;
    } else if (self.reserveXPerWad <= lowerBoundX) {
        // As x -> 0, 1E18 - 0 -> 1E18, Φ⁻¹(1E18) = +∞, therefore bound invariantTermXInput to 1E18 - 0 - 1.
        invariantTermXInput = WAD - 1;
    } else {
        invariantTermXInput = WAD - self.reserveXPerWad;
    }

    uint256 invariantTermYInput =
        self.reserveYPerWad.divWadDown(self.strikePriceWad); // y/K -> [0,1]
    if (invariantTermYInput >= WAD) {
        // As y -> K, y/K -> 1E18, Φ⁻¹(1E18) = +∞, therefore bound invariantTermYInput to 1E18 - 1.
        invariantTermYInput = WAD - 1;
    } else if (invariantTermYInput <= 0) {
        // As y -> 0, y/K -> 0, Φ⁻¹(0) = -∞, therefore bound invariantTermYInput to 0 + 1.
        invariantTermYInput = 1;
    }

    // Φ⁻¹(1-x)
    int256 invariantTermX = Gaussian.ppf(int256(invariantTermXInput));
    // Φ⁻¹(y/K)
    int256 invariantTermY = Gaussian.ppf(int256(invariantTermYInput));

    // k = Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ
    invariant = invariantTermY - invariantTermX + int256(stdDevSqrtTau);
}

/**
 * @notice
 * Computes the x reserves given y reserves.
 *
 * @dev
 * Derived from the __adjusted__ trading function defined in `tradingFunction`.
 *
 * @custom:math
 * x = 1 - Φ(Φ⁻¹(y/K) + σ√τ - k)
 *
 */
function approximateXGivenY(NormalCurve memory self)
    pure
    returns (uint256 reserveXPerWad)
{
    (uint256 upperBoundX, uint256 lowerBoundX) = self.getReserveXBounds();
    (uint256 upperBoundY, uint256 lowerBoundY) = self.getReserveYBounds();
    // If y reserves has reached upper bound, x reserves is zero.
    if (self.reserveYPerWad >= upperBoundY) return lowerBoundX;
    // If y reserves has reached lower bound, x reserves is one.
    if (self.reserveYPerWad <= lowerBoundY) return upperBoundX;
    // σ√τ
    uint256 stdDevSqrtTau = self.computeStdDevSqrtTau();
    // y / K, rounded up to avoid truncating the result to 0, which is out of bounds.
    uint256 quotientWad = self.reserveYPerWad.divWadUp(self.strikePriceWad);
    // Φ⁻¹(y/K)
    int256 invariantTermY = Gaussian.ppf(int256(quotientWad));
    // Φ⁻¹(y/K) + σ√τ - k
    int256 independent = invariantTermY + int256(stdDevSqrtTau) - self.invariant;
    // x = 1 - Φ(Φ⁻¹(y/K) + σ√τ - k)
    reserveXPerWad = WAD - uint256(Gaussian.cdf(independent));
}

/**
 * @notice
 * Computes the y reserves given x reserves.
 *
 * @dev
 * Derived from the __adjusted__ trading function.
 *
 * @custom:math
 * y = KΦ(Φ⁻¹(1-x) - σ√τ + k)
 *
 */
function approximateYGivenX(NormalCurve memory self)
    pure
    returns (uint256 reserveYPerWad)
{
    (uint256 upperBoundX, uint256 lowerBoundX) = self.getReserveXBounds();
    (uint256 upperBoundY, uint256 lowerBoundY) = self.getReserveYBounds();
    // If x reserves has reached upper bound, y reserves is zero.
    if (self.reserveXPerWad >= upperBoundX) return lowerBoundY;
    // If x reserves has reached lower bound, y reserves is equal to the strike price.
    if (self.reserveXPerWad <= lowerBoundX) return upperBoundY;
    // σ√τ
    uint256 stdDevSqrtTau = self.computeStdDevSqrtTau();
    // 1 - x
    uint256 differenceWad = WAD - self.reserveXPerWad;
    // Φ⁻¹(1-x)
    int256 invariantTermX = Gaussian.ppf(int256(differenceWad));
    // Φ⁻¹(1-x) - σ√τ + k
    int256 independent = invariantTermX - int256(stdDevSqrtTau) + self.invariant;
    // y = KΦ(Φ⁻¹(1-x) - σ√τ + k)
    reserveYPerWad =
        uint256(Gaussian.cdf(independent)).mulWadDown(self.strikePriceWad);
}

/**
 * @notice
 * Gets approximated x reserves given a price.
 *
 * @dev
 * Derived from the original trading function using approximations that have small error.
 *
 * note
 * x = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ),
 * where S = price, K = strike, σ = volatility, τ = time remaining, Φ = cdf.
 *
 *
 * @param priceWad Price of y asset per x asset, in WAD units.
 * @return reserveXPerWad Approximated x reserves per WAD at `priceWad`.
 */
function approximateXGivenPrice(
    NormalCurve memory self,
    uint256 priceWad
) pure returns (uint256 reserveXPerWad) {
    uint256 quotient = priceWad.divWadDown(self.strikePriceWad);

    if (quotient != 0) {
        int256 logarithm = int256(quotient).lnWad();
        // Convert time remaining seconds to time remaining in years, in WAD units.
        uint256 timeRemainingYearsWad =
            self.timeRemainingSeconds.divWadDown(SECONDS_PER_YEAR);

        // σ²/2
        uint256 varianceHalved =
            self.standardDeviationWad * self.standardDeviationWad / DOUBLE_WAD;

        // σ√τ
        uint256 stdDevSqrtTau = self.computeStdDevSqrtTau();

        // ( ln(S/K) + (σ²/2)τ ) / σ√τ
        int256 cdfInput = logarithm * int256(WAD); // In units of 1E36.
        cdfInput += int256(varianceHalved) * int256(timeRemainingYearsWad); // Product is in units of 1E36.
        cdfInput = cdfInput / int256(stdDevSqrtTau); // Divides by units of 1E18 so quotient is in units of 1E18.

        // Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
        int256 result = Gaussian.cdf(int256(cdfInput));

        // 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
        reserveXPerWad = uint256(int256(WAD) - result);
    }
}

/**
 * @notice
 * Get approximated price of y per x, given x reserves.
 *
 * @dev
 * Derived from the original trading function using approximations that have error.
 *
 * note
 * price(R_x) = Ke^(Φ^-1(1 - R_x)σ√τ - 1/2σ^2τ)
 * As lim_x->0, S(x) = +infinity for all tau > 0 and vol > 0.
 * As lim_x->1, S(x) = 0 for all tau > 0 and vol > 0.
 * If tau or vol is zero, price is equal to strike.
 *
 *
 * @param self Normal curve arguments.
 * @param reserveXPerWad x reserves per WAD.
 * @return priceWad Approximated price of y per x, in WAD units.
 */
function approximatePriceGivenX(
    NormalCurve memory self,
    uint256 reserveXPerWad
) pure returns (uint256 priceWad) {
    (uint256 upperBoundX, uint256 lowerBoundX) = self.getReserveXBounds();

    if (reserveXPerWad >= upperBoundX) return self.strikePriceWad; // Terminal price limit.
    if (reserveXPerWad <= lowerBoundX) return type(uint128).max; // Upper price limit.

    uint256 timeRemainingYearsWad =
        self.timeRemainingSeconds.divWadDown(SECONDS_PER_YEAR);
    int256 stdDevSqrtTau = int256(self.computeStdDevSqrtTau());

    // Φ^-1(1 - R_x)
    int256 invariantTermX = Gaussian.ppf(int256(WAD - reserveXPerWad));
    // Φ^-1(1 - R_x)σ√τ
    int256 firstTerm = invariantTermX * int256(stdDevSqrtTau);
    // σ^2τ/2
    int256 secondTerm = int256(
        (
            self.standardDeviationWad * self.standardDeviationWad
                * timeRemainingYearsWad
        ) / DOUBLE_WAD
    );
    // e^(Φ^-1(1 - R_x)σ√τ - 1/2σ^2τ)
    int256 result = ((firstTerm - secondTerm) / int256(WAD)).expWad();
    // Ke^(Φ^-1(1 - R_x)σ√τ - 1/2σ^2τ)
    priceWad = uint256(result).mulWadDown(self.strikePriceWad);
}

/// @dev Approximates the x and y reserves given a price of y per x, in WAD units.
function approximateReservesGivenPrice(
    NormalCurve memory self,
    uint256 priceWad
) pure returns (uint256 reserveXPerWad, uint256 reserveYPerWad) {
    reserveXPerWad = approximateXGivenPrice(self, priceWad);
    self.reserveXPerWad = reserveXPerWad;
    reserveYPerWad = approximateYGivenX(self);
}

/**
 * @notice
 * Normal Strategy configuration.
 *
 * @dev
 * Configuration variables are immutable and packed into a single storage slot.
 *
 * @param strikePriceWad Strike price of the pool in WAD units, used as the terminal upper price limit.
 * @param volatilityBasisPoints Standard deviation used to compute the normal liquidity distribution, in basis points.
 * @param durationSeconds Duration of the pool in seconds.
 * @param creationTimestamp Timestamp of the pool's creation.
 * @param isPerpetual Whether the pool is perpetual or not. Non-perpetual pools cannot be swapped in after reaching maturity.
 */
struct PortfolioConfig {
    uint128 strikePriceWad;
    uint32 volatilityBasisPoints;
    uint32 durationSeconds;
    uint32 creationTimestamp;
    bool isPerpetual;
}

/**
 * @notice
 * Tranforms a configuration into it's respective trading function parameters,
 * converted to the required units.
 *
 * @dev Notes on the transformation:
 * - Invariant is set to 0. For most functions that utilize the curve parameters,
 * the invariant is not needed. However, for functions like the
 * `approximateYGivenX` and `approximateXGivenY` the invariant is needed.
 * Therefore, after the config has been transformed, it's invariant should be
 * set to the result of `tradingFunction` if using these functions.
 * - Time remaining is set to the config's duration. However,
 * the duration parameter used in this transformed `NormalCurve` should be
 * recomputed based on a fresher timestamp, like the current one. This is because
 * the duration stored in the config is the static duration that the pool started with.
 */
function transform(PortfolioConfig memory config)
    pure
    returns (NormalCurve memory)
{
    return NormalCurve({
        reserveXPerWad: 0,
        reserveYPerWad: 0,
        strikePriceWad: config.strikePriceWad,
        standardDeviationWad: config.volatilityBasisPoints.bpsToPercentWad(),
        timeRemainingSeconds: config.durationSeconds,
        invariant: 0
    });
}

/// @dev Transforms the normal strategy configuration into `strategyArgs` for `createPool`.
function encode(PortfolioConfig memory config) pure returns (bytes memory) {
    return abi.encode(config);
}

/**
 * @notice
 * Instantiates a PortfolioPool's configuration.
 *
 * @dev
 * Duration argument can be zero if `isPerpetual` is true.
 *
 * @param strikePriceWad Strike price of the pool in WAD units, used as the terminal upper price limit.
 * @param volatilityBasisPoints Standard deviation used to compute the normal liquidity distribution, in basis points.
 * @param durationSeconds Duration of the pool in seconds until swaps are no longer allowed.
 * @param isPerpetual Whether the pool is perpetual or not. Non-perpetual pools cannot be swapped in after reaching maturity.
 */
function modify(
    PortfolioConfig storage config,
    uint256 strikePriceWad,
    uint256 volatilityBasisPoints,
    uint256 durationSeconds,
    bool isPerpetual
) {
    if (config.creationTimestamp != 0) revert NormalStrategyLib_ConfigExists();

    if (isPerpetual) {
        config.isPerpetual = isPerpetual;
        config.durationSeconds = SECONDS_PER_YEAR.safeCastTo32();
    } else {
        if (!durationSeconds.isBetween(MIN_DURATION, MAX_DURATION)) {
            revert NormalStrategyLib_InvalidDuration();
        }
        config.durationSeconds = durationSeconds.safeCastTo32();
    }

    if (!volatilityBasisPoints.isBetween(MIN_VOLATILITY, MAX_VOLATILITY)) {
        revert NormalStrategyLib_InvalidVolatility();
    }
    config.volatilityBasisPoints = volatilityBasisPoints.safeCastTo32();

    if (!strikePriceWad.isBetween(MIN_STRIKE_PRICE, MAX_STRIKE_PRICE)) {
        revert NormalStrategyLib_InvalidStrikePrice();
    }
    config.strikePriceWad = strikePriceWad.safeCastTo128();

    config.creationTimestamp = uint32(block.timestamp);
}

/**
 * @notice
 * Get time remaining from timestamp.
 *
 * @dev
 * Computes the time remaining in seconds for the pool to reach maturity.
 *
 * @param timestamp Timestamp (seconds) to start from when computing the time remaining.
 */
function computeTau(
    PortfolioConfig memory config,
    uint256 timestamp
) pure returns (uint256) {
    if (config.isPerpetual) return SECONDS_PER_YEAR;

    uint256 endTimestamp = getMaturity(config);
    unchecked {
        // Cannot underflow as LHS is either equal to `timestamp` or greater.
        return AssemblyLib.max(timestamp, endTimestamp) - timestamp;
    }
}

/// @dev Get the timestamp of the pool's maturity.
function getMaturity(PortfolioConfig memory config) pure returns (uint32) {
    if (config.isPerpetual) revert NormalStrategyLib_NonExpiringPool();

    // Portfolio duration is limited such that this addition will never overflow uint32.
    unchecked {
        return config.creationTimestamp + config.durationSeconds;
    }
}

/**
 * @title
 * NormalStrategyLib.sol
 *
 * @notice
 * Customized trading curve which distributes liquidity over a normal curve.
 *
 * @dev
 * Implements a liquidity distribution strategy
 * of a normal curve with a configurable standard deviation.
 *
 * This creates an efficient liquidity management system
 * for distributing non-uniform liquidity over a price range, reducing gas costs.
 *
 * This is because concentrated automated market making systems
 * require discrete liquidity allocations, increasing the cost of
 * managing non-uniform liquidity distributions.
 *
 * This library extends functionality of the `PortfolioPool` type defined in `PoolLib`.
 *
 * @custom:example
 * ```
 * use NormalStrategyLib for PortfolioPool;
 * ```
 */
library NormalStrategyLib {
    // ----------------- //

    /// @dev Transforms encoded strategy arguments into the normal strategy configuration.
    function decode(bytes memory strategyArgs)
        internal
        pure
        returns (PortfolioConfig memory)
    {
        if (bytes(strategyArgs).length != STRATEGY_ARGS_LENGTH) {
            revert NormalStrategyLib_InvalidStrategyArgs();
        }

        return abi.decode(strategyArgs, (PortfolioConfig));
    }

    /**
     * @notice
     * Get the invariant of the pool, computed on its last swap.
     *
     * @dev
     * Use this to get the "after" swap invariant.
     *
     * Rounded down via rounded down virtual reserves per liquidity.
     * Uses the last swap's timestamp to compute the time remaining in the pool.
     * This invariant result is used in Portfolio's __critical__ invariant check,
     * as it's "after" swap invariant value.
     * A swap will revert if this result has not increased by at least min invariant delta,
     * when compared to the "before" swap invariant value, which is rounded up.
     *
     * @param self Pool's liquidity and reserves to use to compute the invariant.
     * @param config Parameters of the trading function to use in the trading function.
     * @return invariant The invariant of the pool, computed at the time of the last swap.
     */
    function getInvariantDown(
        PortfolioPool memory self,
        PortfolioConfig memory config
    ) internal view returns (int256) {
        // Due to rounding errors, the invariant is not strictly monotonic all the time.
        // This is because the invariant is computed using approximations, and the rounding
        // error could cause enough loss of information to keep the invariant unchanged,
        // even if the reserves change a small amount.
        // Be aware of rounding direction of reserves when computing invariant.
        uint256 reserveXPerWad = self.virtualX.divWadDown(self.liquidity);
        uint256 reserveYPerWad = self.virtualY.divWadDown(self.liquidity);

        // Uses `self.lastTimestamp` as the current timestamp to compute time remaining.
        NormalCurve memory curve = NormalCurve({
            reserveXPerWad: reserveXPerWad,
            reserveYPerWad: reserveYPerWad,
            strikePriceWad: config.strikePriceWad,
            standardDeviationWad: config.volatilityBasisPoints.bpsToPercentWad(),
            timeRemainingSeconds: computeLatestTau(self, config),
            invariant: 0
        });

        return tradingFunction(curve);
    }

    /**
     * @notice
     * Computes the invariant of the pool using a rounded up output reserve.
     *
     * @dev
     * Use this to get the "before" swap invariant.
     *
     * If either reserve increases, the invariant should also increase.
     * However, due to approximation errors and truncation, it's possible
     * the invariant does not change with a small increase in one of the reserves.
     * By rounding one of the reserves up, it has the effect of rounding the invariant up.
     * By rounding specifically the output reserve up, it rounds the output swap quantity down.
     * Rounding the invariant up is advantageous for Portfolio,
     * because the swapper must increase the invariant by the rounded up amount
     * and the minimum invariant delta.
     *
     * @param self Pool's liquidity and reserves to use to compute the invariant.
     * @param config Parameters of the trading function to use in the trading function.
     * @param sellAsset Whether the asset is the input reserve or the output reserve.
     * @param timestamp Expected timestamp of the swap. Used to compute time remaining in the pool.
     * @return invariant Invariant of the pool before a swap in the `sellAsset` direction takes place at the current time.
     */
    function getInvariantUp(
        PortfolioPool memory self,
        PortfolioConfig memory config,
        bool sellAsset,
        uint256 timestamp
    ) internal pure returns (int256) {
        // Computes the existing invariant of the pool using a
        // rounded up virtual output reserve per liquidity.
        // This is to make it advantageous for Portfolio
        // by overestimating the current invariant.
        // Since an invariant must increase in a swap to be valid,
        // this ensures the cost of a swap is rounded to the benefit of liquidity providers.
        uint256 reserveXPerWad = self.virtualX;
        uint256 reserveYPerWad = self.virtualY;
        if (sellAsset) {
            reserveXPerWad = reserveXPerWad.divWadDown(self.liquidity);
            reserveYPerWad = reserveYPerWad.divWadUp(self.liquidity);
        } else {
            reserveXPerWad = reserveXPerWad.divWadUp(self.liquidity);
            reserveYPerWad = reserveYPerWad.divWadDown(self.liquidity);
        }

        // Uses `timestamp` as the current timestamp to compute time remaining.
        NormalCurve memory curve = NormalCurve({
            reserveXPerWad: reserveXPerWad,
            reserveYPerWad: reserveYPerWad,
            strikePriceWad: config.strikePriceWad,
            standardDeviationWad: config.volatilityBasisPoints.bpsToPercentWad(),
            timeRemainingSeconds: config.computeTau(timestamp),
            invariant: 0
        });

        // This invariant uses the rounded up output reserves and start `timestamp`.
        return tradingFunction(curve);
    }

    /**
     * @notice
     * Get the invariant values used to verify a swap given a swap order.
     *
     * @dev
     * Assumes order input and output amounts are in WAD units.
     * This is used to verify that the invariant has increased since the last swap.
     * The reserves per liquidity are rounded in a specific direction to overestimate
     * this invariant result. This will require the invariant after the trade to strictly increase.
     * Enforcing that the invariant strictly increases is a __critical__ invariant condition of the protocol.
     *
     * @param timestamp Expected timestamp of the swap to be included in a block.
     */
    function getSwapInvariants(
        PortfolioPool memory self,
        PortfolioConfig memory config,
        Order memory order,
        uint256 timestamp,
        uint256 protocolFee,
        address swapper
    )
        internal
        view
        returns (
            uint256 adjustedIndependentReserve,
            int256 prevInvariant,
            int256 postInvariant
        )
    {
        // Computed using a rounded up output reserve per liquidity.
        prevInvariant = getInvariantUp(self, config, order.sellAsset, timestamp);

        // Compute the next invariant if the swap amounts are non zero.
        (uint256 reserveX, uint256 reserveY) = (self.virtualX, self.virtualY);

        uint256 feeBps = swapper == self.controller
            ? self.priorityFeeBasisPoints
            : self.feeBasisPoints;

        // Compute the adjusted reserves.
        (,, reserveX, reserveY) =
            order.computeSwapResult(reserveX, reserveY, feeBps, protocolFee);

        // Uses the `timestamp` as the current time for computing the time remaining in the pool.
        NormalCurve memory curve = NormalCurve({
            reserveXPerWad: 0,
            reserveYPerWad: 0,
            strikePriceWad: config.strikePriceWad,
            standardDeviationWad: config.volatilityBasisPoints.bpsToPercentWad(),
            timeRemainingSeconds: config.computeTau(timestamp),
            invariant: 0
        });

        // Rounded down reserves to round the invariant down.
        curve.reserveXPerWad = reserveX.divWadDown(self.liquidity);
        curve.reserveYPerWad = reserveY.divWadDown(self.liquidity);
        postInvariant = tradingFunction(curve);
        adjustedIndependentReserve =
            order.sellAsset ? curve.reserveXPerWad : curve.reserveYPerWad;
    }

    function approximateAmountOut(
        PortfolioPool memory self,
        PortfolioConfig memory config,
        Order memory order,
        uint256 timestamp,
        uint256 protocolFee,
        address swapper
    ) internal view returns (uint256 amountOutWad) {
        (uint256 independentReserve, int256 prevInv, int256 postInv) =
        getSwapInvariants(self, config, order, timestamp, protocolFee, swapper);

        NormalCurve memory curve = transform(config);
        curve.invariant = prevInv;
        curve.timeRemainingSeconds = config.computeTau(timestamp);

        uint256 adjustedDependentReserve;
        bool sellAsset = order.sellAsset;

        // Approximate the output reserve per liquidity using the math functions.
        if (sellAsset) {
            curve.reserveXPerWad = independentReserve;
            curve.reserveYPerWad = curve.approximateYGivenX();
            adjustedDependentReserve = curve.reserveYPerWad;
        } else {
            curve.reserveYPerWad = independentReserve;
            curve.reserveXPerWad = curve.approximateXGivenY();
            adjustedDependentReserve = curve.reserveXPerWad;
        }

        // If the approximated dependent reserve is 0,
        // then the output amount is the remaining dependent reserves.
        // Since Portfolio does not rely on the output of this function to verify swaps,
        // "tricking" the dependent reserve to become 0 will not result in a vulnerability.
        // It may result in a mispriced swap if this output is relied on or off chain.
        if (adjustedDependentReserve == 0) {
            return (sellAsset ? self.virtualY : self.virtualX);
        }

        uint256 lower = adjustedDependentReserve.mulDivDown(50, 100);
        uint256 upper = adjustedDependentReserve.mulDivUp(150, 100);
        // Output reserve is approximated with the derived math functions,
        // but to get it precise it needs a root finding algorithm.
        // Approximates the dependent reserve per liquidity by finding the root of the trading function.
        adjustedDependentReserve = bisection(
            abi.encode(curve),
            lower,
            upper,
            BISECTION_EPSILON, // Set to 1 to find the exact dependent reserve which increases invariant by 1.
            BISECTION_MAX_ITER, // Maximum amount of loops to run in bisection.
            sellAsset ? findRootForSwappingInX : findRootForSwappingInY
        );

        // Rounded up since the bisection could result in a fractional value, which is truncated.
        adjustedDependentReserve++;
        // Convert the adjustedDependentReserve per liquidity to adjustedDependentReserve for all liquidity.
        adjustedDependentReserve =
            adjustedDependentReserve.mulWadDown(self.liquidity);
        // Compute the difference between the previous dependent reserve and adjusted dependent reserve.
        amountOutWad = (sellAsset ? self.virtualY : self.virtualX)
            - adjustedDependentReserve;
    }

    function findRootForSwappingInX(
        bytes memory args,
        uint256 value
    ) internal pure returns (int256) {
        // Optimize the trading function such that it is strictly monotonically increasing.
        // Find the root: f(x) - (invariant + min invariant delta) = 0
        NormalCurve memory curve = abi.decode(args, (NormalCurve));
        curve.reserveYPerWad = value;
        return
            tradingFunction(curve) - (curve.invariant + MINIMUM_INVARIANT_DELTA);
    }

    function findRootForSwappingInY(
        bytes memory args,
        uint256 value
    ) internal pure returns (int256) {
        // Optimize the trading function such that it is strictly monotonically increasing.
        // Find the root: f(x) - (invariant + min invariant delta) = 0
        NormalCurve memory curve = abi.decode(args, (NormalCurve));
        curve.reserveXPerWad = value;
        return
            tradingFunction(curve) - (curve.invariant + MINIMUM_INVARIANT_DELTA);
    }

    // ----------------- //

    /// @dev Returns true if last timestamp is beyond maturity and its not a perpetual pool.
    function expired(
        PortfolioPool memory self,
        PortfolioConfig memory config
    ) internal view returns (bool) {
        if (config.isPerpetual) return false;

        return self.lastTimestamp >= getMaturity(config);
    }

    /**
     * @notice
     * Gets the latest updated time remaining in seconds for the pool since the last swap.
     *
     * @dev
     * If the pool is perpetual, the time remaining is permanently equal to one year.
     *
     */
    function computeLatestTau(
        PortfolioPool memory self,
        PortfolioConfig memory config
    ) internal view returns (uint256) {
        return computeTau(config, self.lastTimestamp);
    }

    // ----------------- //
}
