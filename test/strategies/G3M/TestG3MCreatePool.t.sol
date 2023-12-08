// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../../Setup.sol";

contract TestG3MCreatePool is Setup {
    using FixedPointMathLib for *;

    address controller = address(0);
    uint256 reserveX = 18_600 ether;
    uint256 startWeightX = 0.75 ether;
    uint256 endWeightX = 0.75 ether;
    uint256 startUpdate = block.timestamp;
    uint256 endUpdate = block.timestamp;
    uint256 initialPrice = 1937.5 ether;

    function deployTokens(
        IPortfolio subject,
        bool createPair
    ) internal returns (MockERC20 token0, MockERC20 token1) {
        token0 = new MockERC20("tkn", "tkn", 18);
        token1 = new MockERC20("tkn", "tkn", 18);
        token0.mint(address(this), type(uint256).max);
        token0.approve(address(subject), type(uint256).max);
        token1.mint(address(this), type(uint256).max);
        token1.approve(address(subject), type(uint256).max);

        if (createPair) {
            subject.createPair(address(token0), address(token1));
        }
    }

    function test_G3M_createPool() public {
        deployTokens(subject(), true);

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        G3MStrategy(g3mStrategy()).getStrategyData(
            abi.encode(
                controller,
                reserveX,
                startWeightX,
                endWeightX,
                startUpdate,
                endUpdate,
                initialPrice
            )
        );

        uint64 poolId = subject().createPool(
            0,
            initialX,
            initialY,
            100,
            0,
            address(0),
            g3mStrategy(),
            strategyData
        );

        assertEq(subject().getSpotPrice(poolId), initialPrice);
        assertEq(subject().getStrategy(poolId), g3mStrategy());

        (
            address configController,
            uint256 configStartWeightX,
            uint256 configEndWeightX,
            uint256 configStartUpdate,
            uint256 configEndUpdate
        ) = G3MStrategy(g3mStrategy()).configs(poolId);

        assertEq(configController, controller);
        assertEq(configStartWeightX, startWeightX);
        assertEq(configEndWeightX, endWeightX);
        assertEq(configStartUpdate, startUpdate);
        assertEq(configEndUpdate, endUpdate);
    }
}
