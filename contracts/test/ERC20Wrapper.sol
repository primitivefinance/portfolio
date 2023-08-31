// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC1155.sol";

contract ERC20Wrapper is ERC20, ERC1155TokenReceiver {
    address immutable PORTFOLIO;
    uint256[] public POOL_IDS;

    constructor(
        address portfolio_,
        uint64[] memory poolIds_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_, 18) {
        PORTFOLIO = portfolio_;
        POOL_IDS = poolIds_;
    }

    function mint(address to, uint256 amount) external {
        uint256[] memory amounts = new uint256[](POOL_IDS.length);

        for (uint256 i = 0; i < POOL_IDS.length; i++) {
            amounts[i] = amount;
        }

        ERC1155(PORTFOLIO).safeBatchTransferFrom(
            msg.sender, address(this), POOL_IDS, amounts, ""
        );

        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        _burn(msg.sender, amount);

        uint256[] memory amounts = new uint256[](POOL_IDS.length);

        for (uint256 i = 0; i < POOL_IDS.length; i++) {
            amounts[i] = amount;
        }

        ERC1155(PORTFOLIO).safeBatchTransferFrom(
            address(this), to, POOL_IDS, amounts, ""
        );
    }
}
