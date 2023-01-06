pragma solidity ^0.8.0;
import "solmate/tokens/WETH.sol";
import "../test/TestERC20.sol";
import "../Hyper.sol";

contract EchidnaE2E {
	WETH _weth;
	TestERC20 _erc20;
	Hyper _hyper;
	event AssertionFailed(string msg, uint256 value);
	constructor() public {
		_weth = new WETH();
		_erc20 = new TestERC20("Token","TKN",18);
		_hyper = new Hyper(address(_weth));
		
	}
	function check_proper_deployment() public { 
		assert(address(_weth) != address(0));
		assert(address(_erc20) != address(0));
		assert(address(_hyper) != address(0));

		assert(_hyper.locked() == 1);

		// Retrieve the OS.__account__
		// Ensure __account__.settled = true 

		// Ditto above for prepared 
	}
}