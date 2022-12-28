// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Pair, Curve, HyperPool, HyperPosition} from "contracts/EnigmaTypes.sol";

interface IHyperStruct {
    function curves(uint32 curveId) external view returns (Curve memory);

    function pairs(uint16 pairId) external view returns (Pair memory);

    function positions(address owner, uint48 positionId) external view returns (HyperPosition memory);

    function pools(uint48 poolId) external view returns (HyperPool memory);
}

interface HyperLike {
    function getReserve(address) external view returns (uint);

    function getBalance(address, address) external view returns (uint);
}

contract HelperHyperView {
    function getPool(address hyper, uint48 poolId) public view returns (HyperPool memory) {
        return IHyperStruct(hyper).pools(poolId);
    }

    function getCurve(address hyper, uint32 curveId) public view returns (Curve memory) {
        return IHyperStruct(hyper).curves(curveId);
    }

    function getPair(address hyper, uint16 pairId) public view returns (Pair memory) {
        return IHyperStruct(hyper).pairs(pairId);
    }

    function getPosition(address hyper, address owner, uint48 positionId) public view returns (HyperPosition memory) {
        return IHyperStruct(hyper).positions(owner, positionId);
    }

    function getReserve(address hyper, address token) public view returns (uint) {
        return HyperLike(hyper).getReserve(token);
    }

    function getBalance(address hyper, address owner, address token) public view returns (uint) {
        return HyperLike(hyper).getBalance(owner, token);
    }
}
