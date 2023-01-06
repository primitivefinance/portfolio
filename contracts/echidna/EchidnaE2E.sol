pragma solidity ^0.8.0;
import "solmate/tokens/WETH.sol";
import "../test/TestERC20.sol";
import "../Hyper.sol";

contract EchidnaE2E {
	WETH _weth;
	TestERC20 _erc20;
	Hyper _hyper;
	bool deployed;

	constructor() public {
		_weth = new WETH();
		_erc20 = new TestERC20("Token","TKN",18);
	}
	function setup_hyper() public { 
		_hyper = new Hyper(address(_weth));
		assert(address(_hyper) != address(0));
		deployed = true;
	}
	function sanity_check() public {
		if (!deployed) { setup_hyper();}
		assert(_hyper.getLocked() == 1);
	}
}