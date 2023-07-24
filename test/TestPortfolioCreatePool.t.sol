// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioCreatePool is Setup {
    using NormalConfiguration for Configuration;
    using NormalStrategyLib for PortfolioPool;
    using { safeCastTo16 } for uint256;

    uint256 internal constant PAIR_NONCE_STORAGE_SLOT = 4;
    uint256 internal constant POOL_NONCE_STORAGE_SLOT = 6;

    function testFuzz_createPool(uint256 seed) public fuzzAllConfig(seed) {
        PortfolioPool memory pool = ghost().pool();
        PortfolioConfig memory config = ghost().config();
        PortfolioConfig memory globalPortfolioConfig =
            NormalStrategyLib.decode(global_config().strategyArgs);

        assertEq(pool.controller, global_config().controller, "controller");
        assertEq(
            pool.priorityFeeBasisPoints,
            global_config().priorityFeeBasisPoints,
            "priorityFee"
        );
        assertEq(pool.feeBasisPoints, global_config().feeBasisPoints, "fee");
        assertEq(
            config.volatilityBasisPoints,
            globalPortfolioConfig.volatilityBasisPoints,
            "volatility"
        );
        assertEq(
            config.durationSeconds,
            globalPortfolioConfig.durationSeconds,
            "duration"
        );
        assertEq(
            config.strikePriceWad,
            globalPortfolioConfig.strikePriceWad,
            "strikePrice"
        );
    }

    function test_revert_createPool_invalid_pair_nonce() public {
        Configuration memory testConfig = configureNormalStrategy();

        testConfig.reserveXPerWad++; // Avoid the reserve error
        testConfig.reserveYPerWad++; // Avoid the reserve error

        vm.expectRevert();

        subject().createPool(
            0,
            testConfig.reserveXPerWad,
            testConfig.reserveYPerWad,
            100, // fee
            0, // prior fee
            address(0), // controller
            address(0), // strategy
            testConfig.strategyArgs
        );
    }

    function test_createPool_no_strategy_defaults() public defaultConfig {
        Configuration memory testConfig = configureNormalStrategy();

        testConfig.reserveXPerWad++; // Avoid the reserve error
        testConfig.reserveYPerWad++; // Avoid the reserve error

        uint64 poolId = subject().createPool(
            0,
            testConfig.reserveXPerWad,
            testConfig.reserveYPerWad,
            100, // fee
            0, // prior fee
            address(0), // controller
            address(0), // strategy
            testConfig.strategyArgs
        );

        (,,,,,,, address strategy) = subject().pools(poolId);
        assertEq(strategy, subject().DEFAULT_STRATEGY());
    }

    function test_revert_createPool_invalid_priority_fee() public {
        bytes[] memory data = new bytes[](1);

        Configuration memory testConfig = configureNormalStrategy().edit(
            "priorityFeeBasisPoints", abi.encode(0)
        );

        testConfig.reserveXPerWad++; // Avoid the reserve error
        testConfig.reserveYPerWad++; // Avoid the reserve error

        data[0] = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                uint24(1), // magic pair id to use the nonce, which is the createPairId!
                testConfig.reserveXPerWad,
                testConfig.reserveYPerWad,
                1, // fee
                testConfig.priorityFeeBasisPoints.safeCastTo16(), // prior fee
                address(this), // controller
                subject().DEFAULT_STRATEGY(),
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
        Configuration memory testConfig = DefaultStrategy.getTestConfig({
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
                subject().DEFAULT_STRATEGY(),
                abi.encode(
                    PortfolioConfig(
                        100,
                        100,
                        uint32(100) * 1 days,
                        uint32(block.timestamp),
                        true
                    )
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
