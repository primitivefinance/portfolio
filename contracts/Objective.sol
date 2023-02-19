// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./HyperLib.sol";
import "./interfaces/IHyper.sol";
import "./interfaces/IERC20.sol";

/**
 * @notice Virtual interface to implement the logic for a "Portfolio".
 */
abstract contract Objective is IHyper {
    function afterSwapEffects(uint64 poolId, Iteration memory iteration) internal virtual returns (bool);

    function beforeSwap(uint64 poolId) internal virtual returns (bool success, int256 invariant);

    function canUpdatePosition(
        HyperPool memory pool,
        HyperPosition memory position,
        int256 delta
    ) public view virtual returns (bool);

    function checkPool(HyperPool memory pool) public view virtual returns (bool);

    function checkInvariant(
        HyperPool memory pool,
        int256 invariant,
        uint reserve0,
        uint reserve1
    ) public view virtual returns (bool success, int nextInvariant);

    function computeMaxInput(
        HyperPool memory pool,
        bool direction,
        uint reserveIn,
        uint liquidity
    ) public view virtual returns (uint);

    function computeReservesFromPrice(
        HyperPool memory pool,
        uint price
    ) public view virtual returns (uint reserve0, uint reserve1);

    function estimatePrice(uint64 poolId) public view virtual returns (uint price);

    function getReserves(HyperPool memory pool) public view virtual returns (uint reserve0, uint reserve1);

    function _estimateAmountOut(
        HyperPool memory pool,
        bool sellAsset,
        uint amountIn
    ) internal view virtual returns (uint output);

    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn
    ) public view virtual override(IHyperGetters) returns (uint256 output);
}
