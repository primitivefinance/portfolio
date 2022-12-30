// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/InvariantTargetContract.sol";

contract InvariantFundDraw is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    function fund_asset(uint amount) public {
        amount = bound(amount, 1, 1e36);

        __asset__.approve(address(__hyper__), amount);
        deal(address(__asset__), address(this), amount);

        uint preRes = getReserve(address(__hyper__), address(__asset__));
        uint preBal = getBalance(address(__hyper__), address(this), address(__asset__));
        __hyper__.fund(address(__asset__), amount);
        uint postRes = getReserve(address(__hyper__), address(__asset__));
        uint postBal = getBalance(address(__hyper__), address(this), address(__asset__));

        assertEq(postBal, preBal + amount, "fund-delta-asset-balance");
        assertEq(postRes, preRes + amount, "fund-delta-asset-reserve");
    }

    function fund_quote(uint amount) public {
        amount = bound(amount, 1, 1e36);

        __quote__.approve(address(__hyper__), amount);
        deal(address(__quote__), address(this), amount);

        uint preRes = getReserve(address(__hyper__), address(__quote__));
        uint preBal = getBalance(address(__hyper__), address(this), address(__quote__));
        __hyper__.fund(address(__quote__), amount);
        uint postRes = getReserve(address(__hyper__), address(__quote__));
        uint postBal = getBalance(address(__hyper__), address(this), address(__quote__));

        assertEq(postBal, preBal + amount, "fund-delta-quote-balance");
        assertEq(postRes, preRes + amount, "fund-delta-quote-reserve");
    }
}
