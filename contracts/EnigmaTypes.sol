// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/utils/SafeCastLib.sol";
import "./libraries/Price.sol";
import "./Assembly.sol" as Assembly;
import "./CPU.sol" as CPU;
import "./OS.sol" as OS;

import {console} from "forge-std/Test.sol";

using {
    changePoolLiquidity,
    changePoolParameters,
    exists,
    syncPoolTimestamp,
    strike,
    computePriceChangeWithTime,
    isMutable,
    getMaxLiquidity,
    getVirtualReserves,
    getLiquidityDeltas,
    getAmounts,
    lastTau,
    tau,
    getRMM,
    getAmountOut
} for HyperPool global;
using {maturity} for HyperCurve global;
using {changePositionLiquidity, syncPositionFees, getTimeSinceChanged} for HyperPosition global;
using Price for Price.RMM;
using SafeCastLib for uint;
using FixedPointMathLib for uint;

int24 constant MAX_TICK = 25556; // todo: fix, Equal to 5x price at 1bps tick sizes.
int24 constant TICK_SIZE = 256; // todo: use this?
uint8 constant MIN_DECIMALS = 6;
uint8 constant MAX_DECIMALS = 18;
uint256 constant BUFFER = 300;
uint256 constant MIN_POOL_FEE = 1;
uint256 constant MAX_POOL_FEE = 1e3;
uint256 constant JUST_IN_TIME_MAX = 600;
uint256 constant JUST_IN_TIME_LIQUIDITY_POLICY = 4;

error DrawBalance();
error InvalidDecimals(uint8 decimals);
error InvalidDuration(uint16);
error InvalidFee(uint16 fee);
error InvalidInstruction();
error InvalidInvariant(int256 prev, int256 next);
error InvalidJit(uint16);
error InvalidReentrancy();
error InvalidSettlement();
error InvalidStrike(uint128 strike);
error InvalidTick(int24);
error InvalidVolatility(uint24 sigma);
error JitLiquidity(uint256 distance);
error MaxFee(uint16 fee);
error NotController();
error NonExistentPool(uint64 poolId);
error PairExists(uint24 pairId);
error PerLiquidityError(uint256 deltaAsset);
error PoolExists();
error PoolExpired();
error PositionStaked(uint96 positionId);
error PositionZeroLiquidity(uint96 positionId);
error PositionNotStaked(uint96 positionId);
error SameTokenError();
error SwapLimitReached();
error ZeroInput();
error ZeroLiquidity();
error ZeroPrice();

struct Pair {
    address tokenAsset;
    uint8 decimalsAsset;
    address tokenQuote;
    uint8 decimalsQuote;
}

struct HyperCurve {
    // single slot
    int24 maxTick;
    uint16 jit;
    uint16 fee;
    uint16 duration;
    uint16 volatility;
    uint16 priorityFee;
    uint48 createdAt;
}

struct HyperPool {
    int24 lastTick; // mutable so not optimized in slot.
    uint32 lastTimestamp; // updated on swaps
    address controller;
    uint256 feeGrowthGlobalAsset;
    uint256 feeGrowthGlobalQuote;
    // single slot
    uint128 lastPrice;
    uint128 liquidity; // available liquidity to remove
    uint128 stakedLiquidity; // locked liquidity
    int128 stakedLiquidityDelta; // liquidity to be added or removed
    HyperCurve params;
}

// todo: optimize slot
struct HyperPosition {
    uint128 totalLiquidity;
    uint256 lastTimestamp;
    uint256 stakeTimestamp;
    uint256 unstakeTimestamp;
    uint256 lastRewardGrowth;
    uint256 feeGrowthAssetLast;
    uint256 feeGrowthQuoteLast;
    uint128 tokensOwedAsset;
    uint128 tokensOwedQuote;
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
    uint128 limit;
    uint8 direction;
}

struct Iteration {
    int24 tick;
    uint256 price;
    uint256 remainder;
    uint256 feeAmount;
    uint256 liquidity;
    uint256 input;
    uint256 output;
}

struct SwapState {
    bool sell;
    uint256 fee;
    uint256 feeGrowthGlobal;
}

function syncPoolTimestamp(HyperPool storage self, uint timestamp) {
    self.lastTimestamp = SafeCastLib.safeCastTo32(timestamp);
}

function changePoolLiquidity(HyperPool storage self, int128 liquidityDelta) {
    self.liquidity = Assembly.addSignedDelta(self.liquidity, liquidityDelta);
}

// todo: proper parameter checks
function changePoolParameters(HyperPool storage self, HyperCurve memory updated) {
    if (self.controller != msg.sender) revert NotController();
    if (updated.maxTick >= MAX_TICK) revert InvalidTick(updated.maxTick);
    if (updated.jit > JUST_IN_TIME_LIQUIDITY_POLICY * 10) revert InvalidJit(updated.jit);
    if (updated.jit != 0) self.params.jit = updated.jit;
    if (updated.maxTick != 0) self.params.maxTick = updated.maxTick;
    if (updated.fee != 0) self.params.fee = updated.fee;
    if (updated.volatility != 0) self.params.volatility = updated.volatility;
    if (updated.duration != 0) self.params.duration = updated.duration;
    if (updated.priorityFee != 0) self.params.priorityFee = updated.priorityFee;
}

function exists(HyperPool memory self) view returns (bool) {
    return self.lastTimestamp != 0;
}

function isMutable(HyperPool memory self) view returns (bool) {
    return self.controller != address(0);
}

function strike(HyperPool memory self) view returns (uint strike) {
    return Price.computePriceWithTick(self.params.maxTick);
}

function computePriceChangeWithTime(
    HyperPool memory self,
    uint tau,
    uint epsilon
) pure returns (uint price, int24 tick) {
    uint strike = Price.computePriceWithTick(self.params.maxTick);
    price = Price.computePriceWithChangeInTau(strike, self.params.volatility, self.lastPrice, tau, epsilon);
    tick = Price.computeTickWithPrice(price);
}

function getMaxLiquidity(
    HyperPool memory self,
    uint deltaAsset,
    uint deltaQuote
) view returns (uint128 deltaLiquidity) {
    (uint amountAsset, uint amountQuote) = self.getAmounts();
    uint liquidity0 = deltaAsset.divWadDown(amountAsset);
    uint liquidity1 = deltaQuote.divWadDown(amountQuote);
    deltaLiquidity = (liquidity0 < liquidity1 ? liquidity0 : liquidity1).safeCastTo128();
}

function getVirtualReserves(HyperPool memory self) view returns (uint128 reserveAsset, uint128 reserveQuote) {
    return self.getLiquidityDeltas(-int128(self.liquidity)); // rounds down
}

/** @dev Rounds positive deltas up. Rounds negative deltas down. */
function getLiquidityDeltas(
    HyperPool memory self,
    int128 deltaLiquidity
) view returns (uint128 deltaAsset, uint128 deltaQuote) {
    if (deltaLiquidity == 0) return (deltaAsset, deltaQuote);
    (uint amountAsset, uint amountQuote) = self.getAmounts();

    uint delta;
    if (deltaLiquidity > 0) {
        delta = uint128(deltaLiquidity);
        deltaAsset = amountAsset.mulWadUp(delta).safeCastTo128();
        deltaQuote = amountQuote.mulWadUp(delta).safeCastTo128();
    } else {
        delta = uint128(-deltaLiquidity);
        deltaAsset = amountAsset.mulWadDown(delta).safeCastTo128();
        deltaQuote = amountQuote.mulWadDown(delta).safeCastTo128();
    }
}

/** @dev WAD Amounts per WAD of liquidity. */
function getAmounts(HyperPool memory self) view returns (uint amountAsset, uint amountQuote) {
    Price.RMM memory rmm = self.getRMM();
    amountAsset = rmm.computeR2WithPrice(self.lastPrice);
    amountQuote = rmm.computeR1WithR2(amountAsset);
}

function getAmountOut(
    HyperPool memory self,
    Pair memory pair,
    bool sellAsset,
    uint amountIn,
    uint timeSinceUpdate
) view returns (uint, uint) {
    Iteration memory data;
    Price.RMM memory rmm = self.getRMM();
    (data.price, data.tick) = self.computePriceChangeWithTime(self.lastTau(), timeSinceUpdate);
    data.remainder = amountIn * 10 ** (MAX_DECIMALS - (sellAsset ? pair.decimalsAsset : pair.decimalsQuote));
    data.liquidity = self.liquidity;

    uint prevInd;
    uint prevDep;
    uint nextInd;
    uint nextDep;

    {
        uint maxInput;
        uint delInput;

        if (sellAsset) {
            (prevDep, prevInd) = rmm.computeReserves(data.price);
            maxInput = (FixedPointMathLib.WAD - prevInd).mulWadDown(self.liquidity); // There can be maximum 1:1 ratio between assets and liqudiity.
        } else {
            (prevInd, prevDep) = rmm.computeReserves(data.price);
            maxInput = (rmm.strike - prevInd).mulWadDown(self.liquidity); // There can be maximum strike:1 liquidity ratio between quote and liquidity.
        }

        data.feeAmount = ((data.remainder > maxInput ? maxInput : data.remainder) * self.params.fee) / 10_000;

        if (data.remainder > maxInput) {
            delInput = maxInput - data.feeAmount;
            nextInd = prevInd + delInput.divWadDown(data.liquidity);
            data.remainder -= (delInput + data.feeAmount);
        } else {
            delInput = data.remainder - data.feeAmount;
            nextInd = prevInd + delInput.divWadDown(data.liquidity);
            delInput = data.remainder; // Swap input amount including the fee payment.
            data.remainder = 0; // Clear the remainder to zero, as the order has been filled.
        }

        // Compute the output of the swap by computing the difference between the dependent reserves.
        if (sellAsset) nextDep = rmm.computeR1WithR2(nextInd);
        else nextDep = rmm.computeR2WithR1(nextInd);

        data.input += delInput;
        data.output += (prevDep - nextDep);
    }

    {
        // Scale down amounts from WAD.
        uint inputScale;
        uint outputScale;
        if (sellAsset) {
            inputScale = MAX_DECIMALS - pair.decimalsAsset;
            outputScale = MAX_DECIMALS - pair.decimalsQuote;
        } else {
            inputScale = MAX_DECIMALS - pair.decimalsQuote;
            outputScale = MAX_DECIMALS - pair.decimalsAsset;
        }

        data.input = data.input / (10 ** inputScale);
        data.output = data.output / (10 ** outputScale);
    }

    return (data.output, data.remainder);
}

function getRMM(HyperPool memory self) view returns (Price.RMM memory) {
    return Price.RMM({strike: self.strike(), sigma: self.params.volatility, tau: self.lastTau()});
}

function lastTau(HyperPool memory self) view returns (uint tau) {
    return self.tau(self.lastTimestamp);
}

function tau(HyperPool memory self, uint timestamp) view returns (uint) {
    uint end = self.params.maturity();
    if (timestamp > end) return 0;
    return end - timestamp;
}

function maturity(HyperCurve memory self) view returns (uint endTimestamp) {
    return Assembly.convertDaysToSeconds(self.duration) + self.createdAt;
}

function getTimeSinceChanged(HyperPosition memory self, uint timestamp) view returns (uint distance) {
    return timestamp - self.lastTimestamp;
}

function syncPositionFees(
    HyperPosition storage self,
    uint liquidity,
    uint feeGrowthAsset,
    uint feeGrowthQuote
) returns (uint feeAssetEarned, uint feeQuoteEarned) {
    uint checkpointAsset = Assembly.computeCheckpointDistance(feeGrowthAsset, self.feeGrowthAssetLast);
    uint checkpointQuote = Assembly.computeCheckpointDistance(feeGrowthQuote, self.feeGrowthQuoteLast);

    feeAssetEarned = FixedPointMathLib.mulWadDown(checkpointAsset, liquidity);
    feeQuoteEarned = FixedPointMathLib.mulWadDown(checkpointQuote, liquidity);

    self.feeGrowthAssetLast = feeGrowthAsset;
    self.feeGrowthQuoteLast = feeGrowthQuote;

    self.tokensOwedAsset += SafeCastLib.safeCastTo128(feeAssetEarned);
    self.tokensOwedQuote += SafeCastLib.safeCastTo128(feeAssetEarned);
}

function changePositionLiquidity(HyperPosition storage self, uint256 timestamp, int128 liquidityDelta) {
    self.lastTimestamp = timestamp;
    self.totalLiquidity = Assembly.addSignedDelta(self.totalLiquidity, liquidityDelta);
}
