pragma solidity ^0.8.0;

library Instructions {
    function decodeCreatePair(bytes calldata data) internal returns (address tokenBase, address tokenQuote) {
        tokenBase = address(bytes20(data[0:20]));
        tokenQuote = address(bytes20(data[20:data.length - 1]));
    }

    function decodeCreate(bytes calldata data) internal returns (uint256) {}

    function decodeAddLiquidity(bytes calldata data) internal returns (uint256) {}

    function decodeSwapExactETH(bytes calldata data) internal returns (uint256) {}
}
