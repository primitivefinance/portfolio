pragma solidity ^0.8.4;
import "./EchidnaStateHandling.sol";

contract Swaps is EchidnaStateHandling {
    using RMM01Lib for HyperPool;

    function mint_and_allocate(HyperPair memory pair, uint128 amount, uint64 poolId) internal {
        mint_and_approve(EchidnaERC20(pair.tokenAsset), amount);
        mint_and_approve(EchidnaERC20(pair.tokenQuote), amount);
        _hyper.multiprocess(EnigmaLib.encodeAllocate(uint8(0), poolId, 0x0, amount));
    }

    function clamp_liquidity(uint256 id, uint64 poolId) internal returns (uint256 liquidity) {
        (uint256 amountAsset, uint256 amountQuote) = _hyper.getReserves(poolId);
        uint256 liquidity = between(id, 1, uint128(type(int128).max));
        if (amountAsset != 0) {
            liquidity = between(liquidity, amountAsset, (uint128(type(int128).max) + amountAsset - 1) / amountAsset);
        }
        if (amountQuote != 0) {
            liquidity = between(liquidity, amountQuote, (uint128(type(int128).max) + amountQuote - 1) / amountQuote);
        }
    }

    function clam_safe_input_output_value(
        bool sellAsset,
        uint256 liquidity,
        HyperPool memory pool
    ) internal returns (uint256 input, uint256 output) {
        uint maxInput;
        uint maxOutput;
        HyperCurve memory curve = pool.params;
        uint stk = curve.maxPrice;

        // Compute reserves to determine max input and output.
        (uint256 R_y, uint256 R_x) = RMM01Lib.computeReservesWithPrice(pool, stk, 0);

        if (sellAsset) {
            // console.log("selling");
            // console.log("liveIndependent R_x", R_x);
            // console.log("liveDependent R_y", R_y);
            if (R_x >= 1e18) return (0, 0); // Shouldn't happen
            maxInput = ((1e18 - R_x) * liquidity) / 1e18;
            maxOutput = (R_y * liquidity) / 1e18;
        } else {
            // console.log("buying");
            emit LogUint256("liveIndependent R_y", R_y);
            emit LogUint256("liveDependent R_x", R_x);
            if (R_y > stk) return (0, 0); // Can happen although this will lead to an overflow on computing max in the swap fn.
            maxInput = ((stk - R_y) * liquidity) / 1e18; // (2-2)*2/1e18
            maxOutput = (R_x * liquidity) / 1e18;
        }
        emit LogUint256("max input", maxInput);
        emit LogUint256("max ouput ", maxOutput);
        // assert(false);

        if (maxInput < 1 || maxOutput < 1) return (0, 0); // Will revert in swap due to input/output == 0.
        input = between(liquidity, 1, maxInput);
        output = between(liquidity, 1, maxOutput);
    }

    // Swaps
    function swap_should_succeed(uint id, bool sellAsset) public {
        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        HyperCurve memory curve = pool.params;

        uint256 liquidity = clamp_liquidity(id, poolId);
        mint_and_allocate(pool.pair, liquidity, poolId);

        emit LogUint256("difference in maturity and timestamp:", uint256(curve.maturity()) - uint256(block.timestamp));

        if (curve.maturity() <= block.timestamp) {
            emit LogUint256("Maturity timestamp", curve.maturity());
            emit LogUint256("block.timestamp", block.timestamp);
            swap_should_fail(poolId, true, id, id, "BUG: Swap on an expired pool should have failed.");
        } else {
            uint256 stk = curve.maxPrice;
            emit LogUint256("stk", stk);

            (uint input, uint output) = clam_safe_input_output_value(sellAsset, liquidity, pool);
            if (input == 0 && output == 0) return;
            check_swap_error(pool, poolId, sellAsset, input, output);
        }
    }

    function check_swap_error(
        HyperPool memory pool,
        uint64 poolId,
        bool sellAsset,
        uint256 input,
        uint256 output
    ) internal {
        HyperPair memory pair = pool.pair;
        uint256 initAsset = EchidnaERC20(pair.tokenAsset).balanceOf(address(this));
        uint256 initQuote = EchidnaERC20(pair.tokenQuote).balanceOf(address(this));
        // Max error margin the invariant check in the swap allows for.
        uint256 maxErr = 100 * 1e18;
        {
            // Swapping back and forth should not succeed if `output > input` under normal circumstances.
            (bool success, ) = swapBackAndForthCall(
                poolId,
                sellAsset,
                uint128(input),
                uint128(output),
                uint128(input + maxErr)
            );

            if (success) {
                _hyper.draw(pair.tokenAsset, _hyper.getBalance(address(this), pair.tokenAsset), address(this));
                _hyper.draw(pair.tokenQuote, _hyper.getBalance(address(this), pair.tokenQuote), address(this));

                emit LogUint256("asset gain", EchidnaERC20(pair.tokenAsset).balanceOf(address(this)) - initAsset);
                emit LogUint256("quote gain", EchidnaERC20(pair.tokenQuote).balanceOf(address(this)) - initQuote);
                emit AssertionFailed("Swap allowed to extract tokens");
            }
        }
    }

    function swapBackAndForthCall(
        uint64 poolId,
        bool sell,
        uint128 input,
        uint128 output1,
        uint128 output2
    ) internal returns (bool success, bytes memory returndata) {
        bytes[] memory instructions = new bytes[](2);

        instructions[0] = ProcessingLib.encodeSwap(0, poolId, 0, input, 0, output1, sell ? 0 : 1);
        instructions[1] = ProcessingLib.encodeSwap(0, poolId, 0, output1, 0, output2, sell ? 1 : 0);

        bytes memory data = ProcessingLib.encodeJumpInstruction(instructions);

        try _hyper.multiprocess(data) {
            success = true;
        } catch {}
    }

    function swap_on_non_existent_pool_should_fail(uint64 id) public {
        // Ensure that the pool id was not one that's already been created
        require(!is_created_pool(id));

        swap_should_fail(id, true, id, id, "BUG: Swap on a nonexistent pool should fail.");
    }

    function swap_on_zero_amount_should_fail() public {
        // Will always return a pool that exists
        (, uint64 poolId, , ) = retrieve_non_expired_pool_and_tokens();
        uint256 amount = 0;

        swap_should_fail(poolId, true, amount, poolId + 1, "BUG: Swap with zero swap amount should fail.");
    }

    function swap_on_limit_amount_of_zero_should_fail() public {
        // Will always return a pool that exists
        (, uint64 poolId, , ) = retrieve_non_expired_pool_and_tokens();
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
        try
            _hyper.multiprocess(
                EnigmaLib.encodeSwap(uint8(0), poolId, 0x0, amount, 0x0, limit, uint8(sellAsset ? 0 : 1))
            )
        {
            emit AssertionFailed(failureMsg);
        } catch {}
    }

    function swap_assets_in_always_decreases_price(uint128 amount, uint128 limit) public {
        bool sellAsset = true;

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

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        _Changes_ memory c = _Changes_({
            prevReserveSell: getReserve(address(_hyper), address(_asset)),
            prevReserveBuy: getReserve(address(_hyper), address(_quote)),
            prePoolLastPrice: _hyper.getLatestEstimatedPrice(poolId),
            postPoolLastPrice: 0,
            postReserveSell: 0,
            postReserveBuy: 0
        });

        try
            _hyper.multiprocess(
                EnigmaLib.encodeSwap(uint8(0), poolId, 0x0, amount, 0x0, limit, uint8(sellAsset ? 0 : 1))
            )
        {
            HyperPool memory postPool = getPool(address(_hyper), poolId);
            c.postPoolLastPrice = _hyper.getLatestEstimatedPrice(poolId);

            c.postReserveSell = getReserve(address(_hyper), address(_asset));
            c.postReserveBuy = getReserve(address(_hyper), address(_quote));

            if (c.postPoolLastPrice == 0) {
                emit LogUint256("lastPrice", c.postPoolLastPrice);
                emit AssertionFailed("BUG: pool.lastPrice is zero on a swap.");
            }
            if (c.postPoolLastPrice > c.prePoolLastPrice) {
                emit LogUint256("price before swap", c.prePoolLastPrice);
                emit LogUint256("price after swap", c.postPoolLastPrice);
                emit AssertionFailed(
                    "BUG: pool.lastPrice increased after swapping assets in, it should have decreased."
                );
            }

            // feeGrowthSell = asset
            check_external_swap_invariants(
                c.prePoolLastPrice,
                c.postPoolLastPrice,
                prePool.liquidity,
                postPool.liquidity,
                c.prevReserveSell,
                c.postReserveSell,
                c.prevReserveBuy,
                c.postReserveBuy,
                prePool.feeGrowthGlobalAsset,
                postPool.feeGrowthGlobalAsset,
                prePool.feeGrowthGlobalQuote,
                postPool.feeGrowthGlobalQuote
            );
        } catch {}
    }

    function swap_quote_in_always_increases_price(uint256 amount, uint256 limit) public {
        bool sellAsset = false;

        // Will always return a pool that exists
        (, uint64 poolId, EchidnaERC20 _asset, EchidnaERC20 _quote) = retrieve_non_expired_pool_and_tokens();

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        _Changes_ memory c = _Changes_({
            prevReserveSell: getReserve(address(_hyper), address(_asset)),
            prevReserveBuy: getReserve(address(_hyper), address(_quote)),
            prePoolLastPrice: _hyper.getLatestEstimatedPrice(poolId),
            postPoolLastPrice: 0,
            postReserveSell: 0,
            postReserveBuy: 0
        });
        uint256 prevReserveSell = getReserve(address(_hyper), address(_quote));
        uint256 prevReserveBuy = getReserve(address(_hyper), address(_asset));

        try _hyper.multiprocess(EnigmaLib.encodeSwap(uint8(0), poolId, 0x0, amount, 0x0, limit, sellAsset)) {
            HyperPool memory postPool = getPool(address(_hyper), poolId);
            c.postPoolLastPrice = _hyper.getLatestEstimatedPrice(poolId);

            c.postReserveSell = getReserve(address(_hyper), address(_quote));
            c.postReserveBuy = getReserve(address(_hyper), address(_asset));

            if (c.postPoolLastPrice < c.prePoolLastPrice) {
                emit LogUint256("price before swap", c.prePoolLastPrice);
                emit LogUint256("price after swap", c.postPoolLastPrice);
                emit AssertionFailed(
                    "BUG: pool.lastPrice decreased after swapping quote in, it should have increased."
                );
            }

            // feeGrowthSell = quote
            check_external_swap_invariants(
                c.prePoolLastPrice,
                c.postPoolLastPrice,
                prePool.liquidity,
                postPool.liquidity,
                prevReserveSell,
                c.postReserveSell,
                prevReserveBuy,
                c.postReserveBuy,
                prePool.feeGrowthGlobalQuote,
                postPool.feeGrowthGlobalQuote,
                prePool.feeGrowthGlobalAsset,
                postPool.feeGrowthGlobalAsset
            );
        } catch {}
    }

    struct _Changes_ {
        uint256 prevReserveSell;
        uint256 prevReserveBuy;
        uint256 prePoolLastPrice;
        uint256 postPoolLastPrice;
        uint256 postReserveSell;
        uint256 postReserveBuy;
    }

    function swap_asset_in_increases_reserve(uint256 amount, uint256 limit) public {
        bool sellAsset = true;

        // Will always return a pool that exists
        (, uint64 poolId, EchidnaERC20 _asset, EchidnaERC20 _quote) = retrieve_non_expired_pool_and_tokens();

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        _Changes_ memory c = _Changes_({
            prevReserveSell: getReserve(address(_hyper), address(_asset)),
            prevReserveBuy: getReserve(address(_hyper), address(_quote)),
            prePoolLastPrice: _hyper.getLatestEstimatedPrice(poolId),
            postPoolLastPrice: 0,
            postReserveSell: 0,
            postReserveBuy: 0
        });

        try
            _hyper.multiprocess(
                EnigmaLib.encodeSwap(uint8(0), poolId, 0x0, amount, 0x0, limit, uint8(sellAsset ? 0 : 1))
            )
        {
            HyperPool memory postPool = getPool(address(_hyper), poolId);
            c.postPoolLastPrice = _hyper.getLatestEstimatedPrice(poolId);

            c.postReserveSell = getReserve(address(_hyper), address(_asset));
            c.postReserveBuy = getReserve(address(_hyper), address(_quote));

            if (c.postReserveSell < c.prevReserveSell) {
                emit LogUint256("asset reserve before swap", c.prevReserveSell);
                emit LogUint256("asset reserve after swap", c.postReserveSell);
                emit AssertionFailed("BUG: reserve decreased after swapping asset in, it should have increased.");
            }

            // feeGrowthSell = asset
            check_external_swap_invariants(
                c.prePoolLastPrice,
                c.postPoolLastPrice,
                prePool.liquidity,
                postPool.liquidity,
                c.prevReserveSell,
                c.postReserveSell,
                c.prevReserveBuy,
                c.postReserveBuy,
                prePool.feeGrowthGlobalAsset,
                postPool.feeGrowthGlobalAsset,
                prePool.feeGrowthGlobalQuote,
                postPool.feeGrowthGlobalQuote
            );
        } catch {}
    }

    function swap_quote_in_increases_reserve(uint256 amount, uint256 limit) public {
        bool sellAsset = false;

        // Will always return a pool that exists
        (, uint64 poolId, EchidnaERC20 _asset, EchidnaERC20 _quote) = retrieve_non_expired_pool_and_tokens();

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        _Changes_ memory c = _Changes_({
            prevReserveSell: getReserve(address(_hyper), address(_asset)),
            prevReserveBuy: getReserve(address(_hyper), address(_quote)),
            prePoolLastPrice: _hyper.getLatestEstimatedPrice(poolId),
            postPoolLastPrice: 0,
            postReserveSell: 0,
            postReserveBuy: 0
        });

        try
            _hyper.multiprocess(
                EnigmaLib.encodeSwap(uint8(0), poolId, 0x0, amount, 0x0, limit, uint8(sellAsset ? 0 : 1))
            )
        {
            HyperPool memory postPool = getPool(address(_hyper), poolId);
            c.postPoolLastPrice = _hyper.getLatestEstimatedPrice(poolId);

            c.postReserveSell = getReserve(address(_hyper), address(_quote));
            c.postReserveBuy = getReserve(address(_hyper), address(_asset));

            if (c.prevReserveSell < c.prevReserveSell) {
                emit LogUint256("quote reserve before swap", c.prevReserveSell);
                emit LogUint256("quote reserve after swap", c.prevReserveSell);
                emit AssertionFailed("BUG: reserve decreased after swapping quote in, it should have increased.");
            }

            // feeGrowthSell = quote
            check_external_swap_invariants(
                c.prePoolLastPrice,
                c.postPoolLastPrice,
                prePool.liquidity,
                postPool.liquidity,
                c.prevReserveSell,
                c.postReserveSell,
                c.prevReserveBuy,
                c.postReserveBuy,
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
        assert(postFeeGrowthBuy >= prevFeeGrowthBuy);

        // actual token balances increase or decrease for non-internal balance swaps.
        assert(postReserveSell > prevReserveSell);
        assert(postReserveBuy < prevReserveBuy);
    }

    function swap_quote_with_fifteen_decimals(uint128 amount, uint128 limit) public {
        require(specialPoolCreated, "Special Pool not created");
        uint128 _amount = between(amount, 1, type(uint128).max);
        uint128 _limit = between(limit, 1, type(uint128).max);

        HyperPool memory prePool = getPool(address(_hyper), specialPoolId);
        uint256 prePoolLastPrice = _hyper.getLatestEstimatedPrice(specialPoolId);

        mint_and_approve(EchidnaERC20(prePool.pair.tokenAsset), _amount);
        mint_and_approve(EchidnaERC20(prePool.pair.tokenQuote), _amount);

        emit LogUint256("amount: ", _amount);
        emit LogUint256("limit:", _limit);

        uint256 prevReserveSell = getReserve(address(_hyper), prePool.pair.tokenQuote);
        uint256 prevReserveBuy = getReserve(address(_hyper), prePool.pair.tokenAsset);

        try _hyper.multiprocess(EnigmaLib.encodeSwap(uint8(0), specialPoolId, 0x0, _amount, 0x0, _limit, uint8(1))) {
            // sellAsset = false
            HyperPool memory postPool = getPool(address(_hyper), specialPoolId);
            uint256 postPoolLastPrice = _hyper.getLatestEstimatedPrice(specialPoolId);

            uint256 postReserveSell = getReserve(address(_hyper), postPool.pair.tokenQuote);
            uint256 postReserveBuy = getReserve(address(_hyper), postPool.pair.tokenAsset);

            assert(postPoolLastPrice != prePoolLastPrice);

            // liquidity only changes in allocate and unallocate
            assert(prePool.liquidity == postPool.liquidity);

            // fee growth checkpoints are always changing
            assert(postPool.feeGrowthGlobalQuote >= prePool.feeGrowthGlobalQuote);
            assert(postPool.feeGrowthGlobalAsset >= prePool.feeGrowthGlobalAsset); //maybe reverse

            // actual token balances increase or decrease for non-internal balance swaps.
            assert(postReserveSell > prevReserveSell);
            assert(postReserveBuy < prevReserveBuy);
        } catch {}
    }
}
