pragma solidity ^0.8.0;
import "./EchidnaStateHandling.sol";

contract Swaps is EchidnaStateHandling {
    // Swaps
    function swap_should_succeed(uint id, bool sellAsset, uint256 amount, uint256 limit) public {
        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        HyperCurve memory curve = pool.params;
        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        HyperState memory preState = getState(address(_hyper), poolId, address(this), owners);

        // emit LogUint256("maturity",uint256(curve.maturity()));
        // emit LogUint256("block.timestamp", block.timestamp);
        emit LogUint256("difference in maturity and timestamp:", uint256(curve.maturity()) - uint256(block.timestamp));

        if (curve.maturity() <= block.timestamp) {
            emit LogUint256("Maturity timestamp", curve.maturity());
            emit LogUint256("block.timestamp", block.timestamp);
            swap_should_fail(poolId, true, amount, amount, "BUG: Swap on an expired pool should have failed.");
        } else {
            try _hyper.swap(poolId, sellAsset, amount, limit) returns (uint256 output, uint256 remainder) {
                HyperState memory postState = getState(address(_hyper), poolId, address(this), owners);
                {
                    // change in asset's balance after swaps is equivalent to the change in reserves
                    int256 assetBalanceOf = int256(postState.physicalBalanceAsset - preState.physicalBalanceAsset);
                    int256 reserveAssetDiff = int256(postState.reserveAsset - preState.reserveAsset);
                    if (assetBalanceOf != reserveAssetDiff) {
                        emit LogInt256("assetBalanceOf", assetBalanceOf);
                        emit LogInt256("reserveAssetDiff", reserveAssetDiff);
                        emit AssertionFailed(
                            "BUG: Hyper's balance of asset token did not equal change in asset reserves"
                        );
                    }
                }
                {
                    // change in quote's balance after swaps is equivalent to the change in reserves
                    int256 quoteBalanceOf = int(postState.physicalBalanceQuote - preState.physicalBalanceQuote);
                    int256 reserveQuoteDiff = int(postState.reserveQuote - preState.reserveQuote);
                    if (quoteBalanceOf != reserveQuoteDiff) {
                        emit LogInt256("quoteBalanceOf", quoteBalanceOf);
                        emit LogInt256("reserveQuoteDiff", reserveQuoteDiff);
                        emit AssertionFailed(
                            "BUG: Hyper's balance of quote token did not equal change in asset reserves"
                        );
                    }
                }
            } catch {}
        }
    }

    function swap_on_non_existent_pool_should_fail(uint64 id) public {
        // Ensure that the pool id was not one that's already been created
        require(!is_created_pool(id));
        HyperPool memory pool = getPool(address(_hyper), id);

        swap_should_fail(id, true, id, id, "BUG: Swap on a nonexistent pool should fail.");
    }

    function swap_on_zero_amount_should_fail() public {
        // Will always return a pool that exists
        (HyperPool memory pool, uint64 poolId, , ) = retrieve_non_expired_pool_and_tokens();
        uint256 amount = 0;

        swap_should_fail(poolId, true, amount, poolId + 1, "BUG: Swap with zero swap amount should fail.");
    }

    function swap_on_limit_amount_of_zero_should_fail() public {
        // Will always return a pool that exists
        (HyperPool memory pool, uint64 poolId, , ) = retrieve_non_expired_pool_and_tokens();
        uint256 amount = between(poolId, 1, type(uint256).max);

        swap_should_fail(poolId, true, amount, 0, "BUG: Swap with zero limit amount should fail.");
    }

    function swap_should_fail(
        uint64 poolId,
        bool sellAsset,
        uint256 amount,
        uint256 limit,
        string memory failureMsg
    ) private {
        try _hyper.swap(poolId, sellAsset, amount, limit) {
            emit AssertionFailed(failureMsg);
        } catch {}
    }

    function swap_assets_in_always_decreases_price(uint256 amount, uint256 limit) public {
        bool sellAsset = true;

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens();
        HyperCurve memory curve = pool.params;
        emit LogUint256("curve maturity", uint256(curve.maturity()));
        emit LogUint256("block timestamp", block.timestamp);
        emit LogBool("is curve maturity greater than timestamp?", curve.maturity() > block.timestamp);
        // require(curve.maturity() > block.timestamp);

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        uint256 prevReserveSell = getReserve(address(_hyper), address(_asset));
        uint256 prevReserveBuy = getReserve(address(_hyper), address(_quote));

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        try _hyper.swap(poolId, sellAsset, amount, limit) {
            HyperPool memory postPool = getPool(address(_hyper), poolId);

            uint256 postReserveSell = getReserve(address(_hyper), address(_asset));
            uint256 postReserveBuy = getReserve(address(_hyper), address(_quote));

            if (postPool.lastPrice == 0) {
                emit LogUint256("lastPrice", postPool.lastPrice);
                emit AssertionFailed("BUG: pool.lastPrice is zero on a swap.");
            }
            if (postPool.lastPrice > prePool.lastPrice) {
                emit LogUint256("price before swap", prePool.lastPrice);
                emit LogUint256("price after swap", postPool.lastPrice);
                emit AssertionFailed(
                    "BUG: pool.lastPrice increased after swapping assets in, it should have decreased."
                );
            }

            // feeGrowthSell = asset
            check_external_swap_invariants(
                prePool.lastPrice,
                postPool.lastPrice,
                prePool.liquidity,
                postPool.liquidity,
                prevReserveSell,
                postReserveSell,
                prevReserveBuy,
                postReserveBuy,
                prePool.feeGrowthGlobalAsset,
                postPool.feeGrowthGlobalAsset,
                prePool.feeGrowthGlobalQuote,
                postPool.feeGrowthGlobalQuote
            );
        } catch {}
    }

    function swap_quote_in_always_increases_price(uint256 amount, uint256 limit) public {
        bool sellAsset = false;

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens();
        HyperCurve memory curve = pool.params;
        // require(curve.maturity() > block.timestamp);

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        uint256 prevReserveSell = getReserve(address(_hyper), address(_quote));
        uint256 prevReserveBuy = getReserve(address(_hyper), address(_asset));

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        try _hyper.swap(poolId, sellAsset, amount, limit) {
            HyperPool memory postPool = getPool(address(_hyper), poolId);

            uint256 postReserveSell = getReserve(address(_hyper), address(_quote));
            uint256 postReserveBuy = getReserve(address(_hyper), address(_asset));

            if (postPool.lastPrice < prePool.lastPrice) {
                emit LogUint256("price before swap", prePool.lastPrice);
                emit LogUint256("price after swap", postPool.lastPrice);
                emit AssertionFailed(
                    "BUG: pool.lastPrice decreased after swapping quote in, it should have increased."
                );
            }

            // feeGrowthSell = quote
            check_external_swap_invariants(
                prePool.lastPrice,
                postPool.lastPrice,
                prePool.liquidity,
                postPool.liquidity,
                prevReserveSell,
                postReserveSell,
                prevReserveBuy,
                postReserveBuy,
                prePool.feeGrowthGlobalQuote,
                postPool.feeGrowthGlobalQuote,
                prePool.feeGrowthGlobalAsset,
                postPool.feeGrowthGlobalAsset
            );
        } catch {}
    }

    function swap_asset_in_increases_reserve(uint256 amount, uint256 limit) public {
        bool sellAsset = true;

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens();
        HyperCurve memory curve = pool.params;
        // require(curve.maturity() > block.timestamp);

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        uint256 prevReserveSell = getReserve(address(_hyper), address(_asset));
        uint256 prevReserveBuy = getReserve(address(_hyper), address(_quote));

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        try _hyper.swap(poolId, sellAsset, amount, limit) {
            HyperPool memory postPool = getPool(address(_hyper), poolId);

            uint256 postReserveSell = getReserve(address(_hyper), address(_asset));
            uint256 postReserveBuy = getReserve(address(_hyper), address(_quote));

            if (postReserveSell < prevReserveSell) {
                emit LogUint256("asset reserve before swap", prevReserveSell);
                emit LogUint256("asset reserve after swap", postReserveSell);
                emit AssertionFailed("BUG: reserve decreased after swapping asset in, it should have increased.");
            }

            // feeGrowthSell = asset
            check_external_swap_invariants(
                prePool.lastPrice,
                postPool.lastPrice,
                prePool.liquidity,
                postPool.liquidity,
                prevReserveSell,
                postReserveSell,
                prevReserveBuy,
                postReserveBuy,
                prePool.feeGrowthGlobalAsset,
                postPool.feeGrowthGlobalAsset,
                prePool.feeGrowthGlobalQuote,
                postPool.feeGrowthGlobalQuote
            );
        } catch {}
    }

    function swap_quote_in_increases_reserve(uint256 amount, uint256 limit) public {
        bool sellAsset = false;

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens();
        HyperCurve memory curve = pool.params;
        // require(curve.maturity() > block.timestamp);

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        uint256 prevReserveSell = getReserve(address(_hyper), address(_quote));
        uint256 prevReserveBuy = getReserve(address(_hyper), address(_asset));

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        try _hyper.swap(poolId, sellAsset, amount, limit) {
            HyperPool memory postPool = getPool(address(_hyper), poolId);

            uint256 postReserveSell = getReserve(address(_hyper), address(_quote));
            uint256 postReserveBuy = getReserve(address(_hyper), address(_asset));

            if (prevReserveSell < prevReserveSell) {
                emit LogUint256("quote reserve before swap", prevReserveSell);
                emit LogUint256("quote reserve after swap", prevReserveSell);
                emit AssertionFailed("BUG: reserve decreased after swapping quote in, it should have increased.");
            }

            // feeGrowthSell = quote
            check_external_swap_invariants(
                prePool.lastPrice,
                postPool.lastPrice,
                prePool.liquidity,
                postPool.liquidity,
                prevReserveSell,
                postReserveSell,
                prevReserveBuy,
                postReserveBuy,
                prePool.feeGrowthGlobalQuote,
                postPool.feeGrowthGlobalQuote,
                prePool.feeGrowthGlobalAsset,
                postPool.feeGrowthGlobalAsset
            );
        } catch {}
    }

    function check_external_swap_invariants(
        uint prevPrice,
        uint postPrice,
        uint prevLiquidity,
        uint postLiquidity,
        uint prevReserveSell,
        uint postReserveSell,
        uint prevReserveBuy,
        uint postReserveBuy,
        uint prevFeeGrowthSell,
        uint postFeeGrowthSell,
        uint prevFeeGrowthBuy,
        uint postFeeGrowthBuy
    ) internal pure {
        // price always changes in a swap
        assert(postPrice != prevPrice);

        // liquidity only changes in allocate and unallocate
        assert(prevLiquidity == postLiquidity);

        // fee growth checkpoints are always changing
        assert(postFeeGrowthSell >= prevFeeGrowthSell);
        assert(postFeeGrowthBuy >= postFeeGrowthBuy);

        // actual token balances increase or decrease for non-internal balance swaps.
        assert(postReserveSell > prevReserveSell);
        assert(postReserveBuy < prevReserveBuy);
    }
}
