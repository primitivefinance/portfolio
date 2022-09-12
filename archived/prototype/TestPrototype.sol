pragma solidity 0.8.13;

import {FakeEnigmaAbstractOverrides} from "./BaseTest.sol";
import "../../contracts/prototype/HyperPrototype.sol";

contract TestPrototype is FakeEnigmaAbstractOverrides, HyperPrototype {
    constructor(address weth) FakeEnigmaAbstractOverrides(weth) {}

    /* uint256 public timestamp;

    function _blockTimestamp() internal view override returns (uint128) {
        return uint128(timestamp);
    } */

    function doesPoolExist(uint48 poolId) external view returns (bool) {
        return _doesPoolExist(poolId);
    }

    // --- Implemented --- //

    function process(bytes calldata data) external {
        uint48 poolId_;
        bytes1 instruction = bytes1(data[0] & 0x0f);
        if (instruction == Instructions.UNKNOWN) revert UnknownInstruction();

        if (instruction == Instructions.ADD_LIQUIDITY) {
            (poolId_, ) = _addLiquidity(data);
        } else if (instruction == Instructions.REMOVE_LIQUIDITY) {
            (poolId_, , ) = _removeLiquidity(data);
        } else if (instruction == Instructions.SWAP) {
            (poolId_, , , ) = _swapExactForExact(data);
        } else if (instruction == Instructions.STAKE_POSITION) {
            (poolId_, ) = _stakePosition(data);
        } else if (instruction == Instructions.UNSTAKE_POSITION) {
            (poolId_, ) = _unstakePosition(data);
        } else if (instruction == Instructions.CREATE_POOL) {
            (poolId_) = _createPool(data);
        } else if (instruction == Instructions.CREATE_CURVE) {
            _createCurve(data);
        } else if (instruction == Instructions.CREATE_PAIR) {
            _createPair(data);
        } else {
            revert UnknownInstruction();
        }
    }
}
