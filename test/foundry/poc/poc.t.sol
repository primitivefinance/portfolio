// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "solmate/tokens/WETH.sol";
import "contracts/test/TestERC20.sol";

import "./HyperHelper.sol";

uint24 constant DEFAULT_SIGMA = 1e4;
uint16 constant DEFAULT_FEE = 100; // 100 bps = 1%
uint32 constant DEFAULT_PRIORITY_FEE = 50; // 50 bps = 0.5%
uint16 constant DEFAULT_DURATION_DAYS = 365;
uint128 constant DEFAULT_LIQUIDITY = 1e18;
uint128 constant DEFAULT_PRICE = 8e18;
int24 constant DEFAULT_TICK = int24(23027); // 10e18, rounded up! pay attention
uint16 constant DEFAULT_JIT = 4;
uint16 constant DEFAULT_VOLATILITY = 10_000; // same as DEFAULT_SIGMA but uint16
uint256 constant STARTING_BALANCE = 4000e18;
uint256 constant ERROR = 1e10;

contract Poc is Test {
    WETH public weth;
    HyperHelper public hyper;

    TestERC20 public quote;
    TestERC20 public asset;

    address alice = address(0xa11ce);
    address bob = address(0xb0b);
    address eve = address(0xe11e);

    uint64 public constant FIRST_POOL = 0x0000010000000001;

    function setUp() public {
        weth = new WETH();

        hyper = new HyperHelper(address(weth));

        quote = new TestERC20("Quote Token", "QT", 6);
        asset = new TestERC20("Asset Token", "AT", 18);

        // Create a pair and pool
        uint24 pairId = createPair(address(asset), address(quote));
        uint64 poolId = createDefaultPool(pairId, address(0));
    }

    function createPair(address token0, address token1) internal returns (uint24) {
        bytes[] memory instructions = new bytes[](1);
        uint24 magicPoolId = 0x000000;
        instructions[0] = (Enigma.encodeCreatePair(token0, token1));
        bytes memory data = Enigma.encodeJumpInstruction(instructions);

        (bool success, ) = address(hyper).call(data);
        require(success, "Can not create pair");

        return uint24(hyper.getPairNonce());
    }

    /** @dev Encodes jump process for creating a pair + curve + pool in one tx. */
    function createPool(
        uint24 pairId,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 maxPrice,
        uint128 price
    ) internal returns (uint64) {
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = (
            Enigma.encodeCreatePool(
                pairId,
                controller,
                priorityFee,
                fee,
                volatility,
                duration,
                jit,
                maxPrice,
                price
            )
        );
        bytes memory data = Enigma.encodeJumpInstruction(instructions);

        (bool success, ) = address(hyper).call(data);
        require(success, "Can not create pool");

        bool isControlled = controller != address(0);
        return Enigma.encodePoolId(pairId, isControlled, uint32(hyper.getPoolNonce()));
    }

    function createDefaultPool(uint24 pairId, address controller) internal returns (uint64 poolId) {
        poolId = createPool(
            pairId,
            controller,
            uint16(DEFAULT_PRIORITY_FEE),
            uint16(DEFAULT_FEE),
            uint16(DEFAULT_SIGMA),
            uint16(DEFAULT_DURATION_DAYS),
            DEFAULT_JIT,
            DEFAULT_PRICE,
            DEFAULT_PRICE
        );
    }

    function fundUsersAndApprove() public {
        deal(address(asset), alice, STARTING_BALANCE);
        deal(address(quote), alice, STARTING_BALANCE);
        deal(address(asset), bob, STARTING_BALANCE);
        deal(address(quote), bob, STARTING_BALANCE);
        deal(address(asset), eve, STARTING_BALANCE);
        deal(address(quote), eve, STARTING_BALANCE);

        vm.startPrank(alice);
        asset.approve(address(hyper), type(uint256).max);
        quote.approve(address(hyper), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        asset.approve(address(hyper), type(uint256).max);
        quote.approve(address(hyper), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(eve);
        asset.approve(address(hyper), type(uint256).max);
        quote.approve(address(hyper), type(uint256).max);
        vm.stopPrank();
    }

    function test_poc_swap_fee_on_max_input() public {
        fundUsersAndApprove();

        // Allocate to the pool from Alice
        vm.startPrank(alice);
        hyper.allocate(FIRST_POOL, DEFAULT_LIQUIDITY);
        vm.stopPrank();
        // Stop alice

        // Compute max input for selling asset token
        (uint128 assetRes, uint128 quoteRes) = hyper.getVirtualReserves(FIRST_POOL);
        uint128 maxInput = 1e18 - assetRes; // 691404108115560204
        console.log("Value of max input for selling asset token %s", vm.toString(maxInput));

        // Sell maxInput + 10 tokens from bob
        vm.startPrank(bob);
        uint128 input = maxInput + 10;
        (uint output, uint remainder) = hyper.swap(FIRST_POOL, true, input, 0);
        console.log("Swap output: %s and remainder: %s", output, remainder);
        hyper.draw(address(quote), output, bob);
        vm.stopPrank();
        // Stop bob

        // Check effects on bob's balance and pool reserves
        uint bobAsset = asset.balanceOf(bob);
        uint bobQuote = quote.balanceOf(bob);
        (uint128 assetRes1, uint128 quoteRes1) = hyper.getVirtualReserves(FIRST_POOL);

        uint bobAssetDiff = STARTING_BALANCE - bobAsset;
        uint bobQuoteDiff = bobQuote - STARTING_BALANCE;
        uint poolAssetDiff = assetRes1 - assetRes;
        uint poolQuoteDiff = quoteRes - quoteRes1;
        uint poolFeeGrowth = hyper.getPoolFeeGrowthAsset(FIRST_POOL);

        console.log("User input: %s", input);
        console.log("User diffs: %s : %s", bobAssetDiff, bobQuoteDiff);
        console.log("Pool diffs: %s : %s", poolAssetDiff, poolQuoteDiff);
        console.log("Pool Asset: %s", input - poolFeeGrowth);
        console.log("Pool fee growth : %s", poolFeeGrowth);

        // Can not check of equality becaise of error introduced by issue #28
        // Therefore we are checking for error being more than 1e10
        // error more than 1e10 means that user balance did not change as much
        // as it shuld have been considering fee amount
        uint error =  (poolAssetDiff + poolFeeGrowth) - bobAssetDiff;
        assertGt(error, ERROR);
        // console.log("error : %s", error);
    }

    function test_poc_position_fee() public {
        fundUsersAndApprove();

        // Allocate to the pool from Alice
        vm.startPrank(alice);
        hyper.allocate(FIRST_POOL, DEFAULT_LIQUIDITY/2);
        vm.stopPrank();
        // Stop alice

        // Allocate to the pool from Eve
        vm.startPrank(eve);
        hyper.allocate(FIRST_POOL, DEFAULT_LIQUIDITY/2);
        vm.stopPrank();
        // Stop Eve

        // Sell asset tokens from bob
        vm.startPrank(bob);
        uint128 input = 0.1 ether;
        hyper.swap(FIRST_POOL, true, input, 0);
        hyper.swap(FIRST_POOL, true, input, 0);
        hyper.swap(FIRST_POOL, true, input, 0);
        hyper.swap(FIRST_POOL, true, input, 0);
        vm.stopPrank();
        // Stop bob

        uint poolFeeGrowthAsset = hyper.getPoolFeeGrowthAsset(FIRST_POOL);

        vm.prank(eve);
        hyper.claim(FIRST_POOL, 0, 0);

        vm.prank(alice);
        hyper.claim(FIRST_POOL, 0, 0);

        uint aliceFeeGrowthAsset = hyper.getPosFeeGrowthAsset(alice, FIRST_POOL);
        uint eveFeeGrowthAsset = hyper.getPosFeeGrowthAsset(eve, FIRST_POOL);

        // Check if both alice and eve get total fee of the pool
        assertEq(aliceFeeGrowthAsset, poolFeeGrowthAsset);
        assertEq(eveFeeGrowthAsset, poolFeeGrowthAsset);
    }

    /*
    function test_poc_change_in_price_with_time() public {
        // Get current price and price after some time without any changes in params
        uint startingPrice = hyper.getLatestPrice(FIRST_POOL);
        skip(182 days);
        uint halfTimePrice = hyper.getLatestPrice(FIRST_POOL);
        console.log("Price change without any other change:  %s, %s", startingPrice, halfTimePrice);

        // Change in price with change in volatility
        uint64 poolId = createDefaultPool(uint24(hyper.getPairNonce()), address(this));
        uint startingPriceDS = hyper.getLatestPrice(poolId);
        skip(182 days);
        hyper.changeParameters(
            poolId,
            0,
            0,
            uint16(DEFAULT_SIGMA * 2),
            0,
            0,
            0
        );
        uint halfTimePriceDS = hyper.getLatestPrice(poolId);
        console.log("Price change with change in volatility: %s, %s", startingPriceDS, halfTimePriceDS);

        // Change in price with change in strike price
        poolId = createDefaultPool(uint24(hyper.getPairNonce()), address(this));
        uint startingPriceKS = hyper.getLatestPrice(poolId);
        skip(182 days);
        hyper.changeParameters(
            poolId,
            0,
            0,
            0,
            0,
            0,
            DEFAULT_TICK*2
        );
        uint halfTimePriceKS = hyper.getLatestPrice(poolId);
        console.log("Price change with change in strike:     %s, %s", startingPriceKS, halfTimePriceKS);

        // Change in price with change in maturity
        poolId = createDefaultPool(uint24(hyper.getPairNonce()), address(this));
        uint startingPriceTS = hyper.getLatestPrice(poolId);
        skip(182 days);
        hyper.changeParameters(
            poolId,
            0,
            0,
            0,
            450,
            0,
            0
        );
        uint halfTimePriceTS = hyper.getLatestPrice(poolId);
        console.log("Price change with change in maturity:   %s, %s", startingPriceTS, halfTimePriceTS);

        assertFalse(halfTimePrice == halfTimePriceDS);
        assertFalse(halfTimePrice == halfTimePriceKS);
        assertFalse(halfTimePrice == halfTimePriceTS);
    }
    */

    function test_poc_swap_output_scale() public {
        fundUsersAndApprove();

        // Allocate to the pool from Alice
        vm.startPrank(alice);
        hyper.allocate(FIRST_POOL, DEFAULT_LIQUIDITY);
        vm.stopPrank();
        // Stop alice

        uint128 input = 0.1 ether;

        vm.startPrank(bob);
        (uint outputAt1, uint remainderAt1) = hyper.swap(FIRST_POOL, true, input, 0);
        console.log("Swap output: %s and remainder: %s", outputAt1, remainderAt1);
        vm.stopPrank();

        vm.startPrank(alice);
        hyper.allocate(FIRST_POOL, DEFAULT_LIQUIDITY*9);
        vm.stopPrank();

        vm.startPrank(bob);
        (uint outputAt10, uint remainderAt10) = hyper.swap(FIRST_POOL, true, input, 0);
        console.log("Swap output: %s and remainder: %s", outputAt10, remainderAt10);
        vm.stopPrank();

        // Checking that output at liquidity 1 is 10 times the output at liquidity 10
        // tells us that the input amount has been devided by liquidity amount but the
        // output amount has not been multiplied by liquidity amount to scale it back.
        // It shows that for same amount of input the output varies at same order at
        // which liquidity varies.
        assertEq(true, outputAt1/outputAt10 >= 10);
    }
}
