// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "./PoolDefaults.sol";

import "../../contracts/Hyper.sol";
import "../../contracts/test/TestERC20.sol";

contract TestUpdateLiquidity is Test {
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

    function test_updateLiquidity_add_above_current_slot_succeeds() public mintApproveTokens {
        // activate pool
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        // get pool id
        PoolId poolId = getPoolId(address(tokenA), address(tokenB));
        // fetch activated pool
        (, , , , , , , int128 slotIndex, , , , ) = hyper.pools(poolId);
        // set position range params
        int128 lowerSlotIndex = slotIndex + 10;
        int128 upperSlotIndex = lowerSlotIndex + 10;
        // finally, add liquidity
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, int256(100));
    }

    function test_updateLiquidity_add_including_current_slot_succeeds() public mintApproveTokens {
        // activate pool
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        // get pool id
        PoolId poolId = getPoolId(address(tokenA), address(tokenB));
        // fetch activated pool
        (, , , , , , , int128 slotIndex, , , , ) = hyper.pools(poolId);
        // set position range params
        int128 lowerSlotIndex = slotIndex - 10;
        int128 upperSlotIndex = slotIndex + 10;
        // finally, add liquidity
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, int256(100));
    }

    function test_updateLiquidity_add_below_current_slot_succeeds() public mintApproveTokens {
        // activate pool
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        // get pool id
        PoolId poolId = getPoolId(address(tokenA), address(tokenB));
        // fetch activated pool
        (, , , , , , , int128 slotIndex, , , , ) = hyper.pools(poolId);
        // set position range params
        int128 lowerSlotIndex = slotIndex - 100;
        int128 upperSlotIndex = slotIndex - 10;
        // finally, add liquidity
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, int256(100));
    }

    function test_updateLiquidity_add_above_current_slot_tokenA_balance_increases() public {
        test_updateLiquidity_add_above_current_slot_succeeds();
        // check only tokenA balance increases
        assert(tokenA.balanceOf(address(hyper)) > 0 && tokenB.balanceOf(address(hyper)) == 0);
    }

    function test_updateLiquidity_add_including_current_slot_tokenAB_balance_increases() public {
        test_updateLiquidity_add_including_current_slot_succeeds();
        // check both token balances increase
        assert(tokenA.balanceOf(address(hyper)) > 0 && tokenB.balanceOf(address(hyper)) > 0);
    }

    function test_updateLiquidity_add_below_current_slot_tokenB_balance_increases() public {
        test_updateLiquidity_add_below_current_slot_succeeds();
        // check only tokenB balance increases
        assert(tokenA.balanceOf(address(hyper)) == 0 && tokenB.balanceOf(address(hyper)) > 0);
    }

    function test_updateLiquidity_remove_pending_above_current_slot_succeeds() public mintApproveTokens {
        // activate pool
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        // get pool id
        PoolId poolId = getPoolId(address(tokenA), address(tokenB));
        // fetch activated pool
        (, , , , , , , int128 slotIndex, , , , ) = hyper.pools(poolId);
        // set position range params
        int128 lowerSlotIndex = slotIndex + 10;
        int128 upperSlotIndex = lowerSlotIndex + 10;
        // add liquidity
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, int256(100));
        // remove liquidity
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, -int256(100));
    }

    function test_updateLiquidity_remove_matured_above_current_slot_succeeds() public mintApproveTokens {
        // activate pool
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        // get pool id
        PoolId poolId = getPoolId(address(tokenA), address(tokenB));
        // fetch activated pool
        (, , , , , , , int128 slotIndex, , , , ) = hyper.pools(poolId);
        // set position range params
        int128 lowerSlotIndex = slotIndex + 10;
        int128 upperSlotIndex = lowerSlotIndex + 10;
        // add liquidity
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, int256(100));
        // get current epoch
        (uint256 epochId, , uint256 epochLength) = hyper.epoch();
        // warp timestamp to next epoch
        vm.warp(block.timestamp + epochLength);
        // remove liquidity
        hyper.updateLiquidity(poolId, lowerSlotIndex, upperSlotIndex, -int256(100));
        // ensure the epoch was increased
        (uint256 newEpochId, , ) = hyper.epoch();
        assert(newEpochId > epochId);
    }
}
