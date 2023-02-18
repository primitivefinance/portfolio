// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/libraries/EnigmaLib.sol" as ProcessingLib;
import "./HelperHyperProfiles.sol";

contract HelperHyperActions {
    /** @dev Encodes jump process for creating a pair + curve + pool in one tx. */
    function createPool(
        address token0,
        address token1,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 maxPrice,
        uint128 price
    ) internal pure returns (bytes memory data) {
        bytes[] memory instructions = new bytes[](2);
        uint24 magicPoolId = 0x000000;
        instructions[0] = (ProcessingLib.encodeCreatePair(token0, token1));
        instructions[1] = (
            ProcessingLib.encodeCreatePool(
                magicPoolId, // magic variable
                controller,
                priorityFee,
                fee,
                volatility,
                duration,
                jit,
                maxPrice,
                price
            )
        );
        data = ProcessingLib.encodeJumpInstruction(instructions);
    }

    function allocatePool(address hyper, uint64 poolId, uint256 amount) internal {
        bytes memory data = ProcessingLib.encodeAllocate(
            0, // useMax = false
            poolId,
            0x0, // amount multiplier = 10^0 = 1
            uint128(amount)
        );
        (bool success, ) = hyper.call{value: 0}(data);
        require(success, "failed to allocate");
    }
}
