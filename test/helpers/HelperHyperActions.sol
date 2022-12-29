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
    ) internal pure returns (bytes memory data) {
        bytes[] memory instructions = new bytes[](3);
        uint48 magicPoolId = 0x000000000000;
        instructions[0] = (CPU.encodeCreatePair(token0, token1));
        instructions[1] = (CPU.encodeCreateCurve(sigma, maturity, fee, priorityFee, strike));
        instructions[2] = (CPU.encodeCreatePool(magicPoolId, price));
        data = CPU.encodeJumpInstruction(instructions);
    }

    function allocatePool(address hyper, uint48 poolId, uint amount) internal {
        bytes memory data = CPU.encodeAllocate(
            0, // useMax = false
            poolId,
            0x0, // amount multiplier = 10^0 = 1
            uint128(amount)
        );
        (bool success, ) = hyper.call{value: 0}(data);
        require(success, "failed to allocate");
    }
}
