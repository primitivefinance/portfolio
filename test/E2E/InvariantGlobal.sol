// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/InvariantTargetContract.sol";

bytes32 constant SLOT_LOCKED = bytes32(uint(5));

contract InvariantGlobal is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    function invariant_global() public {
        bytes32 locked = vm.load(address(__hyper__), SLOT_LOCKED);
        assertEq(uint(locked), 1, "invariant-locked");

        (bool prepared, bool settled) = __hyper__.__account__();
        assertTrue(!prepared, "invariant-prepared");
        assertTrue(settled, "invariant-settled");

        uint balance = address(__hyper__).balance;
        assertEq(balance, 0, "invariant-ether");

        (uint reserve, uint physical, uint balances) = getBalances(address(__asset__));
        assertTrue(physical >= reserve + balances, "invariant-asset-physical-balance");

        (reserve, physical, balances) = getBalances(address(__quote__));
        assertTrue(physical >= reserve + balances, "invariant-quite-physical-balance");
    }

    function getBalances(address token) internal view returns (uint reserve, uint physical, uint balances) {
        reserve = getReserve(address(__hyper__), token);
        physical = getPhysicalBalance(address(__hyper__), token);
        balances = getBalanceSum(address(__hyper__), token, ctx.users());
    }
}
