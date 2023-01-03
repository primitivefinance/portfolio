// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperDraw is TestHyperSetup {
    function testDrawReducesBalance() public postTestInvariantChecks {
        // Fund the account
        __hyperTestingContract__.fund(address(defaultScenario.asset), 4000);

        // Draw
        uint prevReserve = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        uint prevBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        __hyperTestingContract__.draw(address(defaultScenario.asset), 4000, address(this));
        uint nextBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        uint nextReserve = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));

        assertTrue(nextBalance == 0);
        assertTrue(nextBalance < prevBalance);
        assertTrue(nextReserve < prevReserve);
    }

    function testDrawRevertsWithDrawBalance() public {
        vm.expectRevert(DrawBalance.selector);
        __hyperTestingContract__.draw(address(defaultScenario.asset), 1e18, address(this));
    }

    function testDrawFromWethTransfersEther() public postTestInvariantChecks {
        // First fund the account
        __hyperTestingContract__.deposit{value: 4000}();

        // Draw
        uint prevBalance = address(this).balance;
        __hyperTestingContract__.draw(address(__weth__), 4000, address(this));
        uint nextBalance = address(this).balance;

        assertTrue(nextBalance > prevBalance);
    }
}
