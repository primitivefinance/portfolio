// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestHyperSetup.sol";

contract TestHyperClaim is TestHyperSetup {
    function testClaimCreditsAssetBalance() public postTestInvariantChecks {
        basicAllocate();
        basicSwap();
        HyperPool memory pool = defaultPool();
        uint real0 = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        uint real1 = getReserve(address(__hyperTestingContract__), address(defaultScenario.quote));
        (uint res0, uint res1) = pool.getVirtualReserves();

        //int inv = Invariant.invariantOf(res1, res0, pool.params.strike(), pool.params.volatility(), pool.lastTau());
        console.log("real0", real0);
        console.log("real1", real1);
        console.log("res0", res0);
        console.log("res1", res1);
        basicUnallocate();
        maxDraw(); // zero balance to ensure we aren't paying ourself.
        HyperPosition memory pos = defaultPosition();
        pool = defaultPool();
        (uint fee0, uint fee1) = (pos.tokensOwedAsset, pos.tokensOwedQuote);
        assertTrue(fee0 > 0, "fee0-zero");
        assertTrue(pool.liquidity == 0, "non-zero-liquidity");
        // assertTrue(fee1 > 0, "fee1-zero"); // basic swap only pays asset token fees

        // Claim
        uint prevReserve = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        uint prevBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        __hyperTestingContract__.claim(defaultScenario.poolId, fee0, fee1);
        uint nextBalance = getBalance(address(__hyperTestingContract__), address(this), address(defaultScenario.asset));
        maxDraw(); // clear reserve
        uint nextReserve = getReserve(address(__hyperTestingContract__), address(defaultScenario.asset));
        // todo: fix these tests...
        assertTrue(nextBalance > prevBalance, "no fee claimed");
        assertTrue(nextReserve < prevReserve, "no fee removed");
    }
}
