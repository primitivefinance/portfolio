// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "solmate/test/utils/mocks/MockERC20.sol";

import "../contracts/test/SimpleRegistry.sol";
import "../contracts/Portfolio.sol";
import "../contracts/PositionRenderer.sol";
import "../contracts/libraries/AssemblyLib.sol";

contract TestDeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address sender = vm.addr(deployerPrivateKey);
        console.log("Sender:", sender);
        vm.startBroadcast(deployerPrivateKey);

        MockERC20 usdt = new MockERC20("USDT", "USDT", 18);
        MockERC20 dai = new MockERC20("DAI", "DAI", 18);
        MockERC20 weth = new MockERC20("Wrapped Ether", "WETH", 18);
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 6);

        address registry = address(new SimpleRegistry());
        address positionRenderer = address(new PositionRenderer());
        Portfolio portfolio =
            new Portfolio(address(weth), registry, positionRenderer);

        // USDT - DAI

        uint64 poolId = _createPool(
            portfolio,
            address(usdt),
            address(dai),
            AssemblyLib.scaleToWad(1 ether, 18)
        );
        _allocate(sender, portfolio, poolId, usdt, dai, 1000 ether, 1000 ether);

        // USDT - USDC

        poolId = _createPool(
            portfolio,
            address(usdt),
            address(usdc),
            AssemblyLib.scaleToWad(1 * 10 ** 6, 6)
        );
        _allocate(
            sender, portfolio, poolId, usdt, usdc, 2000 ether, 2000 * 10 ** 6
        );

        // WETH - USDC
        poolId = _createPool(
            portfolio,
            address(weth),
            address(usdc),
            AssemblyLib.scaleToWad(2000 * 10 ** 6, 6)
        );
        _allocate(
            sender, portfolio, poolId, weth, usdc, 2 ether, 4000 * 10 ** 6
        );

        console.log(unicode"🚀 Contracts deployed!");
        console.log("Portfolio:", address(portfolio));

        vm.stopBroadcast();
    }

    function _createPool(
        Portfolio portfolio,
        address asset,
        address quote,
        uint256 price
    ) public returns (uint64) {
        uint24 pairId = portfolio.getPairId(asset, quote);

        if (pairId == 0) pairId = portfolio.createPair(asset, quote);

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        INormalStrategy(portfolio.DEFAULT_STRATEGY()).getStrategyData(
            price, 1_00, 3 days, false, price
        );

        uint64 poolId = portfolio.createPool(
            pairId,
            initialX,
            initialY,
            100,
            0,
            address(0),
            address(0),
            strategyData
        );

        return poolId;
    }

    function _allocate(
        address sender,
        Portfolio portfolio,
        uint64 poolId,
        MockERC20 asset,
        MockERC20 quote,
        uint128 amount0,
        uint128 amount1
    ) public {
        asset.mint(sender, amount0);
        asset.approve(address(portfolio), amount0);
        quote.mint(sender, amount1);
        quote.approve(address(portfolio), amount1);

        uint128 deltaLiquidity =
            portfolio.getMaxLiquidity(poolId, amount0, amount1);

        (uint128 deltaAsset, uint128 deltaQuote) =
            portfolio.getLiquidityDeltas(poolId, int128(deltaLiquidity));

        portfolio.allocate(
            false, sender, poolId, deltaLiquidity, deltaAsset, deltaQuote
        );
    }
}
