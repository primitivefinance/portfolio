// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {TestERC20, Hyper, HyperTimeOverride, HyperCatchReverts, RevertCatcher} from "./HyperTestOverrides.sol";

uint constant STARTING_BALANCE = 4000e18;

/** @dev Deploys test contracts, test tokens, sets labels, funds users, and approves contracts to spend tokens. */
contract Setup is Test {
    WETH public __weth__;
    Hyper public __hyper__;
    HyperTimeOverride public __hyperTimeOverride__;
    HyperCatchReverts public __hyperCatchReverts__;
    RevertCatcher public __revertCatcher__;

    TestERC20 public __usdc__;
    TestERC20 public __token_8__;
    TestERC20 public __token_18__;
    TestERC20 public __badToken__;

    address[] public __contracts__;
    address[] public __users__;
    address[] public __tokens__;

    function setUp() public {
        initContracts();
        initUsers();
        approveTokens();

        afterSetUp();
    }

    /** @dev Hook to run after test setup. */
    function afterSetUp() public virtual {}

    function initContracts() internal {
        __weth__ = new WETH();

        // --- Hyper Contracts --- //
        __hyper__ = new Hyper(address(__weth__));
        __hyperTimeOverride__ = new HyperTimeOverride(address(__weth__));
        __hyperCatchReverts__ = new HyperCatchReverts(address(__weth__));
        __revertCatcher__ = new RevertCatcher(address(__hyperCatchReverts__));
        __contracts__.push(address(__hyper__));
        __contracts__.push(address(__hyperTimeOverride__));
        __contracts__.push(address(__hyperCatchReverts__));
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

        vm.label(self, "Self");
        vm.label(alicent, "Alicent");
        vm.label(boba, "Boba");

        __users__.push(self);
        __users__.push(alicent);
        __users__.push(boba);

        fundUsers();
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
            deal(address(__usdc__), __users__[i], STARTING_BALANCE); // TODO: Use regular ERC20, since we can deal.
        }
    }

    function setLabels() internal {
        vm.label(address(__weth__), "Weth");
        vm.label(address(__revertCatcher__), "RevertCatcher");
        vm.label(address(__hyper__), "DefaultHyper");
        vm.label(address(__hyperTimeOverride__), "HyperTimeOverride");
        vm.label(address(__hyperCatchReverts__), "HyperCatchReverts");
        vm.label(address(__usdc__), "USDC");
        vm.label(address(__token_8__), "Token8Decimals");
        vm.label(address(__token_18__), "Token18Decimals");
        vm.label(address(__badToken__), "BadToken");
    }
}
