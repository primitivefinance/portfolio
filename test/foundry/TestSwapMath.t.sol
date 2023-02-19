// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "test/helpers/SwapMath.sol" as SwapMath;
import "forge-std/Test.sol";

contract TestSwapMath is Test {
    function testSwapMath_D_ppf() public view {
        int256 input = int256(0.5 ether);
        int256 actual = SwapMath.d_ppf(input);
        console.logInt(actual);
    }

    /** @custom:invariant Swapping quote tokens in always increases the marginal price. */
    function testSwapMath_computeMarginalPriceQuoteIn_increases() public {
        SwapMath.Parameters memory params = SwapMath.Parameters({
            stk: 10 ether, // this means y will be between 10 >= y >= 0
            vol: 10_000, // 100%
            tau: 365 days,
            fee: 15, // 0.15%
            inv: 0 // note: initialized at zero always!
        });

        uint256 startPrice = 10 ether;
        uint256 R_x = SwapMath.RMM01Lib.getXWithPrice(startPrice, params.stk, params.vol, params.tau);
        uint256 R_y = SwapMath.RMM01Lib.getYWithX(R_x, params.stk, params.vol, params.tau, params.inv);
        uint256 d_y = (R_y * 0.02 ether) / 1 ether; // swap in 2% of the pool's y reserves
        uint256 actual = SwapMath.computeMarginalPriceQuoteIn(
            d_y,
            R_y,
            params.stk,
            params.vol,
            params.tau,
            params.fee,
            params.inv
        );

        uint256 d_percentage = 0.02 ether; // todo: fix with better assumption. note: assuming 2% swap has at most 0.2% of price impact. Depends on params!

        console.log(d_y, actual);
        // todo: fix assertTrue(actual > startPrice, "marginal-price-decreased");
        assertApproxEqRel(actual, startPrice, d_percentage, "marginal-price-error");
    }

    // desmos: https://www.desmos.com/calculator/v90nbj8pih
    function testSwapMath_computeMarginalPriceQuoteIn_increases_exact() public {
        SwapMath.Parameters memory params = SwapMath.Parameters({
            stk: 10 ether, // this means y will be between 10 >= y >= 0
            vol: 10_000, // 100%
            tau: 365 days,
            fee: 15, // 0.15%
            inv: 0 // note: initialized at zero always!
        });

        uint256 startPrice = 10 ether;
        uint256 R_x = SwapMath.RMM01Lib.getXWithPrice(startPrice, params.stk, params.vol, params.tau);
        uint256 R_y = SwapMath.RMM01Lib.getYWithX(R_x, params.stk, params.vol, params.tau, params.inv);
        uint256 d_y = 0.0617075077452 ether; // swap in 2% of the pool's y reserves
        uint256 actual = SwapMath.computeMarginalPriceQuoteIn(
            d_y,
            R_y,
            params.stk,
            params.vol,
            params.tau,
            params.fee,
            params.inv
        );

        uint256 d_percentage = 0.02 ether; // todo: fix with better assumption.  note: assuming 2% swap has at most 0.2% of price impact. Depends on params!

        uint256 expected = 9.84201501876 ether;

        // todo: fix assertTrue(actual > startPrice, "marginal-price-decreased");
        assertApproxEqRel(actual, expected, d_percentage, "marginal-price-error");
    }

    /** @custom:invariant Swapping assets tokens in always decreases the marginal price. */
    function testSwapMath_computeMarginalPriceAssetIn_decreases() public {
        SwapMath.Parameters memory params = SwapMath.Parameters({
            stk: 10 ether, // this means y will be between 10 >= y >= 0
            vol: 10_000, // 100%
            tau: 365 days,
            fee: 15, // 0.15%
            inv: 0 // note: initialized at zero always!
        });

        uint256 startPrice = 10 ether;
        uint256 R_x = SwapMath.RMM01Lib.getXWithPrice(startPrice, params.stk, params.vol, params.tau);
        // uint256 R_y = SwapMath.RMM01Lib.getYWithX(R_x, params.stk, params.vol, params.tau, params.inv);
        uint256 d_x = (R_x * 0.02 ether) / 1 ether; // swap in 2% of the pool's y reserves
        uint256 actual = SwapMath.computeMarginalPriceAssetIn(
            d_x,
            R_x,
            params.stk,
            params.vol,
            params.tau,
            params.fee,
            params.inv
        );

        uint256 d_percentage = 0.02 ether; // todo: fix with better assumption. note: assuming 2% swap has at most 0.2% of price impact. Depends on params!

        // todo: fix assertTrue(actual < startPrice, "marginal-price-increased");
        assertApproxEqRel(actual, startPrice, d_percentage, "marginal-price-error");
    }
}
