// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Order } from "../libraries/SwapLib.sol";
import { IPortfolioStrategy } from "./IPortfolio.sol";

/**
 * @title
 * IStrategy
 *
 * @notice
 * Functions implemented by strategy contracts.
 *
 * @dev
 * These functions MUST be implemented by strategy contracts to be compatible with the Portfolio protocol.
 *
 */
interface IStrategy is IPortfolioStrategy {
    // ====== Required ====== //
    // Includes: IPortfolioStrategy

    /**
     * @notice
     * Called by the Portfolio contract after a pool is created.
     *
     * @dev
     * This function MUST return a boolean value to indicate success or failure.
     * The standard for encoding `strategyArgs` is to use abi.encode on a struct that defines
     * the configuration of the strategy. This is a straightforward way to have
     * customize structs for each strategy while maintaining a standard function signature.
     *
     * @param strategyArgs Data used in the pool instatiation process for a strategy.
     * @return success Whether the pool creation was successful.
     */
    function afterCreate(
        uint64 poolId,
        bytes calldata strategyArgs
    ) external returns (bool success);

    /**
     * @notice
     * Called by the Portfolio contract before a swap is executed.
     *
     * @dev
     * This function MUST return a boolean value to indicate whether the swap should proceed.
     *
     * @param sellAsset Whether the asset being sold is the input asset.
     * @param swapper Address executing the swap.
     * @return success Whether the swap should proceed.
     * @return invariant Pre-swap invariant used in `validateSwap`.
     */
    function beforeSwap(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external returns (bool, int256);

    /**
     * @notice
     * Checks if a pool is in the instantiated or active states.
     *
     * @dev
     * This function MUST return a boolean value to indicate whether the pool can be manipulated.
     *
     * @return success Whether the pool is in the instantiated or active states.
     */
    function validatePool(uint64 poolId) external view returns (bool);

    /**
     * @notice
     * Validates a swap using the strategy's implemented trading function.
     *
     * @dev
     * Critical function that is responsible for the economic validity of the protocol.
     *
     * @param invariant Pre-swap invariant returned after the `beforeSwap` call is executed.
     * @param reserveX Reserve of the `asset` token in the pool.
     * @param reserveY Reserve of the `quote` token in the pool.
     * @return success Whether the swap is valid.
     * @return postInvariant Post-swap invariant after the reserves are adjusted from the swap.
     */
    function validateSwap(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY
    ) external view returns (bool, int256);
}
