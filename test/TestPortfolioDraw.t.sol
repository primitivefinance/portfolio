// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioDraw is Setup {
    modifier fund(uint256 amt) {
        ghost().asset().prepare(address(this), address(subject()), amt);
        subject().fund(ghost().asset().to_addr(), amt);
        _;
    }

    /* function test_draw_reduces_user_balance()
        public
        defaultConfig
        useActor
        fund(1 ether)
        isArmed
    {
        uint256 prev = ghost().balance(address(this), ghost().asset().to_addr());
        subject().draw(ghost().asset().to_addr(), 1 ether, address(this));
        uint256 post = ghost().balance(address(this), ghost().asset().to_addr());
        assertTrue(post < prev, "non-decreasing-balance");
        assertEq(post, prev - 1 ether, "post-balance");
    } */

    function test_revert_draw_greater_than_balance()
        public
        defaultConfig
        useActor
        isArmed
    {
        address tkn = ghost().asset().to_addr();
        vm.expectRevert(DrawBalance.selector);
        subject().draw(tkn, 1 ether, address(this));
    }

    /*  function test_draw_weth_transfers_ether() public useActor {
        uint256 amt = 1 ether;
        subject().deposit{value: amt}();
        uint256 prev = address(this).balance;
        subject().draw(subject().WETH(), amt, address(this));
        uint256 post = address(this).balance;
        assertEq(post, prev + amt, "post-balance");
        assertTrue(post > prev, "draw-did-not-increase-balance");
    } */

    /* function test_draw_max_balance()
        public
        defaultConfig
        useActor
        fund(1 ether)
        isArmed
    {
        uint256 prev = ghost().balance(address(this), ghost().asset().to_addr());
        subject().draw(
            ghost().asset().to_addr(), type(uint256).max, address(this)
        );
        uint256 post = ghost().balance(address(this), ghost().asset().to_addr());
        assertEq(post, prev - 1 ether, "did-not-draw-max");
    } */
}
