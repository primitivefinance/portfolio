pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../../contracts/libraries/Invariant.sol";

contract TestHyperSwapLib is Test {
    function testComputePriceWithR2OOBFail() public {}

    function testComputeR2WithPriceOOBFail() public {}

    function testComputeR2WithPriceZeroTauFail() public {}

    function testComputePriceR2ZeroTauReturnsStrike() public {}

    function testGetY() public {
        uint256 R_x = 481800390188356246;
        uint256 stk = 1600 * 1e18;
        uint256 vol = 1e18;
        uint256 tau = 62694;
        int256 inv = 0;
        uint256 y = Invariant.getY(R_x, stk, vol, tau, inv);
        console.log(y);
    }
}
