// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import "solmate/utils/FixedPointMathLib.sol";
import "solmate/utils/SafeCastLib.sol";
import "./AssemblyLib.sol";

using AssemblyLib for uint256;
using FixedPointMathLib for uint256;
using FixedPointMathLib for uint128;
using FixedPointMathLib for int256;
using SafeCastLib for uint256;

type PoolId is uint64;

using PoolIdLib for PoolId global;

/// @dev Helper methods to decode the data encoded in a pool id.
library PoolIdLib {
    /// @dev Pair id is encoded in the first 24-bits.
    function pairId(PoolId poolId) internal pure returns (uint24 id) {
        id = uint24(PoolId.unwrap(poolId) >> 40);
    }

    /// @dev Controlled boolean is between the first 24-bits and last 32-bits.
    function controlled(PoolId poolId) internal pure returns (bool) {
        return uint8(PoolId.unwrap(poolId) >> 32) == 1;
    }

    /// @dev Nonce is encoded in the last 32-bits.
    function nonce(PoolId poolId) internal pure returns (uint32 nonce) {
        nonce = uint32(PoolId.unwrap(poolId));
    }
}

using {
    adjustReserves,
    createPool,
    changePoolLiquidity,
    exists,
    getPoolLiquidityDeltas,
    getPoolMaxLiquidity,
    getPoolReserves,
    isActive,
    isEmpty,
    syncPoolTimestamp
} for PortfolioPool global;

/// @dev Amount of liquidity permanently burned on the first `allocate()` call.
uint256 constant BURNED_LIQUIDITY = 1e9;

/// @dev Used as the pool's liquidity on the first `allocate()` call, because pool's are initialized without liquidity.
uint256 constant INIT_LIQUIDITY = 1e18;

/// @dev Minimum fee and priority fee denominated in basis points.
uint256 constant MIN_FEE = 1; // 0.01%

/// @dev Maximum fee and priority fee denominated in basis points.
uint256 constant MAX_FEE = 1000; // 10%

/// @dev A pool's maximum liquidity cannot exceed 2^127 - 1.
error PoolLib_UpperLiquidityLimit();

error PoolLib_AlreadyCreated();
error PoolLib_InvalidPriorityFee(uint256);
error PoolLib_InvalidFee(uint256);
error PoolLib_InvalidReserveX();
error PoolLib_InvalidReserveY();

// ----------------- //

/**
 * @notice
 * Data structure for tracking the pool's reserves and liquidity.
 *
 * @dev
 * This is the most important data structure since it handles the token amounts of a pool.
 *
 * note
 * Optimized to fit in two storage slots.
 *
 * note Reserves:
 * Pool's reserves are virtual because they track amounts in WAD units (one = 1E18),
 * regardless of tokens' decimals that underly the reserves.
 * This is to keep internal unit denominations consistent throughout the codebase.
 *
 * note Pool State:
 * Pools can implictly be in one of three states and can only transition into the next state:
 * 1. Non-existent: the pool has not been created via `createPool()`.
 * 2. Empty: the pool has been created with `createPool()`, but has no liquidity.
 * 3. Active: the pool has been allocated liquidity via `allocate()`.
 *
 * Once a pool is active, it can never be empty again because a small amount of liquidity is burned.
 * This is to prevent pools from being created and destroyed, or being monopolized by a single user.
 *
 * note Liquidity:
 * Liquidity is tracked in WAD units (one = 1E18). It represents the ownership of a pool's reserves.
 *
 * note Timestamp:
 * The pool's timestamp is updated __only__ on `swap()`.
 * This is to prevent the timestamp from being updated on `allocate()` and `deallocate()`.
 * Updating the timestamp __CAN__ affect the prices offered by the pool.
 * This is entirely dependent on the higher level strategy that implements & inherits Portfolio.sol.
 * The uint32 timestamp will revert with overflow in the year 2106, this is not an issue.
 *
 * @param virtualX Total asset token reserves in WAD units for all liquidity.
 * @param virtualY Total quote token reserves in WAD units for all liquidity.
 * @param liquidity Total supply of liquidity.
 * @param lastTimestamp The block.timestamp of the last `swap()` call.
 * @param feeBasisPoints The swap fee denominated in basis points, where 1 basis point = 0.01%.
 * @param priorityFeeBasisPoints Fee paid by the `controller` if the controller swaps, denominated in basis points.
 * @param controller Address that can change the swap fees.
 * @param strategy Address implementing the strategy.
 */
struct PortfolioPool {
    uint128 virtualX; // Total X reserves in WAD units for all liquidity.
    uint128 virtualY; // Total Y reserves in WAD units for all liquidity.
    uint128 liquidity; // Total supply of liquidity.
    uint32 lastTimestamp; // Updated __only__ on `swap()`.
    uint16 feeBasisPoints;
    uint16 priorityFeeBasisPoints;
    address controller; // Address that can call `changeParameters()`.
    address strategy;
}

// ----------------- //

/// @dev Used in `createPool()` to initialize a pool's state.
function createPool(
    PortfolioPool storage self,
    uint256 reserveX,
    uint256 reserveY,
    uint256 feeBasisPoints,
    uint256 priorityFeeBasisPoints,
    address controller,
    address strategy
) {
    // Check if the pool has already been created.
    if (self.exists()) revert PoolLib_AlreadyCreated();
    self.syncPoolTimestamp(block.timestamp);

    if (reserveX == 0) revert PoolLib_InvalidReserveX();
    self.virtualX = reserveX.safeCastTo128();

    if (reserveY == 0) revert PoolLib_InvalidReserveY();
    self.virtualY = reserveY.safeCastTo128();

    if (!feeBasisPoints.isBetween(MIN_FEE, MAX_FEE)) {
        revert PoolLib_InvalidFee(feeBasisPoints);
    }
    self.feeBasisPoints = feeBasisPoints.safeCastTo16();

    // Controller is not required, so it can remain uninitialized at the zero address.
    bool controlled = controller != address(0);
    if (controlled) {
        if (!priorityFeeBasisPoints.isBetween(MIN_FEE, feeBasisPoints)) {
            revert PoolLib_InvalidPriorityFee(priorityFeeBasisPoints);
        }

        self.controller = controller;
        self.priorityFeeBasisPoints = priorityFeeBasisPoints.safeCastTo16();
    }

    self.strategy = strategy;
}

/// @dev Used in `swap()` to update the pool's timestamp.
function syncPoolTimestamp(PortfolioPool storage self, uint256 timestamp) {
    self.lastTimestamp = SafeCastLib.safeCastTo32(timestamp);
}

/// @dev Modifies the liquidity of a pool.
function changePoolLiquidity(
    PortfolioPool storage self,
    int128 liquidityDelta
) {
    self.liquidity = AssemblyLib.addSignedDelta(self.liquidity, liquidityDelta);
}

/// @dev Applies reserve adjustments after a swap.
function adjustReserves(
    PortfolioPool storage self,
    bool sellAsset,
    uint256 deltaInWad,
    uint256 deltaOutWad
) {
    if (sellAsset) {
        self.virtualX += deltaInWad.safeCastTo128();
        self.virtualY -= deltaOutWad.safeCastTo128();
    } else {
        self.virtualX -= deltaOutWad.safeCastTo128();
        self.virtualY += deltaInWad.safeCastTo128();
    }
}

// ----------------- //

/// @dev True if pool has been created with `createPool()`.
function exists(PortfolioPool memory self) pure returns (bool) {
    return self.lastTimestamp != 0;
}

/// @dev True if pool has been created with `createPool()` but has no liquidity.
function isEmpty(PortfolioPool memory self) pure returns (bool) {
    return self.exists() && self.liquidity == 0;
}

/// @dev True if pool has been allocated liquidity with `allocate()`.
function isActive(PortfolioPool memory self) pure returns (bool) {
    return self.exists() && self.liquidity > 0;
}

// ----------------- //

/**
 * @notice
 * Get the amount of liquidity that can be allocated with a given amount of tokens.
 *
 * @dev
 * Computes the maximum amount of liquidity that can be allocated given an amount of asset and quote tokens.
 * Must be used offchain, or else the pool's reserves can be manipulated to
 * take advantage of this function's reliance on the reserves.
 * This function can be used in conjuction with `getPoolLiquidityDeltas` to compute the maximum `allocate()` for a user.
 *
 * @param deltaAsset Desired amount of `asset` to allocate, denominated in WAD.
 * @param deltaQuote Desired amount of `quote` to allocate, denominated in WAD.
 * @return deltaLiquidity Maximum amount of liquidity that can be minted, denominated in WAD.
 */
function getPoolMaxLiquidity(
    PortfolioPool memory self,
    uint256 deltaAsset,
    uint256 deltaQuote
) pure returns (uint128 deltaLiquidity) {
    // Liquidity can only be minted with a zero amount of the respective reserve is also 0.
    if (deltaAsset == 0 && self.virtualX != 0) return 0;
    if (deltaQuote == 0 && self.virtualY != 0) return 0;

    uint256 liquidity0;
    uint256 liquidity1;

    // Max liquidity amounts can be computed even if the pool is empty, by using the init liquidity.
    uint256 totalLiquidity = self.isEmpty() ? INIT_LIQUIDITY : self.liquidity;
    // Amount of liquidity minted from depositing `deltaAsset`. L_0 = dX * L / X
    if(self.virtualX != 0) liquidity0 = deltaAsset.mulDivDown(totalLiquidity, self.virtualX);  // forgefmt: disable-line
    // Amount of liquidity minted from depositing `deltaQuote`. L_1 = dY * L / Y
    if(self.virtualY != 0) liquidity1 = deltaQuote.mulDivDown(totalLiquidity, self.virtualY);  // forgefmt: disable-line
    // Use the smaller of the two liquidity amounts, which should be used to compute the liquidity deltas.
    deltaLiquidity = AssemblyLib.min(liquidity0, liquidity1).safeCastTo128(); // forgefmt: disable-line
    // When one of the reserves is 0, then liquidity can be minted from only one token being allocated.
    if(deltaLiquidity == 0) AssemblyLib.max(liquidity0, liquidity1).safeCastTo128(); // forgefmt: disable-line
}

/**
 * @notice
 * Get reserves of a pool.
 *
 * @dev
 * Computes the real amount of asset and quote tokens in a pool's reserves by getting
 * the amounts removed from the pool if all liquidity was deallocated.
 *
 * note All reserves for all tokens are in WAD units.
 * Scale the output by the token's decimals to get the real amount of tokens in the pool.
 *
 * @return reserveAsset Real `asset` tokens removed from pool, denominated in WAD.
 * @return reserveQuote Real `quote` tokens removed from pool, denominated in WAD.
 */
function getPoolReserves(PortfolioPool memory self)
    pure
    returns (uint128 reserveAsset, uint128 reserveQuote)
{
    // Check if -`self.liquidity` fits within an int128.
    if (self.liquidity > 2 ** 127 - 1) revert PoolLib_UpperLiquidityLimit();
    // Removing liquidity will round down the output amounts, giving us a floor on the reserves.
    return self.getPoolLiquidityDeltas(-int128(self.liquidity));
}

/**
 * @notice
 * Get amount of tokens that underly a given amount of liquidity.
 *
 * @dev
 * Computes the amount of tokens needed to allocate a given amount of liquidity, rounding up.
 * Computes the amount of tokens deallocated from a given amount of liquidity, rounding down.
 *
 * note
 * Rounding direction is important because it affects the inflows and outflows of tokens.
 * The rounding direction is chosen to favor the pool, not the user. This prevents
 * users from taking advantage of the rounding to extract tokens from the pool.
 *
 * @param deltaLiquidity Quantity of liquidity to allocate (+) or deallocate (-),  in WAD.
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

    if (deltaLiquidity > 0) {
        // If allocating liquidity for the first time, use initialization liquidity.
        if (self.isEmpty()) totalLiquidity = INIT_LIQUIDITY;

        // If allocating liquidity, round token amounts up.
        delta = uint128(deltaLiquidity);
        deltaAsset =
            delta.mulDivUp(self.virtualX, totalLiquidity).safeCastTo128();
        deltaQuote =
            delta.mulDivUp(self.virtualY, totalLiquidity).safeCastTo128();
    } else {
        // If deallocating liquidity, round token amounts down.
        delta = uint128(-deltaLiquidity);
        deltaAsset =
            delta.mulDivDown(self.virtualX, totalLiquidity).safeCastTo128();
        deltaQuote =
            delta.mulDivDown(self.virtualY, totalLiquidity).safeCastTo128();
    }
}

// ----------------- //
