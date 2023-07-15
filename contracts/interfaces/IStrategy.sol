// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Order } from "../libraries/SwapLib.sol";

/**
 * @title
 * IStrategy
 *
 * @notice
 * Functions implemented by strategy contracts.
 *
 */
interface IStrategy {
    function afterCreate(uint64 poolId, bytes calldata data) external;

    function beforeSwap(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external returns (bool, int256);

    function verifyPool(uint64 poolId) external view returns (bool);

    function verifySwap(
        uint64 poolId,
        int256 invariant,
        uint256 reserveX,
        uint256 reserveY
    ) external view returns (bool, int256);

    function getInvariant(uint64 poolId) external view returns (int256);

    function getSwapInvariants(Order memory order)
        external
        view
        returns (int256, int256);

    function getFees(uint64 poolId)
        external
        view
        returns (uint256 fee, uint256 priorityFee, uint256 protocolFee);

    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) external view returns (uint256 amountOut);

    function getSpotPrice(uint64 poolId)
        external
        view
        returns (uint256 spotPrice);

    function getMaxOrder(
        uint64 poolId,
        bool sellAsset
    ) external view returns (Order memory order);

    function approximateReservesGivenPrice(bytes memory data)
        external
        view
        returns (uint256 reserveX, uint256 reserveY);

    function getStrategyData(
        uint256 strikePriceWad,
        uint256 volatilityBasisPoints,
        uint256 durationSeconds,
        bool isPerpetual,
        uint256 priceWad
    ) external view returns (bytes memory strategyData, uint256, uint256);
}
