// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../../contracts/recipes/SwapMath.sol" as SwapMath;
import "forge-std/Test.sol";

contract TestSwapMath is Test {
    function testSwapMath_D_ppf() public {
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

        uint startPrice = 10 ether;
        uint R_x = SwapMath.Price.getXWithPrice(startPrice, params.stk, params.vol, params.tau);
        uint R_y = SwapMath.Price.getYWithX(R_x, params.stk, params.vol, params.tau, params.inv);
        uint d_y = (R_y * 0.02 ether) / 1 ether; // swap in 2% of the pool's y reserves
        uint actual = SwapMath.computeMarginalPriceQuoteIn(
            d_y,
            R_y,
            R_x,
            params.stk,
            params.vol,
            params.tau,
            params.fee,
            params.inv
        );

        uint d_percentage = 0.002 ether; // note: assuming 2% swap has at most 0.2% of price impact. Depends on params!

        assertTrue(actual > startPrice, "marginal-price-decreased");
        assertApproxEqRel(actual, startPrice, d_percentage, "marginal-price-error");
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

        uint startPrice = 10 ether;
        uint R_x = SwapMath.Price.getXWithPrice(startPrice, params.stk, params.vol, params.tau);
        uint R_y = SwapMath.Price.getYWithX(R_x, params.stk, params.vol, params.tau, params.inv);
        uint d_x = (R_x * 0.02 ether) / 1 ether; // swap in 2% of the pool's y reserves
        uint actual = SwapMath.computeMarginalPriceAssetIn(
            d_x,
            R_y,
            R_x,
            params.stk,
            params.vol,
            params.tau,
            params.fee,
            params.inv
        );

        uint d_percentage = 0.002 ether; // note: assuming 2% swap has at most 0.2% of price impact. Depends on params!

        assertTrue(actual < startPrice, "marginal-price-increased");
        assertApproxEqRel(actual, startPrice, d_percentage, "marginal-price-error");
    }
}
