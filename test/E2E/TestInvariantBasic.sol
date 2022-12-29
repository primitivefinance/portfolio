// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./setup/TestInvariantSetup.sol";

/** @dev Example invariant testing contract, for reference only. */
contract InvariantBreaker {
    bool public flag0 = true;
    bool public flag1 = true;

    function set0(int val) public returns (bool) {
        if (val % 100 == 0) flag0 = false;
        return flag0;
    }

    function set1(int val) public returns (bool) {
        if (val % 10 == 0 && !flag0) flag1 = false;
        return flag1;
    }
}

/** @dev Example invariant test. */
contract TestInvariantBasic is TestInvariantSetup, Test {
    InvariantBreaker inv;

    function setUp() public {
        inv = new InvariantBreaker();
        addTargetContract(address(inv));
    }

    function invariant_neverFalse() public {
        require(inv.flag1());
    }
}
