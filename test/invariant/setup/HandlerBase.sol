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
    function setGhostPoolId(uint64) external;

    function addGhostPoolId(uint64) external;

    function setGhostActor(address) external;

    function addGhostActor(address) external;

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
abstract contract HandlerBase is Test {
    Context ctx;
    mapping(bytes32 => uint256) public calls;
    bytes32 _key;

    constructor() {
        ctx = Context(msg.sender);
    }

    modifier countCall(bytes32 key) {
        _key = key;
        calls[key]++;
        _;
    }

    function callSummary() external view {
        console.log(name(), calls[_key]);
    }

    function name() public view virtual returns (string memory);

    modifier createActor() {
        ctx.setGhostActor(msg.sender);
        ctx.addGhostActor(msg.sender);
        _;
    }

    modifier useActor(uint seed) {
        ctx.setGhostActor(ctx.getRandomActor(seed));
        _;
    }

    modifier usePool(uint seed) {
        ctx.setGhostPoolId(ctx.getRandomPoolId(seed));
        _;
    }
}
