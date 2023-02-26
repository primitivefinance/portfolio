// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./Setup.sol";
import "./TestHyperAllocate.t.sol";
import "./TestHyperChangeParameters.t.sol";
import "./TestHyperCreatePair.t.sol";
import "./TestHyperCreatePool.t.sol";
import "./TestHyperDeposit.t.sol";
import "./TestHyperDraw.t.sol";
import "./TestHyperFund.t.sol";
import "./TestHyperSwap.t.sol";
import "./TestHyperUnallocate.t.sol";

contract TestRMM01 is
    TestHyperAllocate,
    TestHyperChangeParameters,
    TestHyperCreatePair,
    TestHyperCreatePool,
    TestHyperDeposit,
    TestHyperDraw,
    TestHyperFund,
    TestHyperSwap,
    TestHyperUnallocate
{
    function setUp() public override {
        super.setUp();

        // todo: Update this when each portfolio exists. Right now, default portfolio is RMM01.
        // address new_subject = address(new CCPortfolio(address(subjects().weth)));
        // subjects().change_subject(new_subject);
    }
}
