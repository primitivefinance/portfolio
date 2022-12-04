pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/libraries/BitMath.sol";

contract TestBitMath is Test {
    function testRight() public {
        assertEq(mostSignificantBit(36), 5);
    }

    function testLeft() public {
        assertEq(leastSignificantBit(36), 2);
    }

    function testFlip() public {
        uint256 bitmap;
        bitmap = flip(bitmap, 128);
        assertEq(hasLiquidity(bitmap, 128), true);
    }

    function testFlip2() public {
        uint256 bitmap;
        bitmap = flip(bitmap, 255);
        assertEq(hasLiquidity(bitmap, 255), true);
    }

    function test_findNextSlotWithinChunk_left() public {
        uint256 bitmap;
        bitmap = flip(bitmap, 24);
        bitmap = flip(bitmap, 12);
        bitmap = flip(bitmap, 6);

        (bool hasNextSlot, uint8 nextSlot) = findNextSlotWithinChunk(bitmap, 12, true);

        assertEq(hasNextSlot, true);
        assertEq(nextSlot, 24);
    }

    function test_findNextSlotWithinChunk_right() public {
        uint256 bitmap;
        bitmap = flip(bitmap, 22);
        bitmap = flip(bitmap, 11);
        bitmap = flip(bitmap, 6);

        (bool hasNextSlot, uint8 nextSlot) = findNextSlotWithinChunk(bitmap, 11, false);

        assertEq(hasNextSlot, true);
        assertEq(nextSlot, 6);
    }

    function test_findNextSlotWithinChunk_right_empty() public {
        uint256 bitmap;
        (bool hasNextSlot, uint8 nextSlot) = findNextSlotWithinChunk(bitmap, 11, false);
        assertEq(hasNextSlot, false);
        console.log(nextSlot);
    }
}
