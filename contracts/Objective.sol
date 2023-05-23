// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "./libraries/PortfolioLib.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPortfolio.sol";
import "./interfaces/IPortfolioRegistry.sol";

/**
 * @title   Objective
 * @author  Primitive™
 * @notice  Implements objective specific logic for a Portfolio.
 */
abstract contract Objective is IPortfolio {
    /**
     * @dev Used to apply changes to a `pool`, like it's timestamp, before a swap occurs.
     * @param sellAsset Determines rounding direction for reserves to compute invariant, round Y up (true) or round X up (false).
     * @return success True if pool can be swapped in.
     * @return invariant Current invariant value of the pool in WAD units.
     */
    function _beforeSwapEffects(
        uint64 poolId,
        bool sellAsset
    ) internal virtual returns (bool success, int256 invariant);

    /**
     * @dev Conditional check before interacting with a pool.
     * @return True if pool exists and is ready to be interacted with.
     */
    function checkPool(uint64 poolId) public view virtual returns (bool);

    /**
     * @dev Computes the invariant given `reserveX` and `reserveY` and returns the invariant condition status.
     * @param invariant Last invariant value of the pool in WAD units.
     * @param reserveX Amount of "asset" reserves in WAD units per WAD of liquidity.
     * @param reserveY Amount of "quote" reserves in WAD units per WAD of liquidity.
     * @param timestamp Timestamp at which the invariant condition will be checked. Used to compute time until maturity.
     */
    function checkInvariant(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY,
        uint256 timestamp
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
     * @dev Computes the reserves in WAD units using a `price` in WAD units.
     * @param price Quote tokens per Asset token in WAD units.
     */
    function computeReservesFromPrice(
        uint64 poolId,
        uint256 price
    ) public view virtual returns (uint256 reserveX, uint256 reserveY);

    /// @inheritdoc IPortfolioGetters
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    )
        public
        view
        virtual
        override(IPortfolioGetters)
        returns (uint256 output);

    /// @inheritdoc IPortfolioGetters
    function getSpotPrice(uint64 poolId)
        public
        view
        virtual
        returns (uint256 price);
}
