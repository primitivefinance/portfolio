// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestPriceSetup.sol";

contract TestPriceComputeReserves is TestPriceSetup {
    using Price for Price.RMM;

    function testComputedAssetReserveWithDefaultPrice() public {
        uint actual = cases[0].getXWithPrice(DEFAULT_PRICE);
        assertEq(actual, DEFAULT_ASSET_RESERVE);
    }

    function testComputedQuoteReserveWithDefaultAssetReserve() public {
        uint actual = cases[0].getYWithX(DEFAULT_ASSET_RESERVE, 0);
        assertEq(actual, DEFAULT_QUOTE_RESERVE);
    }

    function testComputedAssetReserveWithDefaultQuoteReserve() public {
        uint actual = cases[0].getXWithY(DEFAULT_QUOTE_RESERVE, 0);
        assertEq(actual, DEFAULT_ASSET_RESERVE);
    }

    function testComputedReservesWithDefaultPrice() public {
        (uint actualQuoteReserve, uint actualAssetReserve) = cases[0].computeReserves(DEFAULT_PRICE, 0);
        assertEq(actualQuoteReserve, DEFAULT_QUOTE_RESERVE);
        assertEq(actualAssetReserve, DEFAULT_ASSET_RESERVE);
    }

    function testFuzz_computeReserves_no_reverts(uint price) public {
        vm.assume(price > 0);
        vm.assume(price < type(uint128).max);
        (uint y, uint x) = cases[0].computeReserves(price, 0);
    }
}
