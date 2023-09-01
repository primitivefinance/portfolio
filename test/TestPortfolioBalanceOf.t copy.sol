// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/tokens/ERC1155.sol";
import "../contracts/libraries/AssemblyLib.sol";
import "./Setup.sol";
import "../contracts/strategies/NormalStrategy.sol";

contract TestPortfolioBalanceOf is Setup {
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
