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
        uint16 pairId,
        address base,
        address quote
    ) public {
        pairs[pairId] = Pair({
            tokenBase: base,
            decimalsBase: IERC20(base).decimals(),
            tokenQuote: quote,
            decimalsQuote: IERC20(quote).decimals()
        });
    }

    function setLiquidity(
        uint48 poolId,
        uint256 base,
        uint256 quote,
        uint256 liquidity
    ) public {
        pools[poolId] = Pool({
            internalBase: uint128(base),
            internalQuote: uint128(quote),
            internalLiquidity: uint128(liquidity),
            blockTimestamp: uint128(block.timestamp)
        });
    }

    function setCurve(
        uint32 curveId,
        uint128 strike,
        uint24 sigma,
        uint32 maturity,
        uint32 gamma
    ) public {
        curves[curveId] = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});
    }

    // --- Create --- //

    function testCreatePair(bytes calldata data) public returns (uint16) {
        return _createPair(data);
    }

    function testCreateCurve(bytes calldata data) public returns (uint32) {
        return _createCurve(data);
    }

    function testCreatePool(bytes calldata data)
        public
        returns (
            uint48,
            uint256,
            uint256
        )
    {
        return _createPool(data);
    }
}
