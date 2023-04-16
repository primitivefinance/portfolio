// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioFund is Setup {
    struct FundGhostVariables {
        uint256 userAddressBalance;
        uint256 userSubjectBalance;
        uint256 subjectReserveBalance;
        uint256 subjectActualBalance;
    }

    /* function test_fund_increases_user_balance() public defaultConfig isArmed {
        uint256 amt = 1 ether;
        address tkn = ghost().asset().to_addr();
        ghost().asset().prepare(address(this), address(subject()), amt);
        uint256 prev = ghost().balance(address(this), tkn);
        subject().fund(tkn, amt);
        uint256 post = ghost().balance(address(this), tkn);
        assertEq(post, prev + amt, "did-not-increase-balance");
    } */

    /* function test_fund_max_balance() public defaultConfig isArmed {
        uint256 amt = 10 ether;
        address tkn = ghost().asset().to_addr();
        ghost().asset().prepare(address(this), address(subject()), amt);
        uint256 prev = ghost().balance(address(this), tkn);
        subject().fund(tkn, amt);
        uint256 post = ghost().balance(address(this), tkn);
        assertEq(post, prev + amt, "did-not-increase-balance");
    } */

    /* function testFuzz_fund_then_draw(uint64 amt) public defaultConfig isArmed {
        vm.assume(amt > 0);

        // Prepare the token and give this contract a balanc and approve subject().
        ghost().asset().prepare(address(this), address(subject()), amt);

        // Store ghost variables
        FundGhostVariables memory ghost_state_prev = FundGhostVariables({
            userAddressBalance: ghost().asset().to_token().balanceOf(address(this)),
            userSubjectBalance: ghost().balance(
                address(this), ghost().asset().to_addr()
                ),
            subjectReserveBalance: ghost().reserve(ghost().asset().to_addr()),
            subjectActualBalance: ghost().asset().to_token().balanceOf(
                address(subject())
                )
        });

        // Fund the account.
        subject().fund(ghost().asset().to_addr(), amt);

        // Store the variables after funding.
        FundGhostVariables memory ghost_state_post = FundGhostVariables({
            userAddressBalance: ghost().asset().to_token().balanceOf(address(this)),
            userSubjectBalance: ghost().balance(
                address(this), ghost().asset().to_addr()
                ),
            subjectReserveBalance: ghost().reserve(ghost().asset().to_addr()),
            subjectActualBalance: ghost().asset().to_token().balanceOf(
                address(subject())
                )
        });

        // Check to make sure balances increased.
        assertEq(
            ghost_state_post.userAddressBalance,
            ghost_state_prev.userAddressBalance - amt,
            "user-addr-balance-post"
        );
        assertEq(
            ghost_state_post.userSubjectBalance,
            ghost_state_prev.userSubjectBalance + amt,
            "user-subj-balance-post"
        );
        assertEq(
            ghost_state_post.subjectReserveBalance,
            ghost_state_prev.subjectReserveBalance + amt,
            "subj-reserve-balance-post"
        );
        assertEq(
            ghost_state_post.subjectActualBalance,
            ghost_state_prev.subjectActualBalance + amt,
            "subj-actual-balance-post"
        );

        // Max draw tokens.
        subject().draw(
            ghost().asset().to_addr(), type(uint256).max, address(this)
        );

        // Get final variables.
        FundGhostVariables memory ghost_state_final = FundGhostVariables({
            userAddressBalance: ghost().asset().to_token().balanceOf(address(this)),
            userSubjectBalance: ghost().balance(
                address(this), ghost().asset().to_addr()
                ),
            subjectReserveBalance: ghost().reserve(ghost().asset().to_addr()),
            subjectActualBalance: ghost().asset().to_token().balanceOf(
                address(subject())
                )
        });

        // Ghost assertions.
        assertEq(
            ghost_state_final.userAddressBalance,
            ghost_state_prev.userAddressBalance,
            "user-addr-balance-final"
        );
        assertEq(
            ghost_state_final.userSubjectBalance,
            ghost_state_prev.userSubjectBalance,
            "user-subj-balance-final"
        );
        assertEq(
            ghost_state_final.subjectReserveBalance,
            ghost_state_prev.subjectReserveBalance,
            "subj-reserve-balance-final"
        );
        assertEq(
            ghost_state_final.subjectActualBalance,
            ghost_state_prev.subjectActualBalance,
            "subj-actual-balance-final"
        );
    } */
}
