// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestFVMJump is Setup {
    modifier pauseGas() {
        vm.pauseGasMetering();
        _;
    }

    bytes[] instructions;

    // Maximum 2^8 = 256 instructions.
    // The amount of instructions to process is limited to 2^8 since it uses 1 byte.
    function testFuzz_allocate_deallocate_many(uint8 totalCalls)
        public
        pauseGas
        noJit
        defaultConfig
        useActor
        usePairTokens(100 ether)
        isArmed
    {
        vm.assume(totalCalls < 50); // temp: this can go higher but it takes much longer to fuzz
        uint128 amount = 0.2 ether;

        for (uint256 i; i != totalCalls; ++i) {
            if (i % 2 == 0) {
                instructions.push(
                    FVMLib.encodeAllocate(uint8(0), ghost().poolId, amount)
                );
            } else {
                instructions.push(
                    FVMLib.encodeDeallocate(
                        uint8(0), ghost().poolId, amount / 2
                    )
                );
            }
        }
        console.log("Encoding quantity of instructions:", instructions.length);

        console.log("Got instructions");
        bytes memory payload = FVMLib.encodeJumpInstruction(instructions);
        console.log("Got calldata payload length:", payload.length);
        console.log("Executing");
        console.log(
            "Liquidity before (should be 0): ",
            ghost().position(actor()).freeLiquidity
        );
        vm.resumeGasMetering();
        subject().multiprocess(payload);
        vm.pauseGasMetering();
        console.log(
            "Liquidity after: ", ghost().position(actor()).freeLiquidity
        );
    }
}
