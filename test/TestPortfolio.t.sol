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

    function test_encode_pool_id() public {
        bool controlled = true;
        bool altered = true;
        uint24 pairId = 2;
        uint32 poolNonce = 1;

        uint64 encoded =
            PoolIdLib.encode(controlled, altered, pairId, poolNonce);

        uint64 poolId_ = uint64(bytes8(hex"1100000200000001"));
        assertEq(encoded, poolId_, "pool id");
        assertEq(PoolId.wrap(poolId_).altered(), altered, "altered-method");
        assertEq(
            PoolId.wrap(poolId_).controlled(), controlled, "controlled-method"
        );
        assertEq(PoolId.wrap(poolId_).nonce(), uint32(encoded), "pool-nonce");
        assertEq(uint32(encoded), poolNonce, "pool nonce");
        assertEq(uint24(encoded >> 32), pairId, "pair id");
        assertEq(uint8(encoded >> 56), 0x11, "controlled and altered");
        assertEq(
            uint8(bytes1(bytes1(uint8(encoded >> 56)) & 0x0f)),
            controlled ? 1 : 0,
            "controlled"
        );
        assertEq(uint8(encoded >> 60), altered ? 1 : 0, "altered");
    }

    function test_pair_id_encode() public {
        bool controlled = true;
        bool altered = true;
        uint24 pairId = 2;
        uint32 poolNonce = 1;

        uint64 encoded =
            PoolIdLib.encode(controlled, altered, pairId, poolNonce);

        assertEq(uint24(encoded >> 32), pairId, "pair id");

        uint24 expected = PoolId.wrap(encoded).pairId();
        assertEq(expected, uint24(encoded >> 32), "pair id method");
    }
}
