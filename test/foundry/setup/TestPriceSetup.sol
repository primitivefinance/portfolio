// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "contracts/libraries/Price.sol";
import "../helpers/HelperHyperProfiles.sol";

contract TestPriceSetup is HelperHyperProfiles, Test {
    Price.Expiring[] cases;

    function setUp() public {
        addTestCase(DEFAULT_STRIKE, DEFAULT_SIGMA, DEFAULT_MATURITY);
    }

    function addTestCase(uint strike, uint sigma, uint tau) internal returns (Price.Expiring memory) {
        Price.Expiring memory info = Price.Expiring(strike, sigma, tau);
        cases.push(info);
        return info;
    }
}
