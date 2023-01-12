pragma solidity ^0.8.0;
import "solmate/tokens/WETH.sol";
import "../test/TestERC20.sol";
import "../Hyper.sol";
import "../Enigma.sol" as ProcessingLib;
import "../../test/helpers/HelperHyperProfiles.sol" as DefaultValues;
import "../../test/helpers/HelperHyperView.sol";


contract EchidnaE2E is HelperHyperView
{
	WETH _weth;
	TestERC20 _quote;
	TestERC20 _asset;
	Hyper _hyper;
	uint24 pairId;
	TestERC20[] hyperTokens;
	uint64 [] poolIds;
	bool isPairCreated;

	event AssertionFailed(string msg);
	event LogUint256(string msg, uint256 value);
	event LogBytes(string msg, bytes value);
	event LogAddress(string msg, address tkn);
	constructor() public {
		_weth = new WETH();
		_quote = new TestERC20("6 Decimals","6DEC",6);
		_asset = new TestERC20("18 Decimals", "18DEC", 18);

		_hyper = new Hyper(address(_weth));
		
	}
	OS.AccountSystem hyperAccount;
	// ******************** Check Proper System Deployment ********************
	function check_proper_deployment() public { 
		assert(address(_weth) != address(0));
		assert(address(_quote) != address(0));
		assert(address(_asset) != address(0));
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
	function non_zero_priority_fee_if_controlled(uint64 id) public {
		(HyperPool memory pool,) = retrieve_created_pool(id);
		// if the pool has a controller, the priority fee should never be zero
		if (pool.controller != address(0)) { 
			assert(pool.params.priorityFee != 0);
		}
	}
	// The token balance of Hyper should be greater or equal to the reserve for all tokens 
	// Note: assumption that pairs are created through create_pair invariant test 
	// which will add the token to the hyperTokens list 
	// this function is built so that extending the creation of new pairs should not require code changes here
	function token_balance_greater_or_equal_reserves() public {
		uint256 reserveBalance = 0;
		uint256 tokenBalance = 0;
		for (uint8 i=0; i<hyperTokens.length; i++){
			TestERC20 token = hyperTokens[i];
			// retrieve reserves of the token and add to tracked reserve balance
			reserveBalance = getReserve(address(_hyper),address(token));
			// get token balance and add to tracked token balance
			tokenBalance += token.balanceOf(address(_hyper));
		}
		assert(tokenBalance >= reserveBalance);
	}		
		

	// ******************** Create Pairs ********************
	/** Future Invariant: This assumes that there is a single pair of _asset and _quote token 
	        - In the future, can be extended to deploy tokens from here and save the address in a list 
			which allows echidna to test against different pairs. 
			- Assumption: 1 pair for now. 
	 */
	function create_token(uint8 decimals) public returns (TestERC20 token){
		TestERC20 token = new TestERC20("Token", "TKN", decimals);
		assert(token.decimals() == decimals);
	}
	/* Future Invariant: This could be extended to create arbitrary pairs. 
    For now for complexity, I am leaving as is. 
	Test overlapping token pairs
	*/
	function create_pair_with_default() public { 
		// require that this specific pair ID does not exist (i.e: this function has not been invoked yet)
		require(!isPairCreated);
		// without this, Echidna may decide to call the TestERC20.setDecimals 
		require(_quote.decimals() == 6); 
		require(_asset.decimals() == 18);
		uint256 preCreationNonce = _hyper.getPairNonce();
		
		// encode createPair arguments and call hyper contract
	 	bytes memory createPairData = ProcessingLib.encodeCreatePair(address(_asset), address(_quote));
        (bool success, ) = address(_hyper).call(createPairData);
		assert(success);
		pair_id_saved_properly(address(_asset), address(_quote));

		uint256 pairNonce = _hyper.getPairNonce();
		assert(pairNonce == preCreationNonce + 1);
	}
	/** Future Invariant: This can likely be extended to ensure that pairID's must always match backwards to the tokens saved
	 */
	function pair_id_saved_properly(address asset, address quote) private {
		// retrieve recently created pair ID 
		pairId = _hyper.getPairId(address(asset),address(quote));
		if (pairId == 0) {
			emit LogUint256("PairId Exists", uint256(pairId));
			assert(false);
		}
		
		// retrieve pair information and ensure pair was saved 
		HyperPair memory pair  = getPair(address(_hyper),pairId);
		assert(pair.tokenAsset == address(asset));
		assert(pair.decimalsAsset == TestERC20(asset).decimals());
		assert(pair.tokenQuote == address(quote));
		assert(pair.decimalsQuote == TestERC20(quote).decimals());

		// save internal Echidna state to test against
		isPairCreated = true;
		hyperTokens.push(TestERC20(asset));
		hyperTokens.push(TestERC20(quote));
	}
	function create_same_pair_should_fail() public {
	 	bytes memory createPairData = ProcessingLib.encodeCreatePair(address(_quote), address(_quote));
        (bool success, ) = address(_hyper).call(createPairData);
		assert(!success);
	}
	function create_pair_with_less_than_min_decimals_should_fail(uint256 decimals) public {
		decimals = uint8(between(decimals,0,5));
		TestERC20 testToken = create_token(uint8(decimals));
	 	bytes memory createPairData = ProcessingLib.encodeCreatePair(address(testToken), address(_quote));
        (bool success, ) = address(_hyper).call(createPairData);
		assert(!success);
	}	
	function create_pair_with_more_than_max_decimals_should_fail(uint256 decimals) public {
		decimals = uint8(between(decimals,19,type(uint64).max));
		TestERC20 testToken = create_token(uint8(decimals));
	 	bytes memory createPairData = ProcessingLib.encodeCreatePair(address(testToken), address(_quote));
        (bool success, ) = address(_hyper).call(createPairData);
		assert(!success);
	}	
	// ******************** Create Pool ********************
	int24 constant MAX_TICK = 887272;
	uint256 constant BUFFER = 300 seconds;
	uint256 constant MIN_FEE = 1; // 0.01%
	uint256 constant MAX_FEE = 1000; // 10%
	uint256 constant MIN_VOLATILITY = 100; // 1%
	uint256 constant MAX_VOLATILITY = 25_000; // 250%
	uint256 constant MIN_DURATION = 1; // days, but without units
	uint256 constant MAX_DURATION = 500; // days, but without units
	uint256 constant JUST_IN_TIME_MAX = 600 seconds;
	uint256 constant JUST_IN_TIME_LIQUIDITY_POLICY = 4 seconds;	

	// Create a non controlled pool (controller address is 0) with default pair
	// Note: This function can be extended to choose from any created pair and create a pool on top of it
	function create_non_controlled_pool(
		uint16 fee, 
		int24 maxTick,
		uint16 volatility, 
		uint16 duration, 
		uint128 price
	) public {
		if(!isPairCreated) { create_pair_with_default(); }
		{ 
			// scaling remaining pool creation values
			fee = uint16(between(fee, MIN_FEE, MAX_FEE));
			volatility = uint16(between(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
			duration = uint16(between(duration, MIN_DURATION, MAX_DURATION));
			maxTick = (-MAX_TICK) + (maxTick % (MAX_TICK - (-MAX_TICK))); // [-MAX_TICK,MAX_TICK]
			price = uint128(between(price,1,type(uint128).max)); // price is between 1-uint256.max		
		}
		bytes memory createPoolData = ProcessingLib.encodeCreatePool(
			pairId,
			address(0), // no controller 
			0, // no priority fee 
			fee,
			volatility,
			duration,
			0, // no jit 
			maxTick,
			price
		);		
		{ 
			(HyperPool memory pool,uint64 poolId) = execute_create_pool(createPoolData, false);
			assert(!pool.isMutable());	
			HyperCurve memory curve = pool.params;
			assert(pool.lastTimestamp == block.timestamp);
			assert(curve.createdAt == block.timestamp);
			assert(pool.controller == address(0));
			assert(curve.priorityFee == 0);
			assert(curve.fee == fee);
			assert(curve.volatility == volatility);
			assert(curve.duration == duration);
			assert(curve.jit == JUST_IN_TIME_LIQUIDITY_POLICY);
			assert(curve.maxTick == maxTick);				
		}
	}
	function create_controlled_pool(
		uint16 priorityFee,
		uint16 fee, 
		int24 maxTick,
		uint16 volatility, 
		uint16 duration, 
		uint16 jit,
		uint128 price
	) public {
		if(!isPairCreated) { create_pair_with_default(); }
		{ 
			// scaling remaining pool creation values
			fee = uint16(between(fee, MIN_FEE, MAX_FEE));
			priorityFee = uint16(between(priorityFee, 1, fee));
			emit LogUint256("priority fee", uint256(priorityFee));
			volatility = uint16(between(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
			duration = uint16(between(duration, MIN_DURATION, MAX_DURATION));
			maxTick = (-MAX_TICK) + (maxTick % (MAX_TICK - (-MAX_TICK))); // [-MAX_TICK,MAX_TICK]
			jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
			price = uint128(between(price,1,type(uint128).max)); // price is between 1-uint256.max		
		}
		bytes memory createPoolData = ProcessingLib.encodeCreatePool(
			pairId,
			address(this), //controller
			priorityFee, // no priority fee 
			fee,
			volatility,
			duration,
			jit, // no jit 
			maxTick,
			price
		);		
		{ 
			(HyperPool memory pool,uint64 poolId) = execute_create_pool(createPoolData, true);		
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
			assert(curve.maxTick == maxTick);
		}
	}
	function create_controlled_pool_with_zero_priority_fee_should_fail(
		uint16 fee, 
		int24 maxTick,
		uint16 volatility, 
		uint16 duration, 
		uint16 jit,
		uint128 price
	) public {
		if(!isPairCreated) { create_pair_with_default(); }
		uint16 priorityFee = 0;
		{ 
			// scaling remaining pool creation values
			fee = uint16(between(fee, MIN_FEE, MAX_FEE));
			emit LogUint256("priority fee", uint256(priorityFee));
			volatility = uint16(between(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
			duration = uint16(between(duration, MIN_DURATION, MAX_DURATION));
			maxTick = (-MAX_TICK) + (maxTick % (MAX_TICK - (-MAX_TICK))); // [-MAX_TICK,MAX_TICK]
			jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
			price = uint128(between(price,1,type(uint128).max)); // price is between 1-uint256.max		
		}
		bytes memory createPoolData = ProcessingLib.encodeCreatePool(
			pairId,
			address(this), //controller
			priorityFee, // no priority fee 
			fee,
			volatility,
			duration,
			jit, // no jit 
			maxTick,
			price
		);		
		(bool success, ) = address(_hyper).call(createPoolData);
		assert(!success);
	}
	function execute_create_pool(
		bytes memory createPoolData, 
		bool hasController
	) private returns (HyperPool memory pool,uint64 poolId){
		uint256 preCreationPoolNonce = _hyper.getPoolNonce();
		(bool success, ) = address(_hyper).call(createPoolData);

		// pool nonce should increase by 1 each time a pool is created
		uint256 poolNonce = _hyper.getPoolNonce();
		assert(poolNonce == preCreationPoolNonce + 1);
		
		// pool should be created and exist 
		poolId = ProcessingLib.encodePoolId(pairId, hasController, uint32(poolNonce));
		pool = getPool(address(_hyper),poolId);
		assert(pool.exists());

		// save pools in Echidna
		poolIds.push(poolId);
	}
	// ******************** Change Pool Parameters ********************	
	function change_parameters(
		uint256 id,
		uint16 priorityFee,
		uint16 fee, 
		int24 maxTick,
		uint16 volatility, 
		uint16 duration, 
		uint16 jit,
		uint128 price
	) public {
		(HyperPool memory preChangeState,uint64 poolId) = retrieve_created_pool(id);
		emit LogUint256("created pools",poolIds.length);
		emit LogUint256("pool ID",uint256(poolId));
		require(preChangeState.isMutable());
		require(preChangeState.controller == address(this));
		{ 
			// scaling remaining pool creation values
			fee = uint16(between(fee, MIN_FEE, MAX_FEE));
			priorityFee = uint16(between(priorityFee, 1, fee));
			volatility = uint16(between(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
			duration = uint16(between(duration, MIN_DURATION, MAX_DURATION));
			maxTick = (-MAX_TICK) + (maxTick % (MAX_TICK - (-MAX_TICK))); // [-MAX_TICK,MAX_TICK]
			jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
			price = uint128(between(price,1,type(uint128).max)); // price is between 1-uint256.max		
		}

		_hyper.changeParameters(poolId, priorityFee, fee, volatility, duration, jit, maxTick);
		{ 
			(HyperPool memory postChangeState,) = retrieve_created_pool(id);
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
			assert(postChangeCurve.maxTick == maxTick);		
		}
	}
	// ******************** Funding ********************	
	function fund_with_correct_preconditions_should_succeed(
		uint256 assetAmount,
		uint256 quoteAmount
	) public {
		// asset and quote amount > 1
		assetAmount = between(assetAmount,1,type(uint64).max);
		quoteAmount = between(quoteAmount,1,type(uint64).max);

		emit LogUint256("assetAmount",assetAmount);
		emit LogUint256("quoteAmount",quoteAmount);
		setup_fund(assetAmount, quoteAmount);

		if(_asset.balanceOf(address(this)) < assetAmount) {
			emit LogUint256("asset balance",_asset.balanceOf(address(this)));
		}
		if (_quote.balanceOf(address(this)) < quoteAmount) {
			emit LogUint256("quote balance",_quote.balanceOf(address(this)));			
		}

		fund_token(address(_asset), assetAmount);
		fund_token(address(_quote), quoteAmount);
	}		
	function fund_with_insufficient_funds_should_fail(uint256 assetAmount, uint256 quoteAmount) public {
		assetAmount = between(assetAmount,1,type(uint256).max);
		quoteAmount = between(quoteAmount,1,type(uint256).max);

		try _hyper.fund(address(_asset),assetAmount) {
			emit AssertionFailed("funding with insufficient funds should fail");
		} 
		catch {}


		try _hyper.fund(address(_quote),quoteAmount) {
			emit AssertionFailed("funding with insufficient quote should fail");
		}
		catch {}
	}
	function fund_with_insufficient_allowance_should_fail(uint256 fundAmount) public {
		uint256 smallAssetAllowance = between(fundAmount,1,fundAmount-1);

		// mint the asset to address(this) and approve some amount < fund
		_asset.mint(address(this),fundAmount);
		_asset.approve(address(_hyper),smallAssetAllowance);
		try _hyper.fund(address(_asset),fundAmount) {
			emit LogUint256("small asset allowance", smallAssetAllowance);
			emit AssertionFailed("insufficient allowance should fail.");
		}
		catch {} 

		// mint the quote token to address(this), approve some amount < fund
		_quote.mint(address(this),fundAmount);
		_quote.approve(address(_hyper),smallAssetAllowance);
		try _hyper.fund(address(_quote),fundAmount) {
			emit LogUint256("small asset allowance", smallAssetAllowance);			
			emit AssertionFailed("insufficient allownce should fail.");
		}
		catch {} 
	}
	function fund_with_zero() public {
		setup_fund(0,0);
		_hyper.fund(address(_asset),0);
		_hyper.fund(address(_quote),0);		
	}

	function fund_token(address token, uint256 amount) private returns(bool) {
		uint256 senderBalancePreFund = TestERC20(token).balanceOf(address(this));	
		uint256 virtualBalancePreFund = getBalance(address(_hyper),address(this),address(token));
		uint256 reservePreFund = getReserve(address(_hyper),address(token));
		uint256 hyperBalancePreFund = TestERC20(token).balanceOf(address(_hyper));

		try _hyper.fund(address(token),amount) {
		} catch (bytes memory error) {
			emit LogBytes("error", error);
			assert(false);
		}

		// sender's token balance should decrease 
		// usdc sender pre token balance = 100 ; usdc sender post token = 100 - 1
		uint256 senderBalancePostFund = TestERC20(token).balanceOf(address(this));			
		if(senderBalancePostFund != senderBalancePreFund - amount) {
			emit LogUint256("postTransfer sender balance", senderBalancePostFund);
			emit LogUint256("preTransfer:", senderBalancePreFund);
			emit AssertionFailed("Sender balance did not decrease by amount after funding");
		}
		// hyper balance of the sender should increase 
		// pre hyper balance = a; post hyperbalance + 100
		uint256 virtualBalancePostFund = getBalance(address(_hyper),address(this),address(token));
		if(virtualBalancePostFund != virtualBalancePreFund + amount){
			emit LogUint256("virtual balance after funding", virtualBalancePostFund);
			emit LogUint256("virtual balance before funding:", virtualBalancePreFund);
			emit AssertionFailed("Virtual balance did not increase after funding");
		}
		// hyper reserves for token should increase
		// reserve balance = b; post reserves + 100
		uint256 reservePostFund = getReserve(address(_hyper),address(token));
		if(reservePostFund != reservePreFund + amount){
			emit LogUint256("reserve after funding", reservePostFund);
			emit LogUint256("reserve balance before funding:", reservePreFund);
			emit AssertionFailed("Reserve did not increase after funding");			
		}
		// hyper's token balance should increase
		// pre balance of usdc = y; post balance = y + 100
		uint256 hyperBalancePostFund = TestERC20(token).balanceOf(address(_hyper));
		if(hyperBalancePostFund  != hyperBalancePreFund + amount){
			emit LogUint256("hyper token balance after funding", hyperBalancePostFund);
			emit LogUint256("hyper balance before funding:", hyperBalancePreFund);
			emit AssertionFailed("hyper token balance did not increase after funding");			
		}
		return true;
	}
	function setup_fund(uint256 assetAmount, uint256 quoteAmount) private {
		_asset.mint(address(this),assetAmount);
		_quote.mint(address(this),quoteAmount);
		_asset.approve(address(_hyper),type(uint256).max);
		_quote.approve(address(_hyper),type(uint256).max);
	}
	// ******************** Draw ********************	
	function draw_should_succeed(uint256 assetAmount,uint256 quoteAmount, address recipient) public {	
		assetAmount = between(assetAmount,1,type(uint64).max);
		quoteAmount = between(quoteAmount,1,type(uint64).max);
		emit LogUint256("asset amount: ", assetAmount);
		emit LogUint256("quote amount:", quoteAmount);

		require(recipient != address(_hyper));
		require(recipient != address(0));

		draw_token(address(_asset),assetAmount, recipient);
		draw_token(address(_quote),quoteAmount, recipient);
	}
	function draw_token(address token, uint256 amount, address recipient) private {
		// make sure a user has funded already 
		uint256 virtualBalancePreFund = getBalance(address(_hyper),address(this),address(token));
		require (virtualBalancePreFund>0);
		amount = between(amount,1,virtualBalancePreFund);

		uint256 recipientBalancePreFund = TestERC20(token).balanceOf(address(recipient));	
		uint256 reservePreFund = getReserve(address(_hyper),address(token));
		uint256 hyperBalancePreFund = TestERC20(token).balanceOf(address(_hyper));		

		_hyper.draw(token,amount,recipient);
		
		//-- Postconditions 
		// caller balance should decrease 
		// pre caller balance = a; post caller balance = a - 100
		uint256 virtualBalancePostFund = getBalance(address(_hyper),address(this),address(token));
		if(virtualBalancePostFund != virtualBalancePreFund - amount){
			emit LogUint256("virtual balance post draw",virtualBalancePostFund);
			emit LogUint256("virtual balance pre draw", virtualBalancePreFund);
			emit AssertionFailed("virtual balance should decrease after drawing tokens");
		}
		// reserves should decrease 
		uint256 reservePostFund = getReserve(address(_hyper),address(token));
		if(reservePostFund != reservePreFund - amount){
			emit LogUint256("reserve post draw",reservePostFund);
			emit LogUint256("reserve pre draw", reservePreFund);
			emit AssertionFailed("reserve balance should decrease after drawing tokens");
		}
		// to address should increase 
		// pre-token balance = a; post-token = a + 100
		uint256 recipientBalancePostFund = TestERC20(token).balanceOf(address(recipient));			
		if(recipientBalancePostFund  != recipientBalancePreFund + amount){
			emit LogUint256("recipient balance post draw",recipientBalancePostFund);
			emit LogUint256("recipient balance pre draw", recipientBalancePreFund);
			emit AssertionFailed("recipient balance should increase after drawing tokens");			
		}
		// hyper token's balance should decrease
		uint256 tokenPostFund = TestERC20(token).balanceOf(address(_hyper));
		if(tokenPostFund != hyperBalancePreFund - amount){
			emit LogUint256("token post draw",tokenPostFund);
			emit LogUint256("token pre draw", hyperBalancePreFund);
			emit AssertionFailed("hyper token balance should increase after drawing tokens");						
		}
	}	
	function draw_to_zero_should_fail(uint256 assetAmount) public {
		// make sure a user has funded already 
		uint256 virtualBalancePreFund = getBalance(address(_hyper),address(this),address(_asset));
		emit LogUint256("virtual balance pre fund",virtualBalancePreFund);
		require (virtualBalancePreFund >= 0);
		assetAmount = between(assetAmount,1,virtualBalancePreFund);

		try _hyper.draw(address(_asset),assetAmount,address(0)) { 
			emit AssertionFailed("draw should fail attempting to transfer to zero");
		} catch { } 
	}
	function fund_then_draw(uint256 whichToken, uint256 amount) public {
		// this can be extended to use the token list in `hyperTokens`
		address token; 
		if (whichToken%2==0) token = address(_asset);
		else token = address(_quote);

		setup_fund(amount,amount);
		
		uint256 virtualBalancePreFund = getBalance(address(_hyper),address(this),address(token));
		uint256 recipientBalancePreFund = TestERC20(token).balanceOf(address(this));	
		uint256 reservePreFund = getReserve(address(_hyper),address(token));
		uint256 hyperBalancePreFund = TestERC20(token).balanceOf(address(_hyper));		

		// Call fund and draw
		_hyper.fund(token,amount);
		_hyper.draw(token,amount,address(this));

		//-- Postconditions 
		// caller balance should be equal 
		uint256 virtualBalancePostFund = getBalance(address(_hyper),address(this),address(token));
		if(virtualBalancePostFund != virtualBalancePreFund){
			emit LogUint256("virtual balance post fund-draw",virtualBalancePostFund);
			emit LogUint256("virtual balance pre fund-draw", virtualBalancePreFund);
			emit AssertionFailed("virtual balance should be equal after fund-draw");
		}
		// reserves should be equal
		uint256 reservePostFund = getReserve(address(_hyper),address(token));
		if(reservePostFund != reservePreFund){
			emit LogUint256("reserve post fund-draw",reservePostFund);
			emit LogUint256("reserve pre fund-draw", reservePreFund);
			emit AssertionFailed("reserve balance should be equal after fund-draw");
		}
		// recipient = sender balance should be equal
		uint256 recipientBalancePostFund = TestERC20(token).balanceOf(address(this));			
		if(recipientBalancePostFund  != recipientBalancePreFund){
			emit LogUint256("recipient balance post fund-draw",recipientBalancePostFund);
			emit LogUint256("recipient balance pre fund-draw", recipientBalancePreFund);
			emit AssertionFailed("recipient balance should be equal after fund-draw");			
		}
		// hyper token's balance should be equal
		uint256 tokenPostFund = TestERC20(token).balanceOf(address(_hyper));
		if(tokenPostFund != hyperBalancePreFund){
			emit LogUint256("token post fund-draw",tokenPostFund);
			emit LogUint256("token pre fund-draw", hyperBalancePreFund);
			emit AssertionFailed("hyper token balance should be equal after fund-draw");						
		}		
	}
	// ******************** Depositing ********************	
	// function deposit_with_correct_preconditions_should_succeed() public payable {
	// 	require(msg.value>0);

	// 	uint256 ethBalancePreTransfer = address(this).balance;
	// 	uint256 wethPreTransfer = _weth.balanceOf(address(_hyper));
	// 	_hyper.deposit();
	// 	uint256 ethBalancePostTransfer = address(this).balance;		
	// 	uint256 wethPostTransfer = _weth.balanceOf(address(_hyper));

	// 	// sender's eth balance should decrease 
	// 	assert(ethBalancePostTransfer == ethBalancePreTransfer - msg.value);
	// 	// weth balance of contract should increase
	// 	assert(wethPostTransfer - msg.value == wethPreTransfer);
	// }		
	// ******************** Helper ********************	
    function between(uint256 random,uint256 low, uint256 high) private returns (uint256) {
        return low + (random % (high - low));
    }
	function retrieve_created_pool(uint256 id) private returns (HyperPool memory pool, uint64 poolId) {
		require(poolIds.length > 0);
		id = between(id,0,poolIds.length);
		return (getPool(address(_hyper),poolIds[id]),poolIds[id]);
	}
}