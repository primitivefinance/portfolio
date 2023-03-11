// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "contracts/RMM03Portfolio.sol";

import "./Setup.sol";
import "./TestPortfolioAllocate.t.sol";
import "./TestPortfolioSwap.t.sol";

contract TestRMM03 is TestPortfolioAllocate, TestPortfolioSwap {
    function setUp() public override {
        super.setUp();

        address new_subject = address(new RMM03Portfolio(address(subjects().weth)));

        _change_subject(new_subject);
    }

    function test_allocate_simple() public noJit defaultConfig useActor usePairTokens(10 ether) isArmed {
        subject().multiprocess(FVMLib.encodeAllocate(uint8(0), ghost().poolId, 1 ether));

        console.log("L          ", ghost().position(actor()).freeLiquidity);
        console.log("x          ", ghost().pool().virtualX);
        console.log("y          ", ghost().pool().virtualY);

        console.log("fee (bps)  ", ghost().pool().params.fee);
        uint256 amountIn = 0.2 ether;
        uint256 amountOut = subject().getAmountOut(ghost().poolId, true, amountIn); // Close to price * amountIn
        console.log("amountIn   ", amountIn);
        console.log("amountOut  ", amountOut);

        uint256 price = subject().getLatestEstimatedPrice(ghost().poolId);
        console.log("price      ", price);

        // Try swapping
        uint256 balIn = ghost().balance(actor(), ghost().quote().to_addr());
        subject().multiprocess(
            FVMLib.encodeSwap(uint8(0), ghost().poolId, uint128(amountIn), uint128(amountOut), uint8(1))
        );
        uint256 balOut = ghost().balance(actor(), ghost().quote().to_addr());
        console.log("inputAmt   ", amountIn);
        console.log("outputAmt  ", balOut);
        console.log("Success    ", balOut == amountOut);
    }
}
