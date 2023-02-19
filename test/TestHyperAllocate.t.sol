// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./Setup.sol";

contract TestHyperAllocate is Setup {
    function test_allocate_modifies_pool_liquidity() public defaultConfig useActor isArmed {
        // Approve and mint tokens for actor.
        ghost().asset().prepare({owner: actor(), spender: address(subject()), amount: 10 ether});
        ghost().quote().prepare({owner: actor(), spender: address(subject()), amount: 10 ether});
        // Arguments for test.
        uint amount = 0.1 ether;
        // Fetch the ghost variables to interact with the target pool.
        uint64 xid = ghost().poolId;
        // Fetch the variable we are changing (pool.liquidity).
        uint prev = ghost().pool().liquidity;
        // Trigger the function being tested.
        subject().allocate({poolId: xid, amount: amount});
        // Fetch the variable changed.
        uint post = ghost().pool().liquidity;
        // Ghost assertions comparing the actual and expected deltas.
        assertEq(post, prev + amount, "pool.liquidity");
        // Direct assertions of pool state.
        assertEq(
            ghost().pool().liquidity,
            ghost().position(actor()).freeLiquidity,
            "position.freeLiquidity != pool.liquidity"
        );
    }
}
