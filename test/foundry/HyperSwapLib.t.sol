pragma solidity 0.8.13;

import "../shared/BaseTest.sol";

contract TestHyperSwapLib is BaseTest {
    constructor(address weth) BaseTest(weth) {}

    function testComputePriceWithR2OOBFail() public {}

    function testComputeR2WithPriceOOBFail() public {}

    function testComputeR2WithPriceZeroTauFail() public {}

    function testComputePriceR2ZeroTauReturnsStrike() public {}
}
