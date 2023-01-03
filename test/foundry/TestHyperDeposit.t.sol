// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Vm.sol";
import "./setup/TestHyperSetup.sol";

contract TestHyperDeposit is TestHyperSetup {
    function testDepositMsgValueZero_reverts() public {
        vm.expectRevert(ZeroValue.selector);
        __hyperTestingContract__.deposit{value: 0}();
    }

    function testDepositWethTotalSupplyReturnsMsgValue() public {
        uint pre = __weth__.totalSupply();
        __hyperTestingContract__.deposit{value: 100}();
        uint post = __weth__.totalSupply();
        uint delta = post - pre;
        assertEq(post, 100, "ts");
        assertEq(delta, 100, "del");
    }

    function testDepositCallersBalanceReturnsMsgValue() public {
        uint pre = getBalance(address(__hyperTestingContract__), address(this), address(__weth__));
        __hyperTestingContract__.deposit{value: 100}();
        uint post = getBalance(address(__hyperTestingContract__), address(this), address(__weth__));
        uint delta = post - pre;
        assertEq(post, 100, "ts");
        assertEq(delta, 100, "del");
    }

    function testDepositEtherBalanceReturnsZero() public {
        __hyperTestingContract__.deposit{value: 100}();
        uint actual = address(__hyperTestingContract__).balance;
        assertEq(actual, 0, "balance");
    }

    function testDepositWethReservesReturnsMsgValue() public {
        uint pre = getReserve(address(__hyperTestingContract__), address(__weth__));
        __hyperTestingContract__.deposit{value: 100}();
        uint post = getReserve(address(__hyperTestingContract__), address(__weth__));
        uint delta = post - pre;
        assertEq(post, 100, "ts");
        assertEq(delta, 100, "del");
    }

    function testDepositBalanceOfWethReturnsMsgValue() public {
        __hyperTestingContract__.deposit{value: 100}();
        uint actual = __weth__.balanceOf(address(__hyperTestingContract__));
        assertEq(actual, 100, "balance");
    }

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
