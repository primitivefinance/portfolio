// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "solmate/tokens/WETH.sol";
import "contracts/libraries/Price.sol";
import "contracts/HyperLib.sol";
import "test/helpers/HelperHyperActions.sol";
import "test/helpers/HelperHyperInvariants.sol";
import "test/helpers/HelperHyperProfiles.sol";
import "test/helpers/HelperHyperView.sol";

import {TestERC20, HyperTimeOverride} from "test/helpers/HyperTestOverrides.sol";

uint256 constant STARTING_BALANCE = 4000e18;

contract TestEchidnaEvents {
    event AssertionFailed();
    event AssertionFailed(uint256);
    event AssertionFailed(uint256, uint256);
    event AssertionFailed(uint256, uint256, uint256);
    event AssertionFailed(string, uint256);
    event AssertionFailed(bytes);
    event AssertionFailed(int);
}

contract Addresses {
    User public __user__;
    WETH public __weth__;
    HyperTimeOverride public __hyper__;
    TestERC20 public __usdc__;
    TestERC20 public __token_18__;
}

contract User {}

contract TestEchidnaSetup is
    TestEchidnaEvents,
    HelperHyperActions,
    HelperHyperInvariants,
    HelperHyperProfiles,
    HelperHyperView,
    Addresses
{
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    constructor() {
        initContracts();
        fundUsers();
        approveSpenders();

        afterSetUp();
    }

    function initContracts() internal {
        __user__ = new User();
        __weth__ = new WETH();

        // --- Hyper Contracts --- //
        __hyper__ = new HyperTimeOverride(address(__weth__));

        // --- Tokens --- //
        __usdc__ = new TestERC20("USD Coin", "USDC", 6);
        __token_18__ = new TestERC20("18 Decimals", "18DEC", 18);
    }

    /** @dev Hook to override receive. Defaults to just accepting ether sent to this test contract. */
    receive() external payable {
        receiveOverride();
    }

    /** @dev Hook to run after test setup. */
    function afterSetUp() public virtual {}

    /** @dev Hook to implement to handle receive differently. */
    function receiveOverride() public virtual {}

    function deal(TestERC20 token, address to, uint256 amount) internal {
        token.mint(to, amount);
    }

    /** @dev Does not include weth. */
    function fundUsers() internal {
        deal(__token_18__, address(__user__), STARTING_BALANCE); // TODO: Use regular ERC20, since we can deal.
        deal(__usdc__, address(__user__), STARTING_BALANCE);
    }

    /** @dev Does not include weth. */
    function approveSpenders() internal {
        TestERC20(__token_18__).approve(address(__hyper__), type(uint256).max); // Approves test contracts to spend tokens.
        TestERC20(__usdc__).approve(address(__hyper__), type(uint256).max); // Approves test contracts to spend tokens.
    }
}
