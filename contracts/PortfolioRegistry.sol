// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "./interfaces/IERC20.sol";
import "./interfaces/IPortfolioRegistry.sol";
import "solmate/auth/Owned.sol";

interface PortfolioLike {
    function setProtocolFee(uint256) external;
    function claimFee(address, uint256) external;
}

/// @dev Basic registry with a single owner.
contract PortfolioRegistry is IPortfolioRegistry, Owned {
    constructor(address owner_) Owned(owner_) { }

    function controller() external view returns (address) {
        return owner;
    }

    function setFee(address portfolio, uint256 fee) external onlyOwner {
        PortfolioLike(portfolio).setProtocolFee(fee);
    }

    function claimFee(
        address portfolio,
        address token,
        uint256 amount
    ) public onlyOwner {
        PortfolioLike(portfolio).claimFee(token, amount);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "SimpleRegistry/invalid-amount");
        require(
            IERC20(token).transfer(msg.sender, amount),
            "SimpleRegistry/transfer-failed"
        );
    }
}
