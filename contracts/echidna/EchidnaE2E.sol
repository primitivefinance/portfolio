pragma solidity ^0.8.0;

import "../../test/helpers/HelperHyperProfiles.sol" as DefaultValues;
import "./GlobalInvariants.sol";

contract EchidnaE2E is GlobalInvariants {
    constructor() GlobalInvariants() {
        EchidnaERC20 _asset = create_token("Asset Token", "ADEC6", 6);
        EchidnaERC20 _quote = create_token("Quote Token", "QDEC18", 18);
        add_created_hyper_token(_asset);
        add_created_hyper_token(_quote);
        create_pair_with_safe_preconditions(1, 2);
        create_non_controlled_pool(0, 1, 0, 0, 0, 100);
    }

    OS.AccountSystem hyperAccount;

    // ******************** Check Proper System Deployment ********************
    function check_proper_deployment() public view {
        assert(address(_weth) != address(0));
        assert(address(_hyper) != address(0));

        // Note: This invariant may break with tokens on hooks.
        assert(_hyper.locked() == 1);

        // Retrieve the OS.__account__
        (bool prepared, bool settled) = _hyper.__account__();
        assert(!prepared);
        assert(settled);

        address[] memory warmTokens = _hyper.getWarm();
        assert(warmTokens.length == 0);
    }

    // TODO: Find a better name here with `pool_` at the beginning

    function check_hyper_curve_assumptions() public view {
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

    // function check_decoding_pool_id(uint64 _poolId, uint24 _pairId, uint8 _isMutable, uint32 _poolNonce) private {

    //     (uint64 poolId, uint24 pairId, uint8 isMutable, uint32 poolNonce) = ProcessingLib.decodePoolId([_poolId,_pairId,_isMutable,_poolNonce]);

    // }

    // ******************** Change Pool Parameters ********************
    function change_parameters(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        uint128 maxPrice,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        (HyperPool memory preChangeState, uint64 poolId, , ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("created pools", poolIds.length);
        emit LogUint256("pool ID", uint256(poolId));
        require(preChangeState.isMutable());
        require(preChangeState.controller == address(this));
        {
            // scaling remaining pool creation values
            fee = uint16(between(fee, MIN_FEE, MAX_FEE));
            priorityFee = uint16(between(priorityFee, 1, fee));
            volatility = uint16(between(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
            duration = uint16(between(duration, MIN_DURATION, MAX_DURATION));
            // maxTick = (-MAX_TICK) + (maxTick % (MAX_TICK - (-MAX_TICK))); // [-MAX_TICK,MAX_TICK]
            jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
            price = uint128(between(price, 1, type(uint128).max)); // price is between 1-uint256.max
        }

        _hyper.changeParameters(poolId, priorityFee, fee, jit);
        {
            (HyperPool memory postChangeState, , , ) = retrieve_random_pool_and_tokens(id);
            HyperCurve memory preChangeCurve = preChangeState.params;
            HyperCurve memory postChangeCurve = postChangeState.params;
            assert(postChangeState.lastTimestamp == preChangeState.lastTimestamp);
            assert(postChangeState.controller == address(this));
            assert(postChangeCurve.createdAt == preChangeCurve.createdAt);
            assert(postChangeCurve.priorityFee == priorityFee);
            assert(postChangeCurve.fee == fee);
            assert(postChangeCurve.volatility == volatility);
            assert(postChangeCurve.duration == duration);
            assert(postChangeCurve.jit == jit);
            assert(postChangeCurve.maxPrice == maxPrice);
        }
    }

    // Invariant: Attempting to change parameters of a nonmutable pool should fail
    function change_parameters_to_non_mutable_pool_should_fail(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        uint128 maxPrice,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        (HyperPool memory preChangeState, uint64 poolId, , ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("created pools", poolIds.length);
        emit LogUint256("pool ID", uint256(poolId));
        require(!preChangeState.isMutable());
        require(preChangeState.controller == address(this));
        {
            // scaling remaining pool creation values
            fee = uint16(between(fee, MIN_FEE, MAX_FEE));
            priorityFee = uint16(between(priorityFee, 1, fee));
            volatility = uint16(between(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
            duration = uint16(between(duration, MIN_DURATION, MAX_DURATION));
            // maxTick = (-MAX_TICK) + (maxTick % (MAX_TICK - (-MAX_TICK))); // [-MAX_TICK,MAX_TICK]
            jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
            price = uint128(between(price, 1, type(uint128).max)); // price is between 1-uint256.max
        }

        try _hyper.changeParameters(poolId, priorityFee, fee, jit) {
            emit AssertionFailed("BUG: Changing pool parameters of a nonmutable pool should not be possible");
        } catch {}
    }

    using SafeCastLib for uint256;

    // ******************** Claim ********************
    function claim_should_succeed_with_correct_preconditions(
        uint256 id,
        uint256 deltaAsset,
        uint256 deltaQuote
    ) public {
        (, uint64 poolId, , ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        HyperPosition memory preClaimPosition = getPosition(address(_hyper), address(this), poolId);
        require(preClaimPosition.lastTimestamp != 0);

        try _hyper.claim(poolId, deltaAsset, deltaQuote) {
            // if tokens were owned, decrement from position
            // if tokens were owed, getBalance of tokens increased for the caller
        } catch {
            emit AssertionFailed("BUG: claim function should have succeeded");
        }
    }

    function create_special_pool() public {
        require(!specialPoolCreated, "Special Pool already created");
        uint24 pairId = create_special_pair();
        create_special_pool(pairId, PoolParams(0, 0, 1, 0, 0, 0, 100));
    }



    // A user should not be able to allocate more than they own

    // ******************** Unallocate ********************
    function unallocate_with_correct_preconditions_should_work(uint256 id, uint256 amount) public {
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

        (uint256 deltaAsset, uint256 deltaQuote) = _hyper.getAmounts(poolId);

        _hyper.unallocate(poolId, amount);

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
        if (curve.maturity() <= block.timestamp){
            emit LogUint256("Maturity timestamp",curve.maturity());
            emit LogUint256("block.timestamp", block.timestamp);
            swap_should_fail(curve, poolId, true, amount, amount, "BUG: Swap on an expired pool should have failed.");
        } else {
            try _hyper.swap(poolId, sellAsset, amount, limit) returns (uint256 output, uint256 remainder) {
                HyperState memory postState = getState(address(_hyper), poolId, address(this), owners);
            } catch {}
        }

    }

    function swap_on_zero_amount_should_fail(uint id) public {
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        uint256 amount = 0;

        swap_should_fail(pool.params, poolId, true, amount, id, "BUG: Swap with zero amount should fail.");
    }
    function swap_should_fail(HyperCurve memory curve, uint64 poolId, bool sellAsset, uint256 amount, uint256 limit, string memory msg) private {
        try _hyper.swap(poolId, sellAsset, amount, amount) {
            emit AssertionFailed(msg);
        }
        catch {}
    }


    function swap_assets_in_always_decreases_price(uint id, bool sellAsset, uint256 amount, uint256 limit) public {
        require(sellAsset);

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        HyperCurve memory curve = pool.params;
        require(curve.maturity() > block.timestamp);

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);


        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        uint256 prevReserveSell = getReserve(address(_hyper), address(_asset));
        uint256 prevReserveBuy = getReserve(address(_hyper), address(_quote));

        uint256 prePoolLastPrice = _hyper.getLatestPrice(poolId);
        HyperPool memory prePool = getPool(address(_hyper), poolId);
        _hyper.swap(poolId, sellAsset, amount, limit);
        HyperPool memory postPool = getPool(address(_hyper), poolId);

        uint256 postReserveSell = getReserve(address(_hyper), address(_asset));
        uint256 postReserveBuy = getReserve(address(_hyper), address(_quote));

        uint256 postPoolLastPrice = _hyper.getLatestPrice(poolId);

        if(postPoolLastPrice == 0) {
            emit LogUint256("lastPrice", postPoolLastPrice);
            emit AssertionFailed("BUG: postPoolLastPrice is zero on a swap.");
        }
        if(postPoolLastPrice > prePoolLastPrice) {
            emit LogUint256("price before swap", prePoolLastPrice);
            emit LogUint256("price after swap", postPoolLastPrice);
            emit AssertionFailed("BUG: pool.lastPrice increased after swapping assets in, it should have decreased.");
        }

        // feeGrowthSell = asset
        check_external_swap_invariants(
            prePoolLastPrice,
            postPoolLastPrice,
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
    }

    struct _T_ {
        uint256 prevReserveSell;
        uint256 prevReserveBuy;
        uint256 prePoolLastPrice;
        uint256 postPoolLastPrice;
        uint256 postReserveSell;
        uint256 postReserveBuy;
    }

    function swap_quote_in_always_increases_price(uint id, bool sellAsset, uint256 amount, uint256 limit) public {
        require(!sellAsset);

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        HyperCurve memory curve = pool.params;
        require(curve.maturity() > block.timestamp);

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        _T_ memory t = _T_({
            prevReserveSell: getReserve(address(_hyper), address(_quote)),
            prevReserveBuy: getReserve(address(_hyper), address(_asset)),
            prePoolLastPrice: _hyper.getLatestPrice(poolId),
            postPoolLastPrice: 0,
            postReserveSell: 0,
            postReserveBuy: 0
        });

        {
            HyperPool memory prePool = getPool(address(_hyper), poolId);
            _hyper.swap(poolId, sellAsset, amount, limit);
            HyperPool memory postPool = getPool(address(_hyper), poolId);
            t.postPoolLastPrice = _hyper.getLatestPrice(poolId);

            if(t.postPoolLastPrice < t.prePoolLastPrice) {
                emit LogUint256("price before swap", t.prePoolLastPrice);
                emit LogUint256("price after swap", t.postPoolLastPrice);
                emit AssertionFailed("BUG: pool.lastPrice decreased after swapping quote in, it should have increased.");
            }

            t.postReserveSell = getReserve(address(_hyper), address(_quote));
            t.postReserveBuy = getReserve(address(_hyper), address(_asset));

            // feeGrowthSell = quote
            check_external_swap_invariants(
                t.prePoolLastPrice,
                t.postPoolLastPrice,
                prePool.liquidity,
                postPool.liquidity,
                t.prevReserveSell,
                t.postReserveSell,
                t.prevReserveBuy,
                t.postReserveBuy,
                prePool.feeGrowthGlobalQuote,
                postPool.feeGrowthGlobalQuote,
                prePool.feeGrowthGlobalAsset,
                postPool.feeGrowthGlobalAsset
            );
        }
    }

    function swap_asset_in_increases_reserve(uint id, bool sellAsset, uint256 amount, uint256 limit) public {
        require(sellAsset);

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        HyperCurve memory curve = pool.params;
        require(curve.maturity() > block.timestamp);

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);


        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        _T_ memory t = _T_({
            prevReserveSell: getReserve(address(_hyper), address(_quote)),
            prevReserveBuy: getReserve(address(_hyper), address(_asset)),
            prePoolLastPrice: _hyper.getLatestPrice(poolId),
            postPoolLastPrice: 0,
            postReserveSell: 0,
            postReserveBuy: 0
        });

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        _hyper.swap(poolId, sellAsset, amount, limit);
        HyperPool memory postPool = getPool(address(_hyper), poolId);
        t.postPoolLastPrice = _hyper.getLatestPrice(poolId);

        t.postReserveSell = getReserve(address(_hyper), address(_asset));
        t.postReserveBuy = getReserve(address(_hyper), address(_quote));

        if(t.postReserveSell < t.prevReserveSell) {
            emit LogUint256("asset reserve before swap", t.prevReserveSell);
            emit LogUint256("asset reserve after swap", t.postReserveSell);
            emit AssertionFailed("BUG: reserve decreased after swapping asset in, it should have increased.");
        }

        // feeGrowthSell = asset
        check_external_swap_invariants(
            t.prePoolLastPrice,
            t.postPoolLastPrice,
            prePool.liquidity,
            postPool.liquidity,
            t.prevReserveSell,
            t.postReserveSell,
            t.prevReserveBuy,
            t.postReserveBuy,
            prePool.feeGrowthGlobalAsset,
            postPool.feeGrowthGlobalAsset,
            prePool.feeGrowthGlobalQuote,
            postPool.feeGrowthGlobalQuote
        );
    }

    function swap_quote_in_increases_reserve(uint id, bool sellAsset, uint256 amount, uint256 limit) public {
        require(!sellAsset);

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        HyperCurve memory curve = pool.params;
        require(curve.maturity() > block.timestamp);

        amount = between(amount, 1, type(uint256).max);
        limit = between(limit, 1, type(uint256).max);


        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        emit LogUint256("amount: ", amount);
        emit LogUint256("limit:", limit);

        _T_ memory t = _T_({
            prevReserveSell: getReserve(address(_hyper), address(_quote)),
            prevReserveBuy: getReserve(address(_hyper), address(_asset)),
            prePoolLastPrice: _hyper.getLatestPrice(poolId),
            postPoolLastPrice: 0,
            postReserveSell: 0,
            postReserveBuy: 0
        });

        HyperPool memory prePool = getPool(address(_hyper), poolId);
        _hyper.swap(poolId, sellAsset, amount, limit);
        HyperPool memory postPool = getPool(address(_hyper), poolId);
        t.postPoolLastPrice = _hyper.getLatestPrice(poolId);

        t.postReserveSell = getReserve(address(_hyper), address(_quote));
        t.postReserveBuy = getReserve(address(_hyper), address(_asset));

        if(t.prevReserveSell < t.prevReserveSell) {
            emit LogUint256("quote reserve before swap", t.prevReserveSell);
            emit LogUint256("quote reserve after swap", t.prevReserveSell);
            emit AssertionFailed("BUG: reserve decreased after swapping quote in, it should have increased.");
        }

        // feeGrowthSell = quote
        check_external_swap_invariants(
            t.prePoolLastPrice,
            t.postPoolLastPrice,
            prePool.liquidity,
            postPool.liquidity,
            t.prevReserveSell,
            t.postReserveSell,
            t.prevReserveBuy,
            t.postReserveBuy,
            prePool.feeGrowthGlobalQuote,
            postPool.feeGrowthGlobalQuote,
            prePool.feeGrowthGlobalAsset,
            postPool.feeGrowthGlobalAsset
        );
    }
}
