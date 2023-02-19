// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "test/helpers/HelperHyperView.sol";
import "contracts/Hyper.sol";
import {HyperPool, HyperPosition, TestERC20} from "test/helpers/HyperTestOverrides.sol";

interface Context {
    function users() external view returns (address[] memory);

    function getRandomPoolId(uint256 id) external view returns (uint64);

    function setPoolId(uint64 poolId) external;

    function addPoolId(uint64 poolId) external;

    function getRandomUser(uint256 id) external view returns (address);

    function __weth__() external view returns (TestERC20);

    function __asset__() external view returns (TestERC20);

    function __quote__() external view returns (TestERC20);
}

/** @dev Target contract must inherit. Read: https://github.com/dapphub/dapptools/blob/master/src/dapp/README.md#invariant-testing */
contract InvariantTargetContract is HelperHyperView, Test {
    Context ctx;

    uint64 public __poolId__ = 0x0000010000000001;
    Hyper public __hyper__; // Actual contract
    TestERC20 public __quote__;
    TestERC20 public __asset__;

    constructor(address hyper_, address asset_, address quote_) {
        ctx = Context(msg.sender);
        __hyper__ = Hyper(payable(hyper_));
        __asset__ = TestERC20(asset_);
        __quote__ = TestERC20(quote_);

        __asset__.approve(hyper_, type(uint256).max);
        __quote__.approve(hyper_, type(uint256).max);
    }

    /** @dev Uses the initialized context for the getState function. */
    function getState() internal view returns (HyperState memory) {
        return getState(address(__hyper__), __poolId__, address(this), ctx.users());
    }

    function setPoolId(uint64 poolId) internal {
        ctx.setPoolId(poolId); // TODO: duplicating for now...

        HyperPair memory pair = getPair(address(__hyper__), Processor.decodePairIdFromPoolId(poolId));
        __asset__ = TestERC20(pair.tokenAsset);
        __quote__ = TestERC20(pair.tokenQuote);
    }
}
