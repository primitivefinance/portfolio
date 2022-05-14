pragma solidity ^0.8.0;

import "../HyperLiquidity.sol";

contract TestHyperLiquidity is HyperLiquidity {
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

    function fund(address token, uint256 amount) external override {}

    function draw(
        address token,
        uint256 amount,
        address to
    ) external override {}

    function getInvariant(uint48 poolId) public view override returns (int128 invariant) {}

    function updateLastTimestamp(uint48 poolId) external override lock returns (uint128 blockTimestamp) {}

    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        public
        view
        override
        returns (uint256 deltaBase, uint256 deltaQuote)
    {
        Pool memory pool = pools[poolId];
        uint256 total = uint256(pool.internalLiquidity);
        deltaBase = (uint256(pool.internalBase) * deltaLiquidity) / total;
        deltaQuote = (uint256(pool.internalQuote) * deltaLiquidity) / total;
    }
}
