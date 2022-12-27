// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/CPU.sol" as CPU;

contract HelperHyperActions {
    /** @dev Encodes jump process for creating a pair + curve + pool in one tx. */
    function createPool(
        address token0,
        address token1,
        uint24 sigma,
        uint32 maturity,
        uint16 fee,
        uint16 priorityFee,
        uint128 strike,
        uint128 price
    ) public view returns (bytes memory data) {
        bytes[] memory instructions = new bytes[](3);
        uint48 magicPoolId = 0x000000000000;
        instructions[0] = (CPU.encodeCreatePair(token0, token1));
        instructions[1] = (CPU.encodeCreateCurve(sigma, maturity, fee, priorityFee, strike));
        instructions[2] = (CPU.encodeCreatePool(magicPoolId, price));
        data = CPU.encodeJumpInstruction(instructions);
    }
}
