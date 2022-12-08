// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./PoolDefaults.sol";

import "../../contracts/Hyper.sol";
import "../../contracts/test/TestERC20.sol";

contract TestActivatePool is Test {
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
        hyper = new Hyper(
            startTime,
            address(auctionToken),
            EPOCH_LENGTH,
            AUCTION_LENGTH,
            PUBLIC_SWAP_FEE,
            AUCTION_FEE,
            SLOT_SPACING
        );

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

    function test_activatePool_succeeds() public {
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
    }

    function test_activatePool_duplication_reverts() public {
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        vm.expectRevert(IHyper.PoolAlreadyInitializedError.selector);
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
    }
}
