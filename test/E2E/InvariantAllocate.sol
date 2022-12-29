// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "solmate/test/utils/DSTestPlus.sol";
import {State} from "./setup/TestE2ESetup.sol";
import "test/helpers/HelperHyperView.sol";
import {HyperPool, HyperPosition, HyperTimeOverride, TestERC20} from "test/helpers/HyperTestOverrides.sol";

contract InvariantAllocate is HelperHyperView, DSTestPlus {
    uint48 public __poolId__ = 0x000100000001;

    HyperTimeOverride public __hyper__; // Actual contract
    TestERC20 public __quote__;
    TestERC20 public __asset__;

    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    constructor(address hyper_, address asset_, address quote_) {
        __hyper__ = HyperTimeOverride(payable(hyper_));
        __asset__ = TestERC20(asset_);
        __quote__ = TestERC20(quote_);
    }

    event SentTokens(uint amount);

    function send_erc20(uint amount) external {
        __asset__.mint(address(__hyper__), amount);
        emit SentTokens(amount);
    }

    function allocate_unallocate(uint deltaLiquidity) external {
        vm.assume(deltaLiquidity > 0);
        vm.assume(deltaLiquidity < 2 ** 127);
        // TODO: Add use max flag support.

        // Preconditions
        HyperPool memory pool = getPool(address(__hyper__), __poolId__);
        assertTrue(pool.blockTimestamp != 0, "Pool not initialized");
        assertTrue(pool.lastPrice != 0, "Pool not created with a price");

        (uint expectedDeltaAsset, uint expectedDeltaQuote) = __hyper__.getReserveDelta(__poolId__, deltaLiquidity);
        __asset__.mint(address(this), expectedDeltaAsset);
        __quote__.mint(address(this), expectedDeltaQuote);

        // Execution
        State memory prev = getState();
        (uint deltaAsset, uint deltaQuote) = __hyper__.allocate(__poolId__, deltaLiquidity);
        State memory post = getState();

        // Postconditions
        {
            assertEq(deltaAsset, expectedDeltaAsset, "pool-delta-asset");
            assertEq(deltaQuote, expectedDeltaQuote, "pool-delta-quote");
            assertEq(post.totalPoolLiquidity, prev.totalPoolLiquidity + deltaLiquidity, "pool-total-liquidity");
            assertTrue(post.totalPoolLiquidity > prev.totalPoolLiquidity, "pool-liquidity-increases");
            assertEq(
                post.callerPositionLiquidity,
                prev.callerPositionLiquidity + deltaLiquidity,
                "position-liquidity-increases"
            );

            assertEq(post.reserveAsset, prev.reserveAsset + expectedDeltaAsset, "reserve-asset");
            assertEq(post.reserveQuote, prev.reserveQuote + expectedDeltaQuote, "reserve-quote");
            assertEq(post.physicalBalanceAsset, prev.physicalBalanceAsset + expectedDeltaAsset, "physical-asset");
            assertEq(post.physicalBalanceQuote, prev.physicalBalanceQuote + expectedDeltaQuote, "physical-quote");

            uint feeDelta0 = post.feeGrowthAssetPosition - prev.feeGrowthAssetPosition;
            uint feeDelta1 = post.feeGrowthAssetPool - prev.feeGrowthAssetPool;
            assertTrue(feeDelta0 == feeDelta1, "asset-growth");

            uint feeDelta2 = post.feeGrowthQuotePosition - prev.feeGrowthQuotePosition;
            uint feeDelta3 = post.feeGrowthQuotePool - prev.feeGrowthQuotePool;
            assertTrue(feeDelta2 == feeDelta3, "quote-growth");
        }

        // Unallocate
        uint timestamp = block.timestamp + __hyper__.JUST_IN_TIME_LIQUIDITY_POLICY();
        vm.warp(timestamp);
        __hyper__.setTimestamp(uint128(timestamp));
        (uint unallocatedAsset, uint unallocatedQuote) = __hyper__.unallocate(__poolId__, deltaLiquidity);

        {
            State memory end = getState();
            assertEq(unallocatedAsset, deltaAsset);
            assertEq(unallocatedQuote, deltaQuote);
            assertEq(end.reserveAsset, prev.reserveAsset);
            assertEq(end.reserveQuote, prev.reserveQuote);
            assertEq(end.totalPoolLiquidity, prev.totalPoolLiquidity);
            assertEq(end.totalPositionLiquidity, prev.totalPositionLiquidity);
            assertEq(end.callerPositionLiquidity, prev.callerPositionLiquidity);
        }
    }

    function getState() internal view returns (State memory) {
        // Execution
        uint sumAsset;
        uint sumQuote;
        uint sumPositionLiquidity;

        sumAsset += __hyper__.getBalance(address(this), address(__asset__));
        sumQuote += __hyper__.getBalance(address(this), address(__quote__));
        sumPositionLiquidity += getPosition(address(__hyper__), address(this), __poolId__).totalLiquidity;

        HyperPool memory pool = getPool(address(__hyper__), __poolId__);
        HyperPosition memory position = getPosition(address(__hyper__), address(this), __poolId__);
        uint feeGrowthAssetPool = pool.feeGrowthGlobalAsset;
        uint feeGrowthQuotePool = pool.feeGrowthGlobalQuote;
        uint feeGrowthAssetPosition = position.feeGrowthAssetLast;
        uint feeGrowthQuotePosition = position.feeGrowthQuoteLast;

        State memory prev = State(
            __hyper__.getReserve(address(__asset__)),
            __hyper__.getReserve(address(__quote__)),
            __asset__.balanceOf(address(__hyper__)),
            __quote__.balanceOf(address(__hyper__)),
            sumAsset,
            sumQuote,
            sumPositionLiquidity,
            pool.liquidity,
            position.totalLiquidity,
            feeGrowthAssetPool,
            feeGrowthQuotePool,
            feeGrowthAssetPosition,
            feeGrowthQuotePosition
        );

        return prev;
    }

    function getBalances(address token) internal view returns (uint reserve, uint physical, uint balanceSum) {
        reserve = __hyper__.getReserve(token);
        physical = TestERC20(token).balanceOf(address(__hyper__));
        balanceSum += __hyper__.getBalance(address(this), token);
    }
}

interface Vm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;

    // Set block.height (newHeight)
    function roll(uint256) external;

    // Set block.basefee (newBasefee)
    function fee(uint256) external;

    // Loads a storage slot from an address (who, slot)
    function load(address, bytes32) external returns (bytes32);

    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address, bytes32, bytes32) external;

    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256, bytes32) external returns (uint8, bytes32, bytes32);

    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);

    // Performs a foreign function call via terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);

    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;

    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address, address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address, address) external;

    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;

    // Sets an address' balance, (who, newBalance)
    function deal(address, uint256) external;

    // Sets an address' code, (who, newCode)
    function etch(address, bytes calldata) external;

    // Expects an error on next call
    function expectRevert(bytes calldata) external;

    function expectRevert(bytes4) external;

    // Record all storage reads and writes
    function record() external;

    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);

    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool, bool, bool, bool) external;

    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address, bytes calldata, bytes calldata) external;

    // Clears all mocked calls
    function clearMockedCalls() external;

    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address, bytes calldata) external;

    // Gets the code from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata) external returns (bytes memory);

    // Labels an address in call traces
    function label(address, string calldata) external;

    // If the condition is false, discard this run's fuzz inputs and generate new ones
    function assume(bool) external;
}
