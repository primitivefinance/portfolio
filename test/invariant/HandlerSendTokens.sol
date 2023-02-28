// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./setup/HandlerBase.sol";

contract HandlerSendTokens is HandlerBase {
    function name() public view override returns (string memory) {
        return "send-tokens";
    }

    event SentTokens(address indexed token, uint256 amount);

    function sendAssetTokens(uint256 amount) external {
        amount = bound(amount, 1, 2 ** 127);
        transfer(ctx.ghost().asset().to_token(), amount);
    }

    function sendQuoteTokens(uint256 amount) external {
        amount = bound(amount, 1, 2 ** 127);
        transfer(ctx.ghost().quote().to_token(), amount);
    }

    function transfer(MockERC20 token, uint256 amount) internal {
        token.mint(address(ctx.subject()), amount);
        emit SentTokens(address(token), amount);
    }
}
