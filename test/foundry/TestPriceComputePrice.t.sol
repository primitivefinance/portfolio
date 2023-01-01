// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestPriceSetup.sol";

contract TestPriceComputePrice is TestPriceSetup {
    using Price for Price.RMM;

    function testComputedPriceWithDefaultAssetReserve() public {
        uint actual = cases[0].computePriceWithR2(DEFAULT_ASSET_RESERVE);
        uint err = 1e4; // TODO: Fix for error...
        assertTrue(actual <= DEFAULT_PRICE + err && actual >= DEFAULT_PRICE - err);
    }

    // ===== Raw ===== //

    function testComputePriceWithZeroChangeInTauReturnsPrice() public {
        uint price = DEFAULT_PRICE;
        uint actual = cases[0].computePriceWithChangeInTau(price, 0);
        assertEq(actual, price);
    }

    function testComputePriceWithEpsilonEqualsTauReturnsStrike() public {
        Price.RMM memory info = cases[0];
        uint price = DEFAULT_PRICE;
        uint epsilon = info.tau;
        uint actual = info.computePriceWithChangeInTau(price, epsilon);
        assertEq(actual, info.strike);
    }

    function testFuzzComputePriceWithChangeInTau(uint32 epsilon) public {
        Price.RMM memory info = cases[0];
        // Fuzzing Filters
        vm.assume(epsilon > 0); // Fuzzing non-zero test cases only.
        vm.assume(epsilon < info.tau); // Epsilon > tau is the same as epsilon == tau.

        // Behavior: as epsilon gets larger, tau gets smaller, price increases, reaches inflection, price tends to strike after inflection point.
        uint price = DEFAULT_PRICE;
        uint actual = info.computePriceWithChangeInTau(price, epsilon);
        uint actualDiff = actual - info.strike;
        uint expectedDiff = price - info.strike;
        assertTrue(actualDiff > expectedDiff); // maybe? As tau gets smaller, price should increase until epsilon >= tau.
    }

    function testComputePriceWithEpsilonChangeEqualToTauReturnsPrice() public {
        uint price = DEFAULT_PRICE;
        uint actual = cases[0].computePriceWithChangeInTau(price, cases[0].tau);
        assertEq(actual, price);
    }
}
