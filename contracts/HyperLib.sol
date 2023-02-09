// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/**

  -------------

  Comprehensive library with all structs, errors,
  constants, and utils for Hyper.

  -------------

  Primitive™

 */

import "solmate/utils/SafeCastLib.sol";
import "./libraries/Price.sol";
import "./Assembly.sol" as Assembly;
import "./Enigma.sol" as Enigma;
import "./OS.sol" as OS;

using Price for Price.RMM;
using SafeCastLib for uint;
using FixedPointMathLib for uint;
using FixedPointMathLib for int;
using {Assembly.scaleFromWadDown, Assembly.scaleFromWadUp, Assembly.scaleToWad} for uint;
using {checkParameters, maturity, validateParameters} for HyperCurve global;
using {changePositionLiquidity, syncPositionFees, getTimeSinceChanged} for HyperPosition global;
using {
    changePoolLiquidity,
    changePoolParameters,
    exists,
    getAmounts,
    getAmountOut,
    getAmountsWad,
    getLiquidityDeltas,
    getMaxLiquidity,
    getMaxSwapAssetInWad,
    getMaxSwapQuoteInWad,
    getNextInvariant,
    getRMM,
    getVirtualReserves,
    isMutable,
    syncPoolTimestamp,
    lastTau,
    computeTau
} for HyperPool global;

uint256 constant MIN_MAX_PRICE = 1;
uint256 constant MAX_MAX_PRICE = type(uint128).max;
uint256 constant BUFFER = 300 seconds;
uint256 constant MIN_FEE = 1; // 0.01%
uint256 constant MAX_FEE = 1000; // 10%
uint256 constant MIN_VOLATILITY = 100; // 1%
uint256 constant MAX_VOLATILITY = 25_000; // 250%
uint256 constant MIN_DURATION = 1; // days, but without units
uint256 constant MAX_DURATION = 500; // days, but without units
uint256 constant JUST_IN_TIME_MAX = 600 seconds;
uint256 constant JUST_IN_TIME_LIQUIDITY_POLICY = 4 seconds;

// todo: add selectors for debugging?
error DrawBalance();
error InsufficientPosition(uint64 poolId);
error InvalidDecimals(uint8 decimals);
error InvalidDuration(uint16);
error InvalidFee(uint16 fee);
error InvalidInstruction();
error InvalidInvariant(int256 prev, int256 next);
error InvalidJit(uint16);
error InvalidReentrancy();
error InvalidReward();
error InvalidSettlement();
error InvalidStrike(uint128 strike);
error InvalidTick(int24);
error InvalidTransfer();
error InvalidVolatility(uint24 sigma); // todo: fix, use uint16 type.
error JitLiquidity(uint256 distance);
error MaxFee(uint16 fee);
error NotController();
error NonExistentPool(uint64 poolId);
error NonExistentPosition(address owner, uint64 poolId);
error PairExists(uint24 pairId);
error PerLiquidityError(uint256 deltaAsset);
error PoolExists();
error PoolExpired();
error PositionZeroLiquidity(uint96 positionId);
error SameTokenError();
error SwapInputTooSmall();
error SwapLimitReached();
error ZeroAmounts();
error ZeroInput();
error ZeroLiquidity();
error ZeroOutput();
error ZeroPrice();
error ZeroValue();

struct HyperPair {
    address tokenAsset;
    uint8 decimalsAsset;
    address tokenQuote;
    uint8 decimalsQuote;
}

struct HyperCurve {
    // single slot
    uint128 maxPrice;
    uint16 jit;
    uint16 fee;
    uint16 duration;
    uint16 volatility;
    uint16 priorityFee;
    uint32 createdAt;
}

struct HyperPool {
    uint128 virtualX;
    uint128 virtualY;
    uint128 liquidity; // available liquidity to remove
    uint32 lastTimestamp; // updated on swaps.
    address controller;
    uint256 invariantGrowthGlobal;
    uint256 feeGrowthGlobalAsset;
    uint256 feeGrowthGlobalQuote;
    HyperCurve params;
    HyperPair pair;
}

// todo: optimize slot
struct HyperPosition {
    uint128 freeLiquidity;
    uint256 lastTimestamp;
    uint256 invariantGrowthLast;
    uint256 feeGrowthAssetLast;
    uint256 feeGrowthQuoteLast;
    uint128 tokensOwedAsset;
    uint128 tokensOwedQuote;
    uint128 invariantOwed;
}

struct ChangeLiquidityParams {
    address owner;
    uint64 poolId;
    uint256 timestamp;
    uint256 deltaAsset;
    uint256 deltaQuote;
    address tokenAsset;
    address tokenQuote;
    int128 deltaLiquidity;
}

struct Order {
    uint8 useMax;
    uint64 poolId;
    uint128 input;
    // For swapExactIn or swapExactOut, output is the limit price.
    uint128 output;
    uint8 direction;
}

struct Iteration {
    int256 invariant;
    uint256 virtualX;
    uint256 virtualY;
    uint256 remainder;
    uint256 feeAmount;
    uint256 liquidity;
    uint256 input;
    uint256 output;
}

struct SwapState {
    bool sell;
    address tokenInput;
    address tokenOutput;
    uint256 fee;
    uint256 feeGrowthGlobal;
    uint256 invariantGrowthGlobal;
}

struct Payment {
    address token;
    uint amount;
}

function changePoolLiquidity(HyperPool storage self, int128 liquidityDelta) {
    self.liquidity = Assembly.addSignedDelta(self.liquidity, liquidityDelta);
}

function syncPoolTimestamp(HyperPool storage self, uint timestamp) {
    self.lastTimestamp = SafeCastLib.safeCastTo32(timestamp);
}

function changePoolParameters(HyperPool storage self, HyperCurve memory updated) {
    (bool success, ) = updated.validateParameters();
    self.params = updated;
    assert(success);
}

function changePositionLiquidity(HyperPosition storage self, uint256 timestamp, int128 liquidityDelta) {
    self.lastTimestamp = timestamp;
    self.freeLiquidity = Assembly.addSignedDelta(self.freeLiquidity, liquidityDelta);
}

/** @dev Liquidity must be altered after syncing positions and not before. */
function syncPositionFees(
    HyperPosition storage self,
    uint feeGrowthAsset,
    uint feeGrowthQuote,
    uint invariantGrowth
) returns (uint feeAssetEarned, uint feeQuoteEarned, uint feeInvariantEarned) {
    // fee growth current - position fee growth last
    uint differenceAsset = Assembly.computeCheckpointDistance(feeGrowthAsset, self.feeGrowthAssetLast);
    uint differenceQuote = Assembly.computeCheckpointDistance(feeGrowthQuote, self.feeGrowthQuoteLast);
    uint differenceInvariant = Assembly.computeCheckpointDistance(invariantGrowth, self.invariantGrowthLast);

    // fee growth per liquidity * position liquidity
    feeAssetEarned = FixedPointMathLib.mulWadDown(differenceAsset, self.freeLiquidity);
    feeQuoteEarned = FixedPointMathLib.mulWadDown(differenceQuote, self.freeLiquidity);
    feeInvariantEarned = FixedPointMathLib.mulWadDown(differenceInvariant, self.freeLiquidity);

    self.feeGrowthAssetLast = feeGrowthAsset;
    self.feeGrowthQuoteLast = feeGrowthQuote;
    self.invariantGrowthLast = invariantGrowth;

    self.tokensOwedAsset += SafeCastLib.safeCastTo128(feeAssetEarned);
    self.tokensOwedQuote += SafeCastLib.safeCastTo128(feeQuoteEarned);
    self.invariantOwed += SafeCastLib.safeCastTo128(feeInvariantEarned);
}

// ===== View ===== //

function getVirtualReserves(HyperPool memory self) pure returns (uint128 reserveAsset, uint128 reserveQuote) {
    return self.getLiquidityDeltas(-int128(self.liquidity)); // rounds down
}

function getMaxLiquidity(
    HyperPool memory self,
    uint deltaAsset,
    uint deltaQuote
) pure returns (uint128 deltaLiquidity) {
    (uint amountAssetWad, uint amountQuoteWad) = self.getAmountsWad();
    uint liquidity0 = deltaAsset.divWadDown(amountAssetWad);
    uint liquidity1 = deltaQuote.divWadDown(amountQuoteWad);
    deltaLiquidity = (liquidity0 < liquidity1 ? liquidity0 : liquidity1).safeCastTo128();
}

/** @dev Rounds positive deltas up. Rounds negative deltas down. */
function getLiquidityDeltas(
    HyperPool memory self,
    int128 deltaLiquidity
) pure returns (uint128 deltaAsset, uint128 deltaQuote) {
    if (deltaLiquidity == 0) return (deltaAsset, deltaQuote);

    (uint amountAssetWad, uint amountQuoteWad) = self.getAmountsWad();
    uint scaleDownFactorAsset = Assembly.computeScalar(self.pair.decimalsAsset) * Price.WAD;
    uint scaleDownFactorQuote = Assembly.computeScalar(self.pair.decimalsQuote) * Price.WAD;

    uint delta;
    if (deltaLiquidity > 0) {
        delta = uint128(deltaLiquidity);
        deltaAsset = amountAssetWad.mulDivUp(delta, scaleDownFactorAsset).safeCastTo128();
        deltaQuote = amountQuoteWad.mulDivUp(delta, scaleDownFactorQuote).safeCastTo128();
    } else {
        delta = uint128(-deltaLiquidity);
        deltaAsset = amountAssetWad.mulDivDown(delta, scaleDownFactorAsset).safeCastTo128();
        deltaQuote = amountQuoteWad.mulDivDown(delta, scaleDownFactorQuote).safeCastTo128();
    }
}

/** @dev Decimal amounts per WAD of liquidity, rounded down... */
function getAmounts(HyperPool memory self) pure returns (uint amountAssetDec, uint amountQuoteDec) {
    (uint amountAssetWad, uint amountQuoteWad) = self.getAmountsWad();
    amountAssetDec = amountAssetWad.scaleFromWadDown(self.pair.decimalsAsset);
    amountQuoteDec = amountQuoteWad.scaleFromWadDown(self.pair.decimalsQuote);
}

/** @dev WAD Amounts per WAD of liquidity. */
function getAmountsWad(HyperPool memory self) pure returns (uint amountAssetWad, uint amountQuoteWad) {
    amountAssetWad = self.virtualX;
    amountQuoteWad = self.virtualY;
}

// ===== Derived ===== //

function getTimeSinceChanged(HyperPosition memory self, uint timestamp) pure returns (uint distance) {
    return timestamp - self.lastTimestamp;
}

function exists(HyperPool memory self) pure returns (bool) {
    return self.lastTimestamp != 0;
}

function isMutable(HyperPool memory self) pure returns (bool) {
    return self.controller != address(0);
}

function getRMM(HyperPool memory self) pure returns (Price.RMM memory) {
    return Price.RMM({strike: self.params.maxPrice, sigma: self.params.volatility, tau: self.lastTau()});
}

function lastTau(HyperPool memory self) pure returns (uint) {
    return self.computeTau(self.lastTimestamp);
}

function computeTau(HyperPool memory self, uint timestamp) pure returns (uint) {
    uint end = self.params.maturity();
    if (timestamp > end) return 0;
    return end - timestamp;
}

function maturity(HyperCurve memory self) pure returns (uint32 endTimestamp) {
    return (Assembly.convertDaysToSeconds(self.duration) + self.createdAt).safeCastTo32();
}

function validateParameters(HyperCurve memory self) pure returns (bool, bytes memory) {
    (bool success, bytes memory reason) = self.checkParameters();
    if (!success) {
        assembly {
            revert(add(32, reason), mload(reason))
        }
    }

    return (success, reason);
}

/** @dev Invalid parameters should revert. Bound checks are inclusive. */
function checkParameters(HyperCurve memory self) pure returns (bool, bytes memory) {
    if (self.jit > JUST_IN_TIME_MAX) return (false, abi.encodeWithSelector(InvalidJit.selector, self.jit));
    if (!Assembly.isBetween(self.volatility, MIN_VOLATILITY, MAX_VOLATILITY))
        return (false, abi.encodeWithSelector(InvalidVolatility.selector, self.volatility));
    if (!Assembly.isBetween(self.duration, MIN_DURATION, MAX_DURATION))
        return (false, abi.encodeWithSelector(InvalidDuration.selector, self.duration));
    if (!Assembly.isBetween(self.maxPrice, MIN_MAX_PRICE, MAX_MAX_PRICE))
        return (false, abi.encodeWithSelector(InvalidStrike.selector, self.maxPrice));
    if (!Assembly.isBetween(self.fee, MIN_FEE, MAX_FEE))
        return (false, abi.encodeWithSelector(InvalidFee.selector, self.fee));
    // 0 priority fee == no controller, impossible to set to zero unless default from non controlled pools.
    if (!Assembly.isBetween(self.priorityFee, 0, self.fee))
        return (false, abi.encodeWithSelector(InvalidFee.selector, self.priorityFee));

    return (true, "");
}

// ===== Swaps ===== //

function getMaxSwapAssetInWad(HyperPool memory self) pure returns (uint) {
    (uint x, ) = self.getAmountsWad();
    uint maxInput = FixedPointMathLib.WAD - x;
    maxInput = maxInput.mulWadDown(self.liquidity);
    return maxInput.scaleFromWadDown(self.pair.decimalsAsset);
}

function getMaxSwapQuoteInWad(HyperPool memory self) pure returns (uint) {
    Price.RMM memory rmm = self.getRMM();
    (, uint y) = self.getAmountsWad();
    uint maxInput = rmm.strike - y;
    maxInput = maxInput.mulWadDown(self.liquidity);
    return maxInput.scaleFromWadDown(self.pair.decimalsQuote);
}

function getNextInvariant(HyperPool memory self, uint256 timeSinceUpdate) pure returns (int128 invariant, uint tau) {
    Price.RMM memory curve = self.getRMM();

    curve.tau -= timeSinceUpdate; // update to next curve at new time.
    (uint x, uint y) = self.getAmountsWad();

    invariant = int128(curve.invariantOf(y, x)); // todo: fix casting
    tau = curve.tau;
}

/**
 * @dev This is an approximation of the amount out and it is not exactly precise to the optimal amount.
 * @custom:error Maximum absolute error of 1e-6.
 */
function getAmountOut(
    HyperPool memory self,
    bool sellAsset,
    uint amountIn,
    uint timeSinceUpdate
) pure returns (uint, uint) {
    Iteration memory data;
    Price.RMM memory liveCurve = self.getRMM();
    Price.RMM memory nextCurve = liveCurve;

    {
        // fill in data
        data.remainder = amountIn.scaleToWad(sellAsset ? self.pair.decimalsAsset : self.pair.decimalsQuote);
        data.liquidity = self.liquidity;
        (data.virtualX, data.virtualY) = self.getAmountsWad();
        nextCurve.tau -= timeSinceUpdate;
        data.invariant = nextCurve.invariantOf(data.virtualY, data.virtualX);
    }

    uint fee = self.controller != address(0) ? self.params.priorityFee : self.params.fee;
    uint prevInd;
    uint prevDep;
    uint nextInd;
    uint nextDep;
    {
        uint maxInput;
        uint delInput;

        // if sellAsset, ind = x && dep = y, else ind = y && dep = x
        if (sellAsset) {
            (prevInd, prevDep) = (data.virtualX, data.virtualY);
            maxInput = (FixedPointMathLib.WAD - prevInd).mulWadDown(data.liquidity); // There can be maximum 1:1 ratio between assets and liqudiity.
        } else {
            (prevDep, prevInd) = (data.virtualX, data.virtualY);
            maxInput = (liveCurve.strike - prevInd).mulWadDown(data.liquidity); // There can be maximum strike:1 liquidity ratio between quote and liquidity.
        }

        data.feeAmount = ((data.remainder > maxInput ? maxInput : data.remainder) * fee) / 10_000;
        delInput = data.remainder > maxInput ? maxInput : data.remainder;
        nextInd = prevInd + (delInput - data.feeAmount).divWadDown(data.liquidity);

        // Compute the output of the swap by computing the difference between the dependent reserves.
        if (sellAsset) nextDep = nextCurve.getYWithX(nextInd, data.invariant);
        else nextDep = nextCurve.getXWithY(nextInd, data.invariant);

        data.remainder -= delInput;
        data.input += delInput;

        if (nextDep > prevDep) revert SwapInputTooSmall();
        data.output += (prevDep - nextDep).mulWadDown(data.liquidity);
    }

    {
        // Scale down amounts from WAD.
        uint inputDec;
        uint outputDec;
        if (sellAsset) {
            inputDec = self.pair.decimalsAsset;
            outputDec = self.pair.decimalsQuote;
        } else {
            inputDec = self.pair.decimalsQuote;
            outputDec = self.pair.decimalsAsset;
        }

        data.input = data.input.scaleFromWadUp(inputDec);
        data.output = data.output.scaleFromWadDown(outputDec);
    }

    return (data.output, data.remainder);
}

function toInt128(uint128 a) pure returns (int128 b) {
    assembly {
        if gt(a, 0x7fffffffffffffffffffffffffffffff) {
            revert(0, 0)
        }

        b := a
    }
}
