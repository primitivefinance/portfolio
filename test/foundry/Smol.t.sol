pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/Smol.sol";
import "../../contracts/libraries/Pool.sol";

contract TestSmol is Test {
    Smol public smol;

    function setUp() public {
        smol = new Smol(1000, address(0xbeef));
        vm.warp(1000);
        smol.start();
    }

    function test_initiatePool() public {
        smol.activatePool(address(0xbeef), address(0xbabe), 10 ether);
    }

    function test_add_liquidity_above_current_slot() public {
        smol.activatePool(address(0xbeef), address(0xbabe), 10 ether);
        smol.updateLiquidity(Pool.getId(address(0xbeef), address(0xbabe)), 11, 12, int256(1));
    }

    function test_add_liquidity_including_current_slot() public {
        smol.activatePool(address(0xbeef), address(0xbabe), 10 ether);
        smol.updateLiquidity(Pool.getId(address(0xbeef), address(0xbabe)), 9, 11, int256(1000000000000000000));
    }

    function test_add_liquidity_below_current_slot() public {
        smol.activatePool(address(0xbeef), address(0xbabe), 10 ether);
        smol.updateLiquidity(Pool.getId(address(0xbeef), address(0xbabe)), 8, 9, int256(1));
    }
}
