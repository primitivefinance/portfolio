// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "solmate/utils/SafeCastLib.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "./libraries/AssemblyLib.sol";
import "./libraries/FVMLib.sol" as FVM;
import "./libraries/AccountLib.sol" as Account;

using AssemblyLib for uint256;
using FixedPointMathLib for uint256;
using FixedPointMathLib for int256;
using SafeCastLib for uint256;

using {checkParameters, maturity, validateParameters} for PortfolioCurve global;
using {
    changePositionLiquidity,
    syncPositionFees,
    getTimeSinceChanged
} for PortfolioPosition global;
using {
    changePoolLiquidity,
    changePoolParameters,
    exists,
    getPoolAmounts,
    getAmountsWad,
    getPoolLiquidityDeltas,
    getPoolMaxLiquidity,
    getPoolVirtualReserves,
    isMutable,
    syncPoolTimestamp,
    lastTau,
    computeTau
} for PortfolioPool global;

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
error InvalidAmountOut();
error InvalidDecimals(uint8 decimals);
error InvalidDuration(uint16);
error InvalidFee(uint16 fee);
error InvalidInstruction();
error InvalidInvariant(int256 prev, int256 next);
error InvalidJit(uint16);
error InvalidPair();
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

struct PortfolioPair {
    address tokenAsset;
    uint8 decimalsAsset;
    address tokenQuote;
    uint8 decimalsQuote;
}

struct PortfolioCurve {
    // single slot
    uint128 maxPrice;
    uint16 jit;
    uint16 fee;
    uint16 duration;
    uint16 volatility;
    uint16 priorityFee;
    uint32 createdAt;
}

struct PortfolioPool {
    uint128 virtualX; // WAD x per WAD liquidity.
    uint128 virtualY; // WAD y per WAD liquidity.
    uint128 liquidity; // Total supply of liquidity.
    uint32 lastTimestamp; // The block.timestamp of the last swap.
    address controller; // Address that can change fee, priorityFee, or jit params.
    uint256 invariantGrowthGlobal; // Cumulative sum of positive invariant growth.
    uint256 feeGrowthGlobalAsset; // Cumulative sum of fee's denominated in the `asset` with positive invariant.
    uint256 feeGrowthGlobalQuote; // Cumulative sum of fee's denominated in the `quote` with positive invariant.
    PortfolioCurve params; // Parameters of the objective's trading function.
    PortfolioPair pair; // Token pair data.
}

struct PortfolioPosition {
    uint128 freeLiquidity;
    uint32 lastTimestamp;
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
    uint8 sellAsset;
}

struct Iteration {
    int256 prevInvariant;
    int256 nextInvariant;
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
    address sellAsset;
    address tokenOutput;
    uint16 fee;
    uint256 feeGrowthGlobal;
    uint256 invariantGrowthGlobal;
}

struct Payment {
    address token;
    uint256 amount;
}

// ===== Effects ===== //

function changePoolLiquidity(
    PortfolioPool storage self,
    int128 liquidityDelta
) {
    self.liquidity = AssemblyLib.addSignedDelta(self.liquidity, liquidityDelta);
}

function syncPoolTimestamp(PortfolioPool storage self, uint256 timestamp) {
    self.lastTimestamp = SafeCastLib.safeCastTo32(timestamp);
}

function changePoolParameters(
    PortfolioPool storage self,
    PortfolioCurve memory updated
) {
    (bool success, ) = updated.validateParameters();
    self.params = updated;
    assert(success);
}

function changePositionLiquidity(
    PortfolioPosition storage self,
    uint256 timestamp,
    int128 liquidityDelta
) {
    self.lastTimestamp = uint32(timestamp);
    self.freeLiquidity = AssemblyLib.addSignedDelta(
        self.freeLiquidity,
        liquidityDelta
    );
}

/**
 * @dev Liquidity must be altered after syncing positions and not before.
 */
function syncPositionFees(
    PortfolioPosition storage self,
    uint256 feeGrowthAsset,
    uint256 feeGrowthQuote,
    uint256 invariantGrowth
)
    returns (
        uint256 feeAssetEarned,
        uint256 feeQuoteEarned,
        uint256 feeInvariantEarned
    )
{
    // fee growth current - position fee growth last
    uint256 differenceAsset = AssemblyLib.computeCheckpointDistance(
        feeGrowthAsset,
        self.feeGrowthAssetLast
    );
    uint256 differenceQuote = AssemblyLib.computeCheckpointDistance(
        feeGrowthQuote,
        self.feeGrowthQuoteLast
    );
    uint256 differenceInvariant = AssemblyLib.computeCheckpointDistance(
        invariantGrowth,
        self.invariantGrowthLast
    );

    // fee growth per liquidity * position liquidity
    feeAssetEarned = FixedPointMathLib.mulWadDown(
        differenceAsset,
        self.freeLiquidity
    );
    feeQuoteEarned = FixedPointMathLib.mulWadDown(
        differenceQuote,
        self.freeLiquidity
    );
    feeInvariantEarned = FixedPointMathLib.mulWadDown(
        differenceInvariant,
        self.freeLiquidity
    );

    self.feeGrowthAssetLast = feeGrowthAsset;
    self.feeGrowthQuoteLast = feeGrowthQuote;
    self.invariantGrowthLast = invariantGrowth;

    self.tokensOwedAsset += SafeCastLib.safeCastTo128(feeAssetEarned);
    self.tokensOwedQuote += SafeCastLib.safeCastTo128(feeQuoteEarned);
    self.invariantOwed += SafeCastLib.safeCastTo128(feeInvariantEarned);
}

// ===== View ===== //

/**
 * @dev Quantity of tokens in units of their native decimals deallocated if all liquidity was removed.
 */
function getPoolVirtualReserves(
    PortfolioPool memory self
) pure returns (uint128 reserveAsset, uint128 reserveQuote) {
    return self.getPoolLiquidityDeltas(-int128(self.liquidity)); // Rounds down.
}

/**
 * @dev Maximum amount of liquidity minted given amounts of each token.
 * @param deltaAsset Quantity of `asset` tokens denominated in their native decimals.
 * @param deltaQuote Quantity of `quote` tokens denominated in their native decimals.
 */
function getPoolMaxLiquidity(
    PortfolioPool memory self,
    uint256 deltaAsset,
    uint256 deltaQuote
) pure returns (uint128 deltaLiquidity) {
    deltaAsset = deltaAsset.scaleToWad(self.pair.decimalsAsset).safeCastTo128();
    deltaQuote = deltaQuote.scaleToWad(self.pair.decimalsQuote).safeCastTo128();

    (uint256 amountAssetWad, uint256 amountQuoteWad) = self.getAmountsWad();
    uint256 liquidity0 = deltaAsset.divWadDown(amountAssetWad); // L_0 = X / (X / L)
    uint256 liquidity1 = deltaQuote.divWadDown(amountQuoteWad); // L_1 = Y / (Y / L)
    deltaLiquidity = AssemblyLib.min(liquidity0, liquidity1).safeCastTo128();
}

/**
 * @dev Rounds positive deltas up. Rounds negative deltas down.
 */
function getPoolLiquidityDeltas(
    PortfolioPool memory self,
    int128 deltaLiquidity
) pure returns (uint128 deltaAsset, uint128 deltaQuote) {
    if (deltaLiquidity == 0) return (deltaAsset, deltaQuote);

    (uint256 amountAssetWad, uint256 amountQuoteWad) = self.getAmountsWad();
    uint256 scaleDownFactorAsset = AssemblyLib.computeScalar(
        self.pair.decimalsAsset
    ) * FixedPointMathLib.WAD;
    uint256 scaleDownFactorQuote = AssemblyLib.computeScalar(
        self.pair.decimalsQuote
    ) * FixedPointMathLib.WAD;

    uint256 delta;
    if (deltaLiquidity > 0) {
        delta = uint128(deltaLiquidity);
        deltaAsset = amountAssetWad
            .mulDivUp(delta, scaleDownFactorAsset)
            .safeCastTo128();
        deltaQuote = amountQuoteWad
            .mulDivUp(delta, scaleDownFactorQuote)
            .safeCastTo128();
    } else {
        delta = uint128(-deltaLiquidity);
        deltaAsset = amountAssetWad
            .mulDivDown(delta, scaleDownFactorAsset)
            .safeCastTo128();
        deltaQuote = amountQuoteWad
            .mulDivDown(delta, scaleDownFactorQuote)
            .safeCastTo128();
    }
}

/**
 * @dev Scales virtual reserves per liquidity from WAD to native token decimal units.
 * @return amountAssetDec Quantity of `asset` tokens in native decimal units per WAD unit of liquidity.
 * @return amountQuoteDec Quantity of `quote` tokens in native decimal units per WAD unit of liquidity.
 */
function getPoolAmounts(
    PortfolioPool memory self
) pure returns (uint256 amountAssetDec, uint256 amountQuoteDec) {
    (uint256 amountAssetWad, uint256 amountQuoteWad) = self.getAmountsWad();
    amountAssetDec = amountAssetWad.scaleFromWadDown(self.pair.decimalsAsset);
    amountQuoteDec = amountQuoteWad.scaleFromWadDown(self.pair.decimalsQuote);
}

/**
 * @dev Virtual reserves of tokens in WAD units per WAD units of liquidity.
 * @return amountAssetWad Quantity of `asset` tokens in WAD units per WAD of liquidity.
 * @return amountQuoteWad Quantity of `quote` tokens in WAD units per WAD of liquidity.
 */
function getAmountsWad(
    PortfolioPool memory self
) pure returns (uint256 amountAssetWad, uint256 amountQuoteWad) {
    amountAssetWad = self.virtualX;
    amountQuoteWad = self.virtualY;
}

// ===== Derived ===== //

function getTimeSinceChanged(
    PortfolioPosition memory self,
    uint256 timestamp
) pure returns (uint256 distance) {
    return timestamp - self.lastTimestamp;
}

function exists(PortfolioPool memory self) pure returns (bool) {
    return self.lastTimestamp != 0;
}

function isMutable(PortfolioPool memory self) pure returns (bool) {
    return self.controller != address(0);
}

function lastTau(PortfolioPool memory self) pure returns (uint256) {
    return self.computeTau(self.lastTimestamp);
}

function computeTau(
    PortfolioPool memory self,
    uint256 timestamp
) pure returns (uint256) {
    uint256 end = self.params.maturity();
    unchecked {
        // Cannot underflow as LHS is either equal to `timestamp` or greater. 
        return AssemblyLib.max(timestamp, end) - timestamp;
    }
}

function maturity(
    PortfolioCurve memory self
) pure returns (uint32 endTimestamp) {
    unchecked {
        // Portfolio duration is limited such that this addition will never overflow 256 bits.
        endTimestamp = (AssemblyLib.convertDaysToSeconds(self.duration) +
            self.createdAt).safeCastTo32();
    }
}

function validateParameters(
    PortfolioCurve memory self
) pure returns (bool, bytes memory) {
    (bool success, bytes memory reason) = self.checkParameters();
    if (!success) {
        assembly {
            revert(add(32, reason), mload(reason))
        }
    }

    return (success, reason);
}

/**
 * @dev Invalid parameters should revert. Bound checks are inclusive.
 */
function checkParameters(
    PortfolioCurve memory self
) pure returns (bool, bytes memory) {
    if (self.jit > JUST_IN_TIME_MAX)
        return (false, abi.encodeWithSelector(InvalidJit.selector, self.jit));
    if (
        !AssemblyLib.isBetween(self.volatility, MIN_VOLATILITY, MAX_VOLATILITY)
    ) {
        return (
            false,
            abi.encodeWithSelector(InvalidVolatility.selector, self.volatility)
        );
    }
    if (!AssemblyLib.isBetween(self.duration, MIN_DURATION, MAX_DURATION)) {
        return (
            false,
            abi.encodeWithSelector(InvalidDuration.selector, self.duration)
        );
    }
    if (!AssemblyLib.isBetween(self.maxPrice, MIN_MAX_PRICE, MAX_MAX_PRICE)) {
        return (
            false,
            abi.encodeWithSelector(InvalidStrike.selector, self.maxPrice)
        );
    }
    if (!AssemblyLib.isBetween(self.fee, MIN_FEE, MAX_FEE)) {
        return (false, abi.encodeWithSelector(InvalidFee.selector, self.fee));
    }
    // 0 priority fee == no controller, impossible to set to zero unless default from non controlled pools.
    if (!AssemblyLib.isBetween(self.priorityFee, 0, self.fee)) {
        return (
            false,
            abi.encodeWithSelector(InvalidFee.selector, self.priorityFee)
        );
    }

    return (true, "");
}
