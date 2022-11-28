pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/libraries/BitMath.sol";

contract TestBitMath is Test {
    function testRight() public {
        assertEq(BitMath.mostSignificantBit(36), 5);
    }

    function testLeft() public {
        assertEq(BitMath.leastSignificantBit(36), 2);
    }

    function testFlip() public {
        uint256 bitmap;
        bitmap = BitMath.flip(bitmap, 128);
        assertEq(BitMath.hasLiquidity(bitmap, 128), true);
    }
}
