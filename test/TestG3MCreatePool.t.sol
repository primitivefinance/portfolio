// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestG3MCreatePool is Setup {
    function test_g3m_createPool() public {
        address token0 = address(new MockERC20("tkn", "tkn", 18));
        address token1 = address(new MockERC20("tkn", "tkn", 18));
        MockERC20(token0).mint(address(this), 10000 ether);
        MockERC20(token0).approve(address(subject()), 10000 ether);
        MockERC20(token1).mint(address(this), 10000 ether);
        MockERC20(token1).approve(address(subject()), 10000 ether);

        subject().createPair(token0, token1);

        uint64 poolId = subject().createPool(
            0,
            1 ether,
            1 ether,
            100,
            0,
            address(0),
            g3mStrategy(),
            abi.encode(0.5 ether)
        );

        console.log("balance x", MockERC20(token0).balanceOf(address(this)));
        console.log("balance y", MockERC20(token1).balanceOf(address(this)));

        subject().allocate(
            false,
            address(this),
            poolId,
            1 ether,
            type(uint128).max,
            type(uint128).max
        );

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
    }
}
