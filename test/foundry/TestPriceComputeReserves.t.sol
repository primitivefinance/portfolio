// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestPriceSetup.sol";

contract TestPriceComputeReserves is TestPriceSetup {
    using RMM01Lib for RMM01Lib.RMM;

    function testComputedAssetReserveWithDefaultPrice() public {
        uint256 actual = cases[0].getXWithPrice(DEFAULT_PRICE);
        assertEq(actual, DEFAULT_ASSET_RESERVE);
    }

    function testComputedQuoteReserveWithDefaultAssetReserve() public {
        uint256 actual = cases[0].getYWithX(DEFAULT_ASSET_RESERVE, 0);
        assertEq(actual, DEFAULT_QUOTE_RESERVE);
    }

    function testComputedAssetReserveWithDefaultQuoteReserve() public {
        uint256 actual = cases[0].getXWithY(DEFAULT_QUOTE_RESERVE, 0);
        assertEq(actual, DEFAULT_ASSET_RESERVE);
    }

    function testComputedReservesWithDefaultPrice() public {
        (uint256 actualQuoteReserve, uint256 actualAssetReserve) = cases[0].computeReserves(DEFAULT_PRICE, 0);
        assertEq(actualQuoteReserve, DEFAULT_QUOTE_RESERVE);
        assertEq(actualAssetReserve, DEFAULT_ASSET_RESERVE);
    }

    function testFuzz_computeReserves_no_reverts(uint256 price) public pure {
        vm.assume(price > 0);
        vm.assume(price < type(uint128).max);
        // (uint256 y, uint256 x) = cases[0].computeReserves(price, 0);
    }
}
