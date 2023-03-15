// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestGas is Setup {
    using SafeCastLib for uint256;

    modifier usePools(uint256 amount) {
        _create_pools(amount);
        _;
    }

    uint256 internal constant POOLS_LIMIT = 100;

    IPortfolio _subject;

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

    function test_gas_multi_allocate_2_pairs() public pauseGas { }

    function test_gas_multi_allocate_2()
        public
        pauseGas
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(2);
    }

    function test_gas_multi_allocate_5()
        public
        pauseGas
        usePools(5)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(5);
    }

    function test_gas_multi_allocate_10()
        public
        pauseGas
        usePools(10)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(10);
    }

    function test_gas_multi_allocate_25()
        public
        pauseGas
        usePools(25)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(25);
    }

    function test_gas_multi_allocate_50()
        public
        pauseGas
        usePools(50)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(50);
    }

    function test_gas_multi_allocate_100()
        public
        pauseGas
        usePools(100)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(100);
    }

    function test_gas_multi_deallocate_2_pool_2_pair() public pauseGas { }
    function test_gas_multi_deallocate_2() public pauseGas { }
    function test_gas_multi_deallocate_5() public pauseGas { }
    function test_gas_multi_deallocate_10() public pauseGas { }
    function test_gas_multi_deallocate_25() public pauseGas { }
    function test_gas_multi_deallocate_50() public pauseGas { }
    function test_gas_multi_deallocate_100() public pauseGas { }
    function test_gas_multi_create_pool_100() public pauseGas { }
    function test_gas_multi_swap_2_pairs() public pauseGas { }

    function test_gas_multi_swap_2()
        public
        pauseGas
        pauseGas
        usePools(2)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(2);
        _multi_swap(2);
    }

    function test_gas_multi_swap_5()
        public
        pauseGas
        pauseGas
        pauseGas
        usePools(5)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(5);
        _multi_swap(5);
    }

    function test_gas_multi_swap_10()
        public
        pauseGas
        pauseGas
        pauseGas
        usePools(10)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(10);
        _multi_swap(10);
    }

    function test_gas_multi_swap_25()
        public
        pauseGas
        pauseGas
        pauseGas
        usePools(25)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(25);
        _multi_swap(25);
    }

    function test_gas_multi_swap_50()
        public
        pauseGas
        pauseGas
        pauseGas
        usePools(50)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(50);
        _multi_swap(50);
    }

    function test_gas_multi_swap_100()
        public
        pauseGas
        pauseGas
        pauseGas
        usePools(100)
        useActor
        usePairTokens(10_000 ether)
        isArmed
    {
        _multi_allocate(100);
        _multi_swap(100);
    }

    function test_gas_chain_create_allocate() public pauseGas { }
    function test_gas_chain_swap_allocate() public pauseGas { }
    function test_gas_chain_deallocate_swap_create_allocate() public pauseGas { }

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
                    price: uint128(1 ether * i - 0.1 ether / i)
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

    function _multi_allocate(uint256 amount) internal {
        require(amount <= POOLS_LIMIT);

        bytes[] memory instructions = new bytes[](amount);
        for (uint256 i; i != amount; ++i) {
            uint64 poolId = uint64(ghost().poolId + i); // We can do this because we create pools from one nonce.
            instructions[i] =
                FVM.encodeAllocateOrDeallocate(true, uint8(0), poolId, 1 ether);
        }

        bytes memory data = FVM.encodeJumpInstruction(instructions);
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }

    function _multi_swap(uint256 amount) internal {
        require(amount <= POOLS_LIMIT);

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
        vm.resumeGasMetering();
        _subject.multiprocess(data);
    }
}
