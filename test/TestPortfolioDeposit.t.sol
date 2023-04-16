// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioDeposit is Setup {
/* function test_deposit_increases_user_weth_balance() public useActor {
        uint256 amount = 10 ether;
        uint256 prev = ghost().balance(actor(), subject().WETH());
        subject().deposit{value: amount}();
        uint256 post = ghost().balance(actor(), subject().WETH());
        assertEq(post, prev + amount, "missing-weth-deposit");
    }

    function test_deposit_weth_total_supply_equals_msg_value() public {
        uint256 amount = 10 ether;
        uint256 prev = WETH(payable(subject().WETH())).totalSupply();
        subject().deposit{value: amount}();
        uint256 post = WETH(payable(subject().WETH())).totalSupply();
        assertEq(post, amount, "total-supply");
        assertTrue(post > prev, "total-supply-not-increased");
    }

    function test_deposit_reserve_equals_msg_value() public {
        uint256 amount = 10 ether;
        uint256 prev = ghost().reserve(subject().WETH());
        subject().deposit{value: amount}();
        uint256 post = ghost().reserve(subject().WETH());
        assertEq(post, prev + amount, "weth-reserve");
    }

    function test_deposit_ether_balance_equals_zero() public {
        uint256 amount = 10 ether;
        subject().deposit{value: amount}();
        assertEq(address(subject()).balance, 0, "non-zero-balance");
    }

    function test_deposit_ether_balance_of_weth_equals_msg_value() public {
        uint256 amount = 10 ether;
        subject().deposit{value: amount}();
        assertEq(address(subject().WETH()).balance, amount, "zero-balance");
    } */
}
