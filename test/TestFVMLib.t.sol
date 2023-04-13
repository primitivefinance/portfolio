// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "contracts/libraries/FVMLib.sol";

struct CreatePoolParams {
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
        returns (
            uint8 useMax,
            uint64 poolId,
            uint128 input,
            uint128 output,
            uint8 sellAsset
        )
    {
        return decodeSwap(data);
    }

    function decodePoolId_(bytes calldata data)
        external
        pure
        returns (
            uint64 poolId,
            uint24 pairId,
            uint8 isMutable,
            uint32 poolNonce
        )
    {
        return decodePoolId(data);
    }

    function decodeCreatePair_(bytes calldata data)
        external
        pure
        returns (address tokenAsset, address tokenQuote)
    {
        return decodeCreatePair(data);
    }

    function decodeCreatePool_(bytes calldata data)
        external
        pure
        returns (CreatePoolParams memory params)
    {
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

        params.pairId = pairId;
        params.controller = controller;
        params.priorityFee = priorityFee;
        params.fee = fee;
        params.vol = vol;
        params.dur = dur;
        params.jit = jit;
        params.maxPrice = maxPrice;
        params.price = price;
    }

    function decodeAllocateOrDeallocate_(bytes calldata data)
        external
        pure
        returns (
            uint8 useMax,
            uint64 poolId,
            uint128 deltaLiquidity,
            uint128 deltaAsset,
            uint128 deltaQuote
        )
    {
        return decodeAllocateOrDeallocate(data);
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

        (
            uint8 useMax_,
            uint64 poolId_,
            uint128 input_,
            uint128 output_,
            uint8 sellAsset_
        ) = target.decodeSwap_(data);

        assertEq(useMax ? uint8(1) : uint8(0), useMax_, "Wrong use max");
        assertEq(poolId, poolId_);
        assertEq(amount0, input_);
        assertEq(amount1, output_);
        assertEq(sellAsset ? uint8(1) : uint8(0), sellAsset_, "Wrong sellAsset");
    }

    function test_decodeSwap() public {
        bytes memory data =
            encodeSwap(1, 0xaaffffffffffffbb, 1 ether, 2000 * 10 ** 6, 1);

        (
            uint8 useMax,
            uint64 poolId,
            uint128 input,
            uint128 output,
            uint8 sellAsset
        ) = target.decodeSwap_(data);

        assertEq(useMax, 1);
        assertEq(poolId, 0xaaffffffffffffbb);
        assertEq(input, 1 ether);
        assertEq(output, 2000 * 10 ** 6);
        assertEq(sellAsset, 1);
    }

    function test_decodeSwap_RevertIfPower0Overflows() public {
        bytes memory data =
            hex"16aaffffffffffffbb1b4e000000000000000000000000000000010900000000000000000000000000000002";
        vm.expectRevert(Overflow.selector);
        target.decodeSwap_(data);
    }

    function test_decodeSwap_RevertIfPower1Overflows() public {
        bytes memory data =
            hex"16aaffffffffffffbb1b4e000000000000000000000000000000014e00000000000000000000000000000002";
        vm.expectRevert(Overflow.selector);
        target.decodeSwap_(data);
    }

    function test_decodeSwap_RevertIfInputOverflows() public {
        bytes memory data =
            hex"16aaffffffffffffbb1b4effffffffffffffffffffffffffffffff0901";
        vm.expectRevert(Overflow.selector);
        target.decodeSwap_(data);
    }

    function test_decodeSwap_RevertIfOuputOverflows() public {
        bytes memory data =
            hex"16aaffffffffffffbb1b120000000000000000000000000000000109ffffffffffffffffffffffffffffffff";
        vm.expectRevert(Overflow.selector);
        target.decodeSwap_(data);
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
            pairId, controller, priorityFee, fee, vol, dur, jit, maxPrice, price
        );

        CreatePoolParams memory params = target.decodeCreatePool_(data);

        assertEq(pairId, params.pairId);
        assertEq(controller, params.controller);
        assertEq(priorityFee, params.priorityFee);
        assertEq(fee, params.fee);
        assertEq(vol, params.vol);
        assertEq(dur, params.dur);
        assertEq(jit, params.jit);
        assertEq(maxPrice, params.maxPrice);
        assertEq(price, params.price);
    }

    function test_encodeCreatePool() public {
        CreatePoolParams memory params = CreatePoolParams({
            pairId: uint24(0xaaaaaa),
            controller: address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF),
            priorityFee: uint16(0xbbbb),
            fee: uint16(0xcccc),
            vol: uint16(0xdddd),
            dur: uint16(0xeeee),
            jit: uint16(0xffff),
            maxPrice: 2000 * 10 ** 6,
            price: 3 * 10 ** 18
        });

        bytes memory data = encodeCreatePool(
            params.pairId,
            params.controller,
            params.priorityFee,
            params.fee,
            params.vol,
            params.dur,
            params.jit,
            params.maxPrice,
            params.price
        );

        CreatePoolParams memory decoded = target.decodeCreatePool_(data);

        assertEq(decoded.pairId, params.pairId);
        assertEq(decoded.controller, params.controller);
        assertEq(decoded.priorityFee, params.priorityFee);
        assertEq(decoded.fee, params.fee);
        assertEq(decoded.vol, params.vol);
        assertEq(decoded.dur, params.dur);
        assertEq(decoded.jit, params.jit);
        assertEq(decoded.maxPrice, params.maxPrice);
        assertEq(decoded.price, params.price);
    }

    function test_decodeCreatePool() public {
        CreatePoolParams memory decoded = target.decodeCreatePool_(
            hex"0baaaaaaffffffffffffffffffffffffffffffffffffffffbbbbccccddddeeeeffff2509021203"
        );

        assertEq(decoded.pairId, uint24(0xaaaaaa));
        assertEq(
            decoded.controller,
            address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)
        );
        assertEq(decoded.priorityFee, uint16(0xbbbb));
        assertEq(decoded.fee, uint16(0xcccc));
        assertEq(decoded.vol, uint16(0xdddd));
        assertEq(decoded.dur, uint16(0xeeee));
        assertEq(decoded.jit, uint16(0xffff));
        assertEq(decoded.maxPrice, 2 * 10 ** 9);
        assertEq(decoded.price, 3 * 10 ** 18);
    }

    function test_decodeCreatePool_RevertIfMaxPriceOverflows() public {
        vm.expectRevert(Overflow.selector);
        target.decodeCreatePool_(
            hex"0baaaaaaffffffffffffffffffffffffffffffffffffffffbbbbccccddddeeeeffff3409ffffffffffffffffffffffffffffffff0101"
        );
    }

    function test_decodeCreatePool_RevertIfPriceOverflows() public {
        vm.expectRevert(Overflow.selector);
        target.decodeCreatePool_(
            hex"0baaaaaaffffffffffffffffffffffffffffffffffffffffbbbbccccddddeeeeffff25090201ffffffffffffffffffffffffffffffff"
        );
    }

    function testFuzz_encodeAllocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 deltaAsset,
        uint128 deltaQuote
    ) public {
        bytes memory data = encodeAllocateOrDeallocate(
            true,
            useMax ? uint8(1) : uint8(0),
            poolId,
            deltaLiquidity,
            deltaAsset,
            deltaQuote
        );

        (
            uint8 useMax_,
            uint64 poolId_,
            uint128 deltaLiquidity_,
            uint128 deltaAsset_,
            uint128 deltaQuote_
        ) = target.decodeAllocateOrDeallocate_(data);

        assertEq(useMax ? uint8(1) : uint8(0), useMax_);
        assertEq(poolId, poolId_);
        assertEq(deltaLiquidity, deltaLiquidity_);
        assertEq(deltaAsset, deltaAsset_);
        assertEq(deltaQuote, deltaQuote_);
    }

    function testFuzz_encodeDeallocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 deltaAsset,
        uint128 deltaQuote
    ) public {
        bytes memory data = encodeAllocateOrDeallocate(
            false,
            useMax ? uint8(1) : uint8(0),
            poolId,
            deltaLiquidity,
            deltaAsset,
            deltaQuote
        );

        (
            uint8 useMax_,
            uint64 poolId_,
            uint128 deltaLiquidity_,
            uint128 deltaAsset_,
            uint128 deltaQuote_
        ) = target.decodeAllocateOrDeallocate_(data);

        assertEq(useMax ? uint8(1) : uint8(0), useMax_);
        assertEq(poolId, poolId_);
        assertEq(deltaLiquidity, deltaLiquidity_);
        assertEq(deltaAsset, deltaAsset_);
        assertEq(deltaQuote, deltaQuote_);
    }

    function test_decodeAllocateOrDeallocate() public {
        bytes memory data = hex"01aaaaaaaaaaaaaaaa0d0f1202102a0906";

        (
            uint8 useMax,
            uint64 poolId,
            uint128 amount,
            uint128 deltaAsset,
            uint128 deltaQuote
        ) = target.decodeAllocateOrDeallocate_(data);
        assertEq(useMax, 0);
        assertEq(poolId, uint64(0xaaaaaaaaaaaaaaaa));
        assertEq(amount, uint128(2000000000000000000));
        assertEq(deltaAsset, uint128(420000000000000000));
        assertEq(deltaQuote, uint128(6000000000));
    }

    function test_decodeAllocateOrDeallocate_RevertBadLength() public {
        bytes memory data = hex"11aaffffffffffffbb0e";
        vm.expectRevert(
            abi.encodePacked(
                InvalidBytesLength.selector, uint256(11), uint256(10)
            )
        );
        target.decodeAllocateOrDeallocate_(data);
    }

    function test_decodeAllocateOrDeallocate_RevertWhenDeltaLiquidityOverflows()
        public
    {
        bytes memory data =
            hex"1100000000aabbccdd1c2d01ffffffffffffffffffffffffffffffff03000000000000000000000000000000010300000000000000000000000000000002";
        vm.expectRevert(Overflow.selector);
        target.decodeAllocateOrDeallocate_(data);
    }

    function test_decodeAllocateOrDeallocate_RevertWhenDeltaAssetOverflows()
        public
    {
        bytes memory data =
            hex"1100000000aabbccdd1c2d010000000000000000000000000000000103ffffffffffffffffffffffffffffffff0300000000000000000000000000000002";
        vm.expectRevert(Overflow.selector);
        target.decodeAllocateOrDeallocate_(data);
    }

    function test_decodeAllocateOrDeallocate_RevertWhenDeltaQuoteOverflows()
        public
    {
        bytes memory data =
            hex"1100000000aabbccdd1c2d0100000000000000000000000000000001030000000000000000000000000000000103ffffffffffffffffffffffffffffffff";
        vm.expectRevert(Overflow.selector);
        target.decodeAllocateOrDeallocate_(data);
    }

    function test_encodePoolId() public {
        uint64 poolId = encodePoolId(uint24(0xaaaaaa), true, uint32(0xbbbbbbbb));

        assertEq(poolId, uint64(0xaaaaaa01bbbbbbbb));
    }

    function testFuzz_decodePoolId(
        uint24 pairId,
        bool isMutable,
        uint32 poolNonce
    ) public {
        uint64 poolId = encodePoolId(pairId, isMutable, poolNonce);

        console.log(poolId);

        bytes memory data;

        assembly {
            mstore(data, 8)
            mstore(add(0x20, data), shl(192, poolId))
        }

        (uint64 poolId_, uint24 pairId_, uint8 isMutable_, uint32 poolNonce_) =
            target.decodePoolId_(data);

        assertEq(poolId, poolId_);
        assertEq(pairId, pairId_);
        assertEq(isMutable ? uint8(1) : uint8(0), isMutable_);
        assertEq(poolNonce, poolNonce_);
    }

    function test_decodePoolId_RevertsBadLength() public {
        bytes memory data = hex"aaaaaaaaaaaaaa";
        vm.expectRevert(
            abi.encodePacked(
                InvalidBytesLength.selector, uint256(8), uint256(7)
            )
        );
        target.decodePoolId_(data);
        data = hex"aaaaaaaaaaaaaaaaaa";
        vm.expectRevert(
            abi.encodePacked(
                InvalidBytesLength.selector, uint256(8), uint256(9)
            )
        );
        target.decodePoolId_(data);
    }

    function testFuzz_decodePairIdFromPoolId(
        uint24 pairId,
        bool isMutable,
        uint32 poolNonce
    ) public {
        uint64 decodedPairId =
            decodePairIdFromPoolId(encodePoolId(pairId, isMutable, poolNonce));

        assertEq(decodedPairId, pairId);
    }
}
