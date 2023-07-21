// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

contract TestPortfolioUri is Setup {
    function test_uri() public defaultConfig useActor usePairTokens(10 ether) {
        subject().allocate(
            false,
            address(this),
            ghost().poolId,
            1 ether,
            type(uint128).max,
            type(uint128).max
        );

        string memory uri = ERC1155(address(subject())).uri(ghost().poolId);
        console.log(uri);
    }
}
