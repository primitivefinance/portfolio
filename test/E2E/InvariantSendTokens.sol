// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/InvariantTargetContract.sol";

contract InvariantSendTokens is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    event SentTokens(address indexed token, uint amount);

    function sendAssetTokens(uint amount) external {
        amount = bound(amount, 1, 2 ** 127);
        transfer(__asset__, amount);
    }

    function sendQuoteTokens(uint amount) external {
        amount = bound(amount, 1, 2 ** 127);
        transfer(__quote__, amount);
    }

    function transfer(TestERC20 token, uint amount) internal {
        token.mint(address(__hyper__), amount);
        emit SentTokens(address(token), amount);
    }
}
