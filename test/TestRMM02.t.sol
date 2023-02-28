// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "contracts/RMM02Portfolio.sol";

import "./Setup.sol";
import "./TestHyperAllocate.t.sol";

contract TestRMM02 is TestHyperAllocate {
    function setUp() public override {
        super.setUp();

        address new_subject = address(new RMM02Portfolio(address(subjects().weth)));

        subjects().change_subject(new_subject);
    }
}
