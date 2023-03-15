pragma solidity ^0.8.4;

import "./EchidnaStateHandling.sol";

contract AllocateDeallocate is EchidnaStateHandling {
    // ******************** Allocate ********************
    function allocate_should_succeed_with_correct_preconditions(
        uint256 id,
        uint128 deltaLiquidity
    ) public {
        (
            PortfolioPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        require(_portfolio.getVirtualPrice(poolId) != 0);
        require(pool.lastTimestamp != 0);

        // ensures deltaLiquidity is never zero
        deltaLiquidity = between(deltaLiquidity, 1, type(uint256).max);
        if (deltaLiquidity == type(uint256).max) {
            deltaLiquidity = 1;
        } else {
            deltaLiquidity = uint128(deltaLiquidity);
        }

        int128 deltaLiquidityInt = convertToInt128(uint128(deltaLiquidity));
        (uint256 deltaAsset, uint256 deltaQuote) =
            _portfolio.getLiquidityDeltas(poolId, deltaLiquidityInt);

        emit LogUint256("delta asset:", deltaAsset);
        emit LogUint256("delta quote:", deltaQuote);
        emit LogUint256("deltaLiquidity", deltaLiquidity);

        execute_allocate_call(
            poolId, _asset, _quote, deltaAsset, deltaQuote, deltaLiquidity
        );

        if (!hasFunded) {
            _asset.burn(address(_portfolio), 20);
            _quote.burn(address(_portfolio), 20);
            hasFunded = true;
        }
    }

    function execute_allocate_call(
        uint64 poolId,
        EchidnaERC20 _asset,
        EchidnaERC20 _quote,
        uint128 deltaAsset,
        uint128 deltaQuote,
        uint128 deltaLiquidity
    ) internal {
        // Caller must have a balance and have approved Portfolio
        mint_and_approve(_asset, deltaAsset);
        mint_and_approve(_quote, deltaQuote);

        address[] memory owners = new address[](1);

        // Save pre allocation state
        PortfolioState memory preState =
            getState(address(_portfolio), poolId, address(this), owners);

        (uint256 allocateAsset, uint256 allocateQuote) =
            _portfolio.getLiquidityDeltas(deltaLiquidity);
        _portfolio.multiprocess(
            FVMLib.encodeAllocateOrDeallocate(
                true, uint8(0), poolId, 0x0, deltaLiquidity
            )
        );
        emit LogUint256("allocate asset return", allocateAsset);
        emit LogUint256("allocate quote return", allocateQuote);

        PortfolioState memory postState =
            getState(address(_portfolio), poolId, address(this), owners);
        {
            // Reserves in both tokens should increase
            if (preState.reserveAsset + deltaAsset != postState.reserveAsset) {
                emit LogUint256(
                    "pre allocate reserve asset", preState.reserveAsset
                    );
                emit LogUint256(
                    "post allocate reserve asset", postState.reserveAsset
                    );
                emit AssertionFailed(
                    "BUG: Reserve asset did not increase by deltaAsset"
                    );
            }
            if (preState.reserveQuote + deltaQuote != postState.reserveQuote) {
                emit LogUint256(
                    "pre allocate reserve quote", preState.reserveQuote
                    );
                emit LogUint256(
                    "post allocate reserve quote", postState.reserveQuote
                    );
                emit AssertionFailed(
                    "BUG: Reserve quote did not increase by deltaQuote"
                    );
            }
            // Total pool liquidity should increase by deltaLiquidity
            if (
                preState.totalPoolLiquidity + deltaLiquidity
                    != postState.totalPoolLiquidity
            ) {
                emit LogUint256(
                    "pre allocate total pool liqudity",
                    preState.totalPoolLiquidity
                    );
                emit LogUint256(
                    "post allocate total pool liquidity",
                    postState.totalPoolLiquidity
                    );
                emit AssertionFailed(
                    "BUG: Total liquidity did not increase by deltaLiquidity"
                    );
            }
            // Physical asset balance of both tokens should increase
            assert(
                preState.physicalBalanceAsset + deltaAsset
                    == postState.physicalBalanceAsset
            );
            assert(
                preState.physicalBalanceQuote + deltaQuote
                    == postState.physicalBalanceQuote
            );
            assert(
                preState.callerPositionLiquidity + deltaLiquidity
                    == postState.callerPositionLiquidity
            );
        }
        {
            if (preState.feeGrowthAssetPool != postState.feeGrowthAssetPool) {
                assert(postState.feeGrowthAssetPosition != 0);
            }
            if (preState.feeGrowthQuotePool != postState.feeGrowthQuotePool) {
                assert(postState.feeGrowthQuotePosition != 0);
            }
        }
    }

    function allocate_with_non_existent_pool_should_fail(
        uint256 id,
        uint128 deltaLiquidity
    ) public {
        (, uint64 poolId, EchidnaERC20 _asset, EchidnaERC20 _quote) =
            retrieve_random_pool_and_tokens(id);

        require(!is_created_pool(poolId)); // require pool does not exist
        emit LogUint256("pool id:", uint256(poolId));

        deltaLiquidity = between(deltaLiquidity, 1, type(uint256).max);
        if (deltaLiquidity == type(uint256).max) {
            deltaLiquidity = 1;
        } else {
            deltaLiquidity = uint128(deltaLiquidity);
        }

        int128 deltaLiquidityInt = convertToInt128(uint128(deltaLiquidity));
        (uint256 deltaAsset, uint256 deltaQuote) =
            _portfolio.getLiquidityDeltas(poolId, deltaLiquidityInt);

        emit LogUint256("delta asset:", deltaAsset);
        emit LogUint256("delta quote:", deltaQuote);
        emit LogUint256("deltaLiquidity", deltaLiquidity);

        // Caller must have a balance and have approved Portfolio
        mint_and_approve(_asset, deltaAsset);
        mint_and_approve(_quote, deltaQuote);

        try _portfolio.multiprocess(
            FVMLib.encodeAllocateOrDeallocate(
                true, uint8(0), poolId, 0x0, deltaLiquidity
            )
        ) {
            emit AssertionFailed(
                "BUG: allocate with non existent pool should fail"
                );
        } catch { }
    }

    function allocate_with_zero_delta_liquidity_should_fail(uint256 id)
        public
    {
        (
            PortfolioPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        require(_portfolio.getVirtualPrice(poolId) != 0);
        require(pool.lastTimestamp != 0);

        uint128 deltaLiquidity = 0;

        int128 deltaLiquidityInt = convertToInt128(uint128(deltaLiquidity));
        (uint256 deltaAsset, uint256 deltaQuote) =
            _portfolio.getLiquidityDeltas(poolId, deltaLiquidityInt);

        emit LogUint256("delta asset:", deltaAsset);
        emit LogUint256("delta quote:", deltaQuote);
        emit LogUint256("deltaLiquidity", deltaLiquidity);

        // Caller must have a balance and have approved Portfolio
        mint_and_approve(_asset, deltaAsset);
        mint_and_approve(_quote, deltaQuote);

        try _portfolio.multiprocess(
            FVMLib.encodeAllocateOrDeallocate(
                true, uint8(0), poolId, 0x0, deltaLiquidity
            )
        ) {
            emit AssertionFailed(
                "BUG: allocate with deltaLiquidity=0 should fail"
                );
        } catch { }
    }

    // A user should not be able to allocate more than they own

    // ******************** Deallocate ********************
    // A user attempting to deallocate an expired pool should be successful
    // A user attempting to deallocate on any pool should succeed with correct preconditions
    function deallocate_with_correct_preconditions_should_succeed(
        uint256 id,
        uint128 amount
    ) public {
        address[] memory owners = new address[](1);
        (
            PortfolioPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);

        // Save pre unallocation state
        PortfolioState memory preState =
            getState(address(_portfolio), poolId, address(this), owners);
        uint256 preDeallocateAssetBalance = _asset.balanceOf(address(this));
        uint256 preDeallocateQuoteBalance = _quote.balanceOf(address(this));
        require(preState.callerPositionLiquidity > 0);
        require(
            pool.lastTimestamp - block.timestamp < JUST_IN_TIME_LIQUIDITY_POLICY
        );

        (uint256 deltaAsset, uint256 deltaQuote) =
            _portfolio.getPoolReserves(poolId);

        _portfolio.multiprocess(
            FVMLib.decodeAllocateOrDeallocate_(
                false, uint8(0), poolId, 0x0, amount
            )
        );

        // Save post unallocation state
        PortfolioState memory postState =
            getState(address(_portfolio), poolId, address(this), owners);
        {
            uint256 postDeallocateAssetBalance = _asset.balanceOf(address(this));
            uint256 postDeallocateQuoteBalance = _quote.balanceOf(address(this));
            assert(
                preDeallocateAssetBalance + deltaAsset
                    == postDeallocateAssetBalance
            );
            assert(
                preDeallocateQuoteBalance + deltaQuote
                    == postDeallocateQuoteBalance
            );
        }

        assert(
            preState.totalPoolLiquidity - amount == postState.totalPoolLiquidity
        );
        assert(
            preState.callerPositionLiquidity - amount
                == postState.callerPositionLiquidity
        );
        assert(preState.reserveAsset == postState.reserveAsset);
        assert(preState.reserveQuote == postState.reserveQuote);
        assert(preState.physicalBalanceAsset == postState.physicalBalanceAsset);
        assert(preState.physicalBalanceQuote == postState.physicalBalanceQuote);
    }

    // A user without a position should not be able to deallocate funds
    function deallocate_without_position_should_fail(
        uint256 id,
        uint256 amount
    ) public {
        (PortfolioPool memory pool, uint64 poolId,,) =
            retrieve_random_pool_and_tokens(id);

        // Save pre unallocation state
        require(
            pool.lastTimestamp - block.timestamp < JUST_IN_TIME_LIQUIDITY_POLICY
        );

        deallocate_should_fail(
            poolId, amount, "BUG: Deallocate without a position should fail."
        );
    }

    // A user attempting to deallocate a nonexistent pool should fail
    function deallocate_with_non_existent_pool_should_fail(
        uint64 id,
        uint128 amount
    ) public {
        require(!is_created_pool(id));
        amount = between(amount, 1, type(uint256).max);
        deallocate_should_fail(
            id, amount, "BUG: Deallocate to a non-existent pool should fail."
        );
    }

    // Caller position last timestamp <= block.timestamp, with JIT policy
    // A user should not be able to deallocate more than they own
    function deallocate_should_fail(
        uint64 poolId,
        uint256 amount,
        string memory failureMsg
    ) private {
        try _portfolio.multiprocess(
            FVMLib.decodeAllocateOrDeallocate_(
                false, uint8(0), poolId, 0x0, amount
            )
        ) {
            emit AssertionFailed(failureMsg);
        } catch { }
    }

    // A user calling allocate then deallocate should succeed
    function allocate_then_deallocate_should_succeed(
        uint256 id,
        uint128 amount
    ) public {
        (
            PortfolioPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        require(_portfolio.getVirtualPrice(poolId) != 0);
        require(pool.lastTimestamp != 0);

        // ensures deltaLiquidity is never zero
        amount = between(amount, 1, type(uint256).max);
        if (amount == type(uint256).max) {
            amount = 1;
        } else {
            amount = uint128(amount);
        }

        int128 amountInt = convertToInt128(uint128(amount));
        (uint256 deltaAsset, uint256 deltaQuote) =
            _portfolio.getLiquidityDeltas(poolId, amountInt);

        emit LogUint256("delta asset:", deltaAsset);
        emit LogUint256("delta quote:", deltaQuote);
        emit LogUint256("amount", amount);

        execute_allocate_call(
            poolId, _asset, _quote, deltaAsset, deltaQuote, amount
        );
        _portfolio.multiprocess(
            FVMLib.decodeAllocateOrDeallocate(
                false, uint8(0), poolId, 0x0, amount
            )
        );
    }
}
