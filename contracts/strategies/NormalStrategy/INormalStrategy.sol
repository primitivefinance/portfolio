// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../../interfaces/IStrategy.sol";

/**
 * @title
 * INormalStrategy
 *
 * @notice
 * Interface for the Normal Distribution Liquidity Strategy.
 */
interface INormalStrategy is IStrategy {
    /// @dev Emitted when this contract is created.
    event Genesis(address indexed portfolio);

    /// @dev Emitted after a pool is created with a config.
    event AfterCreate(
        address indexed portfolio,
        uint64 indexed poolId,
        uint256 strikePriceWad,
        uint256 volatilityBasisPoints,
        uint256 durationSeconds,
        bool isPerpetual
    );

    /**
     * @notice
     * Gets reserves of a pool which have a reported price equal to the given price.
     *
     * @dev
     * Uses approximated math functions to estimate the reserves at a given price,
     * however, the approximations have error that is propogated to the result.
     *
     * @param priceWad Price of the asset token per quote token, in WAD units.
     * @param strategyArgs Encoded configuration of the Normal Strategy parameters.
     * @return reserveX Approximated X reserves of a pool in WAD units, per WAD liquidity.
     * @return reserveY Approximated Y reserves of a pool in WAD units, per WAD liquidity.
     */
    function approximateReservesGivenPrice(
        uint256 priceWad,
        bytes memory strategyArgs
    ) external view returns (uint256 reserveX, uint256 reserveY);

    function getStrategyData(
        uint256 strikePriceWad,
        uint256 volatilityBasisPoints,
        uint256 durationSeconds,
        bool isPerpetual,
        uint256 priceWad
    ) external view returns (bytes memory strategyData, uint256, uint256);
}
