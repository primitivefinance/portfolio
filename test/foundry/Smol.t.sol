pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/Smol.sol";

contract TestSmol is Test {
    Smol public smol;

    function setUp() public {
        smol = new Smol();
    }

    function test_initiatePool() public {
        smol.initiatePool(address(0xbeef), address(0xbabe), 0, 0);
    }

    function test_add_liquidity_above_current_slot() public {
        smol.initiatePool(address(0xbeef), address(0xbabe), 10, 10);

        smol.addLiquidity(address(0xbeef), address(0xbabe), 11, 12, 1);
    }

    function test_add_liquidity_including_current_slot() public {
        smol.initiatePool(address(0xbeef), address(0xbabe), 1300 ether, 10);

        smol.addLiquidity(address(0xbeef), address(0xbabe), 9, 11, 1000000000000000000);
    }

    function test_add_liquidity_below_current_slot() public {
        smol.initiatePool(address(0xbeef), address(0xbabe), 10, 10);

        smol.addLiquidity(address(0xbeef), address(0xbabe), 8, 9, 1);
    }
}
