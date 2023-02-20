// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperDraw is TestHyperSetup {
    function testDrawReducesBalance() public postTestInvariantChecks {
        // Fund the account
        __hyperTestingContract__.fund(address(defaultScenario.asset), 4000);

        // Draw
        uint256 prevReserve = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        uint256 prevBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        __hyperTestingContract__.draw(address(defaultScenario.asset), 4000, address(this));
        uint256 nextBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        uint256 nextReserve = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));

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
        uint256 prevBalance = address(this).balance;
        __hyperTestingContract__.draw(address(__weth__), 4000, address(this));
        uint256 nextBalance = address(this).balance;

        assertTrue(nextBalance > prevBalance);
    }

    function test_draw_max_balance() public {
        __hyperTestingContract__.fund(address(defaultScenario.asset), 4000);

        uint256 prevBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        __hyperTestingContract__.draw(address(defaultScenario.asset), type(uint256).max, address(this));
        uint256 nextBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));

        assertTrue(prevBalance > 0, "fund-unsuccessful");
        assertEq(nextBalance, 0, "did-not-withdraw-max");
    }
}
