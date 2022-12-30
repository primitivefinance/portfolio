// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/TestE2ESetup.sol";
import "./setup/TestInvariantSetup.sol";

import {InvariantAllocateUnallocate} from "./InvariantAllocateUnallocate.sol";
import {InvariantFundDraw} from "./InvariantFundDraw.sol";
import {InvariantDeposit} from "./InvariantDeposit.sol";
import {InvariantSendTokens} from "./InvariantSendTokens.sol";

bytes32 constant SLOT_LOCKED = bytes32(uint(5));

/**
 * @dev Most important test suite, verifies the critical invariants of Hyper.
 *
 * Invariant 1. balanceOf >= getReserve for all tokens.
 * Invariant 2. AccountSystem.settled == true.
 * Invariant 3. AccountSystem.prepared == false.
 * Invariant 4. (balanceOf(asset), balanceOf(quote)) >= hyper.getVirtualReserves, for all pools.
 * Invariant 5. ∑ hyper.positions(owner, poolId).totalLiquidity == hyper.pools(poolId).liquidity, for all pools.
 */
contract TestE2EInvariant is TestInvariantSetup, TestE2ESetup {
    InvariantAllocateUnallocate internal _allocateUnallocate;
    InvariantFundDraw internal _fundDraw;
    InvariantDeposit internal _deposit;
    InvariantSendTokens internal _sendTokens;

    function setUp() public override {
        super.setUp();

        (address hyper, address asset, address quote) = (address(__hyper__), address(__asset__), address(__quote__));

        _allocateUnallocate = new InvariantAllocateUnallocate(hyper, asset, quote);
        _fundDraw = new InvariantFundDraw(hyper, asset, quote);
        _deposit = new InvariantDeposit(hyper, asset, quote);
        _sendTokens = new InvariantSendTokens(hyper, asset, quote);

        addTargetContract(address(_allocateUnallocate));
        addTargetContract(address(_fundDraw));
        addTargetContract(address(_deposit));
        addTargetContract(address(_sendTokens));

        __users__.push(address(_allocateUnallocate));
        __users__.push(address(_fundDraw));
        __users__.push(address(_deposit));
        __users__.push(address(_sendTokens));
    }

    function invariant_asset_balance_gte_reserves() public {
        (uint reserve, uint physical, ) = getBalances(address(__asset__));
        assertTrue(physical >= reserve, "invariant-asset-physical-balance");
    }

    function invariant_quote_balance_gte_reserves() public {
        (uint reserve, uint physical, ) = getBalances(address(__quote__));
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

    event log(string, uint);

    function invariant_virtual_pool_asset_reserves() public {
        HyperPool memory pool = getPool(address(__hyper__), __poolId__);
        emit log("liq", pool.liquidity);
        (uint a, uint b) = __hyper__.getAllocateAmounts(__poolId__, pool.liquidity);
        emit log("a", a);
        emit log("b", b);

        (uint dAsset, uint dQuote) = __hyper__.getVirtualReserves(__poolId__);
        emit log("dAsset", dAsset);
        emit log("dQuote", dQuote);

        uint bAsset = getPhysicalBalance(address(__hyper__), address(__asset__));
        uint bQuote = getPhysicalBalance(address(__hyper__), address(__quote__));

        emit log("bAsset", bAsset);
        emit log("bQuote", bQuote);
        assertTrue(bAsset >= dAsset, "invariant-virtual-reserves-asset");
    }

    function invariant_virtual_pool_quote_reserves() public {
        HyperPool memory pool = getPool(address(__hyper__), __poolId__);
        emit log("liq", pool.liquidity);
        (uint a, uint b) = __hyper__.getAllocateAmounts(__poolId__, pool.liquidity);
        emit log("a", a);
        emit log("b", b);

        (uint dAsset, uint dQuote) = __hyper__.getVirtualReserves(__poolId__);
        emit log("dAsset", dAsset);
        emit log("dQuote", dQuote);

        uint bAsset = getPhysicalBalance(address(__hyper__), address(__asset__));
        uint bQuote = getPhysicalBalance(address(__hyper__), address(__quote__));

        emit log("bAsset", bAsset);
        emit log("bQuote", bQuote);
        assertTrue(bQuote >= dQuote, "invariant-virtual-reserves-quote");
    }

    function invariant_liquidity_sum() public {
        HyperPool memory pool = getPool(address(__hyper__), __poolId__);

        uint sum;
        for (uint i; i != __users__.length; ++i) {
            HyperPosition memory pos = getPosition(address(__hyper__), __users__[i], __poolId__);
            sum += pos.totalLiquidity;
        }

        assertTrue(sum == pool.liquidity, "invariant-liquidity-sum");
    }

    function invariant_reentrancy() public {
        bytes32 locked = vm.load(address(__hyper__), SLOT_LOCKED);
        assertEq(uint(locked), 1, "invariant-locked");

        uint balance = address(__hyper__).balance;
        assertEq(balance, 0, "invariant-ether");
    }

    function getBalances(address token) internal view returns (uint reserve, uint physical, uint balances) {
        reserve = getReserve(address(__hyper__), token);
        physical = getPhysicalBalance(address(__hyper__), token);
        balances = getBalanceSum(address(__hyper__), token, users());
    }
}
