// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";
import "./TestPortfolioAllocate.t.sol";
import "./TestPortfolioChangeParameters.t.sol";
import "./TestPortfolioCreatePair.t.sol";
import "./TestPortfolioCreatePool.t.sol";
import "./TestPortfolioDeposit.t.sol";
import "./TestPortfolioDraw.t.sol";
import "./TestPortfolioFund.t.sol";
import "./TestPortfolioSwap.t.sol";
import "./TestPortfolioDeallocate.t.sol";

contract TestRMM01 is
    TestPortfolioAllocate,
    TestPortfolioChangeParameters,
    TestPortfolioCreatePair,
    TestPortfolioCreatePool,
    TestPortfolioDeposit,
    TestPortfolioDraw,
    TestPortfolioFund,
    TestPortfolioSwap,
    TestPortfolioDeallocate
{
    function setUp() public override {
        super.setUp();

        // todo: Update this when each portfolio exists. Right now, default portfolio is RMM01.
        // address new_subject = address(new RMM01Portfolio(address(subjects().weth)));
        // subjects().change_subject(new_subject);
    }

    function test_version() public {
        assertEq(subject().VERSION(), "v1.0.0-beta", "version-not-equal");
    }
}
