// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestPriceSetup.sol";

contract TestPriceUtils is TestPriceSetup {
    // ===== Utils ===== //

    function testConvertPercentageReturnsOne() public {
        uint256 percentage = Price.PERCENTAGE;
        uint256 expected = Price.WAD;
        uint256 converted = Price.convertPercentageToWad(percentage);
        assertEq(converted, expected);
    }

    function testFuzzConvertPercentageReturnsComputedValue(uint256 percentage) public {
        vm.assume(percentage < type(uint64).max);
        uint256 expected = (percentage * Price.WAD) / Price.PERCENTAGE;
        uint256 converted = Price.convertPercentageToWad(percentage);
        assertEq(converted, expected);
    }
}
