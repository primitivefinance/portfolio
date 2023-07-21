// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioCreatePool is Setup {
    using NormalStrategyLib for PortfolioPool;

    uint256 internal constant PAIR_NONCE_STORAGE_SLOT = 4;
    uint256 internal constant POOL_NONCE_STORAGE_SLOT = 6;

    function testFuzz_createPool(
        uint16 priorityFee,
        uint16 fee,
        uint16 duration,
        uint16 volatility,
        uint128 strikePrice,
        uint128 price
    ) public {
        uint24 pairId = uint24(1);
        fee = uint16(bound(fee, MIN_FEE + 1, MAX_FEE));
        priorityFee = uint16(bound(priorityFee, 1, fee));
        duration = uint16(bound(duration, 1, 720));
        volatility = uint16(bound(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
        vm.assume(price > 0);
        vm.assume(strikePrice > 0);

        bytes[] memory data = new bytes[](1);

        ConfigType memory testConfig = DefaultStrategy.getTestConfig({
            portfolio: address(subject()),
            strikePriceWad: strikePrice,
            volatilityBasisPoints: volatility,
            durationSeconds: uint32(duration) * 1 days, // todo: fix with correct units
            isPerpetual: false,
            priceWad: uint256(price)
        });

        vm.assume(
            testConfig.reserveXPerWad > 0 && testConfig.reserveYPerWad > 0
        );

        data[0] = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                pairId, // magic pair id to use the nonce, which is the createPairId!
                testConfig.reserveXPerWad,
                testConfig.reserveYPerWad,
                fee, // fee
                priorityFee, // prior fee
                address(this), // controller
                testConfig.strategyArgs
            )
        );

        subject().multicall(data);

        uint64 poolId = AssemblyLib.encodePoolId(
            pairId, true, subject().getPoolNonce(pairId)
        );
        setGhostPoolId(poolId);

        PortfolioPool memory pool = ghost().pool();
        PortfolioConfig memory config = ghost().config();

        assertEq(pool.controller, address(this), "controller");
        assertEq(pool.priorityFeeBasisPoints, priorityFee, "priorityFee");
        assertEq(pool.feeBasisPoints, fee, "fee");
        assertEq(config.volatilityBasisPoints, volatility, "volatility");
        assertEq(
            config.durationSeconds,
            config.isPerpetual ? SECONDS_PER_YEAR : uint32(duration) * 1 days,
            "duration"
        );
        assertEq(config.strikePriceWad, strikePrice, "strikePrice");
    }

    function test_revert_createPool_priority_fee_invalid_fee() public {
        bytes[] memory data = new bytes[](1);

        ConfigType memory testConfig = DefaultStrategy.getTestConfig({
            portfolio: address(subject()),
            strikePriceWad: 1,
            volatilityBasisPoints: 1,
            durationSeconds: 1 * 1 days,
            isPerpetual: false,
            priceWad: 1
        });

        testConfig.reserveXPerWad++; // Avoid the reserve error
        testConfig.reserveYPerWad++; // Avoid the reserve error

        data[0] = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                uint24(1), // magic pair id to use the nonce, which is the createPairId!
                testConfig.reserveXPerWad,
                testConfig.reserveYPerWad,
                1, // fee
                0, // prior fee
                address(this), // controller
                testConfig.strategyArgs
            )
        );

        vm.expectRevert(
            abi.encodeWithSelector(PoolLib_InvalidPriorityFee.selector, 0)
        );
        subject().multicall(data);
    }

    bytes arithmeticError = abi.encodeWithSelector(0x4e487b71, 0x11); // 0x4e487b71 is Panic(uint256), and 0x11 is the
        // panic code for arithmetic overflow.

    /*
    function test_revert_createPool_above_max_pairs() public defaultConfig {
        bytes32 slot = bytes32(PAIR_NONCE_STORAGE_SLOT); // slot is packed so has the pair + pool nonces.
        vm.store(address(subject()), slot, bytes32(type(uint256).max)); // just set the whole slot of 0xf...
        assertEq(
            subject().getPairNonce(), type(uint24).max, "not set to max value"
        );

        address token = address(new MockERC20("t", "t", 18));

        bytes memory data =
            FVM.encodeCreatePair(ghost().asset().to_addr(), token);
        vm.expectRevert(arithmeticError);
        subject().multiprocess(data);
    }
    */

    /*
    function test_revert_createPool_above_max_pools() public {
        uint24 pairNonce = uint24(1);
        bytes32 slot =
            bytes32(keccak256(abi.encode(pairNonce, POOL_NONCE_STORAGE_SLOT)));
        vm.store(address(subject()), slot, bytes32(type(uint256).max)); // just set the whole slot of 0xf...
        assertEq(
            subject().getPoolNonce(pairNonce),
            type(uint32).max,
            "not set to max value"
        );

        bytes[] memory data = new bytes[](1);
        ConfigType memory testConfig = DefaultStrategy.getTestConfig({
            portfolio: address(subject()),
            strikePriceWad: 100,
            volatilityBasisPoints: 100,
            durationSeconds: 100 * 1 days,
            isPerpetual: false,
            priceWad: 1001
        });

        data[0] = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                pairNonce, // magic pair id to use the nonce, which is the createPairId!
                testConfig.reserveXPerWad,
                testConfig.reserveYPerWad,
                100, // fee
                0, // prior fee
                address(0), // controller
                testConfig.strategyArgs
            )
        );

        vm.expectRevert(arithmeticError);
        subject().multicall(data);
    }
    */

    // todo: fix
    function test_createPool_perpetual() public {
        uint24 pairNonce = uint24(1);
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                pairNonce,
                1,
                1,
                100,
                1,
                address(0),
                abi.encode(
                    PortfolioConfig(
                        100,
                        100,
                        uint32(100) * 1 days,
                        uint32(block.timestamp),
                        true
                    ),
                    100
                    )
            )
        );

        subject().multicall(data);
        uint64 poolId = AssemblyLib.encodePoolId(
            pairNonce, false, uint32(subject().getPoolNonce(pairNonce))
        );
        assertEq(
            ghost().configOf(poolId).durationSeconds,
            SECONDS_PER_YEAR,
            "duration != SECONDS_PER_YEAR"
        );
        assertEq(
            ghost().poolOf(poolId).computeTau(ghost().configOf(poolId), 0),
            SECONDS_PER_YEAR,
            "tau != year"
        );
        assertEq(
            ghost().poolOf(poolId).computeLatestTau(ghost().configOf(poolId)),
            SECONDS_PER_YEAR,
            "lastTau != year"
        );
    }
}
