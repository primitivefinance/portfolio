// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/auth/Owned.sol";

interface PortfolioLike {
    function setProtocolFee(uint256) external;
    function claimFee(address, uint256) external;
}

/// @dev Basic registry with a single owner.
contract SimpleRegistry is Owned {
    address public controller;

    constructor() Owned(msg.sender) {
        controller = address(this);
    }

    function setFee(address portfolio, uint256 fee) public onlyOwner {
        PortfolioLike(portfolio).setProtocolFee(fee);
    }

    function claimFee(
        address portfolio,
        address token,
        uint256 amount
    ) public onlyOwner {
        PortfolioLike(portfolio).claimFee(token, amount);
    }

    function withdraw(address token, uint256 amount) public onlyOwner {
        require(amount > 0, "SimpleRegistry/invalid-amount");
        require(
            IERC20(token).transfer(msg.sender, amount),
            "SimpleRegistry/transfer-failed"
        );
    }
}
