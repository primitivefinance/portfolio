// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/Hyper.sol";
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
 * Chain deployments from `deploy` and then call `save`.
 */
library Subjects {
    struct Deploy {
        address caller;
    }

    error UnknownToken(bytes32);

    modifier ready(SubjectsState storage self) {
        require(address(self.vm) != address(0), "did you call deploy(vm) first?");
        _;
    }

    function last_token(SubjectsState storage self) internal view returns (MockERC20) {
        return self.tokens[self.tokens.length - 1];
    }

    /**
     * @dev Loads the vm instance into context to label the following deployed contracts.
     * Should be removed via `save` after all contracts are deployed.
     */
    function deploy(SubjectsState storage self, Vm vm) internal returns (SubjectsState storage) {
        self.vm = vm;

        // Only change if unset or not the existing address.
        if (self.deployer == address(0) || self.deployer != address(this)) {
            self.deployer = address(this);
            self.vm.label(self.deployer, "Deployer");
        }
        return self;
    }

    function wrapper(SubjectsState storage self) internal ready(self) returns (SubjectsState storage) {
        self.weth = new WETH();
        self.vm.label(address(self.weth), "WETH");
        return self;
    }

    function subject(SubjectsState storage self) internal ready(self) returns (SubjectsState storage) {
        self.last = IHyper(new Hyper(address(self.weth)));
        self.vm.label(address(self.last), "Subject");
        return self;
    }

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

    function save(SubjectsState storage self) internal ready(self) returns (SubjectsState storage) {
        delete self.vm;
        return self;
    }
}
