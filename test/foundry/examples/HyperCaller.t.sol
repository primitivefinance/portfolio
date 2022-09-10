pragma solidity 0.8.13;

import "forge-std/Test.sol";
import {WETH} from "solmate/tokens/WETH.sol";

import "../../../contracts/Hyper.sol";
import "../../../contracts/test/TestERC20.sol";
import "../../../contracts/examples/HyperCaller.sol";

contract TestHyperCaller is Test, StandardHelpers {
    Hyper public __hyper;
    WETH public __weth;
    HyperCaller public __caller;
    TestERC20 public __quote;

    function loadDefaultPool() public {
        __caller.loadDefaultPool(address(__weth), address(__quote));
    }

    function setUp() public {
        vm.warp(1);
        __weth = new WETH();
        __hyper = new Hyper(address(__weth));
        __caller = new HyperCaller(address(__hyper));
        __quote = new TestERC20("Test", "tst", 18);

        // approvals
        vm.prank(address(__caller));
        __weth.approve(address(__hyper), type(uint256).max);
        vm.prank(address(__caller));
        __quote.approve(address(__hyper), type(uint256).max);

        // fund acc
        __weth.deposit{value: 10e18}();
        __weth.transfer(address(__caller), 10e18);
        __quote.mint(address(__caller), 100e18);
    }

    function testLoad() public {
        __caller.loadPool(address(__weth), address(__quote), 5e18, 1e4, 500, 9900, 9990);
        (uint48 poolId, , ) = __caller.loaded();
        assertTrue(poolId != 0);
    }

    function testAddLiquidity() public {
        loadDefaultPool();
        (uint48 poolId, , ) = __caller.loaded();
        assertTrue(poolId != 0);

        __caller.addLiquidity(1000, 23027 - 500, 23027 + 500);
    }

    function testRemoveLiquidity() public {
        loadDefaultPool();
        (uint48 poolId, , ) = __caller.loaded();
        assertTrue(poolId != 0);

        __caller.addLiquidity(1000, 23027 - 500, 23027 + 500);

        __caller.removeLiquidity(500, 23027 - 500, 23027 + 500);
    }

    function testSwapInWETH() public {
        loadDefaultPool();
        (uint48 poolId, , ) = __caller.loaded();
        assertTrue(poolId != 0);

        __caller.addLiquidity(10e18, 23027 - 500, 23027 + 500);

        __caller.swapExactIn(address(__weth), 10, 1e22);
    }
}
