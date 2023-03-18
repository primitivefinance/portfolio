// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestGas is Setup {
    using SafeCastLib for uint256;
    using AssemblyLib for uint256;

    // helpers
    modifier usePools(uint256 amount) {
        _create_pools(amount);
        _;
    }

    function _getTokens() internal returns (address, address) {
        return (address(subjects().tokens[0]), address(subjects().tokens[1]));
    }

    uint256 internal constant POOLS_LIMIT = 100;

    IPortfolio _subject;

    // setup
    function setUp() public override {
        super.setUp();
        _subject = subject(); // We use the same subject in this contract.
    }

    function test_gas_single_allocate()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        bytes memory data = FVM.encodeAllocateOrDeallocate(
            true, uint8(0), ghost().poolId, 1 ether
        );
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_single_deallocate()
        public
        pauseGas
        noJit
        usePools(1)
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
        isArmed
    {
        bytes memory data = FVM.encodeAllocateOrDeallocate(
            false, uint8(0), ghost().poolId, 1 ether
        );
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_single_swap()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
        allocateSome(1 ether)
        isArmed
    {
        bool sellAsset = true;
        uint128 amountIn = uint128(0.01 ether);
        uint128 estimatedAmountOut = uint128(
            _subject.getAmountOut(ghost().poolId, sellAsset, amountIn) * 95
                / 100
        );
        bytes memory data = FVM.encodeSwap(
            uint8(0),
            ghost().poolId,
            amountIn,
            estimatedAmountOut,
            uint8(sellAsset ? 1 : 0)
        );
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_multi_allocate_2_pairs()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        // Create another pair and pool.
        (address token0, address token1) =
            (address(subjects().tokens[1]), address(subjects().tokens[2]));

        _approveMint(address(token0), 100 ether);
        _approveMint(address(token1), 100 ether);

        subject().fund(ghost().asset().to_addr(), type(uint256).max);
        subject().fund(address(token0), type(uint256).max);
        subject().fund(address(token1), type(uint256).max);

        subject().multiprocess(
            FVM.encodeCreatePair(address(token0), address(token1))
        );
        uint16 hundred = uint16(100);
        subject().multiprocess(
            FVM.encodeCreatePool(
                uint24(0),
                address(0),
                0,
                hundred,
                1e4,
                hundred,
                0,
                10 ether,
                10 ether
            )
        );

        bytes[] memory instructions = new bytes[](2);
        for (uint256 i; i != 2; ++i) {
            uint64 poolId;
            if (i == 0) poolId = ghost().poolId;
            else poolId = FVM.encodePoolId(uint24(2), false, uint32(1));

            instructions[i] =
                FVM.encodeAllocateOrDeallocate(true, uint8(0), poolId, 1 ether);
        }

        bytes memory data = FVM.encodeJumpInstruction(instructions);
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_multi_allocate_2()
        public
        pauseGas
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(2, false);
    }

    function test_gas_multi_allocate_5()
        public
        pauseGas
        usePools(5)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(5, false);
    }

    function test_gas_multi_allocate_10()
        public
        pauseGas
        usePools(10)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(10, false);
    }

    function test_gas_multi_allocate_25()
        public
        pauseGas
        usePools(25)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(25, false);
    }

    function test_gas_multi_allocate_50()
        public
        pauseGas
        usePools(50)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(50, false);
    }

    function test_gas_multi_allocate_100()
        public
        pauseGas
        usePools(100)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(100, false);
    }

    function test_gas_multi_deallocate_2_pool_2_pair()
        public
        pauseGas
        noJit
        usePools(1)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        // Create another pair and pool.
        (address token0, address token1) =
            (address(subjects().tokens[1]), address(subjects().tokens[2]));

        _approveMint(address(token0), 100 ether);
        _approveMint(address(token1), 100 ether);

        subject().fund(ghost().asset().to_addr(), type(uint256).max);
        subject().fund(address(token0), type(uint256).max);
        subject().fund(address(token1), type(uint256).max);

        subject().multiprocess(
            FVM.encodeCreatePair(address(token0), address(token1))
        );
        uint16 hundred = uint16(100);
        subject().multiprocess(
            FVM.encodeCreatePool(
                uint24(0),
                address(0),
                0,
                hundred,
                1e4,
                hundred,
                0,
                10 ether,
                10 ether
            )
        );

        bytes[] memory instructions = new bytes[](2);
        for (uint256 i; i != 2; ++i) {
            uint64 poolId;
            if (i == 0) poolId = ghost().poolId;
            else poolId = FVM.encodePoolId(uint24(2), false, uint32(1));

            subject().multiprocess(
                FVM.encodeAllocateOrDeallocate(true, uint8(0), poolId, 1 ether)
            );

            instructions[i] =
                FVM.encodeAllocateOrDeallocate(false, uint8(0), poolId, 1 ether);
        }

        bytes memory data = FVM.encodeJumpInstruction(instructions);
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_multi_deallocate_2()
        public
        pauseGas
        noJit
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(2, true);
        _multi_deallocate(2, false);
    }

    function test_gas_multi_deallocate_5()
        public
        pauseGas
        noJit
        usePools(5)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(5, true);
        _multi_deallocate(5, false);
    }

    function test_gas_multi_deallocate_10()
        public
        pauseGas
        noJit
        usePools(10)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(10, true);
        _multi_deallocate(10, false);
    }

    function test_gas_multi_deallocate_25()
        public
        pauseGas
        noJit
        usePools(25)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(25, true);
        _multi_deallocate(25, false);
    }

    function test_gas_multi_deallocate_50()
        public
        pauseGas
        noJit
        usePools(50)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(50, true);
        _multi_deallocate(50, false);
    }

    function test_gas_multi_deallocate_100()
        public
        pauseGas
        noJit
        usePools(100)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(100, true);
        _multi_deallocate(100, false);
    }

    function test_gas_multi_create_pool_100()
        public
        pauseGas
        noJit
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(2, true);
        _multi_deallocate(2, false);
    }

    function test_gas_multi_swap_2_pairs()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        // Create another pair and pool.
        (address token0, address token1) =
            (address(subjects().tokens[1]), address(subjects().tokens[2]));

        _approveMint(address(token0), 100 ether);
        _approveMint(address(token1), 100 ether);

        subject().fund(ghost().asset().to_addr(), type(uint256).max);
        subject().fund(address(token0), type(uint256).max);
        subject().fund(address(token1), type(uint256).max);

        subject().multiprocess(
            FVM.encodeCreatePair(address(token0), address(token1))
        );
        uint16 hundred = uint16(100);
        subject().multiprocess(
            FVM.encodeCreatePool(
                uint24(0),
                address(0),
                0,
                hundred,
                1e4,
                hundred,
                0,
                10 ether,
                10 ether
            )
        );

        bytes[] memory instructions = new bytes[](2);
        for (uint256 i; i != 2; ++i) {
            uint64 poolId;
            if (i == 0) poolId = ghost().poolId;
            else poolId = FVM.encodePoolId(uint24(2), false, uint32(1));
            subject().multiprocess(
                FVM.encodeAllocateOrDeallocate(true, uint8(0), poolId, 5 ether)
            );

            bool sellAsset = i % 2 == 0;
            PortfolioPool memory pool =
                IPortfolioStruct(address(_subject)).pools(poolId);
            uint128 amountIn = RMM01Portfolio(payable(address(_subject)))
                .computeMaxInput({
                poolId: poolId,
                sellAsset: sellAsset,
                reserveIn: sellAsset ? pool.virtualX : pool.virtualY,
                liquidity: pool.liquidity
            }).scaleFromWadDown(pool.pair.decimalsQuote).safeCastTo128() / 20;
            uint128 estimatedAmountOut = uint128(
                _subject.getAmountOut(poolId, sellAsset, amountIn) * 95 / 100
            );

            instructions[i] = FVM.encodeSwap(
                uint8(0),
                poolId,
                amountIn,
                estimatedAmountOut,
                uint8(sellAsset ? 1 : 0)
            );
        }

        bytes memory data = FVM.encodeJumpInstruction(instructions);
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_multi_swap_2()
        public
        pauseGas
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(2, true);
        _multi_swap(2, false);
    }

    function test_gas_multi_swap_5()
        public
        pauseGas
        usePools(5)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(5, true);
        _multi_swap(5, false);
    }

    function test_gas_multi_swap_10()
        public
        pauseGas
        usePools(10)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(10, true);
        _multi_swap(10, false);
    }

    function test_gas_multi_swap_25()
        public
        pauseGas
        usePools(25)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(25, true);
        _multi_swap(25, false);
    }

    function test_gas_multi_swap_50()
        public
        pauseGas
        usePools(50)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(50, true);
        _multi_swap(50, false);
    }

    function test_gas_multi_swap_100()
        public
        pauseGas
        usePools(100)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(100, true);
        _multi_swap(100, false);
    }

    function _create_pools(uint256 amount) internal {
        require(amount <= POOLS_LIMIT);
        address controller = address(0);
        (address a0, address q0) =
            (address(subjects().tokens[0]), address(subjects().tokens[1]));
        bytes[] memory instructions = new bytes[](amount + 1);
        for (uint256 i; i != (amount + 1); ++i) {
            if (i == 0) {
                instructions[i] = FVM.encodeCreatePair(a0, q0);
            } else {
                instructions[i] = FVM.encodeCreatePool({
                    pairId: 0, // magic pair id to use the nonce, which is the createPairId!
                    controller: controller,
                    priorityFee: 0,
                    fee: uint16(100 + 100 / i),
                    vol: uint16(1000 + 1000 / i),
                    dur: uint16(1 + 100 / i),
                    jit: 0,
                    maxPrice: uint128(1 ether * i),
                    price: uint128(1 ether * i)
                });
            }
        }

        // Super important
        uint64 poolId =
            FVM.encodePoolId(uint24(1), controller != address(0), uint32(1));
        // By setting this poolId all the modifiers that rely on the tokens asset and quote
        // can use this set poolId's pair. Since we created all the pools with the same pair,
        // all the test modifiers work, even though we don't use a config modifier in the beginning of them.
        setGhostPoolId(poolId);
        assertEq(ghost().poolId, poolId, "ghost poolId not set");

        subject().multiprocess(FVM.encodeJumpInstruction(instructions));
    }

    function _multi_allocate(
        uint256 amount,
        bool dontResumeGasMetering
    ) internal {
        require(amount <= POOLS_LIMIT);

        // Fund all the tokens we have, because it only makes sense to use internal balances
        // for multiple instructions.
        PortfolioPool memory pool =
            IPortfolioStruct(address(_subject)).pools(ghost().poolId);
        (address a, address q) = (pool.pair.tokenAsset, pool.pair.tokenQuote);
        _subject.fund(a, type(uint256).max);
        _subject.fund(q, type(uint256).max);

        bytes[] memory instructions = new bytes[](amount);
        for (uint256 i; i != amount; ++i) {
            // We can do this because we create pools from one nonce, so just add the nonce to the firsty poolId.
            uint64 poolId = uint64(ghost().poolId + i);

            instructions[i] =
                FVM.encodeAllocateOrDeallocate(true, uint8(0), poolId, 1 ether);
        }

        bytes memory data = FVM.encodeJumpInstruction(instructions);
        if (!dontResumeGasMetering) vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function _multi_deallocate(
        uint256 amount,
        bool dontResumeGasMetering
    ) internal {
        require(amount <= POOLS_LIMIT);

        bytes[] memory instructions = new bytes[](amount);
        for (uint256 i; i != amount; ++i) {
            // We can do this because we create pools from one nonce, so just add the nonce to the firsty poolId.
            uint64 poolId = uint64(ghost().poolId + i);

            instructions[i] =
                FVM.encodeAllocateOrDeallocate(false, uint8(0), poolId, 1 ether);
        }

        bytes memory data = FVM.encodeJumpInstruction(instructions);
        if (!dontResumeGasMetering) vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function _multi_swap(uint256 amount, bool dontResumeGasMetering) internal {
        require(amount <= POOLS_LIMIT);

        // Fund all the tokens we have, because it only makes sense to use internal balances
        // for multiple instructions.
        PortfolioPool memory pool =
            IPortfolioStruct(address(_subject)).pools(ghost().poolId);
        (address a, address q) = (pool.pair.tokenAsset, pool.pair.tokenQuote);
        _subject.fund(a, type(uint256).max);
        _subject.fund(q, type(uint256).max);

        bytes[] memory instructions = new bytes[](amount);
        for (uint256 i; i != amount; ++i) {
            uint64 poolId = uint64(ghost().poolId + i); // We can do this because we create pools from one nonce.

            bool sellAsset = i % 2 == 0;
            uint128 amountIn = RMM01Portfolio(payable(address(_subject)))
                .computeMaxInput({
                poolId: poolId,
                sellAsset: sellAsset,
                reserveIn: IPortfolioStruct(address(_subject)).pools(poolId)
                    .virtualX,
                liquidity: IPortfolioStruct(address(_subject)).pools(poolId)
                    .liquidity
            }).safeCastTo128() / 10;
            uint128 estimatedAmountOut = uint128(
                _subject.getAmountOut(poolId, sellAsset, amountIn) * 95 / 100
            );

            instructions[i] = FVM.encodeSwap(
                uint8(0),
                poolId,
                amountIn,
                estimatedAmountOut,
                uint8(sellAsset ? 1 : 0)
            );
        }

        bytes memory data = FVM.encodeJumpInstruction(instructions);
        if (!dontResumeGasMetering) vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function _createInstruction(uint24 pairId)
        internal
        returns (bytes memory)
    {
        bytes memory createPool = FVM.encodeCreatePool({
            pairId: pairId,
            controller: address(0),
            fee: uint16(100),
            priorityFee: uint16(10),
            vol: uint16(1000),
            dur: uint16(100),
            jit: uint16(4),
            price: uint128(1 ether),
            maxPrice: uint128(1 ether)
        });
        return createPool;
    }

    function _allocateInstruction(uint64 poolId)
        internal
        returns (bytes memory)
    {
        bytes memory allocate =
            FVM.encodeAllocateOrDeallocate(true, uint8(0), poolId, 1 ether);
        return allocate;
    }

    function _swapInstruction(
        bool direction,
        uint64 poolId
    ) internal returns (bytes memory) {
        uint128 amountIn = uint128(0.05 ether);
        uint128 amountOut =
            subject().getAmountOut(poolId, direction, amountIn).safeCastTo128();
        bytes memory swap = FVM.encodeSwap(
            uint8(0), poolId, amountIn, amountOut, uint8(direction ? 1 : 0)
        );
        return swap;
    }

    function _deallocateInstruction(uint64 poolId)
        internal
        returns (bytes memory)
    {
        bytes memory deallocate =
            FVM.encodeAllocateOrDeallocate(false, uint8(0), poolId, 1 ether);
        return deallocate;
    }

    function _approveMint(address token, uint256 amount) internal {
        Coin.wrap(token).prepare(actor(), address(subject()), amount);
    }

    // -=- Start Gas Study -=- //

    function test_gas_chain_create_allocate_from_portfolio()
        public
        pauseGas
        useActor
    {
        // create the pair first
        (address asset, address quote) = _getTokens();
        bytes memory createPair = FVM.encodeCreatePair(asset, quote);
        subject().multiprocess(createPair);

        uint24 pairId = 1;
        uint64 poolId =
            FVM.encodePoolId(pairId, false, subject().getPoolNonce(pairId) + 1);

        bytes[] memory instructions = new bytes[](2);
        instructions[0] = _createInstruction(pairId);
        instructions[1] = _allocateInstruction(poolId);
        bytes memory data = FVM.encodeJumpInstruction(instructions);

        // Fund account with tokens to pay from portfolio
        _approveMint(asset, 100 ether);
        _approveMint(quote, 100 ether);
        subject().fund(asset, 100 ether);
        subject().fund(quote, 100 ether);

        // Run the gas
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_chain_swap_allocate_from_portfolio()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
    {
        // Fund accounts (already approved with modifier)
        subject().fund(ghost().asset().to_addr(), type(uint256).max);
        subject().fund(ghost().quote().to_addr(), type(uint256).max);

        // Allocate to first pool
        uint64 poolId = ghost().poolId;
        subject().multiprocess(
            FVM.encodeAllocateOrDeallocate(true, uint8(0), poolId, 10 ether)
        );

        bytes[] memory instructions = new bytes[](2);
        instructions[0] = _swapInstruction(true, poolId);
        instructions[1] = _allocateInstruction(poolId);
        bytes memory data = FVM.encodeJumpInstruction(instructions);

        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_chain_swap_deallocate_create_allocate_from_portfolio()
        public
        pauseGas
        noJit
        usePools(1)
        useActor
        usePairTokens(100 ether)
        isArmed
    {
        // Fund accounts (already approved with modifier)
        subject().fund(ghost().asset().to_addr(), type(uint256).max);
        subject().fund(ghost().quote().to_addr(), type(uint256).max);

        // Allocate to first pool
        uint24 pairId = 1;
        uint64 poolId = ghost().poolId;
        subject().multiprocess(
            FVM.encodeAllocateOrDeallocate(true, uint8(0), poolId, 25 ether)
        );

        bytes[] memory instructions = new bytes[](4);
        instructions[0] = _swapInstruction(true, poolId);
        instructions[1] = _deallocateInstruction(poolId);
        instructions[2] = _createInstruction(pairId);
        instructions[3] = _allocateInstruction(poolId + 1);
        bytes memory data = FVM.encodeJumpInstruction(instructions);

        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_single_allocate_from_portfolio_balance()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        // Fund accounts (already approved with modifier)
        subject().fund(ghost().asset().to_addr(), 10 ether);
        subject().fund(ghost().quote().to_addr(), 10 ether);

        bytes memory data = _allocateInstruction(ghost().poolId);
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_single_swap_from_portfolio_balance()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        // Fund accounts (already approved with modifier)
        subject().fund(ghost().asset().to_addr(), 10 ether);
        subject().fund(ghost().quote().to_addr(), 10 ether);

        subject().multiprocess(_allocateInstruction(ghost().poolId));

        bytes memory data = _swapInstruction(true, ghost().poolId);
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_create_pool_allocate_transfer_from_wallet()
        public
        pauseGas
    {
        // create the pair first
        (address asset, address quote) = _getTokens();
        bytes memory createPair = FVM.encodeCreatePair(asset, quote);
        subject().multiprocess(createPair);

        uint24 pairId = 1;
        uint64 poolId =
            FVM.encodePoolId(pairId, false, subject().getPoolNonce(pairId) + 1);

        bytes[] memory instructions = new bytes[](2);
        instructions[0] = _createInstruction(pairId);
        instructions[1] = _allocateInstruction(poolId);
        _approveMint(asset, 100 ether);
        _approveMint(quote, 100 ether);

        // Run the gas
        bytes memory data = FVM.encodeJumpInstruction(instructions);
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_fund() public pauseGas {
        (address token,) = _getTokens();
        Coin.wrap(token).prepare(actor(), address(subject()), 1 ether);

        vm.resumeGasMetering();
        _subject.fund(token, 1 ether);
    }

    function test_gas_draw() public pauseGas useActor {
        (address token,) = _getTokens();
        Coin.wrap(token).prepare(actor(), address(subject()), 1 ether);

        _subject.fund(token, 1 ether);
        vm.resumeGasMetering();
        _subject.draw(token, 1 ether, actor());
    }

    function test_gas_chain_allocate_deallocate_from_portfolio_balance()
        public
        pauseGas
        noJit
        usePools(1)
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        subject().fund(ghost().asset().to_addr(), type(uint256).max);
        subject().fund(ghost().quote().to_addr(), type(uint256).max);

        bytes[] memory instructions = new bytes[](2);
        instructions[0] = _allocateInstruction(ghost().poolId);
        instructions[1] = _deallocateInstruction(ghost().poolId);
        bytes memory data = FVM.encodeJumpInstruction(instructions);

        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_chain_allocate_deallocate_draw_from_wallet()
        public
        pauseGas
        noJit
        usePools(1)
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        bytes[] memory instructions = new bytes[](2);
        instructions[0] = _allocateInstruction(ghost().poolId);
        instructions[1] = _deallocateInstruction(ghost().poolId);
        bytes memory data = FVM.encodeJumpInstruction(instructions);

        (address token0, address token1) = _getTokens();
        address to = actor();
        vm.resumeGasMetering();
        _subject.multiprocess(data);
        _subject.draw(token0, type(uint256).max, to);
        _subject.draw(token1, type(uint256).max, to);
    }

    function test_gas_single_swap_from_wallet()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        subject().multiprocess(_allocateInstruction(ghost().poolId));
        bytes memory data = _swapInstruction(true, ghost().poolId);
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function test_gas_single_swap_from_wallet_draw_to_target()
        public
        pauseGas
        usePools(1)
        useActor
        usePairTokens(10 ether)
        isArmed
    {
        subject().multiprocess(_allocateInstruction(ghost().poolId));

        address to = actor();
        address token = ghost().quote().to_addr();
        bytes memory data = _swapInstruction(true, ghost().poolId);
        vm.resumeGasMetering();
        _subject.multiprocess(data);
        _subject.draw(token, type(uint256).max, to);
    }
}
