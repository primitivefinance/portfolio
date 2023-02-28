// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {HyperLike} from "./HelperHyperView.sol";

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
}

contract HelperHyperInvariants {
    error SettlementInvariantInvalid(uint256, uint256);

    function assertSettlementInvariant(
        address hyper,
        address token,
        address[] memory accounts
    ) internal view returns (bool) {
        accounts;

        uint256 reserve = HyperLike(hyper).getReserve(token);
        uint256 physical = ERC20Like(token).balanceOf(hyper);
        if (reserve > physical) revert SettlementInvariantInvalid(physical, reserve);
        return true;
    }
}
