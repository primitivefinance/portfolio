// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "contracts/libraries/RMM01Lib.sol";
import "contracts/test/RMM01ExtendedLib.sol";
import "test/helpers/HelperHyperProfiles.sol";

contract TestPriceSetup is HelperHyperProfiles, Test {
    RMM01Lib.RMM[] cases;

    function setUp() public {
        addTestCase(DEFAULT_STRIKE, DEFAULT_SIGMA, DEFAULT_MATURITY);
    }

    function addTestCase(uint256 strike, uint256 sigma, uint256 tau) internal returns (RMM01Lib.RMM memory) {
        RMM01Lib.RMM memory info = RMM01Lib.RMM(strike, sigma, tau);
        cases.push(info);
        return info;
    }
}
