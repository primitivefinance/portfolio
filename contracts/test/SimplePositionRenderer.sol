// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "../libraries/Base64.sol";
import "../interfaces/IPortfolio.sol";

// @dev Simple contract to render a position.
contract SimplePositionRenderer {
    function uri(uint256 id) external pure returns (string memory) { }

    function render() private pure returns (string memory) {
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
}
