// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "solmate/test/utils/mocks/MockERC20.sol";

import "contracts/interfaces/IHyper.sol";
import {HyperPool, HyperPosition, HyperPair, HyperCurve} from "contracts/HyperLib.sol";
import {GhostState} from "../../HelperGhostLib.sol";
import {ActorsState} from "../../HelperActorsLib.sol";

interface Context {
    // Manipulate ghost environment
    function setPoolId(uint64) external;

    function addPoolId(uint64) external;

    // Ghost environment getters from Setup.sol
    function subject() external view returns (IHyper);

    function actor() external view returns (address);

    function ghost() external view returns (GhostState memory);

    function getActors() external view returns (address[] memory);

    function getRandomActor(uint index) external view returns (address);

    // Ghost Invariant environment getters

    function getPoolIds() external view returns (uint64[] memory);

    function getRandomPoolId(uint index) external view returns (uint64);

    // Subject Specific Getters
    function getBalanceSum(address) external view returns (uint);

    function getPositionsLiquiditySum() external view returns (uint);
}

/** @dev Target contract must inherit. Read: https://github.com/dapphub/dapptools/blob/master/src/dapp/README.md#invariant-testing */
contract HandlerBase is Test {
    Context ctx;

    constructor() {
        ctx = Context(msg.sender);
    }
}
