// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestFVMJump is Setup {
    using SafeCastLib for uint256;

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

    uint64[] poolIds;
    mapping(uint16 => bool) internal usedVolatility;

    uint256 swapCalls;

    function test_swap_across_many()
        public
        pauseGas
        noJit
        defaultConfig
        useActor
        usePairTokens(10000 ether)
        isArmed
    {
        if (swapCalls > 0) return; // Only fuzz once with random seed.

        uint256 amountOfPools = 10;

        for (uint256 i; i != amountOfPools; ++i) {
            uint16 volatility = uint16(1000 * (i + 1));

            uint64 poolId = Configs.fresh().edit(
                "asset", abi.encode(address(subjects().tokens[0]))
            ).edit("quote", abi.encode(address(subjects().tokens[1]))).edit(
                "volatility", abi.encode(volatility)
            ).generate(address(subject()));

            poolIds.push(poolId);
        }

        uint128 amount = 0.1 ether;

        for (uint256 x; x != amountOfPools; ++x) {
            uint64 _poolId = poolIds[x];
            console.log("poolId", _poolId);
            // Add 25 LP
            subject().multiprocess(
                FVM.encodeAllocate(uint8(0), _poolId, 25 ether)
            );

            bool sellAsset = x % 2 == 0;

            // Problem! If I am allocating liquidity before my swap in a jump process, I can't use getAmountOut.
            uint128 amountOut = subject().getAmountOut(
                _poolId, sellAsset, amount
            ).safeCastTo128();
            amountOut = amountOut * 95 / 100;

            instructions.push(
                FVMLib.encodeSwap(
                    uint8(0),
                    _poolId,
                    amount,
                    amountOut,
                    uint8(sellAsset ? 1 : 0)
                )
            );
        }

        bytes memory payload = FVMLib.encodeJumpInstruction(instructions);
        console.log("Got calldata payload length:", payload.length);
        console.log("Executing");
        vm.resumeGasMetering();
        subject().multiprocess(payload);
        vm.pauseGasMetering();

        swapCalls++;
        delete poolIds;
        delete instructions;
    }

    function test_allocate_across_many()
        public
        pauseGas
        noJit
        defaultConfig
        useActor
        usePairTokens(10000 ether)
        isArmed
    {
        if (swapCalls > 0) return; // Only fuzz once with random seed.

        uint256 amountOfPools = 20;

        for (uint256 i; i != amountOfPools; ++i) {
            uint16 volatility = uint16(1000 * (i + 1));

            uint64 poolId = Configs.fresh().edit(
                "asset", abi.encode(address(subjects().tokens[0]))
            ).edit("quote", abi.encode(address(subjects().tokens[1]))).edit(
                "volatility", abi.encode(volatility)
            ).generate(address(subject()));

            poolIds.push(poolId);
        }

        uint128 amount = 0.1 ether;

        for (uint256 x; x != amountOfPools; ++x) {
            uint64 _poolId = poolIds[x];
            instructions.push(FVM.encodeAllocate(uint8(0), _poolId, amount));
        }

        bytes memory payload = FVMLib.encodeJumpInstruction(instructions);
        console.log("Got calldata payload length:", payload.length);
        console.log("Executing");
        vm.resumeGasMetering();
        subject().multiprocess(payload);
        vm.pauseGasMetering();

        delete poolIds;
        delete instructions;
    }
}
