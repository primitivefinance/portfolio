// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestG3MCreatePool is Setup {
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

        uint256 reserveX = 18_600 ether;
        uint256 weightX = 0.75 ether;
        uint256 initialPrice = 1937.5 ether;

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        G3MStrategy(g3mStrategy()).getStrategyData(
            address(this), reserveX, weightX, initialPrice
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
    }

    function test_G3M_allocate() public {
        deployTokens(subject(), true);

        uint256 reserveX = 18_600 ether;
        uint256 weightX = 0.75 ether;
        uint256 initialPrice = 1937.5 ether;

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        G3MStrategy(g3mStrategy()).getStrategyData(
            address(this), reserveX, weightX, initialPrice
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

        subject().allocate(
            false,
            address(this),
            poolId,
            100 ether,
            type(uint128).max,
            type(uint128).max
        );
    }

    function test_G3M_swap() public {
        deployTokens(subject(), true);

        uint256 reserveX = 18_600 ether;
        uint256 weightX = 0.75 ether;
        uint256 initialPrice = 1937.5 ether;

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        G3MStrategy(g3mStrategy()).getStrategyData(
            address(this), reserveX, weightX, initialPrice
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

        subject().allocate(
            false,
            address(this),
            poolId,
            100 ether,
            type(uint128).max,
            type(uint128).max
        );

        Order memory order = Order({
            input: 500 ether,
            output: uint128(
                G3MStrategy(g3mStrategy()).getAmountOut(
                    poolId, true, 500 ether, address(this)
                )
                ),
            useMax: false,
            poolId: poolId,
            sellAsset: true
        });

        subject().swap(order);
    }
}
