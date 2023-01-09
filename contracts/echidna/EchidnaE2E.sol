pragma solidity ^0.8.0;
import "solmate/tokens/WETH.sol";
import "../test/TestERC20.sol";
import "../Hyper.sol";
import "../Enigma.sol" as ProcessingLib;
import "../../test/helpers/HelperHyperProfiles.sol" as DefaultValues;


contract EchidnaE2E {
	WETH _weth;
	TestERC20 _quote;
	TestERC20 _asset;
	Hyper _hyper;
	uint24 pairId;
	mapping(uint64 => uint32) [] pools;
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

		assert(_hyper.locked() == 1);

		// Retrieve the OS.__account__
		(bool prepared, bool settled) = _hyper.__account__();
		assert(!prepared);
		assert(settled);

		address[] memory warmTokens = _hyper.getWarm();
		assert(warmTokens.length == 0);
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
		(address tokenAsset, uint8 decimalsAsset, address tokenQuote, uint8 decimalsQuote) = _hyper.pairs(pairId);
		assert(tokenAsset == address(asset));
		assert(decimalsAsset == TestERC20(asset).decimals());
		assert(tokenQuote == address(quote));
		assert(decimalsQuote == TestERC20(quote).decimals());
		isPairCreated = true;
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

	// Create a non controlled pool (controller address is 0)
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
		execute_create_pool(createPoolData);
	}
	function execute_create_pool(bytes memory createPoolData) private {
		uint256 preCreationPoolNonce = _hyper.getPoolNonce();
		(bool success, ) = address(_hyper).call(createPoolData);

		// pool nonce should increase by 1 each time a pool is created
		uint256 poolNonce = _hyper.getPoolNonce();
		assert(poolNonce == preCreationPoolNonce + 1);
		
		// pool should be created and exist 
		uint64 poolId = ProcessingLib.encodePoolId(pairId, false, uint32(poolNonce));
		HyperPool memory pool = retrieve_hyper_pool(poolId);
		assert(pool.exists());
		assert(!pool.isMutable());
	}
	// ******************** Helper ********************	
    function between(uint256 random,uint256 low, uint256 high) private returns (uint256) {
        return low + (random % (high - low));
    }
	function retrieve_hyper_pool(uint64 poolId) private returns (HyperPool memory hp) {
		(int24 lastTick,
		uint32 lastTimestamp, // updated on swaps.
		address controller,
		uint256 feeGrowthGlobalReward,
		uint256 feeGrowthGlobalAsset,
		uint256 feeGrowthGlobalQuote,
		uint128 lastPrice,
		uint128 liquidity, // available liquidity to remove
		uint128 stakedLiquidity, // locked liquidity
		int128 stakedLiquidityDelta, // liquidity to be added or removed
		HyperCurve memory params,
		HyperPair memory pair) = _hyper.pools(poolId);

		hp = HyperPool(lastTick,lastTimestamp,controller,
		feeGrowthGlobalReward,
		feeGrowthGlobalAsset,
		feeGrowthGlobalQuote,
		lastPrice,
		liquidity, // available liquidity to remove
		stakedLiquidity, // locked liquidity
		stakedLiquidityDelta, // liquidity to be added or removed
		params,
		pair
		);
	}
}