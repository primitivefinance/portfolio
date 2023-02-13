// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import "../../contracts/Hyper.sol";
import "../../contracts/test/TestERC20.sol";

contract InvariantFund is Test {
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

    function invariant_fund() public {
        usdc.mint(address(this), 100 ether);
        usdc.approve(address(hyper), 100 ether);
        hyper.fund(address(usdc), 100 ether);
        assertEq(
            hyper.getBalance(address(this), address(usdc)),
            100 ether
        );
    }
}
