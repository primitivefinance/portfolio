// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestE2ESetup.sol";
import "./setup/TestInvariantSetup.sol";

import {InvariantAllocateUnallocate} from "./InvariantAllocateUnallocate.sol";
import {InvariantFundDraw} from "./InvariantFundDraw.sol";
import {InvariantDeposit} from "./InvariantDeposit.sol";
import {InvariantSendTokens} from "./InvariantSendTokens.sol";
import {InvariantWarper} from "./InvariantWarper.sol";
import {InvariantCreatePool} from "./InvariantCreatePool.sol";

bytes32 constant SLOT_LOCKED = bytes32(uint256(10));

/**
 * @dev Most important test suite, verifies the critical invariants of Hyper.
 *
 * Invariant 1. balanceOf >= getReserve for all tokens.
 * Invariant 2. AccountSystem.settled == true.
 * Invariant 3. AccountSystem.prepared == false.
 * Invariant 4. (balanceOf(asset), balanceOf(quote)) >= hyper.getVirtualReserves, for all pools.
 * Invariant 5. ∑ hyper.positions(owner, poolId).freeLiquidity == hyper.pools(poolId).liquidity, for all pools.
 */
contract TestE2EInvariant is TestInvariantSetup, TestE2ESetup {
    InvariantAllocateUnallocate internal _allocateUnallocate;
    InvariantFundDraw internal _fundDraw;
    InvariantDeposit internal _deposit;
    InvariantSendTokens internal _sendTokens;
    InvariantWarper internal _warper;
    InvariantCreatePool internal _createPool;

    uint64[] public __poolIds__;

    function setUp() public override {
        super.setUp();

        (address hyper, address asset, address quote) = (address(__hyper__), address(__asset__), address(__quote__));

        _allocateUnallocate = new InvariantAllocateUnallocate(hyper, asset, quote);
        _fundDraw = new InvariantFundDraw(hyper, asset, quote);
        _deposit = new InvariantDeposit(hyper, asset, quote);
        _sendTokens = new InvariantSendTokens(hyper, asset, quote);
        _warper = new InvariantWarper(hyper, asset, quote);
        _createPool = new InvariantCreatePool(hyper, asset, quote);

        targetContract(address(_allocateUnallocate));
        targetContract(address(_fundDraw));
        targetContract(address(_deposit));
        targetContract(address(_sendTokens));
        targetContract(address(_warper));
        targetContract(address(_createPool));

        __users__.push(address(_allocateUnallocate));
        __users__.push(address(_fundDraw));
        __users__.push(address(_deposit));
        __users__.push(address(_sendTokens));
        __users__.push(address(_warper));
        __users__.push(address(_createPool));

        addPoolId(__poolId__);
    }

    function invariant_assert_pools_created() public {
        assertTrue(__poolIds__.length > 0);
    }

    function invariant_asset_balance_gte_reserves() public {
        (uint256 reserve, uint256 physical, ) = getBalances(address(__asset__));
        assertTrue(physical >= reserve, "invariant-asset-physical-balance");
    }

    function invariant_quote_balance_gte_reserves() public {
        (uint256 reserve, uint256 physical, ) = getBalances(address(__quote__));
        assertTrue(physical >= reserve, "invariant-quote-physical-balance");
    }

    function invariant_account_settled() public {
        (, bool settled) = __hyper__.__account__();
        assertTrue(settled, "invariant-settled");
    }

    function invariant_account_prepared() public {
        (bool prepared, ) = __hyper__.__account__();
        assertTrue(!prepared, "invariant-prepared");
    }

    function invariant_virtual_pool_asset_reserves() public {
        HyperPool memory pool = getPool(address(__hyper__), __poolId__);

        if (pool.liquidity > 0) {
            (uint256 dAsset, ) = __hyper__.getVirtualReserves(__poolId__);
            uint256 bAsset = getPhysicalBalance(address(__hyper__), address(__asset__));
            assertTrue(bAsset >= dAsset, "invariant-virtual-reserves-asset");
        }
    }

    function invariant_virtual_pool_quote_reserves() public {
        HyperPool memory pool = getPool(address(__hyper__), __poolId__);

        if (pool.liquidity > 0) {
            (, uint256 dQuote) = __hyper__.getVirtualReserves(__poolId__);
            uint256 bQuote = getPhysicalBalance(address(__hyper__), address(__quote__));
            assertTrue(bQuote >= dQuote, "invariant-virtual-reserves-quote");
        }
    }

    function invariant_liquidity_sum() public {
        HyperPool memory pool = getPool(address(__hyper__), __poolId__);

        uint256 sum;
        for (uint256 i; i != __users__.length; ++i) {
            HyperPosition memory pos = getPosition(address(__hyper__), __users__[i], __poolId__);
            sum += pos.freeLiquidity;
        }

        assertTrue(sum == pool.liquidity, "invariant-liquidity-sum");
    }

    function invariant_reentrancy() public {
        bytes32 locked = vm.load(address(__hyper__), SLOT_LOCKED);
        assertEq(uint256(locked), 1, "invariant-locked");

        uint256 balance = address(__hyper__).balance;
        assertEq(balance, 0, "invariant-ether");
    }

    function getBalances(address token) internal view returns (uint256 reserve, uint256 physical, uint256 balances) {
        reserve = getReserve(address(__hyper__), token);
        physical = getPhysicalBalance(address(__hyper__), token);
        balances = getBalanceSum(address(__hyper__), token, __users__);
    }

    function addPoolId(uint64 poolId) public {
        assertTrue(poolId != 0, "zero poolId");
        __poolIds__.push(poolId);
    }

    function getRandomUser(uint256 id) public returns (address) {
        assertTrue(__users__.length > 0);
        uint256 index = id % __users__.length;
        address user = __users__[index];
        return user;
    }

    function getRandomPoolId(uint256 id) public returns (uint64) {
        assertTrue(__poolIds__.length > 0);
        uint256 index = id % __poolIds__.length;
        uint64 poolId = __poolIds__[index];
        return poolId;
    }
}
