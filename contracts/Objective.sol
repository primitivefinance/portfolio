// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./PortfolioLib.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPortfolio.sol";

/**
 * @title   Objective
 * @author  Primitive™
 * @notice  Implements objective specific logic for a Portfolio.
 */
abstract contract Objective is IPortfolio {
    /**
     * @dev Used to apply changes to `_state`.
     */
    function _afterSwapEffects(
        uint64 poolId,
        Iteration memory iteration
    ) internal virtual returns (bool);

    /**
     * @dev Used to apply changes to a `pool`, like it's timestamp, before a swap occurs.
     */
    function _beforeSwapEffects(uint64 poolId)
        internal
        virtual
        returns (bool success, int256 invariant);

    /**
     * @dev Conditional check made before changing `pool.liquidity` and `position.freeLiquidity`.
     * @param delta Signed quantity of liquidity in WAD units to change liquidity by.
     * @return True if position liquidity can be changed by `delta` amount.
     */
    function checkPosition(
        uint64 poolId,
        address owner,
        int256 delta
    ) public view virtual returns (bool);

    /**
     * @dev Conditional check before interacting with a pool.
     */
    function checkPool(uint64 poolId) public view virtual returns (bool);

    /**
     * @dev Computes the invariant given `reserveX` and `reserveY` and returns the invariant condition status.
     */
    function checkInvariant(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY
    ) public view virtual returns (bool success, int256 nextInvariant);

    /**
     * @dev Computes the max amount of tokens that can be swapped into the pool.
     */
    function computeMaxInput(
        uint64 poolId,
        bool sellAsset,
        uint256 reserveIn,
        uint256 liquidity
    ) public view virtual returns (uint256);

    /**
     * @dev Computes the reserves in WAD units using a `price`.
     */
    function computeReservesFromPrice(
        uint64 poolId,
        uint256 price
    ) public view virtual returns (uint256 reserveX, uint256 reserveY);

    /**
     * @dev Computes an amount of tokens out given an amount in, units are in the token's decimals.
     */
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn
    )
        public
        view
        virtual
        override(IPortfolioGetters)
        returns (uint256 output);

    /**
     * @dev Estimates the `price` of a pool with `poolId` given the pool's reserves.
     */
    function getVirtualPrice(uint64 poolId)
        public
        view
        virtual
        returns (uint256 price);
}
