// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolio is Setup {
    uint256 constant LOCKED_SLOT = 12; // `$ forge inspect Portfolio storageLayout`

    function test_reverts_invalid_reentrancy() public {
        // Set the locked variable to != 1.
        vm.store(address(subject()), bytes32(LOCKED_SLOT), bytes32(uint256(2)));
        vm.expectRevert(Portfolio_InvalidReentrancy.selector);
        subject().allocate(false, address(this), ghost().poolId, 1 ether, 0, 0);
    }
}
