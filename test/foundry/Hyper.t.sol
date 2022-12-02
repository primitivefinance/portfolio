pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/Hyper.sol";
import {getPoolId} from "../../contracts/libraries/Pool.sol";

contract TestHyper is Test {
    Hyper public hyper;

    function setUp() public {
        hyper = new Hyper(1000, address(0xbeef));
        vm.warp(1000);
        hyper.start();
    }

    function test_activatePool() public {
        hyper.activatePool(address(0xbeef), address(0xbabe), 10 ether);
    }

    function test_add_liquidity_above_current_slot() public {
        hyper.activatePool(address(0xbeef), address(0xbabe), 10 ether);
        hyper.updateLiquidity(getPoolId(address(0xbeef), address(0xbabe)), 11, 12, int256(1));
    }

    function test_add_liquidity_including_current_slot() public {
        hyper.activatePool(address(0xbeef), address(0xbabe), 10 ether);
        hyper.updateLiquidity(getPoolId(address(0xbeef), address(0xbabe)), 9, 11, int256(1000000000000000000));
    }

    function test_add_liquidity_below_current_slot() public {
        hyper.activatePool(address(0xbeef), address(0xbabe), 10 ether);
        hyper.updateLiquidity(getPoolId(address(0xbeef), address(0xbabe)), 8, 9, int256(1));
    }
}
