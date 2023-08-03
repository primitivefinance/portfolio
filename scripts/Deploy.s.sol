// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "solmate/tokens/WETH.sol";
import "nugu/NuguFactory.sol";

import "../contracts/test/SimpleRegistry.sol";
import "../contracts/Portfolio.sol";
import "../contracts/PositionRenderer.sol";

// This script allows you to deploy the Portfolio contract and its dependencies,
// you can learn how to use it in our documentation:
// https://docs.primitive.xyz/protocol/contracts/deployments#deploying-portfolio
contract Deploy is Script {
    function printJSON(
        string memory name,
        address at,
        string memory status,
        bool isLast
    ) private view {
        console.log(
            string.concat(
                '"%s":{"address":"%s","status":"%s"}', isLast ? "" : ","
            ),
            name,
            at,
            status
        );
    }

    function deployIfNecessary(
        NuguFactory factory,
        string memory name,
        bytes memory creationCode,
        bytes32 salt
    ) private returns (address at) {
        at = factory.getDeployed(salt);

        if (at.code.length == 0) {
            factory.deploy(salt, creationCode, 0);
            printJSON(name, at, "deployed", false);
        } else {
            printJSON(name, at, "skipped", false);
        }
    }

    function run(address weth, address registry) external {
        console.log("~");
        console.log("{");
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
            deployIfNecessary(
                factory, "WETH", type(WETH).creationCode, keccak256("WETH")
            );
        } else {
            printJSON("WETH", weth, "reused", false);
        }

        // Same thing for the Portfolio registry
        if (registry == address(0)) {
            deployIfNecessary(
                factory,
                "Registry",
                type(SimpleRegistry).creationCode,
                keccak256(type(SimpleRegistry).creationCode)
            );
        } else {
            printJSON("Registry", registry, "reused", false);
        }

        // First we deploy the PositionRenderer contract
        address positionRenderer = deployIfNecessary(
            factory,
            "PositionRenderer",
            type(PositionRenderer).creationCode,
            keccak256(type(PositionRenderer).creationCode)
        );

        // Then we can deploy the Portfolio contract
        address portfolio = deployIfNecessary(
            factory,
            "Portfolio",
            abi.encodePacked(
                type(Portfolio).creationCode,
                abi.encode(weth, registry, positionRenderer)
            ),
            keccak256(type(Portfolio).creationCode)
        );

        printJSON(
            "NormalStrategy",
            Portfolio(payable(portfolio)).DEFAULT_STRATEGY(),
            "deployed",
            true
        );

        vm.stopBroadcast();
        console.log("}");
        console.log("~");
    }
}
