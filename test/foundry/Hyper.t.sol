pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {UD60x18, fromUD60x18, toUD60x18, ud} from "@prb/math/UD60x18.sol";

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
        hyper.activatePool(address(0xbeef), address(0xbabe), toUD60x18(10));
    }

    function test_add_liquidity_above_current_slot() public {
        hyper.activatePool(address(0xbeef), address(0xbabe), toUD60x18(10));
        // TODO: This test should fail now due to token settlement, why is it not?
        hyper.updateLiquidity(getPoolId(address(0xbeef), address(0xbabe)), 10, 12, int256(100), false);
    }

    function test_add_liquidity_including_current_slot() public {
        hyper.activatePool(address(0xbeef), address(0xbabe), toUD60x18(10));
        // TODO: This test should fail now due to token settlement, why is it not?
        hyper.updateLiquidity(getPoolId(address(0xbeef), address(0xbabe)), 9, 11, int256(1000000000000000000), false);
    }

    function test_add_liquidity_below_current_slot() public {
        hyper.activatePool(address(0xbeef), address(0xbabe), toUD60x18(10));
        // TODO: This test should fail now due to token settlement, why is it not?
        hyper.updateLiquidity(getPoolId(address(0xbeef), address(0xbabe)), 8, 9, int256(1), false);
    }
}
