pragma solidity ^0.8.0;
import "./PairCreation.sol";
import "./PoolCreation.sol";

contract GlobalInvariants is PairCreation, PoolCreation {
    // ******************** System wide Invariants ********************
    // The token balance of Hyper should be greater or equal to the reserve for all tokens
    // Note: assumption that pairs are created through create_pair invariant test
    // which will add the token to the hyperTokens list
    // this function is built so that extending the creation of new pairs should not require code changes here
    function global_token_balance_greater_or_equal_reserves() public {
        uint256 reserveBalance = 0;
        uint256 tokenBalance = 0;
        for (uint8 i = 0; i < EchidnaStateHandling.hyperTokens.length; i++) {
            EchidnaERC20 token = EchidnaStateHandling.get_token_at_index(i);

            // retrieve reserves of the token and add to tracked reserve balance
            reserveBalance = getReserve(address(_hyper), address(token));

            // get token balance and add to tracked token balance
            tokenBalance = token.balanceOf(address(_hyper));

            assert(tokenBalance >= reserveBalance);
        }
    }

    // ---------- HyperPair Properties -------
    function pair_asset_never_equal_to_quote(uint256 id) public {
        uint24 pairId = retrieve_created_pair(id);

        HyperPair memory pair = getPair(address(_hyper), pairId);
        assert(pair.tokenAsset != pair.tokenQuote);
    }

    function pair_decimals_never_exceed_bounds(uint256 id) public {
        uint24 pairId = retrieve_created_pair(id);

        HyperPair memory pair = getPair(address(_hyper), pairId);
        assert(pair.decimalsAsset == EchidnaERC20(pair.tokenAsset).decimals());
        assert(pair.decimalsAsset >= 6);
        assert(pair.decimalsAsset <= 18);

        assert(pair.decimalsQuote == EchidnaERC20(pair.tokenQuote).decimals());
        assert(pair.decimalsQuote >= 6);
        assert(pair.decimalsQuote <= 18);
    }

    // ---------- Pool Properties -------
    function pool_fee_growth_greater_than_position_fee_growth() public {
        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];
            HyperPool memory pool = getPool(address(_hyper), poolId);
        }
    }

    function pool_non_zero_priority_fee_if_controlled(uint64 id) public {
        (HyperPool memory pool, , , ) = retrieve_random_pool_and_tokens(id);
        // if the pool has a controller, the priority fee should never be zero
        emit LogBool("is mutable", pool.isMutable());
        if (pool.controller != address(0)) {
            if (pool.params.priorityFee == 0) {
                emit LogUint256("priority feel value", pool.params.priorityFee);
                emit AssertionFailed("BUG: Mutable pool has a non zero priority fee.");
            }
        }
    }

    function pool_last_price_not_greater_than_strike() public {
        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];
            HyperPool memory pool = getPool(address(_hyper), poolId);
            HyperCurve memory curve = pool.params;

            emit LogUint256("pool's last price", pool.lastPrice);
            emit LogUint256("strike price", curve.strike());

            assert(pool.lastPrice <= curve.strike());
        }
    }

    // Strike price for a pool should never be zero.
    // If it is, it suggests the mispricing and/or incorrect rounding of assets.
    function pool_strike_price_non_zero() public {
        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];
            HyperPool memory pool = getPool(address(_hyper), poolId);
            HyperCurve memory curve = pool.params;

            emit LogUint256("pool's last price", pool.lastPrice);
            emit LogUint256("strike price", curve.strike());

            if (curve.strike() == 0) {
                emit AssertionFailed("BUG: Strike price should never be 0.");
            }
        }
    }

    function pool_maturity_never_less_last_timestamp() public {
        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];
            HyperPool memory pool = getPool(address(_hyper), poolId);
            HyperCurve memory curve = pool.params;

            emit LogUint256("hyper pool last timestamp: ", pool.lastTimestamp);
            emit LogUint256("maturity", curve.maturity());

            if (curve.maturity() < pool.lastTimestamp) {
                emit AssertionFailed("BUG: curve maturity is less than last timestamp");
            }
        }
    }

    function pool_non_zero_last_price_never_zero_liquidity() public {
        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];

            HyperPool memory pool = getPool(address(_hyper), poolId);
            emit LogUint256("last timestamp", uint256(pool.lastTimestamp));

            if (pool.lastPrice != 0) {
                emit LogUint256("pool's last price", pool.lastPrice);
                if (pool.liquidity == 0) {
                    emit AssertionFailed("BUG: non zero last price should have a non zero liquidity");
                }
            }
            //TODO: if pool.lastPrice == 0; pool.liquidity == 0?
        }
    }

    // TODO: remove if it's a false invariant
    // TODO: Add to iterate over all created-pools

    function pool_liquidity_delta_never_returns_zeroes(uint256 id, int128 deltaLiquidity) public {
        require(deltaLiquidity != 0);
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 quote,
            EchidnaERC20 asset
        ) = retrieve_random_pool_and_tokens(id);

        emit LogInt128("deltaLiquidity", deltaLiquidity);

        (uint128 deltaAsset, uint128 deltaQuote) = _hyper.getLiquidityDeltas(poolId, deltaLiquidity);
        emit LogUint256("deltaAsset", deltaAsset);
        if (deltaAsset == 0) {
            emit AssertionFailed("BUG: getLiquidityDeltas returned 0 for deltaAsset");
        }
        emit LogUint256("deltaQuote", deltaQuote);
        if (deltaQuote == 0) {
            emit AssertionFailed("BUG: getLiquidityDeltas returned 0 for deltaQuote");
        }
    }

    // TODO: Find a better name here with `pool_` at the beginning

    function check_hyper_curve_assumptions() public {
        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];
            HyperPool memory pool = getPool(address(_hyper), poolId);
            HyperCurve memory curve = pool.params;

            assert(curve.fee != 0);
            assert(curve.priorityFee <= curve.fee);
            assert(curve.duration != 0);
            assert(curve.volatility >= MIN_VOLATILITY);
            assert(curve.createdAt != 0);
        }
    }

    // TODO: Find a better name here with `pool_` at the beginning
    function check_hyper_pool_assumptions() public {
        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];
            HyperPool memory pool = getPool(address(_hyper), poolId);
            HyperPair memory pair = pool.pair;

            // The `getVirtualReserves` method always returns values less than Hyper’s respective `getReserve` function for each token of the pool’s pair.

            // `getVirtualReserves method`
            (uint128 deltaAsset, uint128 deltaQuote) = _hyper.getVirtualReserves(poolId);

            // Hyper's `getReserve` function for each of the pool's pair
            uint256 assetReserves = _hyper.getReserve(pair.tokenAsset);
            uint256 quoteReserves = _hyper.getReserve(pair.tokenQuote);

            if (deltaAsset > assetReserves) {
                emit LogUint256("deltaAsset", deltaAsset);
                emit LogUint256("assetReserves", assetReserves);
                emit AssertionFailed("BUG (`asset`): virtualReserves returned more than getReserve function");
            }
            if (deltaQuote > quoteReserves) {
                emit LogUint256("deltaQuote", deltaQuote);
                emit LogUint256("quoteReserves", quoteReserves);
                emit AssertionFailed("BUG (`asset`): virtualReserves returned more than getReserve function");
            }
        }
    }

    function pool_get_amounts_wad_returns_safe_bounds() public {
        // The `getAmountsWad` method always returns less than `1e18` for `amountAssetWad` and `pool.params.strike()` for `amountQuoteWad`.

        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];
            HyperPool memory pool = getPool(address(_hyper), poolId);
            HyperCurve memory curve = pool.params;

            (uint256 amountAssetWad, uint256 amountQuoteWad) = pool.getAmountsWad();

            if (amountAssetWad > 1e18) {
                emit LogUint256("amountAssetWad", amountAssetWad);
                emit AssertionFailed("BUG amountAssetWad is greater than 1e18");
            }
            // Inclusive of strike price?
            if (amountQuoteWad > curve.strike()) {
                emit LogUint256("amountQuoteWad", amountQuoteWad);
                emit AssertionFailed("BUG amountQuoteWad is greater than strike");
            }
        }
    }

    function pool_get_amounts_returns_less_than_get_amounts_wad() public {
        // The `getAmounts` method always returns values less than or equal to `getAmountsWad`.

        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];
            HyperPool memory pool = getPool(address(_hyper), poolId);
            HyperCurve memory curve = pool.params;

            (uint256 amountAssetDec, uint256 amountQuoteDec) = pool.getAmounts();

            (uint256 amountAssetWad, uint256 amountQuoteWad) = pool.getAmountsWad();

            // Assumes inclusivity of bounds (i.e: equivalence is okay)
            if (amountAssetDec > amountAssetWad) {
                emit LogUint256("amountAssetDec", amountAssetDec);
                emit LogUint256("amountAssetWad", amountAssetWad);
                emit AssertionFailed("BUG (asset): getAmounts returned more than getAmountsWad");
            }
            // Assumes inclusivity of bounds (i.e: equivalence is okay)
            if (amountQuoteDec > amountQuoteWad) {
                emit LogUint256("amountQuoteDec", amountQuoteDec);
                emit LogUint256("amountQuoteWad", amountQuoteWad);
                emit AssertionFailed("BUG (quote): getAmounts returned more than getAmountsWad");
            }
        }
    }

    function retrieve_random_pool_and_tokens(
        uint256 id
    ) internal view returns (HyperPool memory pool, uint64 poolId, EchidnaERC20 asset, EchidnaERC20 quote) {
        // assumes that at least one pool exists because it's been created in the constructor
        uint256 random = between(id, 0, poolIds.length - 1);
        if (poolIds.length == 1) random = 0;

        pool = getPool(address(_hyper), poolIds[random]);
        poolId = poolIds[random];
        HyperPair memory pair = pool.pair;
        quote = EchidnaERC20(pair.tokenQuote);
        asset = EchidnaERC20(pair.tokenAsset);
    }

    function retrieve_non_expired_pool_and_tokens(
        uint256 id
    ) internal view returns (HyperPool memory pool, uint64 poolId, EchidnaERC20 asset, EchidnaERC20 quote) {
        for (uint8 i = 0; i < poolIds.length; i++) {
            // will auto skew to the first pool that is not expired, however this should be okay.
            // this gives us a higher chance to return a pool that is not expired through iterating
            pool = getPool(address(_hyper), poolIds[i]);
            HyperCurve memory curve = pool.params;
            if (curve.maturity() > block.timestamp) {
                HyperPair memory pair = pool.pair;
                return (pool, poolIds[i], EchidnaERC20(pair.tokenQuote), EchidnaERC20(pair.tokenAsset));
            }
        }
    }
}
