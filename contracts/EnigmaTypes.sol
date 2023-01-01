// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/utils/SafeCastLib.sol";
import "./libraries/Price.sol";
import "./Assembly.sol" as Assembly;
import "./CPU.sol" as CPU;
import "./OS.sol" as OS;

using {
    changePoolLiquidity,
    changePoolParameters,
    exists,
    syncPoolTimestamp,
    computeStrike,
    computePriceChangeWithTime
} for HyperPool global;
using {maturity} for HyperCurve global;
using {changePositionLiquidity, syncPositionFees} for HyperPosition global;

int24 constant MAX_TICK = 25556; // todo: fix, Equal to 5x price at 1bps tick sizes.
int24 constant TICK_SIZE = 256; // todo: use this?
uint8 constant MIN_DECIMALS = 6;
uint8 constant MAX_DECIMALS = 18;
uint256 constant BUFFER = 300;
uint256 constant MIN_POOL_FEE = 1;
uint256 constant MAX_POOL_FEE = 1e3;
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

function computeStrike(HyperPool memory pool) view returns (uint strike) {
    strike = Price.computePriceWithTick(pool.params.maxTick);
}

function computePriceChangeWithTime(
    HyperPool memory pool,
    uint tau,
    uint epsilon
) view returns (uint price, int24 tick) {
    uint strike = Price.computePriceWithTick(pool.params.maxTick);
    price = Price.computePriceWithChangeInTau(strike, pool.params.volatility, pool.lastPrice, tau, epsilon);
    tick = Price.computeTickWithPrice(price);
}

function getVirtualAmounts(HyperPool memory self) view returns (uint, uint) {}

function lastTau(HyperPool memory self) view returns (uint tau) {
    return self.tau(self.lastTimestamp);
}

function tau(HyperPool memory self, uint timestamp) view returns (uint) {
    uint end = self.params.maturity();
    if (timestamp > end) return 0;
    return end - timestamp;
}

function maturity(HyperCurve memory self) view returns (uint endTimestamp) {
    return Assembly.convertDaysToSeconds(params.duration) + params.createdAt;
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
