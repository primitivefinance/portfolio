pragma solidity ^0.8.0;
import "solmate/tokens/WETH.sol";
import "../test/TestERC20.sol";
import "../Hyper.sol";
import "../Enigma.sol" as ProcessingLib;


contract EchidnaE2E {
	WETH _weth;
	TestERC20 _quote;
	TestERC20 _asset;
	Hyper _hyper;
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
	function create_pair() public { 
		// without this, Echidna may decide to call the TestERC20.setDecimals 
		require(_quote.decimals() == 6); 
		require(_asset.decimals() == 18);
		
		// encode createPair arguments and clal hyper contract
	 	bytes memory createPairData = ProcessingLib.encodeCreatePair(address(_asset), address(_quote));
        (bool success, ) = address(_hyper).call(createPairData);
		assert(success);

		// retrieve recently created pair ID 
		uint24 pairId = _hyper.getPairId(address(_asset),address(_quote));
		if (pairId == 0) {
			emit LogUint256("PairId", uint256(pairId));
			assert(false);
		}
		
		// retrieve pair information and ensure pair was saved 
		(address tokenAsset, uint8 decimalsAsset, address tokenQuote, uint8 decimalsQuote) = _hyper.pairs(pairId);
		assert(tokenAsset == address(_asset));
		assert(decimalsAsset == _asset.decimals());
		assert(tokenQuote == address(_quote));
		assert(decimalsQuote == _quote.decimals());
	}
	function create_same_pair_should_fail() public {
	 	bytes memory createPairData = ProcessingLib.encodeCreatePair(address(_quote), address(_quote));
        (bool success, ) = address(_hyper).call(createPairData);
		assert(!success);
	}
	function create_pair_with_less_than_min_decimals_should_fail() public {
		TestERC20 testToken = new TestERC20("4 Decimals", "4DEC", 4);
	 	bytes memory createPairData = ProcessingLib.encodeCreatePair(address(testToken), address(_quote));
        (bool success, ) = address(_hyper).call(createPairData);
		assert(!success);
	}	
	function create_pair_with_more_than_max_decimals_should_fail() public {
		TestERC20 testToken = new TestERC20("20 Decimals", "20DEC", 20);
	 	bytes memory createPairData = ProcessingLib.encodeCreatePair(address(testToken), address(_quote));
        (bool success, ) = address(_hyper).call(createPairData);
		assert(!success);
	}		
}