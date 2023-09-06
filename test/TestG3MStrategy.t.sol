// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";
import { GeometricMeanStrategy } from
    "../contracts/strategies/GeometricMeanStrategy.sol";

function validateG3MStrategy(Configuration memory config) pure returns (bool) {
    config; // do nothing, but can add validation later.
    return true;
}

contract TestG3MStrategy is Setup {
    address public G3M;

    function setUp() public override {
        super.setUp();

        G3M = address(new GeometricMeanStrategy(address(subject())));
    }

    modifier startup() {
        // note The configure() does NOT set the following:
        // - asset
        // - quote
        // - reserveXPerWad
        // - strategyArgs
        // So we need to override these with what we want.
        // It also sets the strategy contract to the default strategy.
        Configuration memory config = configure();

        // Get the strategy data.
        uint256 assetWeightWad = 0.75 ether;
        uint256 quoteWeightWad = 1 ether - assetWeightWad;
        uint256 initialPrice = 1 ether;
        uint256 initialAssets = 1 ether;
        (bytes memory strategyArgs, uint256 reserveX, uint256 reserveY) =
        GeometricMeanStrategy(G3M).getStrategyData({
            assetWeightWad: assetWeightWad,
            quoteWeightWad: quoteWeightWad,
            priceWad: initialPrice,
            assetInWad: initialAssets
        });

        // Override config with the strategy info & data.
        config.strategy = G3M;
        config.strategyArgs = strategyArgs;
        config.reserveXPerWad = reserveX;
        config.reserveYPerWad = reserveY;

        // Activate the config.
        (address asset, address quote) = deployDefaultTokenPair();
        if (config.asset == address(0)) config.asset = asset;
        if (config.quote == address(0)) config.quote = quote;

        // Makes it accessible for debugging via `Setup.global_config()`.
        _global_config = config;

        // Creates a pool with poolId and sets the ghost pool id.
        setGhostPoolId(config.activate(address(subject()), validateG3MStrategy));
        _;
    }

    function test_g3m()
        public
        useActor
        startup
        usePairTokens(10 ether)
        allocateSome(1 ether)
        swapSome(0.1 ether, true)
        deallocateSome(0.5 ether)
        swapSome(0.05 ether, false)
    {
        // modifiers, awesome!
    }
}
