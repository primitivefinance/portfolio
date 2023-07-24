// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "contracts/test/FeeOnTransferToken.sol";
import "solmate/test/utils/mocks/MockERC20.sol";

/// @dev Universal type for a token which is used in the testing environment.
type Coin is address;

using { prepare, to_token, to_addr } for Coin global;

error Coin_UnknownTokenKey(bytes32);

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

function deploy(bytes32 key, bytes memory constructorArgs) returns (Coin) {
    (string memory name, string memory symbol, uint8 decimals) =
        abi.decode(constructorArgs, (string, string, uint8));

    MockERC20 token;
    if (key == "token") {
        token = new MockERC20(name, symbol, decimals);
    } else if (key == "RTL") { } else if (key == "FOT") {
        FeeOnTransferToken _token =
            new FeeOnTransferToken(name, symbol, decimals);
        token = MockERC20(address(_token));
    } else {
        revert Coin_UnknownTokenKey(key);
    }

    return Coin.wrap(address(token));
}
