// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/GeometricPortfolio.sol";

import "./Setup.sol";
import "./TestHyperAllocate.t.sol";

contract TestRMM01 is TestHyperAllocate {
    function setUp() public override {
        super.setUp();

        address new_subject = address(new GeometricPortfolio(address(subjects().weth)));

        subjects().change_subject(new_subject);
    }
}
