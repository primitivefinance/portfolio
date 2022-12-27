// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperAllocate is TestHyperSetup {
    function testAllocateFull() public checkSettlementInvariant {
        uint256 price = getPool(address(__hyperTestingContract__), defaultScenario.poolId).lastPrice;
        Curve memory curve = getCurve(address(__hyperTestingContract__), uint32(defaultScenario.poolId));
        uint256 theoreticalR2 = Price.computeR2WithPrice(
            price,
            curve.strike,
            curve.sigma,
            curve.maturity - block.timestamp
        );

        __hyperTestingContract__.allocate(defaultScenario.poolId, 4e6);

        uint256 globalR1 = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));
        uint256 globalR2 = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        assertTrue((theoreticalR2 - FixedPointMathLib.divWadUp(globalR2, 4_000_000)) <= 1e14);
    }

    function testAllocateUseMax() public checkSettlementInvariant {
        uint maxLiquidity = __hyperTestingContract__.getLiquidityMinted(
            defaultScenario.poolId,
            defaultScenario.asset.balanceOf(address(this)),
            defaultScenario.quote.balanceOf(address(this))
        );

        (uint deltaAsset, uint deltaQuote) = __hyperTestingContract__.getReserveDelta(
            defaultScenario.poolId,
            maxLiquidity
        );

        __hyperTestingContract__.allocate(defaultScenario.poolId, type(uint256).max);

        assertEq(maxLiquidity, getPool(address(__hyperTestingContract__), defaultScenario.poolId).liquidity);
        assertEq(deltaAsset, getReserve(address(__hyperTestingContract__), address(defaultScenario.asset)));
        assertEq(deltaQuote, getReserve(address(__hyperTestingContract__), address(defaultScenario.quote)));
    }

    function testFuzzAllocate() public {}
}
