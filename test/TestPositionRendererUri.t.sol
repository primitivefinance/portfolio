// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/tokens/ERC1155.sol";
import "../contracts/libraries/AssemblyLib.sol";
import "./Setup.sol";
import "../contracts/strategies/NormalStrategy/NormalStrategy.sol";

contract TestPositionRendererUri is Setup {
    struct MetaContext {
        address asset;
        address quote;
        uint256 strikePriceWad;
        uint256 durationSeconds;
        uint16 swapFee;
        bool isPerpetual;
        uint256 priceWad;
        address controller;
        address strategy;
        uint16 prioritySwapFee;
    }

    function _createPool(MetaContext memory ctx)
        public
        returns (uint64 poolId)
    {
        uint24 pairId = subject().getPairId(ctx.asset, ctx.quote);

        if (pairId == 0) {
            pairId = subject().createPair(ctx.asset, ctx.quote);
        }

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        INormalStrategy(normalStrategy()).getStrategyData(
            ctx.strikePriceWad,
            1_00, // volatilityBasisPoints
            ctx.durationSeconds,
            ctx.isPerpetual,
            ctx.priceWad
        );

        poolId = subject().createPool(
            pairId,
            initialX,
            initialY,
            ctx.swapFee,
            ctx.prioritySwapFee,
            ctx.controller,
            ctx.strategy,
            strategyData
        );
    }

    function _allocate(
        MetaContext memory ctx,
        uint64 poolId,
        uint256 amount0,
        uint256 amount1
    ) public {
        MockERC20(ctx.asset).mint(address(this), amount0);
        MockERC20(ctx.asset).approve(address(subject()), amount0);
        MockERC20(ctx.quote).mint(address(this), amount1);
        MockERC20(ctx.quote).approve(address(subject()), amount1);

        uint128 deltaLiquidity =
            subject().getMaxLiquidity(poolId, amount0, amount1);

        (uint128 deltaAsset, uint128 deltaQuote) =
            subject().getLiquidityDeltas(poolId, int128(deltaLiquidity));

        subject().allocate(
            false, address(this), poolId, deltaLiquidity, deltaAsset, deltaQuote
        );
    }

    function test_uri() public {
        MetaContext memory ctx = MetaContext({
            asset: address(new MockERC20("Ethereum", "ETH", 18)),
            quote: address(new MockERC20("USD Coin", "USDC", 6)),
            strikePriceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            durationSeconds: 86_400 * 3,
            swapFee: 400,
            isPerpetual: false,
            priceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            controller: address(0),
            strategy: normalStrategy(),
            prioritySwapFee: 0
        });

        uint64 poolId = _createPool(ctx);
        _allocate(ctx, poolId, 1 ether, 2_000 * 10 ** 6);
        console.log(ERC1155(address(subject())).uri(poolId));
    }

    function test_uri_controlled_pool() public {
        MetaContext memory ctx = MetaContext({
            asset: address(new MockERC20("Ethereum", "ETH", 18)),
            quote: address(new MockERC20("USD Coin", "USDC", 6)),
            strikePriceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            durationSeconds: 86_400 * 3,
            swapFee: 400,
            isPerpetual: false,
            priceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            controller: address(this),
            strategy: normalStrategy(),
            prioritySwapFee: 200
        });

        uint64 poolId = _createPool(ctx);
        _allocate(ctx, poolId, 1 ether, 2_000 * 10 ** 6);
        console.log(ERC1155(address(subject())).uri(poolId));
    }

    function test_uri_perpetual() public {
        MetaContext memory ctx = MetaContext({
            asset: address(new MockERC20("Ethereum", "ETH", 18)),
            quote: address(new MockERC20("USD Coin", "USDC", 6)),
            strikePriceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            durationSeconds: 86_400 * 3,
            swapFee: 400,
            isPerpetual: true,
            priceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            controller: address(0),
            strategy: normalStrategy(),
            prioritySwapFee: 0
        });

        uint64 poolId = _createPool(ctx);
        _allocate(ctx, poolId, 1 ether, 2_000 * 10 ** 6);
        console.log(ERC1155(address(subject())).uri(poolId));
    }

    function test_uri_custom_strategy() public {
        MetaContext memory ctx = MetaContext({
            asset: address(new MockERC20("Ethereum", "ETH", 18)),
            quote: address(new MockERC20("USD Coin", "USDC", 6)),
            strikePriceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            durationSeconds: 86_400 * 3,
            swapFee: 400,
            isPerpetual: false,
            priceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            controller: address(0),
            strategy: address(new NormalStrategy(address(subject()))),
            prioritySwapFee: 0
        });

        uint64 poolId = _createPool(ctx);
        _allocate(ctx, poolId, 1 ether, 2_000 * 10 ** 6);
        console.log(ERC1155(address(subject())).uri(poolId));
    }

    function test_uri_controlled_custom_strategy() public {
        MetaContext memory ctx = MetaContext({
            asset: address(new MockERC20("Ethereum", "ETH", 18)),
            quote: address(new MockERC20("USD Coin", "USDC", 6)),
            strikePriceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            durationSeconds: 86_400 * 3,
            swapFee: 400,
            isPerpetual: false,
            priceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            controller: address(this),
            strategy: address(new NormalStrategy(address(subject()))),
            prioritySwapFee: 100
        });

        uint64 poolId = _createPool(ctx);
        _allocate(ctx, poolId, 1 ether, 2_000 * 10 ** 6);
        console.log(ERC1155(address(subject())).uri(poolId));
    }

    function test_uri_many_pools() public {
        MetaContext memory ctx = MetaContext({
            asset: address(new MockERC20("Ethereum", "ETH", 18)),
            quote: address(new MockERC20("USD Coin", "USDC", 6)),
            strikePriceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            durationSeconds: 86_400 * 3,
            swapFee: 400,
            isPerpetual: false,
            priceWad: AssemblyLib.scaleToWad(1666 * 10 ** 6, 6),
            controller: address(0),
            strategy: normalStrategy(),
            prioritySwapFee: 0
        });

        _createPool(ctx);
        _createPool(ctx);
        uint64 poolId = _createPool(ctx);
        _allocate(ctx, poolId, 1 ether, 2_000 * 10 ** 6);
        console.log(ERC1155(address(subject())).uri(poolId));
    }
}
