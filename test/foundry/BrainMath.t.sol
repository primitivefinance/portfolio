pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/libraries/BrainMath.sol";

contract TestBrainMath is Test {
    function setUp() public {}

    function test_getSlotFromPrice() public {
        int256 price = 1300 ether;
        int256 a = 10001 ether / 10000;

        uint256 slot = BrainMath.getSlotFromPrice(price, a);
        assertEq(slot / 1 ether, 71705);
    }
}
