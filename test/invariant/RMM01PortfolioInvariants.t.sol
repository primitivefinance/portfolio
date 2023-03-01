// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../Setup.sol";
import "./HelperInvariantLib.sol";

import {HandlerHyper} from "./HandlerHyper.sol";
import {HandlerExternal} from "./HandlerExternal.sol";

bytes32 constant SLOT_LOCKED = bytes32(uint256(10));

interface AccountLike {
    function __account__() external view returns (bool);
}

/**
 * @dev Most important test suite, verifies the critical invariants of Hyper.
 *
 * Invariant 1. balanceOf >= getReserve for all tokens.
 * Invariant 2. AccountSystem.settled == true.
 * Invariant 3. AccountSystem.prepared == false.
 * Invariant 4. (balanceOf(asset), balanceOf(quote)) >= hyper.getVirtualReserves, for all pools.
 * Invariant 5. ∑ hyper.positions(owner, poolId).freeLiquidity == hyper.pools(poolId).liquidity, for all pools.
 */
contract RMM01PortfolioInvariants is Setup {
    /**
     * @dev Helper to manage the pools that are being interacted with via the handlers.
     */
    InvariantGhostState private _ghostInvariant;

    HandlerHyper internal _hyper;
    HandlerExternal internal _external;

    function setUp() public override {
        super.setUp();

        _hyper = new HandlerHyper();

        {
            bytes4[] memory selectors = new bytes4[](6);
            selectors[0] = HandlerHyper.deposit.selector;
            selectors[1] = HandlerHyper.fund_asset.selector;
            selectors[2] = HandlerHyper.fund_quote.selector;
            selectors[3] = HandlerHyper.create_pool.selector;
            selectors[4] = HandlerHyper.allocate.selector;
            selectors[5] = HandlerHyper.unallocate.selector;
            targetSelector(FuzzSelector({addr: address(_hyper), selectors: selectors}));
            targetContract(address(_hyper));
        }

        // Create default pool, used in handlers via `usePool(uint)` modifier.
        uint64 poolId = Configs
            .fresh()
            .edit("asset", abi.encode(address(subjects().tokens[0])))
            .edit("quote", abi.encode(address(subjects().tokens[1])))
            .generate(address(subject()));

        setGhostPoolId(poolId);
    }

    function addGhostPoolId(uint64 poolId) public virtual {
        _ghostInvariant.add(poolId);
    }

    function setGhostPoolId(uint64 poolId) public override {
        super.setGhostPoolId(poolId);
        addGhostPoolId(poolId);
    }

    // ===== Invariants ===== //

    function invariant_asset_balance_gte_reserves() public {
        (uint256 reserve, uint256 physical, ) = getBalances(ghost().asset().to_addr());
        assertTrue(physical >= reserve, "invariant-asset-physical-balance");
    }

    function invariant_quote_balance_gte_reserves() public {
        (uint256 reserve, uint256 physical, ) = getBalances(ghost().quote().to_addr());
        assertTrue(physical >= reserve, "invariant-quote-physical-balance");
    }

    function invariant_account_settled() public {
        bool settled = AccountLike(address(subject())).__account__();
        assertTrue(settled, "invariant-settled");
    }

    function invariant_virtual_pool_asset_reserves() public {
        HyperPool memory pool = ghost().pool();

        if (pool.liquidity > 0) {
            (uint256 dAsset, ) = subject().getReserves(ghost().poolId);
            uint256 bAsset = ghost().physicalBalance(ghost().asset().to_addr());
            assertTrue(bAsset >= dAsset, "invariant-virtual-reserves-asset");
        }
    }

    function invariant_virtual_pool_quote_reserves() public {
        HyperPool memory pool = ghost().pool();

        if (pool.liquidity > 0) {
            (, uint256 dQuote) = subject().getReserves(ghost().poolId);
            uint256 bQuote = ghost().physicalBalance(ghost().quote().to_addr());
            assertTrue(bQuote >= dQuote, "invariant-virtual-reserves-quote");
        }
    }

    function invariant_liquidity_sum() public {
        HyperPool memory pool = ghost().pool();

        uint256 sum;
        for (uint256 i; i != actors().active.length; ++i) {
            HyperPosition memory pos = ghost().position(actors().active[i]);
            sum += pos.freeLiquidity;
        }

        assertTrue(sum == pool.liquidity, "invariant-liquidity-sum");
    }

    function invariant_reentrancy() public {
        bytes32 locked = vm.load(address(subject()), SLOT_LOCKED);
        assertEq(uint256(locked), 1, "invariant-locked");

        uint256 balance = address(subject()).balance;
        assertEq(balance, 0, "invariant-ether");
    }

    function invariant_callSummary() public view {
        console.log("Call summary:");
        console.log("-------------------");
        _hyper.callSummary();
        console.log("pools created", getPoolIds().length);
    }

    // ===== Helpers ===== //

    function ghost_invariant() internal virtual returns (InvariantGhostState storage) {
        return _ghostInvariant;
    }

    function lastPoolId() public view virtual returns (uint64) {
        return _ghostInvariant.last;
    }

    function getPoolIds() public view virtual returns (uint64[] memory) {
        return _ghostInvariant.poolIds;
    }

    function getRandomPoolId(uint index) public view virtual returns (uint64) {
        return _ghostInvariant.rand(index);
    }

    function getBalances(address token) internal view returns (uint256 reserve, uint256 physical, uint256 balances) {
        if (ghost().subject != address(0)) {
            reserve = ghost().reserve(token);
            physical = ghost().physicalBalance(token);
            balances = getBalanceSum(token);
        }
    }

    function getBalanceSum(address token) public view virtual returns (uint) {
        address[] memory actors = getActors();
        uint256 sum;
        for (uint256 x; x != actors.length; ++x) {
            sum += ghost().balance(actors[x], token);
        }

        return sum;
    }

    function getPositionsLiquiditySum() public view virtual returns (uint256) {
        address[] memory actors = getActors();
        uint256 sum;
        for (uint256 i; i != actors.length; ++i) {
            sum += ghost().position(actors[i]).freeLiquidity;
        }

        return sum;
    }
}
