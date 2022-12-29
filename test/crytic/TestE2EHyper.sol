// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/* import "./setup/TestEchidnaSetup.sol"; */

contract TestE2EHyper {
    event AssertionFailed();

    function echidna_jit_policy() public returns (bool) {
        if (5 != 4) emit AssertionFailed();
    }
}
