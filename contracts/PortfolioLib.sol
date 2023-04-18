// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "solmate/utils/SafeCastLib.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "./libraries/AssemblyLib.sol";
import "./libraries/FVMLib.sol" as FVM;
import "./libraries/AccountLib.sol" as Account;

using AssemblyLib for uint256;
using FixedPointMathLib for uint256;
using FixedPointMathLib for uint128;
using FixedPointMathLib for int256;
using SafeCastLib for uint256;

using {
    checkParameters, maturity, validateParameters
} for PortfolioCurve global;
using {
    changePositionLiquidity,
    getTimeSinceChanged
} for PortfolioPosition global;
using {
    changePoolLiquidity,
    changePoolParameters,
    exists,
    getVirtualReservesDec,
    getVirtualReservesWad,
    getPoolLiquidityDeltas,
    getPoolMaxLiquidity,
    getPoolReserves,
    isMutable,
    syncPoolTimestamp,
    lastTau,
    computeTau
} for PortfolioPool global;

uint256 constant BURNED_LIQUIDITY = 1e3;
uint256 constant INIT_LIQUIDITY = 1e18;
uint256 constant PERCENTAGE = 10_000;
uint256 constant MIN_MAX_PRICE = 1;
uint256 constant MAX_MAX_PRICE = type(uint128).max;
uint256 constant MIN_FEE = 1; // 0.01%
uint256 constant MAX_FEE = 1000; // 10%
uint256 constant MIN_VOLATILITY = 100; // 1%
uint256 constant MAX_VOLATILITY = 25_000; // 250%
uint256 constant MIN_DURATION = 1; // days, but without units
uint256 constant MAX_DURATION = 500; // days, but without units
uint256 constant JUST_IN_TIME_MAX = 600 seconds;
uint256 constant JUST_IN_TIME_LIQUIDITY_POLICY = 4 seconds;

error DrawBalance();
error InsufficientLiquidity();
error InvalidDecimals(uint8 decimals);
error InvalidDuration(uint16);
error InvalidFee(uint16 fee);
error InvalidPriorityFee(uint16 priorityFee);
error InvalidInstruction();
error InvalidInvariant(int256 prev, int256 next);
error InvalidJit(uint16);
error InvalidPair();
error InvalidReentrancy();
error InvalidSettlement();
error InvalidStrike(uint128 strike);
error InvalidTransfer();
error InvalidVolatility(uint16 sigma);
error JitLiquidity(uint256 distance);
error NegativeBalance(address token, int256 net);
error NotController();
error NonExistentPool(uint64 poolId);
error NonExistentPosition(address owner, uint64 poolId);
error NotExpiringPool();
error PairExists(uint24 pairId);
error PoolExpired();
error SameTokenError();
error SwapInputTooSmall();
error ZeroAmounts();
error ZeroInput();
error ZeroLiquidity();
error ZeroOutput();
error ZeroPrice();
error ZeroValue();
error MaxDeltaReached();
error MinDeltaUnmatched();
error InvalidNegativeLiquidity();

struct PortfolioPair {
    address tokenAsset; // Base asset, referred to as "X" reserve.
    uint8 decimalsAsset;
    address tokenQuote; // Quote asset, referred to as "Y" reserve.
    uint8 decimalsQuote;
}

struct PortfolioCurve {
    // single slot
    uint128 maxPrice; // Can be used as a terminal price (max price that can be reached by maturity).
    uint16 jit; // Set to a default value in seconds for non-controlled pools.
    uint16 fee; // Can be manipulated by a controller of a pool, if there is one.
    uint16 duration; // Set to max duration for perpetual pools.
    uint16 volatility; // Effects the pool like an amplification factor, increasing price impact of swaps.
    uint16 priorityFee; // Only set for controlled pools, and can be changed by controller.
    uint32 createdAt; // Set to the `block.timestamp` on pool creation.
    bool perpetual; // Set to `true` if the `duration` variable in pool creation is the magic variable type(uint16).max.
}

struct PortfolioPool {
    uint128 virtualX; // Total X reserves in WAD units for all liquidity.
    uint128 virtualY; // Total Y reserves in WAD units for all liquidity.
    uint128 liquidity; // Total supply of liquidity.
    uint32 lastTimestamp; // The block.timestamp of the last swap.
    address controller; // Address that can change fee, priorityFee, or jit params.
    PortfolioCurve params; // Parameters of the objective's trading function.
    PortfolioPair pair; // Token pair data.
}

struct PortfolioPosition {
    uint128 freeLiquidity; // Liquidity owned by the position owner in WAD units.
    uint32 lastTimestamp; // The block.timestamp of the last position update.
}

struct ChangeLiquidityParams {
    address owner;
    uint64 poolId;
    uint256 timestamp;
    uint256 deltaAsset; // Quantity of asset tokens in WAD units to add or remove.
    uint256 deltaQuote; // Quantity of quote tokens in WAD units to add or remove.
    address tokenAsset; // Address of the asset token.
    address tokenQuote; // Address of the quote token.
    int128 deltaLiquidity; // Quantity of liquidity tokens in WAD units to add or remove.
}

struct Order {
    uint8 useMax; // Use the transiently stored `balance` for the `input`.
    uint64 poolId;
    uint128 input; // Quantity of asset tokens in WAD units to swap in, adding to reserves.
    uint128 output; // Quantity of quote tokens in WAD units to swap out, removing from reserves.
    uint8 sellAsset; // 0 = quote -> asset, 1 = asset -> quote.
}

struct Iteration {
    int256 prevInvariant; // Invariant of the pool before the swap, after timestamp update.
    int256 nextInvariant; // Invariant of the pool after the swap.
    uint256 virtualX; // Virtual X reserves in WAD units for all liquidity.
    uint256 virtualY; // Virtual Y reserves in WAD units for all liquidity.
    uint256 remainder; // Remainder of input tokens to swap in, in WAD units.
    uint256 feeAmount; // Fee amount in WAD units.
    uint256 protocolFeeAmount; // WAD
    uint256 liquidity; // Total supply of liquidity in WAD units.
    uint256 input;
    uint256 output;
}

struct SwapState {
    bool sell;
    address tokenInput;
    uint16 fee;
    address tokenOutput;
}

struct Payment {
    address token;
    uint256 amountTransferTo; // Amount to transfer to the `msg.sender` in `settlement`, in WAD.
    uint256 amountTransferFrom; // Amount to transfer from the `msg.sender` in `settlement`, in WAD.
    uint256 balance; // Current `token.balanceOf(address(this))` in `settlement`, in native token decimals.
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
    // Reverts on invalid parameters.
    updated.validateParameters();
    self.params = updated;
}

function changePositionLiquidity(
    PortfolioPosition storage self,
    uint256 timestamp,
    int128 liquidityDelta
) {
    self.lastTimestamp = uint32(timestamp);
    self.freeLiquidity =
        AssemblyLib.addSignedDelta(self.freeLiquidity, liquidityDelta);
}

// ===== View ===== //

/**
 * @dev Quantity of tokens in WAD units if all liquidity was removed.
 * @return reserveAsset Real `asset` tokens removed from pool, denominated in WAD.
 * @return reserveQuote Real `quote` tokens removed from pool, denominated in WAD.
 */
function getPoolReserves(PortfolioPool memory self)
    pure
    returns (uint128 reserveAsset, uint128 reserveQuote)
{
    // Check if -`self.liquidity` fits within an int128
    if (self.liquidity > 2 ** 127 - 1) revert InvalidNegativeLiquidity();
    return self.getPoolLiquidityDeltas(
        -int128(self.liquidity == 0 ? uint128(INIT_LIQUIDITY) : self.liquidity)
    ); // Rounds down.
}

/**
 * @dev Maximum amount of liquidity minted given amounts of each token.
 * @param deltaAsset Up to quantity of `asset` tokens used to mint liquidity, denominated in WAD.
 * @param deltaQuote Up to quantity of `quote` tokens used to mint liquidity, denominated in WAD.
 */
function getPoolMaxLiquidity(
    PortfolioPool memory self,
    uint256 deltaAsset,
    uint256 deltaQuote
) pure returns (uint128 deltaLiquidity) {
    uint256 totalLiquidity = self.liquidity;
    if (totalLiquidity == 0) totalLiquidity = INIT_LIQUIDITY; // use 1E18 of liquidity

    (uint256 amountAssetWad, uint256 amountQuoteWad) =
        self.getVirtualReservesWad();
    uint256 liquidity0 = deltaAsset.mulDivDown(totalLiquidity, amountAssetWad); // L_0 = dX * L / X
    uint256 liquidity1 = deltaQuote.mulDivDown(totalLiquidity, amountQuoteWad); // L_1 = dY * L / Y
    deltaLiquidity = AssemblyLib.min(liquidity0, liquidity1).safeCastTo128();
}

/**
 * @dev Rounds positive deltas up. Rounds negative deltas down.
 * @return deltaAsset Real `asset` tokens underlying `deltaLiquidity`, denominated in WAD.
 * @return deltaQuote Real `quote` tokens underlying `deltaLiquidity`, denominated in WAD.
 */
function getPoolLiquidityDeltas(
    PortfolioPool memory self,
    int128 deltaLiquidity
) pure returns (uint128 deltaAsset, uint128 deltaQuote) {
    if (deltaLiquidity == 0) return (deltaAsset, deltaQuote);

    uint256 delta;
    uint256 totalLiquidity = self.liquidity;
    (uint256 amountAssetWad, uint256 amountQuoteWad) =
        self.getVirtualReservesWad();

    // Pre-allocate pools initialize reserves to 1E18 of liquidity to
    // compute the first allocate quantities.
    if (self.liquidity == 0) {
        totalLiquidity = 1e18;
    }

    if (deltaLiquidity > 0) {
        // If allocating liquidity, round token amounts up.
        delta = uint128(deltaLiquidity);
        deltaAsset =
            delta.mulDivUp(amountAssetWad, totalLiquidity).safeCastTo128();
        deltaQuote =
            delta.mulDivUp(amountQuoteWad, totalLiquidity).safeCastTo128();
    } else {
        // If deallocating liquidity, round token amounts down.
        delta = uint128(-deltaLiquidity);
        deltaAsset =
            delta.mulDivDown(amountAssetWad, totalLiquidity).safeCastTo128();
        deltaQuote =
            delta.mulDivDown(amountQuoteWad, totalLiquidity).safeCastTo128();
    }
}

/**
 * @dev Scales virtual reserves from WAD to native token decimal units.
 * @return amountAssetDec Virtual `asset` tokens tracked, scaled to native decimal units.
 * @return amountQuoteDec Virtual `quote` tokens tracked, scaled to native decimal units.
 */
function getVirtualReservesDec(PortfolioPool memory self)
    pure
    returns (uint128 amountAssetDec, uint128 amountQuoteDec)
{
    (uint256 amountAssetWad, uint256 amountQuoteWad) =
        self.getVirtualReservesWad();
    amountAssetDec =
        amountAssetWad.scaleFromWadDown(self.pair.decimalsAsset).safeCastTo128();
    amountQuoteDec =
        amountQuoteWad.scaleFromWadDown(self.pair.decimalsQuote).safeCastTo128();
}

/**
 * @dev Virtual reserves of tokens in WAD units.
 * @return amountAssetWad Virtual `asset` tokens tracked, in WAD units.
 * @return amountQuoteWad Virtual `quote` tokens tracked, in WAD units.
 */
function getVirtualReservesWad(PortfolioPool memory self)
    pure
    returns (uint128 amountAssetWad, uint128 amountQuoteWad)
{
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
    if (self.params.perpetual) return SECONDS_PER_YEAR; // Default to 1 year for perpetual pools.

    uint256 end = self.params.maturity();
    unchecked {
        // Cannot underflow as LHS is either equal to `timestamp` or greater.
        return AssemblyLib.max(timestamp, end) - timestamp;
    }
}

/**
 * @dev Computes the time in seconds until the pool matures.
 * @custom:reverts If pool is perpetual.
 */
function maturity(PortfolioCurve memory self)
    pure
    returns (uint32 endTimestamp)
{
    if (self.perpetual) revert NotExpiringPool();

    unchecked {
        // Portfolio duration is limited such that this addition will never overflow 256 bits.
        endTimestamp = (
            AssemblyLib.convertDaysToSeconds(self.duration) + self.createdAt
        ).safeCastTo32();
    }
}

function validateParameters(PortfolioCurve memory self) pure {
    (bool success, bytes memory reason) = self.checkParameters();
    if (!success) {
        assembly {
            revert(add(32, reason), mload(reason))
        }
    }
}

/**
 * @dev Invalid parameters should revert. Bound checks are inclusive.
 */
function checkParameters(PortfolioCurve memory self)
    pure
    returns (bool, bytes memory)
{
    if (self.jit > JUST_IN_TIME_MAX) {
        return (false, abi.encodeWithSelector(InvalidJit.selector, self.jit));
    }
    if (!AssemblyLib.isBetween(self.volatility, MIN_VOLATILITY, MAX_VOLATILITY))
    {
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
            false, abi.encodeWithSelector(InvalidStrike.selector, self.maxPrice)
        );
    }
    if (!AssemblyLib.isBetween(self.fee, MIN_FEE, MAX_FEE)) {
        return (false, abi.encodeWithSelector(InvalidFee.selector, self.fee));
    }
    // 0 priority fee == no controller, impossible to set to zero unless default from non controlled pools.
    if (!AssemblyLib.isBetween(self.priorityFee, 0, self.fee)) {
        return (
            false,
            abi.encodeWithSelector(
                InvalidPriorityFee.selector, self.priorityFee
                )
        );
    }

    return (true, "");
}
