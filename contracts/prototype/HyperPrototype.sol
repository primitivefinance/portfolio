// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./EnigmaVirtualMachinePrototype.sol";

abstract contract HyperPrototype is EnigmaVirtualMachinePrototype {
    function _addLiquidity(bytes calldata data) internal returns (uint48 poolId, uint256 a) {}

    function _removeLiquidity(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 a,
            uint256 b
        )
    {}

    function _swapExactForExact(bytes calldata data) internal returns (uint48 poolId, uint256 a) {}

    function _createPool(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 a,
            uint256 b
        )
    {}

    function _createCurve(bytes calldata data) internal {}

    function _createPair(bytes calldata data) internal {}
}
