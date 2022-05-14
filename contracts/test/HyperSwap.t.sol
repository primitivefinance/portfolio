pragma solidity ^0.8.0;

import "./DSTest.sol";

import {EnigmaVirtualMachineActions} from "./EnigmaVirtualMachine.t.sol";
import "../HyperSwap.sol";
import "../libraries/Units.sol";

import "hardhat/console.sol";

contract TestHyperSwap is HyperSwap, DSTest {
    // --- Helpers --- //

    address public base;
    address public quote;

    function helperSetTokens(address base_, address quote_) public {
        base = base_;
        quote = quote_;
    }

    /// @dev Creates a hardcoded pool with parameters plugged into: https://www.desmos.com/calculator/hv9kg9d16x
    function helperCreateStandardPool(uint48 poolId) public {
        require(base != address(0x0), "no-base-token");
        require(quote != address(0x0), "no-quote-token");

        Curve storage curve = curves[uint32(poolId)];
        curve.strike = 1e19; // 10
        curve.sigma = 1e4; // 100%
        curve.maturity = uint32(Units.YEAR) + 1; // adds one second because block timestamp is at least 1
        curve.gamma = 1e4 - 100; // 99%

        Pair storage pair = pairs[uint16(poolId >> 32)];
        pair.decimalsBase = IERC20(base).decimals();
        pair.tokenBase = base;
        pair.decimalsQuote = IERC20(quote).decimals();
        pair.tokenQuote = quote;

        Pool storage pool = pools[poolId];
        pool.internalBase = 308537538726000000; // 0.308
        pool.internalQuote = 3085375387260000000; // 3.08
        pool.internalLiquidity = 1e18; // 1
        pool.blockTimestamp = 1; // arbitrary, but cannot be zero!

        globalReserves[pair.tokenBase] += pool.internalBase;
        globalReserves[pair.tokenQuote] += pool.internalQuote;
    }

    // --- View --- //
    function testCheckSwapMaturityCondition(uint128 timestamp) public {
        require(block.timestamp > timestamp, "HyperSwap/timestamp-not-mature");
        uint256 elapsed = checkSwapMaturityCondition(timestamp);
        assertTrue(elapsed > 0, "HyperSwap/elapsed-time");
    }

    function testGetPhysicalReserves(uint256 deltaLiquidity) public {
        uint48 poolId = uint48(5);
        Pool storage pool = pools[poolId];
        pool.internalBase = 100;
        pool.internalQuote = 500;
        pool.internalLiquidity = 1000;
        pool.blockTimestamp = _blockTimestamp();

        (uint256 deltaBase, uint256 deltaQuote) = getPhysicalReserves(poolId, deltaLiquidity);
        assertEq(deltaBase, (100 * deltaLiquidity) / 1000, "HyperSwap/physical-base-amount");
        assertEq(deltaQuote, (500 * deltaLiquidity) / 1000, "HyperSwap/physical-quote-amount");
    }

    function testGetInvariant() public {
        uint48 poolId = uint48(11);

        helperCreateStandardPool(poolId);

        int128 invariant = getInvariant(poolId);
        uint64 invariantUInt = uint64(uint128(invariant >> 64));
        assertEq(invariantUInt, 0, "HyperSwap/get-invariant"); // Using hardcoded values computed with: https://www.desmos.com/calculator/hv9kg9d16x
    }

    function testSwap(uint8 direction) public {
        uint48 poolId = uint48(7);
        helperCreateStandardPool(poolId);

        // Update the maturity to be one year after this block timestamp.
        // Swap will update the current pool's timestamp to this block timestamp.
        Curve storage curve = curves[uint32(poolId)];
        curve.maturity = curve.maturity + uint32(block.timestamp);

        // Cache the current pool reseverves to compare them after swap.
        Pool memory pre = pools[poolId];

        uint256 deltaIn;
        uint256 deltaOut;
        if (direction == 0) {
            deltaIn = 1e15;
            deltaOut = 9970860704930000; // hardcoded from desmos output
            uint256 absError = deltaOut / 20; // 5% error from desmos output
            deltaOut = deltaOut - absError;
        } else {
            deltaIn = 9970860704930000;
            deltaOut = 1e15;
            uint256 absError = deltaOut / 20; // 5% error from desmos output
            deltaOut = deltaOut - absError;
        }

        // Execute the swap
        _swap(poolId, direction, deltaIn, deltaOut);

        Pool memory post = pools[poolId];
        if (direction == 0) {
            assertEq(
                uint256(pre.internalBase) + deltaIn,
                uint256(post.internalBase),
                "HyperSwap/dir-zero-internal-base"
            );
            assertEq(
                uint256(pre.internalQuote) - deltaOut,
                uint256(post.internalQuote),
                "HyperSwap/dir-zero-internal-quote"
            );
        } else {
            assertEq(uint256(pre.internalBase) - deltaOut, uint256(post.internalBase), "dir-one-internal-base");
            assertEq(uint256(pre.internalQuote) + deltaIn, uint256(post.internalQuote), "dir-one-internal-quote");
        }
    }

    // --- Internal --- //

    function testUpdateLastTimestamp() public {
        uint48 poolId = uint48(12);
        Pool storage pool = pools[poolId];
        pool.blockTimestamp = 44; // non-zero so we pass the non existent pool check.

        Curve storage curve = curves[uint32(poolId)];
        curve.maturity = 100;

        uint128 blockTimestamp = _updateLastTimestamp(poolId);
        if (blockTimestamp > curve.maturity) {
            assertEq(pool.blockTimestamp, curve.maturity); // pool timestamp is at max its maturity.
        } else {
            assertEq(pool.blockTimestamp, blockTimestamp); // pool set to block timestamp in non maturity case
        }
    }

    // --- Implemented --- //
    function getLiquidityMinted(
        uint48,
        uint256,
        uint256
    ) public view override returns (uint256) {}

    function checkJitLiquidity(address, uint48) external view returns (uint256, uint256) {}

    function fund(address, uint256) external override {}

    function draw(
        address,
        uint256,
        address
    ) external override {}
}
