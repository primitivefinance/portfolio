// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/Hyper.sol";
import "contracts/EnigmaTypes.sol";
import "contracts/test/TestERC20.sol";

contract HyperTimeOverride is Hyper {
    constructor(address weth) Hyper(weth) {}

    function _blockTimestamp() internal view override returns (uint128) {
        return uint128(timestamp);
    }

    function _liquidityPolicy() internal view override returns (uint) {
        return jitDelay;
    }

    // ===== Added ==== //

    uint public timestamp;
    uint public jitDelay;

    function setJitPolicy(uint delay) public {
        jitDelay = delay;
    }

    function setTimestamp(uint128 time) public {
        timestamp = time;
    }

    /** @dev Temp jump override for invariant tests. */
    function doJumpProcess(bytes calldata data) external payable lock interactions {
        CPU._jumpProcess(data, super._process);
    }
}

/** @dev To catch reverts, external functions can be called by a contract that has a try-cactch. */
contract HyperCatchReverts is HyperTimeOverride {
    constructor(address weth) HyperTimeOverride(weth) {}

    // ===== Added ===== //

    /** @dev This is an implemented function to test process, so it has to have settle and re-entrancy guard. */
    function jumpProcess(bytes calldata data) external payable lock interactions {
        CPU._jumpProcess(data, super._process);
    }

    /** @dev This is an implemented function to test process, so it has to have settle and re-entrancy guard. */
    function process(bytes calldata data) external payable lock interactions {
        super._process(data);
    }

    /** @dev Solidity does not support error catching with the fallback function, so we use this external function. */
    function mockFallback(bytes calldata data) external payable lock interactions {
        if (data[0] != CPU.INSTRUCTION_JUMP) super._process(data);
        else CPU._jumpProcess(data, super._process);
    }
}

contract RevertCatcher {
    HyperCatchReverts public hyper;

    constructor(address hyper_) {
        hyper = HyperCatchReverts(payable(hyper_));
    }

    receive() external payable {}

    function approve(address token, address spender) external {
        TestERC20(token).approve(spender, type(uint256).max);
    }

    function mockFallback(bytes calldata data) external payable returns (bool) {
        try hyper.mockFallback{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }

    /** @dev Assumes Hyper calls this, for testing only. Uses try catch to bubble up errors. */
    function process(bytes calldata data) external payable returns (bool) {
        try hyper.process{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }

    /** @dev Assumes Hyper calls this, for testing only. Uses try catch to bubble up errors. */
    function jumpProcess(bytes calldata data) external payable returns (bool) {
        try hyper.jumpProcess{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }
}
