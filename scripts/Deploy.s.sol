// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "../contracts/Hyper.sol";

contract Deploy is Script {
    address public __weth__ = 0x575E4246f36a92bd88bcAAaEE2c51499B64116Ed;
    address public __hyper__ = 0x03f22449978FD757e9081c9178B5c98546153465;

    event Deployed(address owner, address weth, address hyper);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address weth = __weth__;
        if (weth == address(0)) weth = address(new WETH());

        address hyper = __hyper__;
        if (hyper == address(0)) hyper = address(new Hyper(weth));

        emit Deployed(msg.sender, weth, hyper);

        vm.stopBroadcast();
    }
}
