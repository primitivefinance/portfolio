pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "../../contracts/Hyper.sol";
import "../../contracts/test/TestERC20.sol";

contract TestActivatePool is Test {
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
        hyper = new Hyper(1000, auctionCollector);

        vm.warp(1000);
        hyper.start();

        vm.startPrank(testUser);

        TestERC20 fakeUSDC = new TestERC20("USD Coin", "USDC", 6);
        TestERC20 fakeWETH = new TestERC20("Wrapped Ether", "WETH", 18);

        (tokenA, tokenB) = address(fakeUSDC) < address(fakeWETH) ? (fakeUSDC, fakeWETH) : (fakeWETH, fakeUSDC);

        assertTrue(tokenA == fakeUSDC);
    }

    function getStartSqrtPrice() public pure returns (UD60x18 sqrtPrice) {
        UD60x18 ethPrice = toUD60x18(1200);
        UD60x18 usdPrice = ethPrice.inv();
        // decimals factor = 10^(tokenB.decimals - tokenA.decimals) = 1e12
        UD60x18 usdcPrice = usdPrice.mul(toUD60x18(1e12));
        sqrtPrice = usdcPrice.sqrt();
    }

    function test_activatePool_succeeds() public {
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
    }

    function test_activatePool_duplication_reverts() public {
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        vm.expectRevert(PoolAlreadyInitializedError.selector);
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
    }
}
