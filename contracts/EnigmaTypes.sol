// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./OS.sol";
import "./CPU.sol" as CPU;
import "./Clock.sol";
import "./Assembly.sol" as asm;
import "./libraries/Price.sol";

/// @dev Maximum price multiple. Equal to 5x price at 1bps tick sizes.
int24 constant MAX_TICK = 25556; // TODO: Fix
/// @dev Distance between the location of prices on the price grid, so distance between price.
int24 constant TICK_SIZE = 256;
/// @dev Minimum amount of decimals supported for ERC20 tokens.
uint8 constant MIN_DECIMALS = 6;
/// @dev Maximum amount of decimals supported for ERC20 tokens.
uint8 constant MAX_DECIMALS = 18;
/// @dev Amount of seconds of available time to swap past maturity of a pool.
uint256 constant BUFFER = 300;
/// @dev Constant amount of 1 ether. All liquidity values have 18 decimals.
uint256 constant PRECISION = 1e18;
/// @dev Constant amount of basis points. All percentage values are integers in basis points.
uint256 constant PERCENTAGE = 1e4;
/// @dev Minimum pool fee. 0.01%.
uint256 constant MIN_POOL_FEE = 1;
/// @dev Maximum pool fee. 10.00%.
uint256 constant MAX_POOL_FEE = 1e3;
/// @dev Amount of seconds that an epoch lasts.
uint256 constant EPOCH_INTERVAL = 3600 seconds; // 1 hr
/// @dev Used to compute the amount of liquidity to burn on creating a pool.
uint256 constant MIN_LIQUIDITY_FACTOR = 6;
/// @dev Policy for the "wait" time in seconds between adding and removing liquidity.
uint256 constant JUST_IN_TIME_LIQUIDITY_POLICY = 4;

error EtherTransferFail();

/// @dev Thrown when attempting to remove more internal token balance than owned by `msg.sender`.
error DrawBalance();
/// @dev Thrown when the jump pointer is further than the length of the next instruction.
error InvalidJump(uint256 pointer);
/// @dev Thrown if the instruction byte is 0x00 or does not match a valid instruction.
error InvalidInstruction();
// --- Default --- //
/// @dev Thrown when the `IERC20.balanceOf` returns false or less data than expected.
error InvalidBalance();
/// @dev Re-entrany guard thrown on re-entering the external functions or fallback.
error InvalidReentrancy();
// --- Creation --- //
/// @dev Thrown when interacting with a pool that has not been created.
error NonExistentPool(uint64 poolId);
/// @dev Thrown when creating a pair that has been created for the two addresses.
error PairExists(uint24 pairId);
/// @dev Thrown when a pool has been created for the pair and curve combination.
error PoolExists();
/// @dev Thrown when decimals of a token in a create pair operation are greater than 18 or less than 6.
error InvalidDecimals(uint8 decimals);
/// @dev Thrown if creating a pair with the same token.
error SameTokenError();
/// @dev Thrown if the amount of base tokens per liquidity is outside of the bounds 0 < x < 1.
error PerLiquidityError(uint256 deltaAsset);
// --- Validation --- //
/// @dev Thrown if the fee used in pool creation is more than 1000.
error MaxFee(uint16 fee);
/// @dev Thrown if the sigma used in pool creation is zero.
error InvalidVolatility(uint24 sigma);
/// @dev Thrown if the strike used in the pool creation is zero.
error InvalidStrike(uint128 strike);
/// @dev Thrown if attempting to create or swap in a pool which has eclipsed its maturity timestamp.
error PoolExpired();
/// @dev Thrown if adding or removing zero liquidity.
error ZeroLiquidity();
/// @dev Thrown if fee is outside of bounds.
error InvalidFee(uint16 fee);
/// @dev Thrown if attempting to create a pool with a zero price.
error ZeroPrice();
// --- Special --- //
/// @dev Thrown if the JIT liquidity condition is false.
error JitLiquidity(uint256 distance);
// --- Swap --- //
/// @dev Thrown if the effects of a swap put the pool in an invalid state according the the trading function.
error InvalidInvariant(int256 prev, int256 next);
/// @dev Thrown if zero swap amount in arguments.
error ZeroInput();

error SwapLimitReached();
// --- Staking --- //
/// @dev Thrown if position is already staked and trying to stake again.
error PositionStaked(uint96 positionId);
/// @dev Thrown if position has zero liquidity and trying to stake.
error PositionZeroLiquidity(uint96 positionId);
/// @dev Thrown if position is not staked and trying to unstake.
error PositionNotStaked(uint96 positionId);

error InvalidSettlement();
error NotController();
error InvalidJit(uint16);
error InvalidTick(int24);
error InvalidDuration(uint16);

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
    uint48 startEpoch;
}

/// @dev Individual live pool state.
/// @param epochStakedLiquidityDelta Liquidity to be added to staked liquidity.
struct HyperPool {
    int24 lastTick; // mutable so not optimized in slot.
    uint32 lastTimestamp;
    address controller;
    uint256 feeGrowthGlobalAsset;
    uint256 feeGrowthGlobalQuote;
    // single slot
    uint128 lastPrice;
    uint128 liquidity;
    uint128 stakedLiquidity;
    int128 epochStakedLiquidityDelta;
    HyperCurve params;
}

// todo: optimize slot
/// @dev Individual position state.
struct HyperPosition {
    uint128 totalLiquidity;
    uint256 blockTimestamp;
    uint256 stakeEpochId;
    uint256 unstakeEpochId;
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

/**
 * @notice Parameters used to submit a swap order.
 * @param useMax Use the caller's total balance of the pair's token to do the swap.
 * @param poolId Identifier of the pool.
 * @param input Amount of tokens to input in the swap.
 * @param limit Maximum price paid to fill the swap order.
 * @param direction Specifies asset token in, quote token out with '0', and quote token in, asset token out with '1'.
 */
struct Order {
    uint8 useMax;
    uint64 poolId;
    uint128 input;
    uint128 limit;
    uint8 direction;
}

/**
 * @notice Temporary variables utilized in the order filling loop.
 * @param tick Key of the slot being used to fill the swap at.
 * @param price Price of the slot being used to fill this swap step at.
 * @param remainder Order amount left to fill.
 * @param liquidity Liquidity available at this slot.
 * @param input Cumulative sum of input amounts for each swap step.
 * @param output Cumulative sum of output amounts for each swap step.
 */
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
    uint256 gamma;
    uint256 feeGrowthGlobal;
}

using {changePoolLiquidity, computeRawParams, changePoolParameters} for HyperPool global;
using {changePositionLiquidity, syncPositionFees} for HyperPosition global;

/**
 * @notice Syncs a pool's liquidity and last updated timestamp.
 */
function changePoolLiquidity(HyperPool storage self, uint256 timestamp, int128 liquidityDelta) {
    // TODO: Investigate updating timestamp.
    // Changing timestamp changes pool price.
    // Cannot change price and liquidity.
    // self.blockTimestamp = timestamp;
    self.liquidity = asm.toUint128(asm.__computeDelta(self.liquidity, liquidityDelta));
}

/**
 * @notice Syncs a position's liquidity, last updated timestamp, fees earned, and fee growth.
 */
function changePositionLiquidity(HyperPosition storage self, uint256 timestamp, int128 liquidityDelta) {
    self.blockTimestamp = timestamp; // Allowed to change timestamp with changing liquidity of a position.
    self.totalLiquidity = asm.toUint128(asm.__computeDelta(self.totalLiquidity, liquidityDelta));
}

function changePoolParameters(HyperPool storage pool, HyperCurve memory updated) {
    if (pool.controller != msg.sender) revert NotController();
    if (updated.maxTick >= MAX_TICK) revert InvalidTick(updated.maxTick);
    if (updated.jit > JUST_IN_TIME_LIQUIDITY_POLICY * 10) revert InvalidJit(updated.jit);
    if (updated.jit != 0) pool.params.jit = updated.jit;
    if (updated.maxTick != 0) pool.params.maxTick = updated.maxTick;
    if (updated.fee != 0) pool.params.fee = updated.fee;
    if (updated.volatility != 0) pool.params.volatility = updated.volatility;
    if (updated.duration != 0) pool.params.duration = updated.duration;
    if (updated.priorityFee != 0) pool.params.priorityFee = updated.priorityFee;
}

function syncPositionFees(
    HyperPosition storage self,
    uint liquidity,
    uint feeGrowthAsset,
    uint feeGrowthQuote
) returns (uint feeAssetEarned, uint feeQuoteEarned) {
    uint checkpointAsset = asm.__computeCheckpointDistance(feeGrowthAsset, self.feeGrowthAssetLast);
    uint checkpointQuote = asm.__computeCheckpointDistance(feeGrowthQuote, self.feeGrowthQuoteLast);

    feeAssetEarned = FixedPointMathLib.mulWadDown(checkpointAsset, liquidity);
    feeQuoteEarned = FixedPointMathLib.mulWadDown(checkpointQuote, liquidity);

    self.feeGrowthAssetLast = feeGrowthAsset;
    self.feeGrowthQuoteLast = feeGrowthQuote;

    self.tokensOwedAsset += asm.toUint128(feeAssetEarned);
    self.tokensOwedQuote += asm.toUint128(feeAssetEarned);
}

function exists(mapping(uint64 => HyperPool) storage pools, uint64 poolId) view returns (bool) {
    return pools[poolId].lastTimestamp != 0;
}

// todo: maybe hash? this is not used anywhere right now.
function computeRawParams(HyperPool memory params) pure returns (bytes32) {
    return
        CPU.toBytes32(
            abi.encodePacked(
                params.controller,
                params.params.priorityFee,
                params.params.fee,
                params.params.volatility,
                params.params.duration,
                params.params.jit,
                params.params.maxTick
            )
        );
}
