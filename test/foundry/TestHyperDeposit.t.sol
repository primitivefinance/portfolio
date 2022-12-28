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

    event Deposit(address indexed account, uint amount);

    function testDepositWrapsEther_emit_Deposit() public {
        vm.expectEmit(true, true, false, true);
        emit Deposit(address(this), 4000);
        __hyperTestingContract__.deposit{value: 4000}();
    }

    event IncreaseUserBalance(address indexed token, uint256 amount);

    function testDepositWrapsEther_emit_IncreaseUserBalance() public {
        vm.expectEmit(true, true, false, true);
        emit IncreaseUserBalance(address(__weth__), 4000);
        __hyperTestingContract__.deposit{value: 4000}();
    }
}
