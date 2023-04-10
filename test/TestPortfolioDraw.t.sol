// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioDraw is Setup {
    modifier fund(uint256 amt) {
        ghost().asset().prepare(address(this), address(subject()), amt);
        subject().fund(ghost().asset().to_addr(), amt);
        _;
    }

    function test_draw_reduces_user_balance()
        public
        defaultConfig
        useActor
        fund(1 ether)
        isArmed
    {
        uint256 prev = ghost().balance(address(this), ghost().asset().to_addr());

        address[] memory tokens = new address[](1);
        tokens[0] = ghost().asset().to_addr();

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        subject().draw(tokens, amounts, address(this));
        uint256 post = ghost().balance(address(this), ghost().asset().to_addr());
        assertTrue(post < prev, "non-decreasing-balance");
        assertEq(post, prev - 1 ether, "post-balance");
    }

    function test_revert_draw_greater_than_balance()
        public
        defaultConfig
        useActor
        isArmed
    {
        address tkn = ghost().asset().to_addr();
        vm.expectRevert(DrawBalance.selector);

        address[] memory tkns = new address[](1);
        tkns[0] = tkn;

        uint256[] memory amts = new uint256[](1);
        amts[0] = 1 ether;
        subject().draw(tkns, amts, address(this));
    }

    function test_draw_weth_transfers_ether() public useActor {
        uint256 amt = 1 ether;
        subject().deposit{value: amt}();
        uint256 prev = address(this).balance;

        address[] memory tokens = new address[](1);
        tokens[0] = subject().WETH();

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amt;

        subject().draw(tokens, amounts, address(this));
        uint256 post = address(this).balance;
        assertEq(post, prev + amt, "post-balance");
        assertTrue(post > prev, "draw-did-not-increase-balance");
    }

    function test_draw_max_balance()
        public
        defaultConfig
        useActor
        fund(1 ether)
        isArmed
    {
        uint256 prev = ghost().balance(address(this), ghost().asset().to_addr());

        address[] memory tokens = new address[](1);
        tokens[0] = ghost().asset().to_addr();

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = type(uint256).max;

        subject().draw(tokens, amounts,  address(this));
        uint256 post = ghost().balance(address(this), ghost().asset().to_addr());
        assertEq(post, prev - 1 ether, "did-not-draw-max");
    }
}
