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

    function testFlip2() public {
        uint256 bitmap;
        bitmap = BitMath.flip(bitmap, 255);
        assertEq(BitMath.hasLiquidity(bitmap, 255), true);
    }

    function test_findNextSlotWithinChunk_left() public {
        uint256 bitmap;
        bitmap = BitMath.flip(bitmap, 24);
        bitmap = BitMath.flip(bitmap, 12);
        bitmap = BitMath.flip(bitmap, 6);

        (bool hasNextSlot, uint8 nextSlot) = BitMath.findNextSlotWithinChunk(bitmap, 12, true);

        assertEq(hasNextSlot, true);
        assertEq(nextSlot, 24);
    }

    function test_findNextSlotWithinChunk_right() public {
        uint256 bitmap;
        bitmap = BitMath.flip(bitmap, 22);
        bitmap = BitMath.flip(bitmap, 11);
        bitmap = BitMath.flip(bitmap, 6);

        (bool hasNextSlot, uint8 nextSlot) = BitMath.findNextSlotWithinChunk(bitmap, 11, false);

        assertEq(hasNextSlot, true);
        assertEq(nextSlot, 6);
    }

    function test_findNextSlotWithinChunk_right_empty() public {
        uint256 bitmap;
        (bool hasNextSlot, uint8 nextSlot) = BitMath.findNextSlotWithinChunk(bitmap, 11, false);
        assertEq(hasNextSlot, false);
        console.log(nextSlot);
    }
}
