pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import {UD60x18, fromUD60x18, toUD60x18, ud} from "@prb/math/UD60x18.sol";

import "../../contracts/Hyper.sol";
import {getPoolId} from "../../contracts/libraries/Pool.sol";
import "../../contracts/test/TestERC20.sol";

contract TestHyper is Test {
    Hyper public hyper;
    TestERC20 public tokenA;
    TestERC20 public tokenB;

    address alice = vm.addr(0xbeef);

    function setUp() public {
        hyper = new Hyper(1000, address(alice));
        tokenA = new TestERC20("TokenA", "TA", 18);
        tokenB = new TestERC20("TokenB", "TB", 18);

        vm.warp(1000);
        hyper.start();
        vm.startPrank(alice);
    }

    function test_activatePool_should_work() public {
        hyper.activatePool(address(tokenA), address(tokenB), toUD60x18(10));
    }

    function test_activatePool_should_fail() public {
        hyper.activatePool(address(tokenA), address(tokenB), toUD60x18(10));
        vm.expectRevert();
        hyper.activatePool(address(tokenA), address(tokenB), toUD60x18(10));
    }

    function test_add_liquidity_above_current_slot() public {
        hyper.activatePool(address(tokenA), address(tokenB), toUD60x18(10));
        tokenA.mint(alice, 1000000 ether);
        tokenA.approve(address(hyper), type(uint256).max);
        tokenB.mint(alice, 1000000 ether);
        tokenB.approve(address(hyper), type(uint256).max);

        hyper.updateLiquidity(getPoolId(address(tokenA), address(tokenB)), 10, 12, int256(100), false);
    }

    function test_add_liquidity_including_current_slot() public {
        hyper.activatePool(address(tokenA), address(tokenB), toUD60x18(10));
        tokenA.mint(alice, 1000000 ether);
        tokenA.approve(address(hyper), type(uint256).max);
        tokenB.mint(alice, 1000000 ether);
        tokenB.approve(address(hyper), type(uint256).max);
        hyper.updateLiquidity(getPoolId(address(tokenA), address(tokenB)), 9, 11, int256(1000000000000000000), false);
    }

    function test_add_liquidity_below_current_slot() public {
        hyper.activatePool(address(tokenA), address(tokenB), toUD60x18(10));
        tokenA.mint(alice, 1000000 ether);
        tokenA.approve(address(hyper), type(uint256).max);
        tokenB.mint(alice, 1000000 ether);
        tokenB.approve(address(hyper), type(uint256).max);
        hyper.updateLiquidity(getPoolId(address(tokenA), address(tokenB)), 8, 9, int256(1), false);
    }
}
