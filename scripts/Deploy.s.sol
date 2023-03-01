// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "contracts/RMM01Portfolio.sol";

contract Deploy is Script {
    // Set address if deploying on a network with an existing weth.
    address public __weth__; //= 0x575E4246f36a92bd88bcAAaEE2c51499B64116Ed;

    event Deployed(address owner, address weth, address Portfolio);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address weth = __weth__;
        if (weth == address(0)) weth = address(new WETH());

        address portfolio = address(new RMM01Portfolio(weth));

        emit Deployed(msg.sender, weth, portfolio);

        vm.stopBroadcast();
    }
}
