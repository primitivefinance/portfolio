// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioClaimFee is Setup {
    function test_claimFee_reverts_portfolio_not_controller()
        public
        defaultConfig
        useActor
        usePairTokens(100 ether)
    {
        vm.expectRevert(Portfolio_NotController.selector);

        // Default config uses the 0 address for the controller. This is being called from actor().
        subject().claimFee(address(1), 1);
    }

    function test_claimFee_not_max()
        public
        defaultConfig
        setProtocolFee(4) // sets protocol fee so fees are generated
        useRegistryController
        usePairTokens(100 ether)
        allocateSome(1 ether)
        swapSome(0.01 ether, true) // swaps some assets, generating protocol fees
    {
        uint256 feeAmount = uint256(
            0.01 ether * global_config().feeBasisPoints / BASIS_POINT_DIVISOR
        ) / subject().protocolFee();
        subject().claimFee(ghost().asset().to_addr(), feeAmount--);
    }

    function test_claimFee_max()
        public
        defaultConfig
        setProtocolFee(4) // sets protocol fee so fees are generated
        useRegistryController
        usePairTokens(100 ether)
        allocateSome(1 ether)
        swapSome(0.01 ether, true) // swaps some assets, generating protocol fees
    {
        // swap input * fee / basis point divisor / protocol fee proportion
        uint256 feeAmount = uint256(
            0.01 ether * global_config().feeBasisPoints / BASIS_POINT_DIVISOR
        ) / subject().protocolFee();

        uint256 prev = ghost().asset().to_token().balanceOf(actor());
        subject().claimFee(ghost().asset().to_addr(), type(uint256).max);
        uint256 post = ghost().asset().to_token().balanceOf(actor());
        assertEq(post, prev + feeAmount, "max not claimed");
    }
}
