pragma solidity 0.8.13;

import {WETH} from "solmate/tokens/WETH.sol";

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../../contracts/Hyper.sol";

contract TestHyper is Test {
    WETH public weth;
    Hyper public hyper;

    function setUp() public {
        weth = new WETH();
        hyper = new Hyper(address(weth));
    }

    function testWeth() public {
        assertEq(hyper.WETH(), address(weth));
    }
}
