// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "openzeppelin/utils/Base64.sol";
import "solmate/tokens/ERC1155.sol";
import "../contracts/libraries/AssemblyLib.sol";
import "./Setup.sol";

contract TestPortfolioUri is Setup {
    function test_uri() public defaultConfig useActor usePairTokens(10 ether) {
        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            1 ether,
            type(uint128).max,
            type(uint128).max
        );

        string memory uri = ERC1155(address(subject())).uri(ghost().poolId);
        console.log(uri);
    }

    function test_metadata() public {
        address asset = address(new MockERC20("Ethereum", "ETH", 18));
        address quote = address(new MockERC20("USD Coin", "USDC", 6));
        uint24 pairId = subject().createPair(asset, quote);

        uint256 strikePriceWad = AssemblyLib.scaleToWad(2000 * 10 ** 6, 6);
        uint256 volatilityBasisPoints = 1_000;
        uint256 durationSeconds = 86_400 * 7;
        bool isPerpetual = false;
        uint256 priceWad = AssemblyLib.scaleToWad(2000 * 10 ** 6, 6);

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        INormalStrategy(subject().DEFAULT_STRATEGY()).getStrategyData(
            strikePriceWad,
            volatilityBasisPoints,
            durationSeconds,
            isPerpetual,
            priceWad
        );

        uint64 poolId = subject().createPool(
            pairId,
            initialX,
            initialY,
            100,
            0,
            address(0),
            subject().DEFAULT_STRATEGY(),
            strategyData
        );

        uint256 amount0 = 10 ether;
        uint256 amount1 = 20_000 * 10 ** 6;

        MockERC20(asset).mint(address(this), 100 ether);
        MockERC20(asset).approve(address(subject()), 100 ether);
        MockERC20(quote).mint(address(this), 200_000 * 10 ** 6);
        MockERC20(quote).approve(address(subject()), 200_000 * 10 ** 6);

        uint128 deltaLiquidity =
            subject().getMaxLiquidity(poolId, amount0, amount1);

        console.log(deltaLiquidity);

        (uint128 deltaAsset, uint128 deltaQuote) =
            subject().getLiquidityDeltas(poolId, int128(deltaLiquidity));

        (uint256 usedDeltaAsset, uint256 usedDeltaQuote) = subject().allocate(
            false,
            address(this),
            poolId,
            deltaLiquidity,
            uint128(amount0),
            uint128(amount1)
        );

        console.log(deltaAsset);
        console.log(deltaQuote);
        console.log("Used:", usedDeltaAsset);
        console.log("Used:", usedDeltaQuote);

        string memory uri = ERC1155(address(subject())).uri(poolId);
        console.log(uri);
    }

    function test_metadata_controlled_pool() public {
        address asset = address(new MockERC20("Ethereum", "ETH", 18));
        address quote = address(new MockERC20("USD Coin", "USDC", 6));
        uint24 pairId = subject().createPair(asset, quote);

        uint256 strikePriceWad = AssemblyLib.scaleToWad(2000 * 10 ** 6, 6);
        uint256 volatilityBasisPoints = 1_000;
        uint256 durationSeconds = 86_400 * 7;
        bool isPerpetual = false;
        uint256 priceWad = AssemblyLib.scaleToWad(2000 * 10 ** 6, 6);

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        INormalStrategy(subject().DEFAULT_STRATEGY()).getStrategyData(
            strikePriceWad,
            volatilityBasisPoints,
            durationSeconds,
            isPerpetual,
            priceWad
        );

        uint64 poolId = subject().createPool(
            pairId,
            initialX,
            initialY,
            200,
            100,
            address(this),
            subject().DEFAULT_STRATEGY(),
            strategyData
        );

        uint256 amount0 = 10 ether;
        uint256 amount1 = 20_000 * 10 ** 6;

        MockERC20(asset).mint(address(this), 100 ether);
        MockERC20(asset).approve(address(subject()), 100 ether);
        MockERC20(quote).mint(address(this), 200_000 * 10 ** 6);
        MockERC20(quote).approve(address(subject()), 200_000 * 10 ** 6);

        uint128 deltaLiquidity =
            subject().getMaxLiquidity(poolId, amount0, amount1);

        console.log(deltaLiquidity);

        (uint128 deltaAsset, uint128 deltaQuote) =
            subject().getLiquidityDeltas(poolId, int128(deltaLiquidity));

        (uint256 usedDeltaAsset, uint256 usedDeltaQuote) = subject().allocate(
            false,
            address(this),
            poolId,
            deltaLiquidity,
            uint128(amount0),
            uint128(amount1)
        );

        console.log(deltaAsset);
        console.log(deltaQuote);
        console.log("Used:", usedDeltaAsset);
        console.log("Used:", usedDeltaQuote);

        string memory uri = ERC1155(address(subject())).uri(poolId);
        console.log(uri);
    }

    function test_balanceOf_allocating_sets_balance()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
    {
        uint128 liquidity = 1 ether;

        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );

        assertEq(
            ERC1155(address(subject())).balanceOf(address(this), ghost().poolId),
            liquidity - BURNED_LIQUIDITY
        );
    }

    function test_balanceOf_allocating_increases_balance()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
    {
        uint128 liquidity = 1 ether;

        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );

        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );

        assertEq(
            ERC1155(address(subject())).balanceOf(address(this), ghost().poolId),
            liquidity * 2 - BURNED_LIQUIDITY
        );
    }

    function test_balanceOf_deallocating_reduces_balance()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
    {
        uint128 liquidity = 1 ether;

        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );

        subject().deallocate(
            false, ghost().poolId, uint128(liquidity - BURNED_LIQUIDITY), 0, 0
        );

        assertEq(
            ERC1155(address(subject())).balanceOf(address(this), ghost().poolId),
            0
        );
    }
}
