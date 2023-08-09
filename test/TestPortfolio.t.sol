// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";
import "../contracts/libraries/SafeTransferLib.sol" as TransferLib;

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
            PoolIdLib.encode(altered, controlled, pairId, poolNonce);

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

    function test_encode_pool_id_altered_not_controlled() public {
        bool altered = true;
        bool controlled = false;
        uint24 pairId = 2;
        uint32 poolNonce = 1;

        uint64 encoded =
            PoolIdLib.encode(altered, controlled, pairId, poolNonce);

        assertEq(PoolId.wrap(encoded).altered(), altered, "altered-method");
        assertEq(
            PoolId.wrap(encoded).controlled(), controlled, "controlled-method"
        );
        assertEq(uint8(encoded >> 56), 0x10, "first byte");
        assertEq(
            uint8(bytes1(bytes1(uint8(encoded >> 56)) & 0x0f)),
            controlled ? 1 : 0,
            "controlled"
        );
        assertEq(uint8(encoded >> 60), altered ? 1 : 0, "altered");
    }

    function test_encode_pool_id_not_altered_controlled() public {
        bool altered = false;
        bool controlled = true;
        uint24 pairId = 2;
        uint32 poolNonce = 1;

        uint64 encoded =
            PoolIdLib.encode(altered, controlled, pairId, poolNonce);

        assertEq(PoolId.wrap(encoded).altered(), altered, "altered-method");
        assertEq(
            PoolId.wrap(encoded).controlled(), controlled, "controlled-method"
        );
        assertEq(uint8(encoded >> 56), 0x01, "first byte");
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

    address internal _malicious;

    modifier makeMaliciousToken() {
        _malicious = address(new MaliciousReentrancyToken());
        _;
    }

    /// @dev To set this test up, we need to inject a single-call re-entrancy
    /// using the `transferFrom` function on a malicious token.
    /// This will get triggered during settlement.
    /// multicall
    ///     preLock()
    ///         allocate()
    ///     postLock()
    ///     settlement()
    ///        transferFrom()
    ///            multicall()
    ///                preLock()
    /// ...             should revert here.
    function test_reentrancy_duing_multicall_settlement()
        public
        makeMaliciousToken
        customTokenConfig(true, _malicious)
        useActor
        usePairTokens(100 ether)
    {
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                ghost().poolId,
                1 ether, // make sure we can provide enough liquidity...
                type(uint128).max,
                type(uint128).max
            )
        );

        // Send some tokens to the malicious token contract so it can allocate...
        ghost().asset().to_token().transfer(_malicious, 25 ether);
        ghost().quote().to_token().transfer(_malicious, 25 ether);

        IPortfolio subject_ = subject();

        // The call originally reverts with `Portfolio_InvalidInvariant`, however...
        // because the external call was `safeTransferFrom`, the revert is caught
        // and the `TokenTransferFrom` error is thrown instead.
        // Pass the -vvv flag to the test command to see the revert message.
        // forge test -vvv --match-test test_reentrancy_duing_multicall_settlement
        vm.expectRevert(TransferLib.TokenTransferFrom.selector);
        subject_.multicall(instructions);
    }
}

contract MaliciousReentrancyToken is ERC20, ERC1155TokenReceiver {
    constructor() ERC20("MaliciousReentrancy", "MUTEX", 18) {
        if (block.chainid == 1) revert("bad");
    }

    uint64 internal _poolId;

    function set(uint64 poolId) external {
        _poolId = poolId;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @dev Malicious re-entrancy in untrusted & dangerous `transferFrom` call in settlement.
    /// Portfolio.settlement
    ///    this.transferFrom()
    ///        msg.sender.multicall()
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        // Re-enter here.
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (
                false,
                address(this),
                _poolId,
                1 ether, // make sure we can provide enough liquidity...
                type(uint128).max,
                type(uint128).max
            )
        );

        // Re-enter with multicall!
        IPortfolio(msg.sender).multicall(instructions);

        // Call the regular logic..
        super.transferFrom(from, to, amount);
        return true;
    }
}
