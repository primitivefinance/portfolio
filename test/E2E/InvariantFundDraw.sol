// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/InvariantTargetContract.sol";

contract InvariantFundDraw is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    function fund(uint amount) public {
        amount = bound(amount, 1, 1e36);

        __asset__.approve(address(__hyper__), amount);
        deal(address(__asset__), address(this), amount);
        __hyper__.fund(address(__asset__), amount);
    }
}
