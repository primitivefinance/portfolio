// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "openzeppelin-contracts/utils/Base64.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "solmate/tokens/ERC20.sol";
import "../interfaces/IPortfolio.sol";

// @dev Simple contract to render a position.
contract SimplePositionRenderer {
    IPortfolio public portfolio;

    constructor(IPortfolio _portfolio) {
        portfolio = _portfolio;
    }

    function uri(uint256 id) external view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            _generateName(id),
                            '","image":"',
                            _generateImage(),
                            '","license":"MIT","creator":"primitive.eth",',
                            '"description":"Concentrated liquidity tokens of a two-token AMM",',
                            '"properties":{',
                            _generateProperties(id),
                            "}}"
                        )
                    )
                )
            )
        );
    }

    function _generateName(uint256 id) private view returns (string memory) {
        (address tokenAsset,, address tokenQuote,) =
            portfolio.pairs(uint24(uint64(id) >> 40));

        return string(
            abi.encodePacked(
                "Primitive Portfolio LP ",
                ERC20(tokenAsset).symbol(),
                "-",
                ERC20(tokenQuote).symbol()
            )
        );
    }

    function _generateImage() private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    bytes(
                        '<svg width="512" height="512" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="#000" d="M0 0h512v512H0z"/><path fill-rule="evenodd" clip-rule="evenodd" d="M339.976 134.664h41.048L256 340.586 130.976 134.664h41.047V98H64.143L256 414 447.857 98H339.976v36.664Zm-38.759 0V98h-90.436v36.664h90.436Z" fill="#fff"/></svg>'
                    )
                )
            )
        );
    }

    function _generateProperties(uint256 id)
        private
        view
        returns (string memory)
    {
        (address tokenAsset,, address tokenQuote,) =
            portfolio.pairs(uint24(uint64(id) >> 40));

        return string(
            abi.encodePacked(
                '"asset":"',
                ERC20(tokenAsset).name(),
                '",',
                '"quote":"',
                ERC20(tokenQuote).name(),
                '",'
            )
        );
    }
}
