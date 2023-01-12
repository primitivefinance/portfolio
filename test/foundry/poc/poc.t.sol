// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "solmate/tokens/WETH.sol";
import "contracts/Enigma.sol" as ProcessingLib;
import "contracts/test/TestERC20.sol";

import "./HyperHelper.sol";

uint24 constant DEFAULT_SIGMA = 1e4;
uint32 constant DEFAULT_MATURITY = 31556953; // adds 1
uint16 constant DEFAULT_FEE = 100; // 100 bps = 1%
uint32 constant DEFAULT_PRIORITY_FEE = 50; // 50 bps = 0.5%
uint16 constant DEFAULT_DURATION_DAYS = 365;
uint128 constant DEFAULT_QUOTE_RESERVE = 3085375116376210650;
uint128 constant DEFAULT_ASSET_RESERVE = 308537516918601823; // 308596235182
uint128 constant DEFAULT_LIQUIDITY = 1e18;
uint128 constant DEFAULT_PRICE = 10e18;
int24 constant DEFAULT_TICK = int24(23027); // 10e18, rounded up! pay attention
uint256 constant DEFAULT_SWAP_INPUT = 0.1 ether;
uint256 constant DEFAULT_SWAP_OUTPUT = 97_627 wei;
uint16 constant DEFAULT_JIT = 4;
uint16 constant DEFAULT_VOLATILITY = 10_000; // same as DEFAULT_SIGMA but uint16
int24 constant DEFAULT_MAX_TICK = int24(23027);
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
        bytes memory data = createPool(
            address(asset),
            address(quote),
            address(0),
            uint16(DEFAULT_PRIORITY_FEE),
            uint16(DEFAULT_FEE),
            uint16(DEFAULT_SIGMA),
            uint16(DEFAULT_DURATION_DAYS),
            DEFAULT_JIT,
            DEFAULT_TICK,
            DEFAULT_PRICE
        );
        
        // Execute above instructions on hyper by triggering fallback function
        (bool success, ) = address(hyper).call(data);
        require(success, "Can not create pool");
    }

    /** @dev Encodes jump process for creating a pair + curve + pool in one tx. */
    function createPool(
        address token0,
        address token1,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        int24 maxTick,
        uint128 price
    ) internal pure returns (bytes memory data) {
        bytes[] memory instructions = new bytes[](2);
        uint24 magicPoolId = 0x000000;
        instructions[0] = (ProcessingLib.encodeCreatePair(token0, token1));
        instructions[1] = (
            ProcessingLib.encodeCreatePool(
                magicPoolId, // magic variable
                controller,
                priorityFee,
                fee,
                volatility,
                duration,
                jit,
                maxTick,
                price
            )
        );
        data = ProcessingLib.encodeJumpInstruction(instructions);
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

    function test_poc_swap_fee_issue_25() public {
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

    
}
