pragma solidity ^0.8.0;

import "../HyperLiquidity.sol";

contract TestHyperLiquidity is HyperLiquidity {
    function setTokens(
        uint8 id,
        address base,
        address quote
    ) public {
        pairs[id] = Pair({
            tokenBase: base,
            decimalsBase: IERC20(base).decimals(),
            tokenQuote: quote,
            decimalsQuote: IERC20(quote).decimals()
        });
    }

    function setLiquidity(
        uint8 id,
        uint256 base,
        uint256 quote,
        uint256 liquidity
    ) public {
        pools[id] = Pool({
            internalBase: uint128(base),
            internalQuote: uint128(quote),
            internalLiquidity: uint128(liquidity),
            blockTimestamp: uint128(block.timestamp)
        });
    }
}
