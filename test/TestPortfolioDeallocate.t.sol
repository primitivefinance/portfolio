// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioDeallocate is Setup {
    function test_deallocate_max()
        public
        noJit
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        uint128 liquidity = 1 ether;
        subject().multiprocess(
            FVMLib.encodeAllocateOrDeallocate(true, uint8(0), ghost().poolId, liquidity)
        );

        // Deallocating liquidity can round down.
        uint256 prev = ghost().position(actor()).freeLiquidity;
        subject().multiprocess(
            FVMLib.encodeAllocateOrDeallocate(false, uint8(1), ghost().poolId, liquidity)
        );
        uint256 post = ghost().position(actor()).freeLiquidity;

        assertApproxEqAbs(
            post, prev - liquidity, 1, "liquidity-did-not-decrease"
        );
    }

    function test_deallocate_low_decimals(uint64 liquidity)
        public
        noJit
        sixDecimalQuoteConfig
        useActor
        usePairTokens(500 ether)
        isArmed
    {
        vm.assume(liquidity > 0);
        subject().multiprocess(
            FVMLib.encodeAllocateOrDeallocate(true, uint8(0), ghost().poolId, liquidity)
        );
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_volatility(
        uint64 liquidity,
        uint16 volatility
    )
        public
        noJit
        volatilityConfig(uint16(bound(volatility, MIN_VOLATILITY, MAX_VOLATILITY)))
        useActor
        usePairTokens(500 ether)
        isArmed
    {
        vm.assume(liquidity > 0);
        subject().multiprocess(
            FVMLib.encodeAllocateOrDeallocate(true, uint8(0), ghost().poolId, liquidity)
        );
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_duration(
        uint64 liquidity,
        uint16 duration
    )
        public
        noJit
        durationConfig(uint16(bound(duration, MIN_DURATION, MAX_DURATION)))
        useActor
        usePairTokens(500 ether)
        isArmed
    {
        vm.assume(liquidity > 0);
        subject().multiprocess(
            FVMLib.encodeAllocateOrDeallocate(true, uint8(0), ghost().poolId, liquidity)
        );
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_weth(uint64 liquidity)
        public
        noJit
        wethConfig
        useActor
        usePairTokens(500 ether)
        isArmed
    {
        vm.assume(liquidity > 0);
        vm.deal(actor(), 250 ether);
        subject().multiprocess{value: 250 ether}(
            FVMLib.encodeAllocateOrDeallocate(true, uint8(0), ghost().poolId, liquidity)
        );
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_over_time(
        uint64 liquidity,
        uint24 timestep
    ) public noJit defaultConfig useActor usePairTokens(500 ether) isArmed {
        vm.assume(liquidity > 0);
        subject().multiprocess(
            FVMLib.encodeAllocateOrDeallocate(true, uint8(0), ghost().poolId, liquidity)
        );
        vm.warp(block.timestamp + timestep);
        _simple_deallocate(liquidity);
    }

    function _simple_deallocate(uint128 amount) internal {
        uint256 prev = ghost().position(actor()).freeLiquidity;
        subject().multiprocess(
            FVMLib.encodeAllocateOrDeallocate(false, uint8(1), ghost().poolId, amount)
        );
        uint256 post = ghost().position(actor()).freeLiquidity;

        // Deallocating liquidity can round down.
        assertApproxEqAbs(post, prev - amount, 1, "liquidity-did-not-decrease");
    }
}
