pragma solidity ^0.8.0;

import "../Compiler.sol";

contract TestCompiler is Compiler {
    uint256 public timestamp;

    function setTimestamp(uint256 timestamp_) public {
        timestamp = timestamp_;
    }

    function _blockTimestamp() internal view override(EnigmaVirtualMachine) returns (uint128) {
        return uint128(timestamp);
    }

    function setTokens(
        uint8 id,
        address base,
        address quote
    ) public {
        tokens[id] = Tokens({
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

    function setCurve(
        uint8 id,
        uint128 strike,
        uint64 sigma,
        uint32 maturity,
        uint32 gamma
    ) public {
        curves[id] = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});
    }
}
