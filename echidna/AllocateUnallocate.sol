pragma solidity ^0.8.4;
import "./EchidnaStateHandling.sol";

contract AllocateUnallocate is EchidnaStateHandling {
    // ******************** Allocate ********************
    function allocate_should_succeed_with_correct_preconditions(uint256 id, uint128 deltaLiquidity) public {
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        require(_hyper.getLatestEstimatedPrice(poolId) != 0);
        require(pool.lastTimestamp != 0);

        // ensures deltaLiquidity is never zero
        deltaLiquidity = between(deltaLiquidity, 1, type(uint256).max);
        if (deltaLiquidity == type(uint256).max) {
            deltaLiquidity = 1;
        } else {
            deltaLiquidity = uint128(deltaLiquidity);
        }

        int128 deltaLiquidityInt = convertToInt128(uint128(deltaLiquidity));
        (uint256 deltaAsset, uint256 deltaQuote) = _hyper.getLiquidityDeltas(poolId, deltaLiquidityInt);

        emit LogUint256("delta asset:", deltaAsset);
        emit LogUint256("delta quote:", deltaQuote);
        emit LogUint256("deltaLiquidity", deltaLiquidity);

        execute_allocate_call(poolId, _asset, _quote, deltaAsset, deltaQuote, deltaLiquidity);

        if (!hasFunded) {
            _asset.burn(address(_hyper), 20);
            _quote.burn(address(_hyper), 20);
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
        // Caller must have a balance and have approved hyper
        mint_and_approve(_asset, deltaAsset);
        mint_and_approve(_quote, deltaQuote);

        address[] memory owners = new address[](1);

        // Save pre allocation state
        HyperState memory preState = getState(address(_hyper), poolId, address(this), owners);

        (uint256 allocateAsset, uint256 allocateQuote) = _hyper.getLiquidityDeltas(deltaLiquidity);
        _hyper.multiprocess(EnigmaLib.encodeAllocate(uint8(0), poolId, 0x0, deltaLiquidity));
        emit LogUint256("allocate asset return", allocateAsset);
        emit LogUint256("allocate quote return", allocateQuote);

        HyperState memory postState = getState(address(_hyper), poolId, address(this), owners);
        {
            // Reserves in both tokens should increase
            if (preState.reserveAsset + deltaAsset != postState.reserveAsset) {
                emit LogUint256("pre allocate reserve asset", preState.reserveAsset);
                emit LogUint256("post allocate reserve asset", postState.reserveAsset);
                emit AssertionFailed("BUG: Reserve asset did not increase by deltaAsset");
            }
            if (preState.reserveQuote + deltaQuote != postState.reserveQuote) {
                emit LogUint256("pre allocate reserve quote", preState.reserveQuote);
                emit LogUint256("post allocate reserve quote", postState.reserveQuote);
                emit AssertionFailed("BUG: Reserve quote did not increase by deltaQuote");
            }
            // Total pool liquidity should increase by deltaLiquidity
            if (preState.totalPoolLiquidity + deltaLiquidity != postState.totalPoolLiquidity) {
                emit LogUint256("pre allocate total pool liqudity", preState.totalPoolLiquidity);
                emit LogUint256("post allocate total pool liquidity", postState.totalPoolLiquidity);
                emit AssertionFailed("BUG: Total liquidity did not increase by deltaLiquidity");
            }
            // Physical asset balance of both tokens should increase
            assert(preState.physicalBalanceAsset + deltaAsset == postState.physicalBalanceAsset);
            assert(preState.physicalBalanceQuote + deltaQuote == postState.physicalBalanceQuote);
            assert(preState.callerPositionLiquidity + deltaLiquidity == postState.callerPositionLiquidity);
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

    function allocate_with_non_existent_pool_should_fail(uint256 id, uint128 deltaLiquidity) public {
        (, uint64 poolId, EchidnaERC20 _asset, EchidnaERC20 _quote) = retrieve_random_pool_and_tokens(id);

        require(!is_created_pool(poolId)); // require pool does not exist
        emit LogUint256("pool id:", uint256(poolId));

        deltaLiquidity = between(deltaLiquidity, 1, type(uint256).max);
        if (deltaLiquidity == type(uint256).max) {
            deltaLiquidity = 1;
        } else {
            deltaLiquidity = uint128(deltaLiquidity);
        }

        int128 deltaLiquidityInt = convertToInt128(uint128(deltaLiquidity));
        (uint256 deltaAsset, uint256 deltaQuote) = _hyper.getLiquidityDeltas(poolId, deltaLiquidityInt);

        emit LogUint256("delta asset:", deltaAsset);
        emit LogUint256("delta quote:", deltaQuote);
        emit LogUint256("deltaLiquidity", deltaLiquidity);

        // Caller must have a balance and have approved hyper
        mint_and_approve(_asset, deltaAsset);
        mint_and_approve(_quote, deltaQuote);

        try _hyper.multiprocess(EnigmaLib.encodeAllocate(uint8(0), poolId, 0x0, deltaLiquidity)) {
            emit AssertionFailed("BUG: allocate with non existent pool should fail");
        } catch {}
    }

    function allocate_with_zero_delta_liquidity_should_fail(uint256 id) public {
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        require(_hyper.getLatestEstimatedPrice(poolId) != 0);
        require(pool.lastTimestamp != 0);

        uint128 deltaLiquidity = 0;

        int128 deltaLiquidityInt = convertToInt128(uint128(deltaLiquidity));
        (uint256 deltaAsset, uint256 deltaQuote) = _hyper.getLiquidityDeltas(poolId, deltaLiquidityInt);

        emit LogUint256("delta asset:", deltaAsset);
        emit LogUint256("delta quote:", deltaQuote);
        emit LogUint256("deltaLiquidity", deltaLiquidity);

        // Caller must have a balance and have approved hyper
        mint_and_approve(_asset, deltaAsset);
        mint_and_approve(_quote, deltaQuote);

        try _hyper.multiprocess(EnigmaLib.encodeAllocate(uint8(0), poolId, 0x0, deltaLiquidity)) {
            emit AssertionFailed("BUG: allocate with deltaLiquidity=0 should fail");
        } catch {}
    }

    // A user should not be able to allocate more than they own

    // ******************** Unallocate ********************
    // A user attempting to unallocate an expired pool should be successful
    // A user attempting to unallocate on any pool should succeed with correct preconditions
    function unallocate_with_correct_preconditions_should_succeed(uint256 id, uint128 amount) public {
        address[] memory owners = new address[](1);
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);

        // Save pre unallocation state
        HyperState memory preState = getState(address(_hyper), poolId, address(this), owners);
        uint256 preUnallocateAssetBalance = _asset.balanceOf(address(this));
        uint256 preUnallocateQuoteBalance = _quote.balanceOf(address(this));
        require(preState.callerPositionLiquidity > 0);
        require(pool.lastTimestamp - block.timestamp < JUST_IN_TIME_LIQUIDITY_POLICY);

        (uint256 deltaAsset, uint256 deltaQuote) = _hyper.getReserves(poolId);

        _hyper.multiprocess(EnigmaLib.encodeUnallocate(uint8(0), poolId, 0x0, amount));

        // Save post unallocation state
        HyperState memory postState = getState(address(_hyper), poolId, address(this), owners);
        {
            uint256 postUnallocateAssetBalance = _asset.balanceOf(address(this));
            uint256 postUnallocateQuoteBalance = _quote.balanceOf(address(this));
            assert(preUnallocateAssetBalance + deltaAsset == postUnallocateAssetBalance);
            assert(preUnallocateQuoteBalance + deltaQuote == postUnallocateQuoteBalance);
        }

        assert(preState.totalPoolLiquidity - amount == postState.totalPoolLiquidity);
        assert(preState.callerPositionLiquidity - amount == postState.callerPositionLiquidity);
        assert(preState.reserveAsset == postState.reserveAsset);
        assert(preState.reserveQuote == postState.reserveQuote);
        assert(preState.physicalBalanceAsset == postState.physicalBalanceAsset);
        assert(preState.physicalBalanceQuote == postState.physicalBalanceQuote);
    }

    // A user without a position should not be able to unallocate funds
    function unallocate_without_position_should_fail(uint256 id, uint256 amount) public {
        (HyperPool memory pool, uint64 poolId, , ) = retrieve_random_pool_and_tokens(id);

        // Save pre unallocation state
        require(pool.lastTimestamp - block.timestamp < JUST_IN_TIME_LIQUIDITY_POLICY);

        unallocate_should_fail(poolId, amount, "BUG: Unallocate without a position should fail.");
    }

    // A user attempting to unallocate a nonexistent pool should fail
    function unallocate_with_non_existent_pool_should_fail(uint64 id, uint128 amount) public {
        require(!is_created_pool(id));
        amount = between(amount, 1, type(uint256).max);
        unallocate_should_fail(id, amount, "BUG: Unallocate to a non-existent pool should fail.");
    }

    // Caller position last timestamp <= block.timestamp, with JIT policy
    // A user should not be able to unallocate more than they own
    function unallocate_should_fail(uint64 poolId, uint256 amount, string memory failureMsg) private {
        try _hyper.multiprocess(EnigmaLib.encodeUnallocate(uint8(0), poolId, 0x0, amount)) {
            emit AssertionFailed(failureMsg);
        } catch {}
    }

    // A user calling allocate then unallocate should succeed
    function allocate_then_unallocate_should_succeed(uint256 id, uint128 amount) public {
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        require(_hyper.getLatestEstimatedPrice(poolId) != 0);
        require(pool.lastTimestamp != 0);

        // ensures deltaLiquidity is never zero
        amount = between(amount, 1, type(uint256).max);
        if (amount == type(uint256).max) {
            amount = 1;
        } else {
            amount = uint128(amount);
        }

        int128 amountInt = convertToInt128(uint128(amount));
        (uint256 deltaAsset, uint256 deltaQuote) = _hyper.getLiquidityDeltas(poolId, amountInt);

        emit LogUint256("delta asset:", deltaAsset);
        emit LogUint256("delta quote:", deltaQuote);
        emit LogUint256("amount", amount);

        execute_allocate_call(poolId, _asset, _quote, deltaAsset, deltaQuote, amount);
        _hyper.multiprocess(EnigmaLib.encodeUnallocate(uint8(0), poolId, 0x0, amount));
    }
}
