// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioDeallocate is Setup {
    function test_deallocate_max()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
        isArmed
    {
        uint128 liquidity = 1 ether;

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                liquidity,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(data);

        // Deallocating liquidity can round down.
        uint256 prev = ghost().position(actor());
        uint128 amount = liquidity;
        if (amount > prev) {
            amount = uint128(prev);
        }
        data[0] = abi.encodeCall(
            IPortfolioActions.deallocate, (true, ghost().poolId, amount, 0, 0)
        );
        subject().multicall(data);
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
        allocateSome(uint128(BURNED_LIQUIDITY * 1e3))
        isArmed
    {
        vm.assume(liquidity > 10 ** (18 - 6));
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                liquidity,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(data);
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_volatility(
        uint64 liquidity,
        uint16 volatility
    )
        public
        volatilityConfig(uint16(bound(volatility, MIN_VOLATILITY, MAX_VOLATILITY)))
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
        isArmed
    {
        vm.assume(liquidity > 0);
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                liquidity,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(data);
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_duration(
        uint64 liquidity,
        uint16 duration
    )
        public
        durationConfig(uint16(bound(duration, MIN_DURATION, MAX_DURATION)))
        useActor
        usePairTokens(500 ether)
        allocateSome(uint128(BURNED_LIQUIDITY))
        isArmed
    {
        vm.assume(liquidity > 0);
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                liquidity,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(data);
        _simple_deallocate(liquidity);
    }

    function testFuzz_deallocate_weth(uint64 liquidity)
        public
        wethConfig
        useActor
        usePairTokens(500 ether)
        isArmed
    {
        vm.assume(liquidity > BURNED_LIQUIDITY);
        vm.deal(actor(), 250 ether);

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                liquidity,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall{ value: 250 ether }(data);
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
        isArmed
    {
        vm.assume(liquidity > 0);
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                liquidity,
                type(uint128).max,
                type(uint128).max
            )
        );
        subject().multicall(data);
        vm.warp(block.timestamp + timestep);
        _simple_deallocate(liquidity);
    }

    function test_deallocate_reverts_when_min_asset_unmatched()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
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
        vm.expectRevert();

        data[0] = abi.encodeCall(
            IPortfolioActions.deallocate,
            (true, ghost().poolId, amount, type(uint128).max, 0)
        );
        subject().multicall(data);
    }

    function test_deallocate_reverts_when_min_quote_unmatched()
        public
        defaultConfig
        useActor
        usePairTokens(10 ether)
        isArmed
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

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.deallocate,
            (useMax, ghost().poolId, amountToRemove, 0, 0)
        );
        subject().multicall(data);

        uint256 post = ghost().position(actor());

        // Deallocating liquidity can round down.
        assertApproxEqAbs(
            post, prev - amountToRemove, 1, "liquidity-did-not-decrease"
        );
    }
}
