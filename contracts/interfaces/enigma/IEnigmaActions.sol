pragma solidity ^0.8.0;

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
}
