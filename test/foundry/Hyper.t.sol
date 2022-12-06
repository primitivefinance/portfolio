pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "../../contracts/Hyper.sol";
import "../../contracts/test/TestERC20.sol";

contract TestHyper is Test {
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

    function test_updateLiquidity_add_above_current_slot_succeeds() public mintApproveTokens {
        // activate pool
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        // get pool id
        bytes32 poolId = getPoolId(address(tokenA), address(tokenB));
        // fetch activated pool
        (, , , , , , int128 slotIndex, , , , ) = hyper.pools(poolId);
        // set position range params
        int128 lowerSlotIndex = slotIndex + 10;
        int128 upperSlotIndex = lowerSlotIndex + 10;
        // don't transfer out (shouldn't matter here)
        bool transferOut = false;
        // finally, add liquidity
        hyper.updateLiquidity(
            getPoolId(address(tokenA), address(tokenB)),
            lowerSlotIndex,
            upperSlotIndex,
            int256(100),
            transferOut
        );
    }

    function test_updateLiquidity_add_including_current_slot_succeeds() public mintApproveTokens {
        // activate pool
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        // get pool id
        bytes32 poolId = getPoolId(address(tokenA), address(tokenB));
        // fetch activated pool
        (, , , , , , int128 slotIndex, , , , ) = hyper.pools(poolId);
        // set position range params
        int128 lowerSlotIndex = slotIndex - 10;
        int128 upperSlotIndex = slotIndex + 10;
        // don't transfer out (shouldn't matter here)
        bool transferOut = false;
        // finally, add liquidity
        hyper.updateLiquidity(
            getPoolId(address(tokenA), address(tokenB)),
            lowerSlotIndex,
            upperSlotIndex,
            int256(100),
            transferOut
        );
    }

    function test_updateLiquidity_add_below_current_slot_succeeds() public mintApproveTokens {
        // activate pool
        hyper.activatePool(address(tokenA), address(tokenB), getStartSqrtPrice());
        // get pool id
        bytes32 poolId = getPoolId(address(tokenA), address(tokenB));
        // fetch activated pool
        (, , , , , , int128 slotIndex, , , , ) = hyper.pools(poolId);
        // set position range params
        int128 lowerSlotIndex = slotIndex - 100;
        int128 upperSlotIndex = slotIndex - 10;
        // don't transfer out (shouldn't matter here)
        bool transferOut = false;
        // finally, add liquidity
        hyper.updateLiquidity(
            getPoolId(address(tokenA), address(tokenB)),
            lowerSlotIndex,
            upperSlotIndex,
            int256(100),
            transferOut
        );
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
}
