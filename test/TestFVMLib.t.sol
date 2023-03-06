// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "contracts/libraries/FVMLib.sol";

struct DecodedCreatePool {
    uint24 pairId;
    address controller;
    uint16 priorityFee;
    uint16 fee;
    uint16 vol;
    uint16 dur;
    uint16 jit;
    uint128 maxPrice;
    uint128 price;
}

contract FVMLibTarget is Test {
    function decodeSwap_(bytes calldata data)
        external
        pure
        returns (uint8 useMax, uint64 poolId, uint128 input, uint128 output, uint8 sellAsset)
    {
        return decodeSwap(data);
    }

    function decodeClaim_(bytes calldata data) external pure returns (uint64 poolId, uint128 fee0, uint128 fee1) {
        return decodeClaim(data);
    }

    function decodePoolId_(bytes calldata data) external pure returns (uint64 poolId, uint24 pairId, uint8 isMutable, uint32 poolNonce) {
        return decodePoolId(data);
    }

    function decodeCreatePair_(bytes calldata data) external pure returns (address tokenAsset, address tokenQuote) {
        return decodeCreatePair(data);
    }

    function decodeCreatePool_(bytes calldata data) external pure returns (DecodedCreatePool memory pool) {
        (
            uint24 pairId,
            address controller,
            uint16 priorityFee,
            uint16 fee,
            uint16 vol,
            uint16 dur,
            uint16 jit,
            uint128 maxPrice,
            uint128 price
        ) = decodeCreatePool(data);

        pool.pairId = pairId;
        pool.controller = controller;
        pool.priorityFee = priorityFee;
        pool.fee = fee;
        pool.vol = vol;
        pool.dur = dur;
        pool.jit = jit;
        pool.maxPrice = maxPrice;
        pool.price = price;
    }
}

contract TestFVMLib is Test {
    FVMLibTarget public target = new FVMLibTarget();

    function testFuzz_encodeSwap(
        bool useMax,
        uint64 poolId,
        uint128 amount0,
        uint128 amount1,
        bool sellAsset
    ) public {
        bytes memory data = encodeSwap(
            useMax ? uint8(1) : uint8(0),
            poolId,
            amount0,
            amount1,
            sellAsset ? uint8(1) : uint8(0)
        );

        console.logBytes(data);

        (uint8 useMax_, uint64 poolId_, uint128 input_, uint128 output_, uint8 sellAsset_) = target.decodeSwap_(data);

        assertEq(useMax ? uint8(1) : uint8(0), useMax_, "Wrong use max");
        assertEq(poolId, poolId_);
        assertEq(amount0, input_);
        assertEq(amount1, output_);
        assertEq(sellAsset ? uint8(1) : uint8(0), sellAsset_, "Wrong sellAsset");
    }

    function test_decodeSwap() public {
        bytes memory data = hex"0500042a0709081204";

        (
            uint8 useMax,
            uint64 poolId,
            uint128 input,
            uint128 output,
            uint8 sellAsset
        ) = target.decodeSwap_(data);

        assertEq(useMax, 0);
        assertEq(poolId, 42);
        assertEq(input, 8000 * 10 ** 6);
        assertEq(output, 4 * 10 ** 18);
        assertEq(sellAsset, 0);
    }

    function testFuzz_encodeClaim(uint64 poolId, uint128 fee0, uint128 fee1) public {
        bytes memory data = encodeClaim(poolId, fee0, fee1);

        (uint64 poolId_, uint128 fee0_, uint128 fee1_) = target.decodeClaim_(data);

        assertEq(poolId, poolId_);
        assertEq(fee0, fee0_);
        assertEq(fee1, fee1_);
    }

    function test_decodeClaim() public {
        bytes memory data = hex"10032a0609081204";
        (uint64 poolId, uint128 fee0, uint128 fee1) = target.decodeClaim_(data);

        assertEq(poolId, 42);
        assertEq(fee0, 8000 * 10 ** 6);
        assertEq(fee1, 4 * 10 ** 18);
    }

    function testFuzz_decodeCreatePair(address token0, address token1) public {
        bytes memory data = encodeCreatePair(token0, token1);
        (address token0_, address token1_) = target.decodeCreatePair_(data);
        assertEq(token0, token0_);
        assertEq(token1, token1_);
    }

    function test_decodeCreatePair_RevertIfBadLength() public {
        bytes memory data = hex"01";
        vm.expectRevert();
        target.decodeCreatePair_(data);
    }

    function testFuzz_encodeCreatePool(
        uint24 pairId,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 vol,
        uint16 dur,
        uint16 jit,
        uint128 maxPrice,
        uint128 price
    ) public {
        bytes memory data = encodeCreatePool(
            pairId,
            controller,
            priorityFee,
            fee,
            vol,
            dur,
            jit,
            maxPrice,
            price
        );

        DecodedCreatePool memory pool = target.decodeCreatePool_(data);

        assertEq(pairId, pool.pairId);
        assertEq(controller, pool.controller);
        assertEq(priorityFee, pool.priorityFee);
        assertEq(fee, pool.fee);
        assertEq(vol, pool.vol);
        assertEq(dur, pool.dur);
        assertEq(jit, pool.jit);
        assertEq(maxPrice, pool.maxPrice);
        assertEq(price, pool.price);
    }
}
