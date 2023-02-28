// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "contracts/libraries/EnigmaLib.sol";

contract EnigmaLibTarget is Test {
    function doEncodeSwap(
        uint8 useMax,
        uint64 poolId,
        uint8 power0,
        uint128 amount0,
        uint8 power1,
        uint128 amount1,
        uint8 direction
    ) external pure returns (bytes memory) {
        return encodeSwap(
            useMax,
            poolId,
            power0,
            amount0,
            power1,
            amount1,
            direction
        );
    }

    function doDecodeSwap(bytes calldata data)
        external
        view
        returns (
            uint8 useMax,
            uint64 poolId,
            uint128 input,
            uint128 output,
            uint8 direction
        )
    {
        console.logBytes(data[9:26]);
        return decodeSwap(data);
    }
}

contract TestEnigmaLib is Test {
    EnigmaLibTarget public target = new EnigmaLibTarget();

    function testFuzz_encodeSwap(
        bool useMax,
        uint64 poolId,
        uint8 power0,
        uint64 amount0,
        uint8 power1,
        uint64 amount1,
        bool direction
    ) public {
        vm.assume(power0 <= 18);
        vm.assume(power1 <= 18);

        bytes memory data = target.doEncodeSwap(
            useMax ? uint8(1) : uint8(0),
            poolId,
            power0,
            amount0,
            power1,
            amount1,
            direction ? uint8(1) : uint8(0)
        );

        console.logBytes(data);

        (
            uint8 useMax_,
            uint64 poolId_,
            uint128 input_,
            uint128 output_,
            uint8 direction_
        ) = target.doDecodeSwap(data);

        assertEq(useMax ? uint8(1) : uint8(0), useMax_, "Wrong use max");
        assertEq(poolId, poolId_);
        assertEq(amount0 * 10 ** power0, input_);
        assertEq(amount1 * 10 ** power1, output_);
        assertEq(direction ? uint8(1) : uint8(0), direction_, "Wrong direction");
    }
}
