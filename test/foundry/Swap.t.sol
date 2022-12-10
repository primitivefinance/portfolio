// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./PoolDefaults.sol";

import {unwrap as unwrapUD60x18} from "@prb/math/UD60x18.sol";

import "../../contracts/Hyper.sol";
import "../../contracts/test/TestERC20.sol";

contract TestSwap is Test {
    Hyper public hyper;

    PoolId poolId;

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

        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        poolId = getPoolId(address(tokenA), address(tokenB));

        vm.startPrank(testUser);
    }

    function getStartSqrtPrice() internal pure returns (UD60x18 sqrtPrice) {
        UD60x18 ethPrice = toUD60x18(1200);
        UD60x18 usdPrice = ethPrice.inv();
        // decimals factor = 10^(tokenB.decimals - tokenA.decimals) = 1e12
        UD60x18 usdcPrice = usdPrice.mul(toUD60x18(1e12));
        sqrtPrice = usdcPrice.sqrt();
    }

    function test_swap_tokenA_fixed_in_liquidity_in_range_succeeds() public mintApproveTokens {
        // fetch slotIndex of pool
        (, , , , , , UD60x18 beforeSqrtPrice, int24 slotIndex, , , , ) = hyper.pools(poolId);

        int256 liquidity = int256(1e18);
        int24 lowerSlotIndex = slotIndex - 10;
        int24 upperSlotIndex = slotIndex + 10;

        // add liquidity around the pool's slot index
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, liquidity);

        uint256 tokenAAmountIn = BrainMath.getDeltaAToNextPrice(
            beforeSqrtPrice,
            BrainMath.getSqrtPriceAtSlot(lowerSlotIndex),
            uint256(liquidity / 2),
            BrainMath.Rounding.Down
        );

        // perform swap
        hyper.swap(poolId, PoolToken.A, true, tokenAAmountIn, zeroUD60x18);

        (, , , , , , UD60x18 afterSqrtPrice, , , , , ) = hyper.pools(poolId);

        assert(afterSqrtPrice.lt(beforeSqrtPrice));
    }

    function test_swap_tokenB_fixed_in_liquidity_in_range_succeeds() public mintApproveTokens {
        // fetch slotIndex of pool
        (, , , , , , UD60x18 beforeSqrtPrice, int24 slotIndex, , , , ) = hyper.pools(poolId);

        int256 liquidity = int256(1e18);
        int24 lowerSlotIndex = slotIndex - 10;
        int24 upperSlotIndex = slotIndex + 10;

        // add liquidity around the pool's slot index
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, liquidity);

        uint256 tokenBAmountIn = BrainMath.getDeltaBToNextPrice(
            beforeSqrtPrice,
            BrainMath.getSqrtPriceAtSlot(upperSlotIndex),
            uint256(liquidity / 2),
            BrainMath.Rounding.Down
        );

        // perform swap
        hyper.swap(poolId, PoolToken.B, true, tokenBAmountIn, zeroUD60x18);

        (, , , , , , UD60x18 afterSqrtPrice, , , , , ) = hyper.pools(poolId);

        assert(afterSqrtPrice.gt(beforeSqrtPrice));
    }

    function test_swap_tokenA_fixed_out_liquidity_in_range_succeeds() public mintApproveTokens {
        // fetch slotIndex of pool
        (, , , , , , UD60x18 beforeSqrtPrice, int24 slotIndex, , , , ) = hyper.pools(poolId);

        int256 liquidity = int256(1e18);
        int24 lowerSlotIndex = slotIndex - 10;
        int24 upperSlotIndex = slotIndex + 10;

        // add liquidity around the pool's slot index
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, liquidity);

        uint256 tokenBAmountOut = BrainMath.getDeltaBToNextPrice(
            beforeSqrtPrice,
            BrainMath.getSqrtPriceAtSlot(upperSlotIndex),
            uint256(liquidity / 2),
            BrainMath.Rounding.Down
        );

        // perform swap
        hyper.swap(poolId, PoolToken.A, false, tokenBAmountOut, zeroUD60x18);

        (, , , , , , UD60x18 afterSqrtPrice, , , , , ) = hyper.pools(poolId);

        assert(afterSqrtPrice.lt(beforeSqrtPrice));
    }

    function test_swap_tokenB_fixed_out_liquidity_in_range_succeeds() public mintApproveTokens {
        // fetch slotIndex of pool
        (, , , , , , UD60x18 beforeSqrtPrice, int24 slotIndex, , , , ) = hyper.pools(poolId);

        int256 liquidity = int256(1e18);
        int24 lowerSlotIndex = slotIndex - 10;
        int24 upperSlotIndex = slotIndex + 10;

        // add liquidity around the pool's slot index
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, liquidity);

        uint256 tokenAAmountOut = BrainMath.getDeltaAToNextPrice(
            beforeSqrtPrice,
            BrainMath.getSqrtPriceAtSlot(lowerSlotIndex),
            uint256(liquidity / 2),
            BrainMath.Rounding.Down
        );

        // perform swap
        hyper.swap(poolId, PoolToken.B, false, tokenAAmountOut, zeroUD60x18);

        (, , , , , , UD60x18 afterSqrtPrice, , , , , ) = hyper.pools(poolId);

        assert(afterSqrtPrice.gt(beforeSqrtPrice));
    }
}
