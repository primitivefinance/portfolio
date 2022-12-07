pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "../../contracts/Hyper.sol";
import "../../contracts/libraries/Pool.sol";
import "../../contracts/test/TestERC20.sol";

contract TestBid is Test {
    Hyper public hyper;

    TestERC20 public tokenA;
    TestERC20 public tokenB;

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
        TestERC20 fakeUSDC = new TestERC20("USD Coin", "USDC", 6);
        TestERC20 fakeWETH = new TestERC20("Wrapped Ether", "WETH", 18);

        hyper = new Hyper(1000, auctionCollector, address(fakeWETH));
        (tokenA, tokenB) = address(fakeUSDC) < address(fakeWETH) ? (fakeUSDC, fakeWETH) : (fakeWETH, fakeUSDC);

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
        vm.expectRevert(AmountZeroError.selector);

        hyper.bid(
            getPoolId(address(tokenA), address(tokenB)),
            0,
            vm.addr(1),
            vm.addr(1),
            0
        );
    }

    function test_bid_should_fail_if_pool_is_not_initialized() public {
        vm.expectRevert(PoolNotInitializedError.selector);

        hyper.bid(
            getPoolId(address(0), address(1)),
            0,
            vm.addr(1),
            vm.addr(1),
            1
        );
    }

    function test_bid_should_succeed() public mintApproveTokens {
        vm.warp(3600 - 60);

        (uint256 id, uint256 endTime) = hyper.epoch();

        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());

        hyper.bid(
            getPoolId(address(tokenA), address(tokenB)),
            id + 1,
            vm.addr(1),
            vm.addr(1),
            1
        );
    }

    function test_bid_should_fail_if_wrong_epoch_id() public {
        vm.warp(3600 - 30);

        (uint256 id, uint256 endTime) = hyper.epoch();

        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());

        vm.expectRevert(InvalidBidEpochError.selector);

        hyper.bid(
            getPoolId(address(tokenA), address(tokenB)),
            id + 2,
            vm.addr(1),
            vm.addr(1),
            1
        );
    }
}
