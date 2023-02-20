// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "solmate/tokens/WETH.sol";
import {RMM01Portfolio as Hyper, Enigma} from "contracts/RMM01Portfolio.sol";
import "contracts/libraries/RMM01Lib.sol";

import "forge-std/Test.sol";
import {TestERC20, FixedPointMathLib} from "test/helpers/HyperTestOverrides.sol";

import "test/helpers/HelperHyperActions.sol";
import "test/helpers/HelperHyperInvariants.sol";
import "test/helpers/HelperHyperProfiles.sol";
import "test/helpers/HelperHyperView.sol";

uint256 constant STARTING_BALANCE = 0;

contract Helpers is HelperHyperActions, HelperHyperInvariants, HelperHyperProfiles, HelperHyperView {}

/** @dev Deploys test contracts, test tokens, sets labels, funds users, and approves contracts to spend tokens. */
contract TestE2ESetup is Helpers, Test {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    // ===== Global Variables ===== //
    uint64 public __poolId__ = 0x0000010000000001;
    address[] public __users__;

    WETH public __weth__;
    TestERC20 public __quote__;
    TestERC20 public __asset__;
    Hyper public __hyper__; // Actual contract

    // ===== Set up ===== //

    function setUp() public virtual {
        initContracts();
        initUsers();
        initScenarios();
        initPrerequisites();
        afterSetUp();
    }

    /** @dev Requires tokens to be spent and spenders to be approved. */
    function initPrerequisites() internal {
        approveTokens();
    }

    /** @dev Hook to override receive. Defaults to just accepting ether sent to this test contract. */
    receive() external payable {
        receiveOverride();
    }

    /** @dev Uses the initialized context for the getState function. */
    function getState() internal view virtual returns (HyperState memory) {
        return getState(address(__hyper__), __poolId__, address(this), __users__);
    }

    /** @dev Hook to run after test setup. */
    function afterSetUp() public virtual {}

    /** @dev Replace receive ether logic. */
    function receiveOverride() public virtual {}

    // ===== Contracts Context ===== //
    function initContracts() internal {
        __weth__ = new WETH();
        __hyper__ = new Hyper(address(__weth__));
        __quote__ = new TestERC20("USD Coin", "USDC", 6);
        __asset__ = new TestERC20("18 Decimals", "18DEC", 18);

        setLabels();
    }

    function setLabels() internal {
        vm.label(address(this), "Self");
        vm.label(address(__weth__), "Weth");
        vm.label(address(__hyper__), "Hyper");
        vm.label(address(__quote__), "QuoteToken");
        vm.label(address(__asset__), "AssetToken");
    }

    // ===== Users ===== //

    function users() public view virtual returns (address[] memory) {
        return __users__;
    }

    function initUsers() internal {
        address self = address(this);
        address alicent = address(0x0001);
        address boba = address(0x0002);

        addUser(self, "Self");
        addUser(alicent, "Alicent");
        addUser(boba, "Boba");
    }

    function addUser(address user, string memory label) public {
        vm.label(user, label);
        __users__.push(user);
    }

    // ===== Test Scenarios ===== //

    function initScenarios() internal {
        // Create default pool
        bytes memory data = createPool(
            address(__asset__),
            address(__quote__),
            address(0),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(DEFAULT_SIGMA),
            uint16(DEFAULT_DURATION_DAYS),
            DEFAULT_JIT,
            DEFAULT_STRIKE,
            DEFAULT_PRICE
        );

        (bool success, ) = address(__hyper__).call(data);
        assertTrue(success, "create pool call failed");
    }

    // ===== Utils ===== //

    /** @dev Does not include weth. */
    function approveTokens() internal {
        for (uint256 z; z != __users__.length; ++z) {
            vm.prank(__users__[z]); // Sets caller
            __asset__.approve(address(__hyper__), type(uint256).max); // Approves test contracts to spend tokens.
            __quote__.approve(address(__hyper__), type(uint256).max); // Approves test contracts to spend tokens.
        }
    }

    /** @dev Does not include weth. */
    function fundUsers(uint256 deltaAsset, uint256 deltaQuote) internal {
        for (uint256 i; i != __users__.length; ++i) {
            deal(address(__asset__), __users__[i], deltaAsset); // TODO: Use regular ERC20, since we can deal.
            deal(address(__quote__), __users__[i], deltaQuote); // TODO: Use regular ERC20, since we can deal.
        }
    }

    event SetNewPoolId(uint64);

    /** @dev Sets the pool id and assets in TestE2ESetup state. Affects all tests! */
    function setPoolId(uint64 poolId) public {
        __poolId__ = poolId;

        HyperPair memory pair = getPair(address(__hyper__), Enigma.decodePairIdFromPoolId(poolId));
        __asset__ = TestERC20(pair.tokenAsset);
        __quote__ = TestERC20(pair.tokenQuote);

        emit SetNewPoolId(poolId);
    }
}
