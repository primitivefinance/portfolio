// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioView is Setup {
    // Uses the negative delta liquidity case, which requires liquidity.
    function test_get_liquidity_deltas()
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        (uint256 deltaAsset, uint256 deltaQuote) =
            subject().getLiquidityDeltas(ghost().poolId, -int128(0.1 ether));
        assertTrue(deltaAsset > 0, "deltaAsset not > 0");
        assertTrue(deltaQuote > 0, "deltaQuote not > 0");
    }

    // Uses the negative delta liquidity case, which requires liquidity.
    function test_get_pool_reserves()
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        (uint256 reserveAsset, uint256 reserveQuote) =
            subject().getPoolReserves(ghost().poolId);
        assertTrue(reserveAsset > 0, "reserveAsset not > 0");
        assertTrue(reserveQuote > 0, "reserveQuote not > 0");
    }

    function test_simulate_swap()
        public
        defaultConfig
        usePairTokens(100 ether)
        allocateSome(1 ether)
    {
        (bool success,,) = subject().simulateSwap({
            order: Order({
                poolId: ghost().poolId,
                sellAsset: true,
                input: 0.01 ether,
                output: 0.001 ether, // works with default config because price is $1
                useMax: false
            }),
            timestamp: block.timestamp,
            swapper: actor()
        });

        assertTrue(success, "simulateSwap failed");
    }
}
