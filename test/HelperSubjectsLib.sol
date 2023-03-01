// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "contracts/RMM01Portfolio.sol";
import "solmate/tokens/WETH.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "solmate/test/utils/weird-tokens/ReturnsTooLittleToken.sol";
import "forge-std/Test.sol";

using Subjects for SubjectsState global;

struct SubjectsState {
    Vm vm;
    address deployer;
    IHyper last;
    WETH weth;
    MockERC20[] tokens;
}

/**
 * @dev Handles the deployment of the contracts used in the test environment.
 *
 * User Manual:
 * - Chain deployments from `startDeploy` and `stopDeploy`.
 * - Change test subject with `change_subject`.
 */
library Subjects {
    struct Deploy {
        address caller;
    }

    error UnknownToken(bytes32);

    modifier ready(SubjectsState storage self) {
        require(address(self.vm) != address(0), "did you call startDeploy(vm) first?");
        _;
    }

    function last_token(SubjectsState storage self) internal view returns (MockERC20) {
        return self.tokens[self.tokens.length - 1];
    }

    /**
     * @dev Modifies the subject of the tests. Use this to change the target portfolio being tested.
     * @custom:example
     * ```
     * pragma solidity ^0.8.4;
     *
     * import "./Setup.sol";
     *
     * contract TestOtherPortfolio is Test{test name}, Setup {
     *    function setUp() public {
     *      super.setUp();
     *      address new_subject = address(new SubjectContract(...));
     *      subjects().change_subject(new_subject);
     *    }
     *
     *    // All tests inherited from Test{test name} will run using the new_subject.
     * }
     */
    function change_subject(SubjectsState storage self, address subject) internal {
        self.last = IHyper(subject);
    }

    /**
     * @dev Loads the vm instance into context to label the following deployed contracts.
     * Should be removed via `stopDeploy` after all contracts are deployed.
     * @custom:example
     * ```
     * self.startDeploy(vm).{...deploy_functions()}.stopDeploy();
     * ```
     */
    function startDeploy(SubjectsState storage self, Vm vm) internal returns (SubjectsState storage) {
        self.vm = vm;

        // Only change if unset or not the existing address.
        if (self.deployer == address(0) || self.deployer != address(this)) {
            self.deployer = address(this);
            self.vm.label(self.deployer, "Deployer");
        }
        return self;
    }

    /**
     * @dev Chain from `startDeploy()` to startDeploy the WETH contract subject.
     * Must have `vm` in context via inheriting `forge-std/Test.sol`.
     * @custom:example
     * ```
     * self.startDeploy(vm).wrapper().stopDeploy();
     * ```
     */
    function wrapper(SubjectsState storage self) internal ready(self) returns (SubjectsState storage) {
        self.weth = new WETH();
        self.vm.label(address(self.weth), "WETH");
        return self;
    }

    /**
     * @dev Chain from `startDeploy()` to startDeploy the default Hyper contract subject.
     * Must have `vm` in context via inheriting `forge-std/Test.sol`.
     * @custom:example
     * ```
     * self.startDeploy(vm).subject().stopDeploy();
     * ```
     */
    function subject(SubjectsState storage self) internal ready(self) returns (SubjectsState storage) {
        self.last = IHyper(new RMM01Portfolio(address(self.weth)));
        self.vm.label(address(self.last), "Subject");
        return self;
    }

    /**
     * @dev Chain from `startDeploy()` to startDeploy a token subject.
     * Must have `vm` in context via inheriting `forge-std/Test.sol`.
     * @custom:example
     * ```
     * self.startDeploy(vm).token("token", abi.encode("Name", "Symbol", 18)).stopDeploy();
     * ```
     */
    function token(
        SubjectsState storage self,
        bytes32 what,
        bytes memory data
    ) internal ready(self) returns (SubjectsState storage) {
        (string memory name, string memory symbol, uint8 decimals) = abi.decode(data, (string, string, uint8));
        if (what == "token") {
            MockERC20 token = new MockERC20(name, symbol, decimals);
            self.tokens.push(token);
            self.vm.label(address(token), symbol);
        } else if (what == "RTL") {} else {
            revert UnknownToken(what);
        }
        return self;
    }

    /**
     * @dev Used at the end of a startDeploy chain to remove the `vm` instance from the SubjectsState.
     * Removing vm will cause startDeploy related calls to revert if attempted without leading
     * the chain with `startDeploy()`.
     */
    function stopDeploy(SubjectsState storage self) internal ready(self) returns (SubjectsState storage) {
        delete self.vm;
        return self;
    }
}
