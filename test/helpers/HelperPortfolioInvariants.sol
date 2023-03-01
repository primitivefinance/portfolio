// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {PortfolioLike} from "./HelperPortfolioView.sol";

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
}

contract HelperPortfolioInvariants {
    error SettlementInvariantInvalid(uint256, uint256);

    function assertSettlementInvariant(
        address portfolio,
        address token,
        address[] memory accounts
    ) internal view returns (bool) {
        accounts;

        uint256 reserve = PortfolioLike(portfolio).getReserve(token);
        uint256 physical = ERC20Like(token).balanceOf(portfolio);
        if (reserve > physical) revert SettlementInvariantInvalid(physical, reserve);
        return true;
    }
}
