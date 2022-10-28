pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/libraries/BrainMath.sol";

contract TestBrainMath is Test {
    uint256 aF = 1000100000000000000;

    function setUp() public {}

    function test_getSlotFromPrice() public {
        uint256 priceF = 1300 ether;

        int128 slot = getSlotFromPrice(priceF, aF);
        assertEq(slot, 71705);
    }

    function test_getSlotProportionFromPrice() public {
        uint256 priceF = 1300 ether;
        int128 slotIndex = 71705;

        uint256 slotProportionF = getSlotProportionFromPrice(priceF, aF, slotIndex);
        assertEq(slotProportionF, 280434520237481183);
    }

    function test_getPriceFromSlot() public {
        int128 slotIndex = 71705;
        uint256 slotProportionF = 280434520237481183;

        uint256 priceF = getPriceFromSlot(aF, slotIndex, slotProportionF);

        assertEq(priceF, 1300 ether);
    }
}
