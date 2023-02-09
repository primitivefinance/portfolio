// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Vm.sol";
import "./setup/TestHyperSetup.sol";

contract TestHyperCreatePair is TestHyperSetup {
    function testCreatePairExternal() public {
        __hyperTestingContract__.createPair(
            address(__usdc__),
            address(__token_18__)
        );
    }
}
