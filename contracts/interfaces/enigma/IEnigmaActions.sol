// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IEnigmaActions {
    /// @dev Increases the `msg.sender` account's internal balance of `token`.
    /// @custom:security High. Calls the `token` external contract.
    function fund(address token, uint256 amount) external;

    /// @notice Transfers `amount` of `token` to the `to` account.
    /// @dev Decreases the `msg.sender` account's internal balance of `token`.
    /// @custom:security High. Calls the `token` external contract.
    function draw(
        address token,
        uint256 amount,
        address to
    ) external;

    /// @notice Syncs a pool with `poolId` to the current `block.timestamp`.
    /// @dev Use this method after the pool is expired or else the invariant method will revert.
    /// @custom:security Medium. Alternative method (instead of swapping) of syncing pools to the current timestamp.
    function updateLastTimestamp(uint48 poolId) external returns (uint128 blockTimestamp);

    // TODO: add collect function to collect swap fees
}
