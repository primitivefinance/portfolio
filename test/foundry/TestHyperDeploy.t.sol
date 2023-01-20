// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Vm.sol";
import "./setup/TestHyperSetup.sol";

contract TestHyperDeploy is TestHyperSetup {
    event Deployed(string, address);

    function testDeploy() public {
        address weth = address(new WETH());
        address usdc = address(new TestERC20("USDC", "USD Coin", 6));
        Hyper hyper = new Hyper(weth);

        emit Deployed("Deployed weth at: ", weth);
        emit Deployed("Deployed hyper at: ", address(hyper));
        emit Deployed("Deployed usdc at: ", usdc);

        assertEq(hyper.WETH(), weth, "weth address");
        (, bool settled) = hyper.__account__();
        assertTrue(settled, "settled");

        assertTrue(bytes32(abi.encodePacked(hyper.VERSION())) == bytes32(abi.encodePacked("beta-v0.1.0")));
    }
}
