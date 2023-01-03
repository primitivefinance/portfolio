// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Vm.sol";
import "./setup/TestHyperSetup.sol";

contract TestHyperDeposit is TestHyperSetup {
    function testDepositWrapsEther() public postTestInvariantChecks {
        uint prevWethBalance = __weth__.balanceOf(address(__hyperTestingContract__));
        uint prevBalance = address(this).balance;
        __hyperTestingContract__.deposit{value: 4000}();
        uint nextBalance = address(this).balance;
        uint nextWethBalance = __weth__.balanceOf(address(__hyperTestingContract__));

        assertTrue(nextBalance < prevBalance);
        assertTrue(nextWethBalance > prevWethBalance);
    }

    function testDepositIncreasesUserBalance() public postTestInvariantChecks {
        uint prevBalance = getBalance(address(__hyperTestingContract__), address(this), address(__weth__));
        __hyperTestingContract__.deposit{value: 4000}();
        uint nextBalance = getBalance(address(__hyperTestingContract__), address(this), address(__weth__));

        assertTrue(nextBalance > prevBalance, "balance-not-increased");
    }

    event Deposit(address indexed account, uint amount);

    function testDepositWrapsEther_emit_Deposit() public {
        vm.expectEmit(true, true, false, true, address(__hyperTestingContract__));
        emit Deposit(address(this), 4000);
        __hyperTestingContract__.deposit{value: 4000}();
    }

    event IncreaseUserBalance(address indexed account, address indexed token, uint256 amount);

    function testDepositWrapsEther_emit_IncreaseUserBalance() public {
        vm.expectEmit(true, true, true, true, address(__hyperTestingContract__));
        emit IncreaseUserBalance(address(this), address(__weth__), 4000);
        __hyperTestingContract__.deposit{value: 4000}();
    }
}
