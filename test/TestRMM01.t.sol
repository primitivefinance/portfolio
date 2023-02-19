// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./Setup.sol";
import "./TestHyperAllocate.t.sol";

contract TestRMM01 is TestHyperAllocate {
    function setUp() public override {
        super.setUp();

        // todo: Update this when each portfolio exists. Right now, default portfolio is RMM01.
        // address new_subject = address(new CCPortfolio(address(subjects().weth)));
        // subjects().change_subject(new_subject);
    }
}
