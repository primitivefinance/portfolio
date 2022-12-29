// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/** @dev Read: https://github.com/dapphub/dapptools/blob/master/src/dapp/README.md#invariant-testing */
contract TestInvariantSetup {
    address[] private _targetContracts;

    function addTargetContract(address target) internal {
        _targetContracts.push(target);
    }

    function targetContracts() public view returns (address[] memory) {
        require(_targetContracts.length != uint(0), "no-target-contracts");
        return _targetContracts;
    }
}
