pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "../../contracts/Hyper.sol";
import "../../contracts/libraries/Pool.sol";

contract TestBid is Test {
    Hyper public hyper;

    function setUp() public {
        hyper = new Hyper(1000, address(0xbeef));
        vm.warp(1000);
        hyper.start();
    }

    function test_bid_should_fail_if_amount_is_zero() public {
        vm.expectRevert();

        hyper.bid(
            getPoolId(address(0xbeef), address(0xbabe)),
            0,
            vm.addr(1),
            vm.addr(1),
            0
        );
    }
}
