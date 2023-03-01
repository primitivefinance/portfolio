// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "../contracts/Portfolio.sol";

contract Deploy is Script {
    address public __weth__; //= 0x575E4246f36a92bd88bcAAaEE2c51499B64116Ed;
    address public __Portfolio__; //= 0x03f22449978FD757e9081c9178B5c98546153465;

    event Deployed(address owner, address weth, address Portfolio);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address weth = __weth__;
        if (weth == address(0)) weth = address(new WETH());

        address Portfolio = __Portfolio__;
        if (Portfolio == address(0)) Portfolio = address(new Portfolio(weth));

        emit Deployed(msg.sender, weth, Portfolio);

        vm.stopBroadcast();
    }
}
