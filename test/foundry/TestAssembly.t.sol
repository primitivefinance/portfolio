// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../contracts/Assembly.sol" as Assembly;
import "forge-std/Test.sol";

contract TestAssembly is Test {
    function setUp() public {}

    // todo: fix assembly then run this test.
    /* function testAddSignedDelta() public {
        uint128 input = 0;
        int128 delta = -int128(1);
        vm.expectRevert();
        uint output = Assembly.addSignedDelta(input, delta);
        assertTrue(output < input, "output greater than input on negative delta");
    } */
}
