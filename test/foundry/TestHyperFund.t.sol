// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperFund is TestHyperSetup {
    function testFundIncreasesBalance() public postTestInvariantChecks {
        uint prevBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        __hyperTestingContract__.fund(address(defaultScenario.asset), 4000);
        uint nextBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));

        assertTrue(nextBalance > prevBalance, "increase-internal-bal");
    }

    function testFuzzFundDrawSuccessful(uint128 amount) public {
        vm.assume(amount > 0);
        _assertFundDraw(amount);
    }

    function _assertFundDraw(uint amount) internal {
        // Preconditions
        defaultScenario.asset.approve(address(__hyperTestingContract__), amount);
        deal(address(defaultScenario.asset), address(this), amount);

        // Execution
        uint preBal = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        HyperState memory prev = getState();
        __hyperTestingContract__.fund(address(defaultScenario.asset), amount);
        HyperState memory post = getState();
        uint postBal = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));

        // Post conditions
        assertTrue(postBal > preBal, "bal-increase");
        assertEq(postBal, preBal + amount, "bal-increase-exact");
        assertEq(post.reserveAsset, prev.reserveAsset + amount, "reserve-increase");
        assertEq(post.physicalBalanceAsset, prev.physicalBalanceAsset + amount, "physical-increase");
        assertEq(post.totalBalanceAsset, prev.totalBalanceAsset + amount, "total-bal-increase");

        __hyperTestingContract__.draw(address(defaultScenario.asset), amount, address(this));
        HyperState memory end = getState();
        uint endBal = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));

        assertEq(endBal, preBal, "reverse-exact-bal");
        assertEq(end.reserveAsset, prev.reserveAsset, "reverse-exact-reserve");
        assertEq(end.physicalBalanceAsset, prev.physicalBalanceAsset, "reverse-exact-physical");
    }
}
