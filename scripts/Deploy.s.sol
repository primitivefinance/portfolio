// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "contracts/RMM01Portfolio.sol";
import "contracts/test/SimpleRegistry.sol";
import "solmate/utils/CREATE3.sol";

contract Factory {
    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) external returns (address deployed) {
        deployed = CREATE3.deploy(salt, creationCode, value);
    }

    function getDeployed(bytes32 salt) external view returns (address) {
        return CREATE3.getDeployed(salt);
    }
}

contract Deploy is Script {
    Factory factory;

    // Set address if deploying on a network with an existing weth.
    address public __weth__; //= 0x575E4246f36a92bd88bcAAaEE2c51499B64116Ed;

    event Deployed(
        address owner, address weth, address portfolio, address registry
    );

    function run(address weth, address registry) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        if (factory == address(0)) factory = address(new Factory());
        nugu = Factory(factory);

        if (weth) {
            // nugu = Factory(0x0000A79C3D8124ED3a7F8EC8427E4DC43a2B154d);

            // address weth = 0xF8781048A099f9EF6CC5E2516F14BBeed6fd6DcD;
            // factory.deploy(keccak256("WETH"), type(WETH).creationCode, 0);

            // address registry = 0x940F5dD92E1170C295c2aF46550B731eC6Ed0EeE;
            // factory.deploy(keccak256("SimpleRegistry"), type(SimpleRegistry).creationCode, 0);

            /*
        address portfolio = factory.deploy(
            keccak256("RMM01Portfolio"),
            abi.encodePacked(
                type(RMM01Portfolio).creationCode, abi.encode(weth, registry)
            ),
            0
        );

        /*

        if (address(factory) == address(0)) factory = new Factory();

        address weth = __weth__;
        if (weth == address(0)) weth = address(new WETH());

        address registry = address(new SimpleRegistry());

        address portfolio = factory.deploy(
            keccak256("cheese"), type(RMM01Portfolio).creationCode, 0
        );
        // address portfolio = address(new RMM01Portfolio(weth, registry));

        emit Deployed(msg.sender, weth, portfolio, registry);

        */

            // console.log("Factory:", address(factory));
            console.log("WETH:", weth);
        }
        // console.log("Portfolio:", portfolio);
        console.log("Registry:", registry);

        vm.stopBroadcast();
    }
}
