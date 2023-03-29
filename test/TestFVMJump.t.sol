// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract DecodeJump {
    function decodeJump(bytes calldata data)
        public
        view
        returns (bytes[] memory)
    {
        return FVM.decodeJumpInstructions(data);
    }

    function decodeCreatePair(bytes calldata data)
        public
        view
        returns (address, address)
    {
        return FVM.decodeCreatePair(data);
    }

    function decodeAllocateOrDeallocate(bytes calldata data)
        public
        view
        returns (uint8, uint64, uint128, uint128, uint128)
    {
        return FVM.decodeAllocateOrDeallocate(data);
    }

    function sliceCalldata(
        bytes calldata data,
        uint256 start,
        uint256 end
    ) public view returns (bytes memory) {
        if (end == 0) {
            return data[start:];
        } else {
            return data[start:end];
        }
    }
}

contract TestFVMJump is Setup {
/* bytes[] instructions;

    function test_encodeJumpInstruction() public {
        address a0 = address(55);
        address a1 = address(66);
        uint64 poolId = uint64(5);
        uint128 amount = uint128(7);
        instructions.push(FVM.encodeCreatePair(a0, a1));
        instructions.push(FVM.encodeAllocateOrDeallocate(true, uint8(0), poolId, amount));
        bytes memory payload = FVM.encodeJumpInstruction(instructions);

        DecodeJump _contract = new DecodeJump();
        bytes[] memory decoded = _contract.decodeJump(payload);
        (address decoded_a0, address decoded_a1) =
            _contract.decodeCreatePair(decoded[0]);
        (, uint64 decoded_poolId, uint128 decoded_amount) =
            _contract.decodeAllocateOrDeallocate(decoded[1]);
        assertEq(decoded_a0, a0, "invalid-a0");
        assertEq(decoded_a1, a1, "invalid-a1");
        assertEq(decoded_poolId, poolId, "invalid-poolId");
        assertEq(decoded_amount, amount, "invalid-amount");

        delete instructions;
    }

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
                    FVMLib.encodeAllocateOrDeallocate(true, uint8(0), ghost().poolId, amount)
                );
            } else {
                instructions.push(
                    FVMLib.encodeAllocateOrDeallocate(
                        false, uint8(0), ghost().poolId, amount / 2
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
    } */
}
