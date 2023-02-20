// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import {RMM01Portfolio as Hyper} from "../../contracts/RMM01Portfolio.sol";
import "../../contracts/test/TestERC20.sol";

contract InvariantDeposit is Test {
    Hyper public hyper;
    WETH public weth;
    TestERC20 public usdc;

    function setUp() public {
        weth = new WETH();
        usdc = new TestERC20("USDC", "USDC", 6);
        hyper = new Hyper(address(weth));

        excludeContract(address(weth));
        excludeContract(address(usdc));
    }

    function invariant_deposit() public {
        vm.deal(address(this), 100 ether);
        hyper.deposit{value: 100 ether}();
        assertEq(hyper.getBalance(address(this), address(weth)), 100 ether);
    }
}
