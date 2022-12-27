// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperDeposit is TestHyperSetup {
    function testDepositWrapsEther() public checkSettlementInvariant {
        uint prevWethBalance = __weth__.balanceOf(address(__hyperTestingContract__));
        uint prevBalance = address(this).balance;
        __hyperTestingContract__.deposit{value: 4000}();
        uint nextBalance = address(this).balance;
        uint nextWethBalance = __weth__.balanceOf(address(__hyperTestingContract__));

        assertTrue(nextBalance < prevBalance);
        assertTrue(nextWethBalance > prevWethBalance);
    }
}
