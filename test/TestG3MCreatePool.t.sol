// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestG3MCreatePool is Setup {
    function test_G3M_createPool_SetsSpotPrice() public {
        uint256 reserveX = 18_600 ether;
        uint256 weightX = 0.75 ether;
        uint256 initialPrice = 1937.5 ether;

        address token0 = address(new MockERC20("tkn", "tkn", 18));
        address token1 = address(new MockERC20("tkn", "tkn", 18));
        MockERC20(token0).mint(address(this), type(uint256).max);
        MockERC20(token0).approve(address(subject()), type(uint256).max);
        MockERC20(token1).mint(address(this), type(uint256).max);
        MockERC20(token1).approve(address(subject()), type(uint256).max);

        subject().createPair(token0, token1);

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        G3MStrategy(g3mStrategy()).getStrategyData(
            reserveX, weightX, initialPrice
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
    }

    function test_g3m_createPool() public {
        address token0 = address(new MockERC20("tkn", "tkn", 18));
        address token1 = address(new MockERC20("tkn", "tkn", 18));
        MockERC20(token0).mint(address(this), type(uint256).max);
        MockERC20(token0).approve(address(subject()), type(uint256).max);
        MockERC20(token1).mint(address(this), type(uint256).max);
        MockERC20(token1).approve(address(subject()), type(uint256).max);

        subject().createPair(token0, token1);

        (bytes memory strategyData, uint256 initialX, uint256 initialY) =
        G3MStrategy(g3mStrategy()).getStrategyData(
            18_600 ether, 0.75 ether, 1937.5 ether
        );

        console.log("initialX:", initialX);
        console.log("initialY:", initialY);

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

        console.log("balance x", MockERC20(token0).balanceOf(address(this)));
        console.log("balance y", MockERC20(token1).balanceOf(address(this)));

        console.log(
            "Portfolio balance x",
            MockERC20(token0).balanceOf(address(subject()))
        );
        console.log(
            "Portfolio balance y",
            MockERC20(token1).balanceOf(address(subject()))
        );

        {
            (
                uint128 virtualX, // Total X reserves in WAD units for all liquidity.
                uint128 virtualY, // Total Y reserves in WAD units for all liquidity.
                uint128 liquidity, // Total supply of liquidity.
                uint32 lastTimestamp, // Updated __only__ on `swap()`.
                uint16 feeBasisPoints,
                uint16 priorityFeeBasisPoints,
                address controller, // Address that can call `changeParameters()`.
                address strategy
            ) = subject().pools(poolId);

            console.log("virtualX", virtualX);
            console.log("virtualY", virtualY);
            console.log("liquidity", liquidity);
        }

        subject().allocate(
            false,
            address(this),
            poolId,
            100 ether,
            type(uint128).max,
            type(uint128).max
        );

        console.log("Invariant:", uint256(subject().getInvariant(poolId)));

        console.log("Spot price:", subject().getSpotPrice(poolId));

        console.log("balance x", MockERC20(token0).balanceOf(address(this)));
        console.log("balance y", MockERC20(token1).balanceOf(address(this)));

        {
            (
                uint128 virtualX, // Total X reserves in WAD units for all liquidity.
                uint128 virtualY, // Total Y reserves in WAD units for all liquidity.
                uint128 liquidity, // Total supply of liquidity.
                uint32 lastTimestamp, // Updated __only__ on `swap()`.
                uint16 feeBasisPoints,
                uint16 priorityFeeBasisPoints,
                address controller, // Address that can call `changeParameters()`.
                address strategy
            ) = subject().pools(poolId);

            console.log("virtualX", virtualX);
            console.log("virtualY", virtualY);
            console.log("liquidity", liquidity);
        }

        console.log(
            "Portfolio balance x",
            MockERC20(token0).balanceOf(address(subject()))
        );
        console.log(
            "Portfolio balance y",
            MockERC20(token1).balanceOf(address(subject()))
        );

        console.log(
            "Out:",
            G3MStrategy(g3mStrategy()).getAmountOut(
                poolId, true, 500 ether, address(this)
            )
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

        (bool success, int256 prevInvariant, int256 postInvariant) =
            subject().simulateSwap(order, block.timestamp, address(this));

        console.log("success:", success);
        console.log("prevInvariant:");
        console.logInt(prevInvariant);
        console.log("postInvariant:");
        console.logInt(postInvariant);

        console.log("Invariant is gud:", postInvariant > prevInvariant);

        subject().swap(order);
    }
}
