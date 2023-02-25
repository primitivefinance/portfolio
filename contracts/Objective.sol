// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./HyperLib.sol";
import "./interfaces/IHyper.sol";
import "./interfaces/IERC20.sol";

/**
 * @notice Virtual interface to implement the logic for a "Portfolio".
 */
abstract contract Objective is IHyper {
    // ===== Internal Effects ===== //
    /**
     * @dev Used to apply changes to `_state`.
     */
    function _afterSwapEffects(uint64 poolId, Iteration memory iteration) internal virtual returns (bool);

    /**
     * @dev Used to apply changes to a `pool`, like it's timestamp, before a swap occurs.
     */
    function _beforeSwapEffects(uint64 poolId) internal virtual returns (bool success, int256 invariant);

    /**
     * @dev Conditional check made before changing `pool.liquidity` and `position.freeLiquidity`..
     */
    function checkPosition(
        HyperPool memory pool,
        HyperPosition memory position,
        int256 delta
    ) public view virtual returns (bool);

    /**
     * @dev Conditional check before interacting with a pool.
     */
    function checkPool(HyperPool memory pool) public view virtual returns (bool);

    /**
     * @dev Computes the invariant given `reserve0` and `reserve1` and returns the invariant condition status.
     */
    function checkInvariant(
        HyperPool memory pool,
        int256 invariant,
        uint reserve0,
        uint reserve1
    ) public view virtual returns (bool success, int nextInvariant);

    /**
     * @dev Computes the max amount of tokens that can be swapped into the pool.
     */
    function computeMaxInput(
        HyperPool memory pool,
        bool direction,
        uint reserveIn,
        uint liquidity
    ) public view virtual returns (uint);

    /**
     * @dev Computes the reserves in WAD units using a `price`.
     */
    function computeReservesFromPrice(
        HyperPool memory pool,
        uint price
    ) public view virtual returns (uint reserve0, uint reserve1);

    /**
     * @dev Computes an amount of tokens out in units of the token's decimals given an amount in.
     */
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn
    ) public view virtual override(IHyperGetters) returns (uint256 output);

    /**
     * @dev Estimates the `price` of a pool with `poolId` given the pool's reserves.
     */
    function getLatestEstimatedPrice(uint64 poolId) public view virtual returns (uint price);
}
