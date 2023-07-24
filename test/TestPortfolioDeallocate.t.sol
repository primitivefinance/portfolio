// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioDeallocate is Setup {
    // todo: fix duration params...
    uint256 constant TEST_DEALLOCATE_MIN_DURATION = 1;
    uint256 constant TEST_DEALLOCATE_MAX_DURATION = 700;

    function test_deallocate_max()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
    {
        uint128 liquidity = 1 ether;

        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );

        // Deallocating liquidity can round down.
        uint256 prev = ghost().position(actor());
        uint128 amount = liquidity;
        if (amount > prev) {
            amount = uint128(prev);
        }

        subject().deallocate(true, ghost().poolId, amount, 0, 0);
        uint256 post = ghost().position(actor());

        assertApproxEqAbs(
            post, prev - liquidity, 1, "liquidity-did-not-decrease"
        );
    }

    function test_deallocate_low_decimals(uint64 liquidity)
        public
        sixDecimalQuoteConfig
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY * 1e5))
    {
        vm.assume(liquidity > 1e15);
        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_volatility(
        uint256 seed,
        uint64 liquidity
    )
        public
        fuzzConfig("volatilityBasisPoints", seed)
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
    {
        vm.assume(liquidity > 0);
        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_duration(
        uint256 seed,
        uint64 liquidity
    )
        public
        fuzzConfig("durationSeconds", seed)
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
    {
        vm.assume(liquidity > 0);
        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_weth(uint64 liquidity)
        public
        wethConfig
        useActor
        usePairTokens(500 ether)
    {
        vm.assume(liquidity > BURNED_LIQUIDITY);
        vm.deal(actor(), 250 ether);
        subject().allocate{ value: 250 ether }(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_over_time(
        uint64 liquidity,
        uint24 timestep
    )
        public
        defaultConfig
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
    {
        vm.assume(liquidity > 0);
        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            liquidity,
            type(uint128).max,
            type(uint128).max
        );
        vm.warp(block.timestamp + timestep);
        _simple_deallocate(liquidity);
    }

    function test_deallocate_reverts_when_min_asset_unmatched()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;
        subject().allocate(
            false,
            address(this),
            xid,
            amount,
            type(uint128).max,
            type(uint128).max
        );
        vm.expectRevert();
        subject().deallocate(true, ghost().poolId, amount, type(uint128).max, 0);
    }

    // TODO: Not sure what's the purpose of this test since deallocate is never
    // called?
    function test_deallocate_reverts_when_min_quote_unmatched()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
    {
        uint128 amount = 0.1 ether;
        uint64 xid = ghost().poolId;

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                xid,
                amount,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(data);

        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (false, address(this), ghost().poolId, amount, 0, type(uint128).max)
        );
        vm.expectRevert();
        subject().multicall(data);
    }

    function _simple_deallocate(uint128 amount) internal {
        uint256 prev = ghost().position(actor());
        uint128 amountToRemove = amount;
        if (amount > prev) {
            amountToRemove = uint128(prev);
        }

        bool useMax = false;
        subject().deallocate(useMax, ghost().poolId, amountToRemove, 0, 0);
        uint256 post = ghost().position(actor());

        // Deallocating liquidity can round down.
        assertApproxEqAbs(
            post, prev - amountToRemove, 1, "liquidity-did-not-decrease"
        );
    }
}
