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

uint constant STARTING_BALANCE = 4000e18;

/** @dev Deploys test contracts, test tokens, sets labels, funds users, and approves contracts to spend tokens. */
contract TestE2ESetup is HelperHyperActions, HelperHyperInvariants, HelperHyperProfiles, HelperHyperView, Test {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    uint48 public __poolId__ = 0x000100000001;

    WETH public __weth__;
    TestERC20 public __quote__;
    TestERC20 public __asset__;
    HyperTimeOverride public __hyper__; // Actual contract

    address[] public __users__;

    function setUp() public {
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
        address revertCatcher = address(__revertCatcher__);

        vm.label(self, "Self");
        vm.label(alicent, "Alicent");
        vm.label(boba, "Boba");

        __users__.push(self);
        __users__.push(alicent);
        __users__.push(boba);
        __users__.push(revertCatcher);
    }

    function initScenarios() internal {
        __hyperTestingContract__.setTimestamp(uint128(block.timestamp)); // Important
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

        bool success = __revertCatcher__.jumpProcess(data);
        assertTrue(success, "__revertCatcher__ call failed");
    }

    /** @dev Requires tokens to be spent and spenders to be approved. */
    function initPrerequisites() internal {
        fundUsers();
        approveTokens();
    }

    /** @dev Does not include weth. */
    function approveTokens() internal {
        for (uint z; z != __users__.length; ++z) {
            vm.prank(__users__[z]); // Sets caller
            TestERC20(__asset__).approve(address(__hyper__), type(uint256).max); // Approves test contracts to spend tokens.
            TestERC20(__quote__).approve(address(__hyper__), type(uint256).max); // Approves test contracts to spend tokens.
        }
    }

    /** @dev Does not include weth. */
    function fundUsers() internal {
        for (uint i; i != __users__.length; ++i) {
            deal(__asset__, __users__[i], STARTING_BALANCE); // TODO: Use regular ERC20, since we can deal.
            deal(__quote__, __users__[i], STARTING_BALANCE); // TODO: Use regular ERC20, since we can deal.
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
}
