// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/InvariantTargetContract.sol";

contract InvariantWarper is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    function warper(uint amount) external {
        ctx.customWarp(block.timestamp + bound(amount, 1, 365 days));
    }

    function warpAfterMaturity(uint amount) external {
        ctx.customWarp(getCurve(address(__hyper__), uint32(__poolId__)).maturity + 1 days);
    }
}
