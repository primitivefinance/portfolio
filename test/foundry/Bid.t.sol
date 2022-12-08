// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./PoolDefaults.sol";

import "../../contracts/Hyper.sol";
import "../../contracts/libraries/Pool.sol";
import "../../contracts/test/TestERC20.sol";

contract TestBid is Test {
    Hyper public hyper;

    TestERC20 public tokenA;
    TestERC20 public tokenB;
    TestERC20 public auctionToken;

    address testUser = vm.addr(0xbeef);
    address auctionCollector = vm.addr(0xbabe);

    modifier mintApproveTokens() {
        // mint tokens to the test user
        tokenA.mint(testUser, 1000000 ether);
        tokenA.approve(address(hyper), type(uint256).max);
        tokenB.mint(testUser, 1000000 ether);
        tokenB.approve(address(hyper), type(uint256).max);
        _;
    }

    function setUp() public {
        TestERC20 fakeWETH = new TestERC20("Wrapped Ether", "WETH", 18);
        TestERC20 fakeUSDC = new TestERC20("USD Coin", "USDC", 6);

        auctionToken = fakeUSDC;

        uint256 startTime = 1000;
        hyper = new Hyper(startTime, address(auctionToken), EPOCH_LENGTH, AUCTION_LENGTH, PUBLIC_SWAP_FEE, AUCTION_FEE);

        (tokenA, tokenB) = address(fakeUSDC) < address(fakeWETH) ? (fakeUSDC, fakeWETH) : (fakeWETH, fakeUSDC);
        assertTrue(tokenA == fakeUSDC);

        vm.warp(1000);
        hyper.start();

        vm.startPrank(testUser);
    }

    function getStartSqrtPrice() public pure returns (UD60x18 sqrtPrice) {
        UD60x18 ethPrice = toUD60x18(1200);
        UD60x18 usdPrice = ethPrice.inv();
        // decimals factor = 10^(tokenB.decimals - tokenA.decimals) = 1e12
        UD60x18 usdcPrice = usdPrice.mul(toUD60x18(1e12));
        sqrtPrice = usdcPrice.sqrt();
    }

    function test_bid_should_fail_if_amount_is_zero() public {
        vm.expectRevert(IHyper.AmountZeroError.selector);

        hyper.bid(getPoolId(address(tokenA), address(tokenB)), 0, vm.addr(1), vm.addr(1), 0);
    }

    function test_bid_should_fail_if_pool_is_not_initialized() public {
        vm.expectRevert(IHyper.PoolNotInitializedError.selector);

        hyper.bid(getPoolId(address(0), address(1)), 0, vm.addr(1), vm.addr(1), 1);
    }

    function test_bid_should_succeed() public mintApproveTokens {
        (uint256 epochId, , uint256 epochLength) = hyper.epoch();

        vm.warp(block.timestamp + epochLength - AUCTION_LENGTH);

        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());

        hyper.bid(getPoolId(address(tokenA), address(tokenB)), epochId + 1, vm.addr(1), vm.addr(1), 1);
    }

    function test_bid_should_fail_if_wrong_epoch_id() public {
        (uint256 epochId, , uint256 epochLength) = hyper.epoch();

        vm.warp(block.timestamp + epochLength - AUCTION_LENGTH);

        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());

        vm.expectRevert(IHyper.InvalidBidEpochError.selector);

        hyper.bid(getPoolId(address(tokenA), address(tokenB)), epochId + 2, vm.addr(1), vm.addr(1), 1);
    }
}
