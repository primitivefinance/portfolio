// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestE2ESetup.sol";

contract TestE2EFundDraw is TestE2ESetup {
    function invariantFuzzFundDrawSuccessful() public withGlobalInvariants {
        uint amount = 1239423423e21;
        vm.assume(amount < type(uint).max);
        vm.assume(amount > 0);

        // Preconditions
        __asset__.approve(address(__hyper__), amount);
        deal(address(__asset__), address(this), amount);

        // Execution
        uint preBal = getBalance(address(__hyper__), address(this), address(__asset__));
        State memory prev = getState();
        __hyper__.fund(address(__asset__), amount);
        State memory post = getState();
        uint postBal = getBalance(address(__hyper__), address(this), address(__asset__));

        // Post conditions
        assertTrue(postBal > preBal, "bal-increase");
        assertEq(postBal, preBal + amount, "bal-increase-exact");
        assertEq(post.reserveAsset, prev.reserveAsset + amount, "reserve-increase");
        assertEq(post.physicalBalanceAsset, prev.physicalBalanceAsset + amount, "physical-increase");
        assertEq(post.totalBalanceAsset, prev.totalBalanceAsset + amount, "total-bal-increase");

        __hyper__.draw(address(__asset__), amount, address(this));
        State memory end = getState();
        uint endBal = getBalance(address(__hyper__), address(this), address(__asset__));

        assertEq(endBal, preBal, "reverse-exact-bal");
        assertEq(end.reserveAsset, prev.reserveAsset, "reverse-exact-reserve");
        assertEq(end.physicalBalanceAsset, prev.physicalBalanceAsset, "reverse-exact-physical");
    }

    function fund(uint amount) public {
        __asset__.approve(address(__hyper__), amount);
        deal(address(__asset__), address(this), amount);
        __hyper__.fund(address(__asset__), amount);
    }
}
