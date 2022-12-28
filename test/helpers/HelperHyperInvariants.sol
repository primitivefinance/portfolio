// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {HyperLike} from "./HelperHyperView.sol";

interface ERC20Like {
    function balanceOf(address) external view returns (uint);
}

contract HelperHyperInvariants {
    error SettlementInvariantInvalid(uint, uint);

    function assertSettlementInvariant(
        address hyper,
        address token,
        address[] memory accounts
    ) internal view returns (bool) {
        uint reserve = HyperLike(hyper).getReserve(token);
        uint physical = ERC20Like(token).balanceOf(hyper);
        if (reserve != physical) {
            uint sum;
            // @dev important! could be wrong if we miss an account with an internal balance
            for (uint i; i != accounts.length; ++i) {
                uint balance = HyperLike(hyper).getBalance(accounts[i], token);
                sum += balance;
            }
            if ((reserve + sum) != physical) revert SettlementInvariantInvalid(physical, reserve + sum);
        }

        return true;
    }
}
