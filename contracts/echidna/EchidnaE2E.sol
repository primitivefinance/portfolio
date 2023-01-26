pragma solidity ^0.8.0;

import "../../test/helpers/HelperHyperProfiles.sol" as DefaultValues;
import "./GlobalInvariants.sol";

contract EchidnaE2E is GlobalInvariants {
    bool hasFunded;

    constructor() public GlobalInvariants() {
        EchidnaERC20 _asset = create_token("Asset Token", "ADEC6", 6);
        EchidnaERC20 _quote = create_token("Quote Token", "QDEC18", 18);
        add_created_hyper_token(_asset);
        add_created_hyper_token(_quote);
        create_pair_with_safe_preconditions(1, 2);
        create_non_controlled_pool(0, 1, 0, 0, 0, 100);
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

        require(pool.lastPrice != 0);
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

        require(pool.lastPrice != 0);
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
    // A user attempting to unallocate an expired pool should be successful
    // A user attempting to unallocate on any pool should succeed with correct preconditions
    function unallocate_with_correct_preconditions_should_succeed(uint256 id, uint256 amount) public {
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

        unallocate_should_fail(poolId, amount, "BUG: Unallocate without a position should fail.");
    }

    // A user attempting to unallocate a nonexistent pool should fail
    function unallocate_with_non_existent_pool_should_fail(uint64 id, uint256 amount) public {
        require(!is_created_pool(id));
        amount = between(amount, 1, type(uint256).max);
        unallocate_should_fail(id, amount, "BUG: Unallocate to a non-existent pool should fail.");
    }

    // Caller position last timestamp <= block.timestamp, with JIT policy
    // A user should not be able to unallocate more than they own
    function unallocate_should_fail(uint64 poolId, uint256 amount, string memory msg) private {
        try _hyper.unallocate(poolId, amount) {
            emit AssertionFailed(msg);
        } catch {}
    }

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

        require(pool.lastPrice != 0);
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

        // emit LogUint256("maturity",uint256(curve.maturity()));
        // emit LogUint256("block.timestamp", block.timestamp);
        emit LogUint256("difference in maturity and timestamp:", uint256(curve.maturity()) - uint256(block.timestamp));

        if (curve.maturity() <= block.timestamp) {
            emit LogUint256("Maturity timestamp", curve.maturity());
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
        HyperPool memory pool = getPool(address(_hyper), id);

        swap_should_fail(pool.params, id, true, id, id, "BUG: Swap on a nonexistent pool should fail.");
    }

    function swap_on_zero_amount_should_fail(uint id) public {
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens(id);
        uint256 amount = 0;

        swap_should_fail(pool.params, poolId, true, amount, id + 1, "BUG: Swap with zero swap amount should fail.");
    }

    function swap_on_limit_amount_of_zero_should_fail(uint id) public {
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens(id);
        uint256 amount = between(id, 1, type(uint256).max);

        swap_should_fail(pool.params, poolId, true, amount, 0, "BUG: Swap with zero limit amount should fail.");
    }

    function swap_should_fail(
        HyperCurve memory curve,
        uint64 poolId,
        bool sellAsset,
        uint256 amount,
        uint256 limit,
        string memory msg
    ) private {
        try _hyper.swap(poolId, sellAsset, amount, amount) {
            emit AssertionFailed(msg);
        } catch {}
    }

    function swap_assets_in_always_decreases_price(uint id, uint256 amount, uint256 limit) public {
        bool sellAsset = true;

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens(id);
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
        _hyper.swap(poolId, sellAsset, amount, limit);
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
            emit AssertionFailed("BUG: pool.lastPrice increased after swapping assets in, it should have decreased.");
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
    }

    function swap_quote_in_always_increases_price(uint id, uint256 amount, uint256 limit) public {
        bool sellAsset = false;

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens(id);
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
        _hyper.swap(poolId, sellAsset, amount, limit);
        HyperPool memory postPool = getPool(address(_hyper), poolId);

        uint256 postReserveSell = getReserve(address(_hyper), address(_quote));
        uint256 postReserveBuy = getReserve(address(_hyper), address(_asset));

        if (postPool.lastPrice < prePool.lastPrice) {
            emit LogUint256("price before swap", prePool.lastPrice);
            emit LogUint256("price after swap", postPool.lastPrice);
            emit AssertionFailed("BUG: pool.lastPrice decreased after swapping quote in, it should have increased.");
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
    }

    function swap_asset_in_increases_reserve(uint id, uint256 amount, uint256 limit) public {
        bool sellAsset = true;

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens(id);
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
        _hyper.swap(poolId, sellAsset, amount, limit);
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
    }

    function swap_quote_in_increases_reserve(uint id, uint256 amount, uint256 limit) public {
        bool sellAsset = false;

        address[] memory owners = new address[](1);
        // Will always return a pool that exists
        (
            HyperPool memory pool,
            uint64 poolId,
            EchidnaERC20 _asset,
            EchidnaERC20 _quote
        ) = retrieve_non_expired_pool_and_tokens(id);
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
        _hyper.swap(poolId, sellAsset, amount, limit);
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
