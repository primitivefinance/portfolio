// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperFund is TestHyperSetup {
    function testFundIncreasesBalance() public postTestInvariantChecks {
        uint prevBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        __hyperTestingContract__.fund(address(defaultScenario.asset), 4000);
        uint nextBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));

        assertTrue(nextBalance > prevBalance);
    }
}
