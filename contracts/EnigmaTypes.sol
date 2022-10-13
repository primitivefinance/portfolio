// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// --- Decompiler --- //
/// @dev Thrown when attempting to remove more internal token balance than owned by `msg.sender`.

error DrawBalance();
/// @dev Thrown when the jump pointer is further than the length of the next instruction.

error JumpError(uint256 pointer);
/// @dev Thrown if the instruction byte is 0x00 or does not match a valid instruction.

error UnknownInstruction();

// --- Default --- //
/// @dev Thrown when the `IERC20.balanceOf` returns false or less data than expected.
error BalanceError();

/// @dev Re-entrany guard thrown on re-entering the external functions or fallback.
error LockedError();

// --- Creation --- //
/// @dev Thrown when a pool is being created which has already been created with the same args.
error CurveExists(uint32 curveId);

/// @dev Thrown when interacting with a pool that has not been created.
error NonExistentPool(uint48 poolId);

/// @dev Thrown when creating a pair that has been created for the two addresses.
error PairExists(uint16 pairId);

/// @dev Thrown when a pool has been created for the pair and curve combination.
error PoolExists();

/// @dev Thrown when decimals of a token in a create pair operation are greater than 18 or less than 6.
error DecimalsError(uint8 decimals);

/// @dev Thrown if creating a pair with the same token.
error SameTokenError();

/// @dev Thrown if the amount of base tokens per liquidity is outside of the bounds 0 < x < 1.
error PerLiquidityError(uint256 deltaBase);

// --- Validation --- //

/// @dev Thrown when creating a pool that has one side of the pool have zero tokens.
error CalibrationError(uint256 deltaBase, uint256 deltaQuote);

/// @dev Thrown if the fee used in pool creation is more than 1000.
error MaxFee(uint16 fee);

/// @dev Thrown if the sigma used in pool creation is zero.
error MinSigma(uint24 sigma);

/// @dev Thrown if the strike used in the pool creation is zero.
error MinStrike(uint128 strike);

/// @dev Thrown if attempting to create or swap in a pool which has eclipsed its maturity timestamp.
error PoolExpiredError();

/// @dev Thrown if adding or removing zero liquidity.
error ZeroLiquidityError();

/// @dev Thrown if fee is outside of bounds.
error FeeOOB(uint16 fee);

/// @dev Thrown if priority fee is outside of bounds.
error PriorityFeeOOB(uint16 priorityFee);

/// @dev Thrown if attempting to create a pool with a zero price.
error ZeroPrice();

// --- Special --- //

/// @dev Thrown if the JIT liquidity condition is false.
error JitLiquidity(uint256 distance);

// --- Swap --- //

/// @dev Thrown if the effects of a swap put the pool in an invalid state according the the trading function.
error InvariantError(int128 prev, int128 post);

/// @dev Thrown if zero swap amount in arguments.
error ZeroInput();

// --- Staking --- //

/// @dev Thrown if position is already staked and trying to stake again.
error PositionStakedError(uint96 positionId);

/// @dev Thrown if position has zero liquidity and trying to stake.
error PositionZeroLiquidityError(uint96 positionId);

/// @dev Thrown if position is not staked and trying to unstake.
error PositionNotStakedError(uint96 positionId);

/// @dev Token information of each two token pool.
struct Pair {
    address token0;
    uint8 token0Decimals;
    address token1;
    uint8 token1Decimals;
}

/// @dev Time interval information for liquidity staking.
struct Epoch {
    uint256 id;
    uint256 endTime;
    uint256 interval;
}

/// @dev Auction parameter information for a pool.
struct AuctionParams {
    uint256 startPrice;
    uint256 endPrice;
    uint256 fee;
    uint256 length;
}

/// @dev Individual live pool state.
struct HyperPool {
    uint256 lastPrice;
    int24 lastTick;
    uint256 blockTimestamp;
    uint256 liquidity;
    uint256 stakedLiquidity;
    int256 pendingStakedLiquidityDelta;
    address prioritySwapper;
    uint256 priorityPaymentPerSecond;
    uint256 priorityGrowthGlobal;
    uint256 feeGrowthGlobalAsset;
    uint256 feeGrowthGlobalQuote;
    uint32 gamma;
    uint32 priorityGamma;
}

/// @dev Individual position state.
struct HyperPosition {
    int24 loTick;
    int24 hiTick;
    uint256 totalLiquidity;
    uint256 stakedLiquidity;
    uint256 stakedEpoch;
    uint256 unstakedEpoch;
    int256 pendingStakedLiquidityDelta;
    uint256 pendingStakedEpoch;
    uint256 feeGrowthInsideAssetLast;
    uint256 feeGrowthInsideQuoteLast;
    uint256 priorityGrowthInsideLast;
    uint256 tokensOwedAsset;
    uint256 tokensOwedQuote;
    uint256 blockTimestamp;
}

/// @dev Liquidity information indexed by tick (a price).
struct HyperSlot {
    int256 liquidityDelta;
    int256 stakedLiquidityDelta;
    int256 pendingStakedLiquidityDelta;
    uint256 totalLiquidity;
    uint256 feeGrowthOutsideAsset;
    uint256 feeGrowthOutsideQuote;
    uint256 priorityGrowthOutside;
    bool instantiated;
    uint256 timestamp;
}

// --- Swap --- //

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
    uint48 poolId;
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
struct SwapIteration {
    int24 tick;
    uint256 price;
    uint256 remainder;
    uint256 feeAmount;
    uint256 liquidity;
    uint256 stakedLiquidity;
    int256 pendingStakedLiquidityDelta;
    uint256 input;
    uint256 output;
}

struct SwapState {
    bool sell;
    uint256 gamma;
    uint256 feeGrowthGlobal;
}

struct SyncIteration {
    int24 tick;
    uint256 liquidity;
    uint256 stakedLiquidity;
    int256 pendingStakedLiquidityDelta;
}
