// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestPriceSetup.sol";

contract TestPriceUtils is TestPriceSetup {
    // ===== Utils ===== //

    function testConvertPercentageReturnsOne() public {
        uint percentage = Price.PERCENTAGE;
        uint expected = Price.WAD;
        uint converted = Price.convertPercentageToWad(percentage);
        assertEq(converted, expected);
    }

    function testFuzzConvertPercentageReturnsComputedValue(uint percentage) public {
        vm.assume(percentage < type(uint64).max);
        uint expected = (percentage * Price.WAD) / Price.PERCENTAGE;
        uint converted = Price.convertPercentageToWad(percentage);
        assertEq(converted, expected);
    }
}
