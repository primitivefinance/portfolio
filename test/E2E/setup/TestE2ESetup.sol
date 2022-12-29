// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "solmate/tokens/WETH.sol";
import "contracts/EnigmaTypes.sol";
import "contracts/libraries/Price.sol";

import "forge-std/Test.sol";
import {TestERC20, Hyper, HyperTimeOverride, HyperCatchReverts, RevertCatcher, FixedPointMathLib} from "test/helpers/HyperTestOverrides.sol";

import "test/helpers/HelperHyperActions.sol";
import "test/helpers/HelperHyperInvariants.sol";
import "test/helpers/HelperHyperProfiles.sol";
import "test/helpers/HelperHyperView.sol";

uint constant STARTING_BALANCE = 0;
bytes32 constant SLOT_LOCKED = bytes32(uint(5));

struct State {
    uint reserveAsset;
    uint reserveQuote;
    uint physicalBalanceAsset;
    uint physicalBalanceQuote;
    uint totalBalanceAsset;
    uint totalBalanceQuote;
    uint totalPoolLiquidity;
    uint totalPositionLiquidity;
    uint callerPositionLiquidity;
    uint feeGrowthAssetPool;
    uint feeGrowthQuotePool;
    uint feeGrowthAssetPosition;
    uint feeGrowthQuotePosition;
}

/** @dev Deploys test contracts, test tokens, sets labels, funds users, and approves contracts to spend tokens. */
contract TestE2ESetup is HelperHyperActions, HelperHyperInvariants, HelperHyperProfiles, HelperHyperView, Test {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    // ===== Global Variables ===== //
    uint48 public __poolId__ = 0x000100000001;
    address[] public __users__;

    WETH public __weth__;
    TestERC20 public __quote__;
    TestERC20 public __asset__;
    HyperTimeOverride public __hyper__; // Actual contract

    // ===== Set up ===== //

    function setUp() public virtual {
        initContracts();
        initUsers();
        initScenarios();
        initPrerequisites();
        afterSetUp();
    }

    /** Hook to override receive. Defaults to just accepting ether sent to this test contract. */
    receive() external payable {
        receiveOverride();
    }

    /** @dev Hook to run after test setup. */
    function afterSetUp() public virtual {}

    function receiveOverride() public virtual {}

    function initContracts() internal {
        __weth__ = new WETH();
        __hyper__ = new HyperTimeOverride(address(__weth__));
        __quote__ = new TestERC20("USD Coin", "USDC", 6);
        __asset__ = new TestERC20("18 Decimals", "18DEC", 18);

        setLabels();
    }

    function initUsers() internal {
        address self = address(this);
        address alicent = address(0x0001);
        address boba = address(0x0002);

        vm.label(self, "Self");
        vm.label(alicent, "Alicent");
        vm.label(boba, "Boba");

        __users__.push(self);
        __users__.push(alicent);
        __users__.push(boba);
    }

    function initScenarios() internal {
        __hyper__.setTimestamp(uint128(block.timestamp)); // Important
        // Create default pool
        bytes memory data = createPool(
            address(__asset__),
            address(__quote__),
            DEFAULT_SIGMA,
            uint32(block.timestamp) + DEFAULT_MATURITY,
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            DEFAULT_STRIKE,
            DEFAULT_PRICE
        );

        (bool success, ) = address(__hyper__).call(data);
        assertTrue(success, "create pool call failed");
    }

    /** @dev Requires tokens to be spent and spenders to be approved. */
    function initPrerequisites() internal {
        approveTokens();
    }

    /** @dev Does not include weth. */
    function approveTokens() internal {
        for (uint z; z != __users__.length; ++z) {
            vm.prank(__users__[z]); // Sets caller
            __asset__.approve(address(__hyper__), type(uint256).max); // Approves test contracts to spend tokens.
            __quote__.approve(address(__hyper__), type(uint256).max); // Approves test contracts to spend tokens.
        }
    }

    /** @dev Does not include weth. */
    function fundUsers(uint deltaAsset, uint deltaQuote) internal {
        for (uint i; i != __users__.length; ++i) {
            deal(address(__asset__), __users__[i], deltaAsset); // TODO: Use regular ERC20, since we can deal.
            deal(address(__quote__), __users__[i], deltaQuote); // TODO: Use regular ERC20, since we can deal.
        }
    }

    function setLabels() internal {
        vm.label(address(this), "Self");
        vm.label(address(__weth__), "Weth");
        vm.label(address(__hyper__), "HyperTimeOverride");
        vm.label(address(__quote__), "QuoteToken");
        vm.label(address(__asset__), "AssetToken");
    }

    function customWarp(uint time) internal {
        vm.warp(time);
        __hyper__.setTimestamp(uint128(time));
    }

    // ===== Global Invariants ===== //

    modifier withGlobalInvariants() {
        checkGlobalInvariants();
        _;
        checkGlobalInvariants();
    }

    function checkGlobalInvariants() public {
        bytes32 locked = vm.load(address(__hyper__), SLOT_LOCKED);
        assertEq(uint(locked), 1, "invariant-locked");

        (bool prepared, bool settled) = __hyper__.__account__();
        assertTrue(!prepared, "invariant-prepared");
        assertTrue(settled, "invariant-settled");

        uint balance = address(__hyper__).balance;
        assertEq(balance, 0, "invariant-ether");

        (uint reserve, uint physical, uint balances) = getBalances(address(__asset__));
        assertTrue(physical >= reserve + balances, "invariant-asset-physical-balance");

        (reserve, physical, balances) = getBalances(address(__quote__));
        assertTrue(physical >= reserve + balances, "invariant-quite-physical-balance");
    }

    function getState() internal view returns (State memory) {
        // Execution
        uint sumAsset;
        uint sumQuote;
        uint sumPositionLiquidity;
        for (uint i; i != __users__.length; ++i) {
            sumAsset += __hyper__.getBalance(__users__[i], address(__asset__));
            sumQuote += __hyper__.getBalance(__users__[i], address(__quote__));
            sumPositionLiquidity += getPosition(address(__hyper__), __users__[i], __poolId__).totalLiquidity;
        }

        HyperPool memory pool = getPool(address(__hyper__), __poolId__);
        HyperPosition memory position = getPosition(address(__hyper__), address(this), __poolId__);
        uint feeGrowthAssetPool = pool.feeGrowthGlobalAsset;
        uint feeGrowthQuotePool = pool.feeGrowthGlobalQuote;
        uint feeGrowthAssetPosition = position.feeGrowthAssetLast;
        uint feeGrowthQuotePosition = position.feeGrowthQuoteLast;

        State memory prev = State(
            __hyper__.getReserve(address(__asset__)),
            __hyper__.getReserve(address(__quote__)),
            __asset__.balanceOf(address(__hyper__)),
            __quote__.balanceOf(address(__hyper__)),
            sumAsset,
            sumQuote,
            sumPositionLiquidity,
            pool.liquidity,
            position.totalLiquidity,
            feeGrowthAssetPool,
            feeGrowthQuotePool,
            feeGrowthAssetPosition,
            feeGrowthQuotePosition
        );

        return prev;
    }

    function getBalances(address token) internal view returns (uint reserve, uint physical, uint balanceSum) {
        reserve = __hyper__.getReserve(token);
        physical = TestERC20(token).balanceOf(address(__hyper__));
        for (uint i; i != __users__.length; ++i) {
            balanceSum += __hyper__.getBalance(__users__[i], token);
        }
    }
}
