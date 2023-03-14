// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

// import "./setup/InvariantTargetContract.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import { RMM01Portfolio as Portfolio } from "contracts/RMM01Portfolio.sol";
import "../Setup.sol";
import "./Helper.sol";

contract StatelessSwaps is Helper, Test {
    // contract Test is DSTest, StdAssertions, StdChains, StdCheats, StdUtils, TestBase

    WETH weth;
    Portfolio portfolio;
    MockERC20 usdc;
    MockERC20 asset;
    MockERC20 quote;

    address immutable self = address(this);
    address immutable alice = address(0xa11ce);

    uint256 constant INITIAL_BALANCE = 1e50;

    constructor() {
        weth = new WETH();
        usdc = new MockERC20("USD Coin", "USDC", 6);
        quote = new MockERC20("Quote", "QUOTE", 18);
        asset = new MockERC20("Asset", "ASSET", 18);
        portfolio = new Portfolio(address(weth));

        // vm.label(address(weth), "WETH");
        // vm.label(address(usdc), "USDC");
        // vm.label(address(asset), "ASSET");
        // vm.label(address(quote), "QUOTE");
        // vm.label(address(Portfolio), "Portfolio");

        // vm.label(address(self), "self");
        // vm.label(address(alice), "alice");

        // Note: swap exploit works without any balance
        // usdc.mint(self, INITIAL_BALANCE);
        // quote.mint(self, INITIAL_BALANCE);
        // asset.mint(self, INITIAL_BALANCE);
        // usdc.approve(address(portfolio), type(uint256).max);
        // quote.approve(address(portfolio), type(uint256).max);
        // asset.approve(address(portfolio), type(uint256).max);

        // vm.startPrank(alice);

        vm.prank(alice);
        quote.mint(alice, INITIAL_BALANCE);
        vm.prank(alice);
        asset.mint(alice, INITIAL_BALANCE);
        vm.prank(alice);
        quote.approve(address(portfolio), type(uint256).max);
        vm.prank(alice);
        asset.approve(address(portfolio), type(uint256).max);

        // vm.stopPrank();
    }

    uint16 priorityFee = 1;
    uint16 fee = 1;
    uint64 poolId;

    function bound(
        uint256 random,
        uint256 low,
        uint256 high
    ) internal pure override returns (uint256) {
        return between(random, low, high + 1);
    }

    /// @dev "Stateless" swap fuzz
    function test_swap_fuzz(
        bool sell,
        uint256 input,
        uint256 output,
        uint256 liquidity,
        uint256 price,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) public {
        stk = bound(stk, 1, type(uint128).max);
        price = bound(price, stk, type(uint128).max); // to prevent lnWad's "UNDEFINED" when `price * 1e18 / stk == 0`.
        vol = bound(vol, 100, 25_000);
        tau = bound(tau, 1, 500);

        {
            // Scoping due to stack-depth.

            // Create pool.
            vm.prank(alice);
            createPool(vol, tau, uint128(stk), uint128(price));
            // Allocate liquidity.
            (uint256 amountAsset, uint256 amountQuote) =
                portfolio.getPoolReserves(poolId);

            // Need to bound liquidity accordingly,
            // so that the required tokens (= amount * liquidity) don't overflow.
            liquidity = bound(liquidity, 1, uint128(type(int128).max));
            if (amountAsset != 0) {
                liquidity = bound(
                    liquidity,
                    amountAsset,
                    (uint128(type(int128).max) + amountAsset - 1) / amountAsset
                );
            }
            if (amountQuote != 0) {
                liquidity = bound(
                    liquidity,
                    amountQuote,
                    (uint128(type(int128).max) + amountQuote - 1) / amountQuote
                );
            }

            emit LogUint256("Allocating liquidity:", liquidity);

            vm.prank(alice);
            portfolio.multiprocess(
                FVMLib.encodeAllocate(uint8(0), poolId, 0x0, uint128(liquidity))
            );
        }

        // Update stk to what portfolio stores, otherwise calculations will be inexcat.
        emit LogUint256("stk", stk);
        {
            PortfolioPool memory pool =
                IPortfolioStruct(address(portfolio)).pools(poolId);

            // Compute reserves to determine max input and output.
            (uint256 R_y, uint256 R_x) =
                RMM01Lib.computeReservesWithPrice(pool, price, 0);

            uint256 maxInput;
            uint256 maxOutput;
            if (sell) {
                // console.log("selling");
                // console.log("liveIndependent R_x", R_x);
                // console.log("liveDependent R_y", R_y);
                if (R_x >= 1e18) return; // Shouldn't happen
                maxInput = ((1e18 - R_x) * liquidity) / 1e18;
                maxOutput = (R_y * liquidity) / 1e18;
            } else {
                // console.log("buying");
                emit LogUint256("liveIndependent R_y", R_y);
                emit LogUint256("liveDependent R_x", R_x);
                if (R_y > stk) return; // Can happen although this will lead to an overflow on computing max in the swap fn.
                maxInput = ((stk - R_y) * liquidity) / 1e18; // (2-2)*2/1e18
                maxOutput = (R_x * liquidity) / 1e18;
            }
            emit LogUint256("max input", maxInput);
            emit LogUint256("max ouput ", maxOutput);
            // assert(false);

            if (maxInput < 1 || maxOutput < 1) return; // Will revert in swap due to input/output == 0.

            input = bound(input, 1, maxInput);
            output = bound(output, 1, maxOutput);

            emit LogUint256("input", input);
            emit LogUint256("output", output);
        }

        // Max error margin the invariant check in the swap allows for.
        uint256 maxErr = 100 * 1e18;

        // Swapping back and forth should not succeed if `output > input` under normal circumstances.
        (bool success,) = swapBackAndForthCall(
            sell, uint128(input), uint128(output), uint128(input + maxErr)
        );

        //
        if (success) {
            // RMM01Lib.RMM memory rmm = RMM01Lib.RMM({strike: stk, sigma: vol, tau: tau});
            // (uint256 R_y, uint256 R_x) = RMM01Lib.computeReserves(rmm, price);
            // console.log("R_x", R_x);
            // console.log("R_y", R_y);
            // console.log("bal asset", portfolio.getBalance(self, address(asset)));
            // console.log("bal quote", portfolio.getBalance(self, address(quote)));
            portfolio.draw(
                address(asset), portfolio.getBalance(self, address(asset)), self
            );
            portfolio.draw(
                address(quote), portfolio.getBalance(self, address(quote)), self
            );

            emit LogUint256(
                "asset gain", asset.balanceOf(self) - INITIAL_BALANCE
                );
            emit LogUint256(
                "quote gain", quote.balanceOf(self) - INITIAL_BALANCE
                );
            emit AssertionFailed("Swap allowed to extract tokens");
            // fail();
        }
    }

    /* ----------------- helper ----------------- */

    function createPool(
        uint256 volatility,
        uint256 duration,
        uint128 stk,
        uint128 price
    ) internal returns (uint64) {
        return createPool(
            address(asset),
            address(quote),
            self,
            priorityFee,
            fee,
            volatility,
            duration,
            0,
            stk,
            price
        );
    }

    function createPool(
        address token0,
        address token1,
        address controller,
        uint256 priorityFee,
        uint256 fee,
        uint256 volatility,
        uint256 duration,
        uint256 jit,
        uint128 stk,
        uint128 price
    ) internal returns (uint64) {
        bytes memory data;
        bytes[] memory instructions = new bytes[](1);
        bool success;
        bytes memory returndata;

        if (poolId == 0) {
            instructions[0] = FVMLib.encodeCreatePair(token0, token1);
            data = FVMLib.encodeJumpInstruction(instructions);

            (success, returndata) = address(portfolio).call(data);
            if (!success) {
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            }
        }

        instructions[0] = FVMLib.encodeCreatePool(
            0x000000, // magic variable
            controller,
            uint16(priorityFee),
            uint16(fee),
            uint16(volatility),
            uint16(duration),
            uint16(jit),
            stk,
            price
        );

        // console.log("\nCreating Pool:");
        // console.log("controller", controller);
        // console.log("priorityFee", uint16(priorityFee));
        // console.log("fee", uint16(fee));
        // console.log("volatility", uint16(volatility));
        // console.log("duration", uint16(duration));
        // console.log("jit", uint16(jit));
        // console.log("stk", stk);
        // console.log("price %s\n", price);

        data = FVMLib.encodeJumpInstruction(instructions);

        (success, returndata) = address(portfolio).call(data);
        if (!success) {
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }

        uint24 pairNonce = portfolio.getPairNonce();
        poolId =
            FVM.encodePoolId(pairNonce, true, portfolio.getPoolNonce(pairNonce));

        console.log("PoolId", poolId);

        return poolId;
    }

    function swapBackAndForth(
        bool sell,
        uint128 input,
        uint128 output1,
        uint128 output2
    ) internal {
        (bool success, bytes memory returndata) =
            swapBackAndForthCall(sell, input, output1, output2);

        if (!success) {
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }
    }

    function swapBackAndForthCall(
        bool sell,
        uint128 input,
        uint128 output1,
        uint128 output2
    ) internal returns (bool success, bytes memory returndata) {
        bytes[] memory instructions = new bytes[](2);

        // console.log(
        //     string.concat(
        //         sell ? "\nSelling, then buying asset" : "\nBuying, then selling asset",
        //         "\nSwapping: ",
        //         sell ? "%s asset -> %s quote -> %s asset" : "%s quote -> %s asset -> %s quote"
        //     ),
        //     input,
        //     output1,
        //     output2
        // );

        instructions[0] =
            FVMLib.encodeSwap(0, poolId, 0, input, 0, output1, sell ? 0 : 1);
        instructions[1] =
            FVMLib.encodeSwap(0, poolId, 0, output1, 0, output2, sell ? 1 : 0);

        bytes memory data = FVMLib.encodeJumpInstruction(instructions);

        (success, returndata) = address(portfolio).call(data);
    }
}

interface PortfolioTau {
    function computeCurrentTau(uint64 poolId) external view returns (uint256);
}
