pragma solidity ^0.8.0;

import "./Helper.sol";
import "solmate/tokens/WETH.sol";
import "../test/EchidnaERC20.sol";
import "../Hyper.sol";
import "../Enigma.sol" as ProcessingLib;
import "../../test/helpers/HelperHyperProfiles.sol" as DefaultValues;
import "../../test/helpers/HelperHyperView.sol";
import "./EchidnaStateHandling.sol";

contract EchidnaE2E is HelperHyperView, Helper, EchidnaStateHandling {
    WETH _weth;
    Hyper _hyper;

    constructor() public {
        _weth = new WETH();
        _hyper = new Hyper(address(_weth));
        EchidnaERC20 _asset = create_token("Asset Token", "ADEC6", 6);
        EchidnaERC20 _quote = create_token("Quote Token", "QDEC18", 18);
        add_created_hyper_token(_asset);
        add_created_hyper_token(_quote);
        create_pair_with_safe_preconditions(1, 2);
        create_non_controlled_pool(0,1,0,0,0,100);
    }

    OS.AccountSystem hyperAccount;

    // ******************** Check Proper System Deployment ********************
    function check_proper_deployment() public {
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

            uint256 poolLastPrice = _hyper.getLatestPrice(poolId);

            emit LogUint256("pool's last price", poolLastPrice);
            emit LogUint256("strike price", curve.maxPrice);

            assert(poolLastPrice <= curve.maxPrice);
        }
    }

    // Strike price for a pool should never be zero.
    // If it is, it suggests the mispricing and/or incorrect rounding of assets.
    function pool_strike_price_non_zero() public {
        for (uint8 i = 0; i < poolIds.length; i++) {
            uint64 poolId = poolIds[i];
            HyperPool memory pool = getPool(address(_hyper), poolId);
            HyperCurve memory curve = pool.params;

            emit LogUint256("pool's last price", _hyper.getLatestPrice(poolId));
            emit LogUint256("strike price", curve.maxPrice);

            if (curve.maxPrice == 0) {
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

            if (_hyper.getLatestPrice(poolId) != 0) {
                emit LogUint256("pool's last price", _hyper.getLatestPrice(poolId));
                if (pool.liquidity == 0) {
                    emit AssertionFailed("BUG: non zero last price should have a non zero liquidity");
                }
            }
            //TODO: if _hyper.getLatestPrice(poolId) == 0; pool.liquidity == 0?
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
            if (amountQuoteWad > curve.maxPrice) {
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

    // ******************** Create Pairs ********************
    /**
     * Future Invariant: This assumes that there is a single pair of _asset and _quote token
     *      - In the future, can be extended to deploy tokens from here and save the address in a list
     * 			which allows echidna to test against different pairs.
     * 			- Assumption: 1 pair for now.
     */
    function create_token(
        string memory tokenName,
        string memory shortform,
        uint8 decimals
    ) public returns (EchidnaERC20 token) {
        token = new EchidnaERC20(tokenName, shortform, decimals, address(_hyper));
        assert(token.decimals() == decimals);
        if (decimals >= 6 && decimals <= 18) {
            add_created_hyper_token(token);
        }
        return token;
    }

    /* Future Invariant: This could be extended to create arbitrary pairs.
    For now for complexity, I am leaving as is.
    Test overlapping token pairs
    */
    function create_pair_with_safe_preconditions(uint256 id1, uint256 id2) public {
        // retrieve an existing rpair of tokens that wee created with 6-18 decimals
        (EchidnaERC20 asset, EchidnaERC20 quote) = get_hyper_tokens(id1, id2);
        emit LogUint256("decimals asset", asset.decimals());
        emit LogUint256("decimals quote", quote.decimals());
        emit LogUint256("pair ID", uint256(_hyper.getPairId(address(asset), address(quote))));

        require(asset.decimals() >= 6 && asset.decimals() <= 18);
        require(quote.decimals() >= 6 && quote.decimals() <= 18);
        require(asset != quote);
        // require that this pair ID does not exist yet
        if (_hyper.getPairId(address(asset), address(quote)) != 0) {
            return;
        }
        // without this, Echidna may decide to call the EchidnaERC20.setDecimals
        uint256 preCreationNonce = _hyper.getPairNonce();

        // encode createPair arguments and call hyper contract
        bytes memory createPairData = ProcessingLib.encodeCreatePair(address(asset), address(quote));
        (bool success, bytes memory err) = address(_hyper).call(createPairData);
        if (!success) {
            emit LogBytes("error", err);
            emit AssertionFailed("FAILED");
        }

        pair_id_saved_properly(address(asset), address(quote));

        uint256 pairNonce = _hyper.getPairNonce();
        assert(pairNonce == preCreationNonce + 1);
    }

    /**
     * Future Invariant: This can likely be extended to ensure that pairID's must always match backwards to the tokens saved
     */
    function pair_id_saved_properly(address asset, address quote) private {
        // retrieve recently created pair ID
        uint24 pairId = _hyper.getPairId(address(asset), address(quote));
        if (pairId == 0) {
            emit LogUint256("PairId Exists", uint256(pairId));
            assert(false);
        }

        // retrieve pair information and ensure pair was saved
        HyperPair memory pair = getPair(address(_hyper), pairId);
        assert(pair.tokenAsset == address(asset));
        assert(pair.decimalsAsset == EchidnaERC20(asset).decimals());
        assert(pair.tokenQuote == address(quote));
        assert(pair.decimalsQuote == EchidnaERC20(quote).decimals());

        // save internal Echidna state to test against
        save_pair_id(pairId);
    }

    function create_same_pair_should_fail() public {
        EchidnaERC20 quote = create_token("Create same pair asset fail", "CSPF", 18);
        bytes memory createPairData = ProcessingLib.encodeCreatePair(address(quote), address(quote));
        (bool success, ) = address(_hyper).call(createPairData);
        assert(!success);
    }

    function create_pair_with_less_than_min_decimals_should_fail(uint256 decimals) public {
        decimals = uint8(between(decimals, 0, 5));
        EchidnaERC20 testToken = create_token("create less min decimals asset fail", "CLMDF", uint8(decimals));
        EchidnaERC20 quote = create_token("create less min decimals quote", "CLMDQ", 18);
        bytes memory createPairData = ProcessingLib.encodeCreatePair(address(testToken), address(quote));
        (bool success, ) = address(_hyper).call(createPairData);
        assert(!success);
    }

    function create_pair_with_more_than_max_decimals_should_fail(uint256 decimals) public {
        decimals = uint8(between(decimals, 19, type(uint8).max));
        EchidnaERC20 testToken = create_token("Create more than max decimals fail", "CMTMF", uint8(decimals));
        EchidnaERC20 quote = create_token("Create more than max decimals fail quote", "CMTMF2", 18);
        bytes memory createPairData = ProcessingLib.encodeCreatePair(address(testToken), address(quote));
        (bool success, ) = address(_hyper).call(createPairData);
        assert(!success);
    }

    // ******************** Create Pool ********************
    // Create a non controlled pool (controller address is 0) with default pair
    // Note: This function can be extended to choose from any created pair and create a pool on top of it
    function create_non_controlled_pool(
        uint256 id,
        uint16 fee,
        uint128 maxPrice,
        uint16 volatility,
        uint16 duration,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(uint256(id));
        {
            (, fee, maxPrice, volatility, duration, , price) = clam_safe_create_bounds(
                0,
                fee,
                maxPrice,
                volatility,
                duration,
                0,
                price
            );
        }
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(0), // no controller
            0, // no priority fee
            fee,
            volatility,
            duration,
            0, // no jit
            maxPrice,
            price
        );
        {
            (HyperPool memory pool, uint64 poolId) = execute_create_pool(pairId, createPoolData, false);
            assert(!pool.isMutable());
            HyperCurve memory curve = pool.params;
            assert(pool.lastTimestamp == block.timestamp);
            // assert(_hyper.getLatestPrice(poolId) == price); FIXME: This is reverting with UndefinedPrice()
            assert(curve.createdAt == block.timestamp);
            assert(pool.controller == address(0));
            assert(curve.priorityFee == 0);
            assert(curve.fee == fee);
            assert(curve.volatility == volatility);
            assert(curve.duration == duration);
            assert(curve.jit == JUST_IN_TIME_LIQUIDITY_POLICY);
            assert(curve.maxPrice == maxPrice);
        }
    }

    function create_controlled_pool(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        uint128 maxPrice,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(id);
        {
            (priorityFee, fee, maxPrice, volatility, duration, jit, price) = clam_safe_create_bounds(
                priorityFee,
                fee,
                maxPrice,
                volatility,
                duration,
                jit,
                price
            );
        }
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(this), //controller
            priorityFee, // no priority fee
            fee,
            volatility,
            duration,
            jit, // no jit
            maxPrice,
            price
        );
        {
            (HyperPool memory pool, uint64 poolId) = execute_create_pool(pairId, createPoolData, true);
            assert(pool.isMutable());
            HyperCurve memory curve = pool.params;
            assert(pool.lastTimestamp == block.timestamp);
            assert(curve.createdAt == block.timestamp);
            assert(pool.controller == address(this));
            assert(curve.priorityFee == priorityFee);
            assert(curve.fee == fee);
            assert(curve.volatility == volatility);
            assert(curve.duration == duration);
            assert(curve.jit == jit);
            assert(curve.maxPrice == maxPrice);
        }
    }

    function create_controlled_pool_with_zero_priority_fee_should_fail(
        uint256 id,
        uint16 fee,
        uint128 maxPrice,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(id);
        uint16 priorityFee = 0;
        {
            (, fee, maxPrice, volatility, duration, jit, price) = clam_safe_create_bounds(
                priorityFee,
                fee,
                maxPrice,
                volatility,
                duration,
                jit,
                price
            );
        }
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(this), //controller
            priorityFee, // no priority fee
            fee,
            volatility,
            duration,
            jit, // no jit
            maxPrice,
            price
        );
        (bool success, ) = address(_hyper).call(createPoolData);
        assert(!success);
    }

    function create_pool_with_negative_max_tick_as_bounds(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        uint128 maxPrice,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(id);
        {
            (priorityFee, fee, maxPrice, volatility, duration, jit, price) = clam_safe_create_bounds(
                priorityFee,
                fee,
                maxPrice,
                volatility,
                duration,
                jit,
                price
            );
        }
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(this), //controller
            priorityFee, // no priority fee
            fee,
            volatility,
            duration,
            jit, // no jit
            maxPrice,
            price
        );
        {
            (HyperPool memory pool, uint64 poolId) = execute_create_pool(pairId, createPoolData, true);
            assert(pool.isMutable());
            HyperCurve memory curve = pool.params;
            assert(pool.lastTimestamp == block.timestamp);
            assert(curve.createdAt == block.timestamp);
            assert(pool.controller == address(this));
            assert(curve.priorityFee == priorityFee);
            assert(curve.fee == fee);
            assert(curve.volatility == volatility);
            assert(curve.duration == duration);
            assert(curve.jit == jit);
            assert(curve.maxPrice == maxPrice);
        }
    }

    function execute_create_pool(
        uint24 pairId,
        bytes memory createPoolData,
        bool hasController
    ) private returns (HyperPool memory pool, uint64 poolId) {
        uint256 preCreationPoolNonce = _hyper.getPoolNonce();
        (bool success, ) = address(_hyper).call(createPoolData);

        // pool nonce should increase by 1 each time a pool is created
        uint256 poolNonce = _hyper.getPoolNonce();
        assert(poolNonce == preCreationPoolNonce + 1);

        // pool should be created and exist
        poolId = ProcessingLib.encodePoolId(pairId, hasController, uint32(poolNonce));
        pool = getPool(address(_hyper), poolId);
        if (!pool.exists()) {
            emit AssertionFailed("BUG: Pool should return true on exists after being created.");
        }

        // save pools in Echidna
        save_pool_id(poolId);
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

    // Invariant: Attempting to change parameters by a non-controller should fail
    // ******************** Funding ********************

    function fund_with_correct_preconditions_should_succeed(uint256 assetAmount, uint256 quoteAmount) public {
        // asset and quote amount > 1
        assetAmount = between(assetAmount, 1, type(uint64).max);
        quoteAmount = between(quoteAmount, 1, type(uint64).max);

        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(assetAmount, quoteAmount);

        emit LogUint256("assetAmount", assetAmount);
        emit LogUint256("quoteAmount", quoteAmount);
        mint_and_approve(_asset, assetAmount);
        mint_and_approve(_quote, quoteAmount);

        if (_asset.balanceOf(address(this)) < assetAmount) {
            emit LogUint256("asset balance", _asset.balanceOf(address(this)));
        }
        if (_quote.balanceOf(address(this)) < quoteAmount) {
            emit LogUint256("quote balance", _quote.balanceOf(address(this)));
        }

        fund_token(address(_asset), assetAmount);
        fund_token(address(_quote), quoteAmount);
    }

    function fund_with_insufficient_funds_should_fail(uint256 assetAmount, uint256 quoteAmount) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(assetAmount, quoteAmount);

        assetAmount = between(assetAmount, 1, type(uint256).max);
        quoteAmount = between(quoteAmount, 1, type(uint256).max);

        try _hyper.fund(address(_asset), assetAmount) {
            emit AssertionFailed("BUG: Funding with insufficient asset should fail");
        } catch {}

        try _hyper.fund(address(_quote), quoteAmount) {
            emit AssertionFailed("Funding with insufficient quote should fail");
        } catch {}
    }

    function fund_with_insufficient_allowance_should_fail(uint256 id, uint256 fundAmount) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(id, fundAmount);

        uint256 smallAssetAllowance = between(fundAmount, 1, fundAmount - 1);

        // mint the asset to address(this) and approve some amount < fund
        _asset.mint(address(this), fundAmount);
        _asset.approve(address(_hyper), smallAssetAllowance);
        try _hyper.fund(address(_asset), fundAmount) {
            emit LogUint256("small asset allowance", smallAssetAllowance);
            emit AssertionFailed("BUG: insufficient allowance on asset should fail.");
        } catch {}

        // mint the quote token to address(this), approve some amount < fund
        _quote.mint(address(this), fundAmount);
        _quote.approve(address(_hyper), smallAssetAllowance);
        try _hyper.fund(address(_quote), fundAmount) {
            emit LogUint256("small quote allowance", smallAssetAllowance);
            emit AssertionFailed("BUG: insufficient allowance on quote should fail.");
        } catch {}
    }

    function fund_with_zero(uint256 id1, uint256 id2) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(id1, id2);

        mint_and_approve(_asset, 0);
        mint_and_approve(_quote, 0);
        _hyper.fund(address(_asset), 0);
        _hyper.fund(address(_quote), 0);
    }

    function fund_token(address token, uint256 amount) private returns (bool) {
        // TODO Refactor: reuse the HelperHyperView.getState() keeps this cleaner
        uint256 senderBalancePreFund = EchidnaERC20(token).balanceOf(address(this));
        uint256 virtualBalancePreFund = getBalance(address(_hyper), address(this), address(token));
        uint256 reservePreFund = getReserve(address(_hyper), address(token));
        uint256 hyperBalancePreFund = EchidnaERC20(token).balanceOf(address(_hyper));

        try _hyper.fund(address(token), amount) {} catch (bytes memory error) {
            emit LogBytes("error", error);
            assert(false);
        }

        // sender's token balance should decrease
        // usdc sender pre token balance = 100 ; usdc sender post token = 100 - 1
        uint256 senderBalancePostFund = EchidnaERC20(token).balanceOf(address(this));
        if (senderBalancePostFund != senderBalancePreFund - amount) {
            emit LogUint256("postTransfer sender balance", senderBalancePostFund);
            emit LogUint256("preTransfer:", senderBalancePreFund);
            emit AssertionFailed("BUG: Sender balance of token did not decrease by amount after funding");
        }
        // hyper balance of the sender should increase
        // pre hyper balance = a; post hyperbalance + 100
        uint256 virtualBalancePostFund = getBalance(address(_hyper), address(this), address(token));
        if (virtualBalancePostFund != virtualBalancePreFund + amount) {
            emit LogUint256("tracked balance after funding", virtualBalancePostFund);
            emit LogUint256("tracked balance before funding:", virtualBalancePreFund);
            emit AssertionFailed("BUG: Tracked balance of sender did not increase after funding");
        }
        // hyper reserves for token should increase
        // reserve balance = b; post reserves + 100
        uint256 reservePostFund = getReserve(address(_hyper), address(token));
        if (reservePostFund != reservePreFund + amount) {
            emit LogUint256("reserve after funding", reservePostFund);
            emit LogUint256("reserve balance before funding:", reservePreFund);
            emit AssertionFailed("BUG: Reserve of hyper did not increase after funding");
        }
        // hyper's token balance should increase
        // pre balance of usdc = y; post balance = y + 100
        uint256 hyperBalancePostFund = EchidnaERC20(token).balanceOf(address(_hyper));
        if (hyperBalancePostFund != hyperBalancePreFund + amount) {
            emit LogUint256("hyper token balance after funding", hyperBalancePostFund);
            emit LogUint256("hyper balance before funding:", hyperBalancePreFund);
            emit AssertionFailed("BUG: Hyper token balance did not increase after funding");
        }
        return true;
    }

    function mint_and_approve(EchidnaERC20 token, uint256 amount) private {
        token.mint(address(this), amount);
        token.approve(address(_hyper), type(uint256).max);
    }

    // ******************** Draw ********************
    function draw_should_succeed(uint256 assetAmount, uint256 quoteAmount, address recipient) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(assetAmount, quoteAmount);

        assetAmount = between(assetAmount, 1, type(uint64).max);
        quoteAmount = between(quoteAmount, 1, type(uint64).max);
        emit LogUint256("asset amount: ", assetAmount);
        emit LogUint256("quote amount:", quoteAmount);

        require(recipient != address(_hyper));
        require(recipient != address(0));

        draw_token(address(_asset), assetAmount, recipient);
        draw_token(address(_quote), quoteAmount, recipient);
    }

    function draw_token(address token, uint256 amount, address recipient) private {
        // make sure a user has funded already
        uint256 virtualBalancePreFund = getBalance(address(_hyper), address(this), address(token));
        require(virtualBalancePreFund > 0);
        amount = between(amount, 1, virtualBalancePreFund);

        uint256 recipientBalancePreFund = EchidnaERC20(token).balanceOf(address(recipient));
        uint256 reservePreFund = getReserve(address(_hyper), address(token));
        uint256 hyperBalancePreFund = EchidnaERC20(token).balanceOf(address(_hyper));

        _hyper.draw(token, amount, recipient);

        //-- Postconditions
        // caller balance should decrease
        // pre caller balance = a; post caller balance = a - 100
        uint256 virtualBalancePostFund = getBalance(address(_hyper), address(this), address(token));
        if (virtualBalancePostFund != virtualBalancePreFund - amount) {
            emit LogUint256("virtual balance post draw", virtualBalancePostFund);
            emit LogUint256("virtual balance pre draw", virtualBalancePreFund);
            emit AssertionFailed("BUG: virtual balance should decrease after drawing tokens");
        }
        // reserves should decrease
        uint256 reservePostFund = getReserve(address(_hyper), address(token));
        if (reservePostFund != reservePreFund - amount) {
            emit LogUint256("reserve post draw", reservePostFund);
            emit LogUint256("reserve pre draw", reservePreFund);
            emit AssertionFailed("BUG: reserve balance should decrease after drawing tokens");
        }
        // to address should increase
        // pre-token balance = a; post-token = a + 100
        uint256 recipientBalancePostFund = EchidnaERC20(token).balanceOf(address(recipient));
        if (recipientBalancePostFund != recipientBalancePreFund + amount) {
            emit LogUint256("recipient balance post draw", recipientBalancePostFund);
            emit LogUint256("recipient balance pre draw", recipientBalancePreFund);
            emit AssertionFailed("BUG: recipient balance should increase after drawing tokens");
        }
        // hyper token's balance should decrease
        uint256 tokenPostFund = EchidnaERC20(token).balanceOf(address(_hyper));
        if (tokenPostFund != hyperBalancePreFund - amount) {
            emit LogUint256("token post draw", tokenPostFund);
            emit LogUint256("token pre draw", hyperBalancePreFund);
            emit AssertionFailed("BUG: hyper token balance should increase after drawing tokens");
        }
    }

    function draw_to_zero_should_fail(uint256 assetAmount, uint256 quoteAmount) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(assetAmount, quoteAmount);

        // make sure a user has funded already
        uint256 virtualBalancePreFund = getBalance(address(_hyper), address(this), address(_asset));
        emit LogUint256("virtual balance pre fund", virtualBalancePreFund);
        require(virtualBalancePreFund >= 0);
        assetAmount = between(assetAmount, 1, virtualBalancePreFund);

        try _hyper.draw(address(_asset), assetAmount, address(0)) {
            emit AssertionFailed("BUG: draw should fail attempting to transfer to zero");
        } catch {}
    }

    function fund_then_draw(uint256 whichToken, uint256 amount) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(amount, whichToken);

        // this can be extended to use the token list in `hyperTokens`
        address token;
        if (whichToken % 2 == 0) token = address(_asset);
        else token = address(_quote);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        uint256 hyperBalancePreFund = EchidnaERC20(token).balanceOf(address(_hyper));
        require(hyperBalancePreFund == 0);

        uint256 virtualBalancePreFund = getBalance(address(_hyper), address(this), address(token));
        uint256 recipientBalancePreFund = EchidnaERC20(token).balanceOf(address(this));
        uint256 reservePreFund = getReserve(address(_hyper), address(token));

        // Call fund and draw
        _hyper.fund(token, amount);
        _hyper.draw(token, amount, address(this));

        //-- Postconditions
        // caller balance should be equal

        //TODO Refactor: use HelperHyperView.getState() here
        uint256 virtualBalancePostFund = getBalance(address(_hyper), address(this), address(token));
        if (virtualBalancePostFund != virtualBalancePreFund) {
            emit LogUint256("virtual balance post fund-draw", virtualBalancePostFund);
            emit LogUint256("virtual balance pre fund-draw", virtualBalancePreFund);
            emit AssertionFailed("BUG: virtual balance should be equal after fund-draw");
        }
        // reserves should be equal
        uint256 reservePostFund = getReserve(address(_hyper), address(token));
        if (reservePostFund != reservePreFund) {
            emit LogUint256("reserve post fund-draw", reservePostFund);
            emit LogUint256("reserve pre fund-draw", reservePreFund);
            emit AssertionFailed("BUG: reserve balance should be equal after fund-draw");
        }
        // recipient = sender balance should be equal
        uint256 recipientBalancePostFund = EchidnaERC20(token).balanceOf(address(this));
        if (recipientBalancePostFund != recipientBalancePreFund) {
            emit LogUint256("recipient balance post fund-draw", recipientBalancePostFund);
            emit LogUint256("recipient balance pre fund-draw", recipientBalancePreFund);
            emit AssertionFailed("BUG: recipient balance should be equal after fund-draw");
        }
        // hyper token's balance should be equal
        uint256 tokenPostFund = EchidnaERC20(token).balanceOf(address(_hyper));
        if (tokenPostFund != hyperBalancePreFund) {
            emit LogUint256("token post fund-draw", tokenPostFund);
            emit LogUint256("token pre fund-draw", hyperBalancePreFund);
            emit AssertionFailed("BUG: hyper token balance should be equal after fund-draw");
        }
    }

    // ******************** Deposits ********************

    function deposit_with_correct_postconditions_should_succeed() public payable {
        require(msg.value > 0);
        emit LogUint256("msg.value", msg.value);

        uint256 thisEthBalancePre = address(this).balance;
        uint256 reserveBalancePre = getReserve(address(_hyper), address(_weth));
        uint256 wethBalancePre = _weth.balanceOf(address(_hyper));

        try _hyper.deposit{value: msg.value}() {
            uint256 thisEthBalancePost = address(this).balance;
            uint256 reserveBalancePost = getReserve(address(_hyper), address(_weth));
            uint256 wethBalancePost = _weth.balanceOf(address(_hyper));
            // Eth balance of this contract should decrease by the deposited amount
            if (thisEthBalancePost != thisEthBalancePre - msg.value) {
                emit LogUint256("eth balance post transfer (sender)", thisEthBalancePost);
                emit LogUint256("eth balance pre transfer (sender)", thisEthBalancePre);
                emit AssertionFailed("sender's eth balance should not change.");
            }
            // Hyper reserve of WETH should increase by msg.value
            if (reserveBalancePost != reserveBalancePre + msg.value) {
                emit LogUint256("weth reserve post transfer (hyper)", reserveBalancePost);
                emit LogUint256("weth reserve pre transfer (hyper)", reserveBalancePre);
                emit AssertionFailed("hyper's weth reserve should increase by added amount.");
            }
            // Hyper balance of WETH should increase by msg.value
            if (wethBalancePost != wethBalancePre + msg.value) {
                emit LogUint256("weth balance post transfer (hyper)", wethBalancePost);
                emit LogUint256("weth balance pre transfer (hyper)", wethBalancePre);
                emit AssertionFailed("hypers's weth balance should increase by added amount.");
            }
        } catch (bytes memory err) {
            emit LogBytes("error", err);
            emit AssertionFailed("BUG: deposit should not have failed.");
        }
    }

    using SafeCastLib for uint256;

    // ******************** Claim ********************
    function claim_should_succeed_with_correct_preconditions(
        uint256 id,
        uint256 deltaAsset,
        uint256 deltaQuote
    ) public {
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
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

    // Future invariant: Funding with WETH and then depositing with ETH should have the same impact on the pool
    // ******************** Allocate ********************
    function allocate_should_succeed_with_correct_preconditions(uint256 id, uint256 deltaLiquidity) public {
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        require(_hyper.getLatestPrice(poolId) != 0);
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
    }

    function execute_allocate_call(
        uint64 poolId,
        EchidnaERC20 _asset,
        EchidnaERC20 _quote,
        uint256 deltaAsset,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    ) internal {
        // Caller must have a balance and have approved hyper
        mint_and_approve(_asset, deltaAsset);
        mint_and_approve(_quote, deltaQuote);

        address[] memory owners = new address[](1);

        // Save pre allocation state
        HyperState memory preState = getState(address(_hyper), poolId, address(this), owners);

        (uint256 allocateAsset, uint256 allocateQuote) = _hyper.allocate(poolId, deltaLiquidity);
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

    function allocate_with_non_existent_pool_should_fail(uint256 id, uint256 deltaLiquidity) public {
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);

        address[] memory owners = new address[](1);
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

        // Save pre allocation state
        HyperState memory preState = getState(address(_hyper), poolId, address(this), owners);

        try _hyper.allocate(poolId, deltaLiquidity) returns (uint256 allocateAset, uint256 allocateQuote) {
            emit AssertionFailed("BUG: allocate with non existent pool should fail");
        } catch {}
    }

    function allocate_with_zero_delta_liquidity_should_fail(uint256 id) public {
        address[] memory owners = new address[](1);
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        require(_hyper.getLatestPrice(poolId) != 0);
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

        try _hyper.allocate(poolId, deltaLiquidity) returns (uint256 allocateAset, uint256 allocateQuote) {
            emit AssertionFailed("BUG: allocate with deltaLiquidity=0 should fail");
        } catch {}
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

    // A user without a position should not be able to unallocate funds
    function unallocate_without_position_should_fail(uint256 id, uint256 amount) public {
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
        require(pool.lastTimestamp - block.timestamp < JUST_IN_TIME_LIQUIDITY_POLICY);

        try _hyper.unallocate(poolId, amount) {
            emit AssertionFailed("BUG: User was able to unallocate without prior allocation");
        } catch {}
    }

    // A user attempting to unallocate a nonexistent pool should fail
    // A user attempting to unallocate an expired pool should be successful
    // Caller position last timestamp <= block.timestamp, with JIT policy
    // A user should not be able to unallocate more than they own
    // A user calling allocate then unallocate should succeed
    function allocate_then_unallocate_should_succeed(uint256 id, uint256 amount) public {
        address[] memory owners = new address[](1);
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        require(_hyper.getLatestPrice(poolId) != 0);
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
        _hyper.unallocate(poolId, amount);
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
    function swap_on_non_existent_pool_should_fail(uint64 id) public {
        // Ensure that the pool id was not one that's already been created
        require(!is_created_pool(id));
        HyperPool memory pool = getPool(address(_hyper),id);

        swap_should_fail(pool.params, id, true, id, id, "BUG: Swap on a nonexistent pool should fail.");
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

    function retrieve_random_pool_and_tokens(
        uint256 id
    ) private view returns (HyperPool memory pool, uint64 poolId, EchidnaERC20 asset, EchidnaERC20 quote) {
        // assumes that at least one pool exists because it's been created in the constructor
        uint256 random = between(id, 0, poolIds.length - 1);
        if (poolIds.length == 1) random = 0;

        pool = getPool(address(_hyper), poolIds[random]);
        poolId = poolIds[random];
        HyperPair memory pair = pool.pair;
        quote = EchidnaERC20(pair.tokenQuote);
        asset = EchidnaERC20(pair.tokenAsset);
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
    ) internal {
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
