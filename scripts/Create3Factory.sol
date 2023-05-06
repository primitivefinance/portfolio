// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/utils/CREATE3.sol";

contract Create3Factory {
    function deploy(
        bytes32 salt,
        bytes memory creationCode
    ) external payable returns (address deployed) {
        salt = keccak256(abi.encodePacked(msg.sender, salt));
        return CREATE3.deploy(salt, creationCode, msg.value);
    }

    function getDeployed(
        address deployer,
        bytes32 salt
    ) external view returns (address deployed) {
        salt = keccak256(abi.encodePacked(deployer, salt));
        return CREATE3.getDeployed(salt);
    }
}
