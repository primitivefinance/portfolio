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
		require(preChangeState.isMutable());
		require(preChangeState.controller == address(this));
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

		_hyper.changeParameters(poolId, priorityFee, fee, volatility, duration, jit, maxTick);

		(HyperPool memory postChangeState,) = retrieve_created_pool(id);
		HyperCurve memory curve = postChangeState.params;
		assert(postChangeState.lastTimestamp == block.timestamp);
		assert(postChangeState.controller == address(this));
		assert(curve.createdAt == block.timestamp);
		assert(curve.priorityFee == priorityFee);
		assert(curve.fee == fee);
		assert(curve.volatility == volatility);
		assert(curve.duration == duration);
		assert(curve.jit == jit);
		assert(curve.maxTick == maxTick);		
	}
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