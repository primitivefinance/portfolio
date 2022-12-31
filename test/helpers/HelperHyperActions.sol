// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/CPU.sol" as CPU;

uint16 constant DEFAULT_HOURLY_EPOCH_ONE_YEAR = 8766;

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
        bytes[] memory instructions = new bytes[](2);
        uint64 magicPoolId = 0x000000000000;
        instructions[0] = (CPU.encodeCreatePair(token0, token1));
        instructions[1] = (
            CPU.encodeCreatePool(
                uint24(0x000000), // magic variable for pairId
                address(0),
                uint16(1), // priorityFee, 1bps
                uint16(30), // fee, 30 bps
                uint16(1e4), // default sigma of 1e4
                uint16(DEFAULT_HOURLY_EPOCH_ONE_YEAR), // default dur of 1 year
                uint16(0), // jit
                int24(23027), // default tick
                price
            )
        );
        data = CPU.encodeJumpInstruction(instructions);
    }

    function allocatePool(address hyper, uint64 poolId, uint amount) internal {
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
