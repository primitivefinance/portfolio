// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioSetProtocolFee is Setup {
    function test_setProtocolFee_reverts_not_controller()
        public
        defaultConfig
    {
        vm.expectRevert(Portfolio_NotController.selector);
        subject().setProtocolFee(1);
    }

    function test_setProtocolFee_reverts_invalid_protocol_fee()
        public
        defaultConfig
        useRegistryController
    {
        vm.expectRevert(
            abi.encodeWithSelector(Portfolio_InvalidProtocolFee.selector, 1000)
        );

        subject().setProtocolFee(1000);
    }

    function test_setProtocolFee() public useRegistryController {
        uint256 prev = subject().protocolFee();
        subject().setProtocolFee(4);
        uint256 post = subject().protocolFee();
        assertTrue(prev != post, "protocol fee not changed");
        assertEq(post, 4, "protocol fee not set");
    }
}
