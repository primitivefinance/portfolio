pragma solidity 0.8.13;
import "../Hyper.sol";

contract EchidnaHyper is Hyper {
	constructor(address weth) Hyper(weth) {} 
	function getLocked() public returns(uint256) {
		return locked;
	}
}