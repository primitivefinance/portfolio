// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "solmate/tokens/WETH.sol";
import "contracts/RMM01Portfolio.sol";
import "contracts/test/SimpleRegistry.sol";

import "nugu/NuguFactory.sol";

contract Deploy is Script {
    function run(address weth, address registry) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Here we specify the factory we want to use
        NuguFactory factory =
            NuguFactory(0x0000A79C3D8124ED3a7F8EC8427E4DC43a2B154d);

        // Let's check if the contract is deployed on this network
        require(
            address(factory).code.length > 0,
            "Nugu Factory not deployed on this network!"
        );

        // If no WETH address is provided, we deploy a new contract
        if (weth == address(0)) {
            weth = factory.deploy(keccak256("WETH"), type(WETH).creationCode, 0);
        }

        // Same thing for the Portfolio registry
        if (registry == address(0)) {
            registry = factory.deploy(
                keccak256("SimpleRegistry"),
                type(SimpleRegistry).creationCode,
                0
            );
        }

        // Then we can deploy the Portfolio contract
        address portfolio = factory.deploy(
            keccak256("RMM01Portfolio"),
            abi.encodePacked(
                type(RMM01Portfolio).creationCode, abi.encode(weth, registry)
            ),
            0
        );

        console.log(unicode"🚀 Contracts deployed!");
        console.log("WETH:", weth);
        console.log("Registry:", registry);
        console.log("Portfolio:", portfolio);

        vm.stopBroadcast();
    }
}
