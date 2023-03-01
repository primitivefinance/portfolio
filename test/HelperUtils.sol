// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/test/utils/mocks/MockERC20.sol";

/**
 * @dev A custom type allows us to define functions globally,
 * making it easier to use common actions on contracts like tokens
 * across the test suite.
 * Without a custom type, we would need to define the `use {function} for MockERC20`
 * for every test file.
 * Coin types are returned in the HelperGhostLib.
 */
type Coin is address;

using {prepare, to_token, to_addr} for Coin global;

/**
 * @dev For use in any tests that require some tokens to be transferred from an actor.
 * @custom:example
 * ```
 * ghost().asset_coin().prepare(owner, spender, amount);
 * assertEq(ghost().asset().allowance(owner, spender), type(uint).max);
 * assertEq(ghost().asset().balanceOf(owner), amount);
 * ```
 */
function prepare(Coin token, address owner, address spender, uint256 amount) {
    token.to_token().approve(spender, type(uint256).max);
    token.to_token().mint(owner, amount);
}

function to_addr(Coin coin) pure returns (address) {
    return Coin.unwrap(coin);
}

function to_token(Coin coin) pure returns (MockERC20) {
    return MockERC20(Coin.unwrap(coin));
}
