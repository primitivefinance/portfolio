// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestE2ESetup.sol";
import "./setup/TestInvariantSetup.sol";

import {InvariantAllocate} from "./InvariantAllocate.sol";

contract TestE2EInvariant is TestInvariantSetup, TestE2ESetup {
    InvariantAllocate internal _allocate;

    function setUp() public override {
        super.setUp();

        _allocate = new InvariantAllocate(address(__hyper__), address(__asset__), address(__quote__));

        addTargetContract(address(_allocate));
    }

    function invariant_global_account() public {
        (bool prepared, bool settled) = __hyper__.__account__();
        assertTrue(!prepared, "invariant-prepared");
        assertTrue(settled, "invariant-settled");
    }
}
