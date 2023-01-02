// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestPriceSetup.sol";

contract TestPriceComputeReserves is TestPriceSetup {
    using Price for Price.RMM;

    function testComputedAssetReserveWithDefaultPrice() public {
        uint actual = cases[0].computeR2WithPrice(DEFAULT_PRICE);
        assertEq(actual, DEFAULT_ASSET_RESERVE);
    }

    function testComputedQuoteReserveWithDefaultAssetReserve() public {
        uint actual = cases[0].computeR1WithR2(DEFAULT_ASSET_RESERVE);
        assertEq(actual, DEFAULT_QUOTE_RESERVE);
    }

    function testComputedAssetReserveWithDefaultQuoteReserve() public {
        uint actual = cases[0].computeR2WithR1(DEFAULT_QUOTE_RESERVE);
        assertEq(actual, DEFAULT_ASSET_RESERVE);
    }

    function testComputedReservesWithDefaultPrice() public {
        (uint actualQuoteReserve, uint actualAssetReserve) = cases[0].computeReserves(DEFAULT_PRICE);
        assertEq(actualQuoteReserve, DEFAULT_QUOTE_RESERVE);
        assertEq(actualAssetReserve, DEFAULT_ASSET_RESERVE);
    }
}
