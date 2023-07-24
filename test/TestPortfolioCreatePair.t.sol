// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioCreatePair is Setup {
    function test_createPair_success() public {
        address token0 = address(new MockERC20("tkn", "tkn", 18));
        address token1 = address(new MockERC20("tkn", "tkn", 18));
        subject().createPair(token0, token1);
    }

    function test_revert_createPair_same_token() public {
        address token0 = address(new MockERC20("tkn", "tkn", 18));
        vm.expectRevert(Portfolio_DuplicateToken.selector);
        subject().createPair(token0, token0);
    }

    function test_revert_createPair_exists() public defaultConfig {
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.createPair,
            (ghost().asset().to_addr(), ghost().quote().to_addr())
        );
        uint24 pairId = PoolId.wrap(ghost().poolId).pairId();
        vm.expectRevert(
            abi.encodeWithSelector(Portfolio_PairExists.selector, pairId)
        );
        subject().multicall(instructions);
    }

    function test_revert_createPair_asset_lower_decimal_bound() public {
        address token0 = address(new MockERC20("t", "t", 5));
        address token1 = address(new MockERC20("t", "t", 18));
        vm.expectRevert(
            abi.encodeWithSelector(Portfolio_InvalidDecimals.selector, 5)
        );
        subject().createPair(token0, token1);
    }

    function test_revert_createPair_quote_lower_decimal_bound() public {
        address token0 = address(new MockERC20("t", "t", 18));
        address token1 = address(new MockERC20("t", "t", 5));
        vm.expectRevert(
            abi.encodeWithSelector(Portfolio_InvalidDecimals.selector, 5)
        );
        subject().createPair(token0, token1);
    }

    function test_revert_createPair_asset_upper_decimal_bound() public {
        address token0 = address(new MockERC20("t", "t", 24));
        address token1 = address(new MockERC20("t", "t", 18));
        vm.expectRevert(
            abi.encodeWithSelector(Portfolio_InvalidDecimals.selector, 24)
        );
        subject().createPair(token0, token1);
    }

    function test_revert_createPair_quote_upper_decimal_bound() public {
        address token0 = address(new MockERC20("t", "t", 18));
        address token1 = address(new MockERC20("t", "t", 24));
        vm.expectRevert(
            abi.encodeWithSelector(Portfolio_InvalidDecimals.selector, 24)
        );
        subject().createPair(token0, token1);
    }

    function test_createPair_nonce_increments_returns_one() public {
        uint256 prevNonce = subject().getPairNonce();
        address token0 = address(new MockERC20("t", "t", 18));
        address token1 = address(new MockERC20("t", "t", 18));
        subject().createPair(token0, token1);
        uint256 nonce = subject().getPairNonce();
        assertEq(nonce, prevNonce + 1);
    }

    function test_createPair_fetch_pair_id_returns_non_zero() public {
        // uint256 prevNonce = subject().getPairNonce();
        address token0 = address(new MockERC20("t", "t", 18));
        address token1 = address(new MockERC20("t", "t", 18));
        subject().createPair(token0, token1);
        uint256 pairId = subject().getPairId(token0, token1);
        assertTrue(pairId != 0);
    }

    function test_createPair_fetch_pair_data_returns_token_data() public {
        // uint256 prevNonce = subject().getPairNonce();
        address token0 = address(new MockERC20("t", "t", 18));
        address token1 = address(new MockERC20("t", "t", 18));
        subject().createPair(token0, token1);
        uint24 pairId = subject().getPairId(token0, token1);
        PortfolioPair memory pair = ghost().pairOf(pairId);
        assertEq(pair.tokenAsset, token0);
        assertEq(pair.tokenQuote, token1);
        assertEq(pair.decimalsAsset, 18);
        assertEq(pair.decimalsQuote, 18);
    }
}
