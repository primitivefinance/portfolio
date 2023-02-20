// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/InvariantTargetContract.sol";

contract InvariantFundDraw is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    function fund_asset(uint256 amount, uint256 index) public {
        amount = bound(amount, 1, 1e36);

        address target = ctx.getRandomUser(index);

        // If net balance > 0, there are tokens in the contract which are not in a pool or balance.
        // They will be credited to the msg.sender of the next call.
        int256 netAssetBalance = __hyper__.getNetBalance(address(__asset__));
        int256 netQuoteBalance = __hyper__.getNetBalance(address(__quote__));
        assertTrue(netAssetBalance >= 0, "negative-net-asset-tokens");
        assertTrue(netQuoteBalance >= 0, "negative-net-quote-tokens");

        vm.prank(target);
        __asset__.approve(address(__hyper__), amount);
        deal(address(__asset__), target, amount);

        uint256 preRes = getReserve(address(__hyper__), address(__asset__));
        uint256 preBal = getBalance(address(__hyper__), target, address(__asset__));
        vm.prank(target);
        __hyper__.fund(address(__asset__), amount);
        uint256 postRes = getReserve(address(__hyper__), address(__asset__));
        uint256 postBal = getBalance(address(__hyper__), target, address(__asset__));

        assertEq(postBal, preBal + amount + uint256(netAssetBalance), "fund-delta-asset-balance");
        assertEq(postRes, preRes + amount + uint256(netQuoteBalance), "fund-delta-asset-reserve");
    }

    function fund_quote(uint256 amount, uint256 index) public {
        amount = bound(amount, 1, 1e36);

        address target = ctx.getRandomUser(index);

        vm.prank(target);
        __quote__.approve(address(__hyper__), amount);
        deal(address(__quote__), target, amount);

        uint256 preRes = getReserve(address(__hyper__), address(__quote__));
        uint256 preBal = getBalance(address(__hyper__), target, address(__quote__));
        vm.prank(target);
        __hyper__.fund(address(__quote__), amount);
        uint256 postRes = getReserve(address(__hyper__), address(__quote__));
        uint256 postBal = getBalance(address(__hyper__), target, address(__quote__));

        assertEq(postBal, preBal + amount, "fund-delta-quote-balance");
        assertEq(postRes, preRes + amount, "fund-delta-quote-reserve");
    }
}
