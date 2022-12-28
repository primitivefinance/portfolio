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

struct TestScenario {
    TestERC20 asset;
    TestERC20 quote;
    uint48 poolId;
    string label;
}

/** @dev Deploys test contracts, test tokens, sets labels, funds users, and approves contracts to spend tokens. */
contract TestHyperSetup is HelperHyperActions, HelperHyperInvariants, HelperHyperProfiles, HelperHyperView, Test {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    WETH public __weth__;
    Hyper public __hyper__; // Actual contract
    HyperTimeOverride public __hyperTimeOverride__; // Inherits Hyper, adds block.timestamp and jit policy overrides
    HyperCatchReverts public __hyperTestingContract__; // Inherits HyperTimeOverrides, adds endpoints to process functions.
    RevertCatcher public __revertCatcher__;

    TestERC20 public __usdc__;
    TestERC20 public __token_8__;
    TestERC20 public __token_18__;
    TestERC20 public __badToken__;

    address[] public __contracts__;
    address[] public __users__;
    address[] public __tokens__;

    TestScenario public defaultScenario;
    TestScenario[] public scenarios;

    modifier postTestInvariantChecks() virtual {
        _;
        assertSettlementInvariant(address(__hyperTestingContract__), address(defaultScenario.asset), __users__);
        assertSettlementInvariant(address(__hyperTestingContract__), address(defaultScenario.quote), __users__);
    }

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

        // --- Hyper Contracts --- //
        __hyper__ = new Hyper(address(__weth__));
        __hyperTimeOverride__ = new HyperTimeOverride(address(__weth__));
        __hyperTestingContract__ = new HyperCatchReverts(address(__weth__));
        __revertCatcher__ = new RevertCatcher(address(__hyperTestingContract__));
        __contracts__.push(address(__hyper__));
        __contracts__.push(address(__hyperTimeOverride__));
        __contracts__.push(address(__hyperTestingContract__));
        __contracts__.push(address(__revertCatcher__));

        __usdc__ = new TestERC20("USD Coin", "USDC", 6);
        __token_8__ = new TestERC20("8 Decimals", "8DEC", 8);
        __token_18__ = new TestERC20("18 Decimals", "18DEC", 18);
        __badToken__ = new TestERC20("Non-standard ERC20", "BAD", 18); // TODO: Add proper bad token.
        __tokens__.push(address(__usdc__));
        __tokens__.push(address(__token_8__));
        __tokens__.push(address(__token_18__));
        __tokens__.push(address(__badToken__));

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
            address(__token_18__),
            address(__usdc__),
            DEFAULT_SIGMA,
            uint32(block.timestamp) + DEFAULT_MATURITY,
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            DEFAULT_STRIKE,
            DEFAULT_PRICE
        );

        bool success = __revertCatcher__.jumpProcess(data);
        assertTrue(success, "__revertCatcher__ call failed");

        // Create default scenario and add to all scenarios.
        defaultScenario = TestScenario(__token_18__, __usdc__, 0x000100000001, "Default");
        scenarios.push(defaultScenario);
    }

    /** @dev Requires tokens to be spent and spenders to be approved. */
    function initPrerequisites() internal {
        fundUsers();
        approveTokens();
    }

    /** @dev Does not include weth. */
    function approveTokens() internal {
        for (uint x; x != __tokens__.length; ++x) {
            for (uint y; y != __contracts__.length; ++y) {
                for (uint z; z != __users__.length; ++z) {
                    vm.prank(__users__[z]); // Sets caller
                    TestERC20(__tokens__[x]).approve(__contracts__[y], type(uint256).max); // Approves test contracts to spend tokens.
                }
            }
        }
    }

    /** @dev Does not include weth. */
    function fundUsers() internal {
        for (uint i; i != __users__.length; ++i) {
            for (uint j; j != __tokens__.length; ++j) {
                deal(__tokens__[j], __users__[i], STARTING_BALANCE); // TODO: Use regular ERC20, since we can deal.
            }
        }
    }

    function setLabels() internal {
        vm.label(address(this), "Self");
        vm.label(address(__weth__), "Weth");
        vm.label(address(__revertCatcher__), "RevertCatcher");
        vm.label(address(__hyper__), "DefaultHyper");
        vm.label(address(__hyperTimeOverride__), "HyperTimeOverride");
        vm.label(address(__hyperTestingContract__), "HyperCatchReverts");
        vm.label(address(__usdc__), "USDC");
        vm.label(address(__token_8__), "Token8Decimals");
        vm.label(address(__token_18__), "Token18Decimals");
        vm.label(address(__badToken__), "BadToken");
    }

    function customWarp(uint time) internal {
        vm.warp(time);
        __hyperTestingContract__.setTimestamp(uint128(time));
    }
}
