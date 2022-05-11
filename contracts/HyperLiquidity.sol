pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interfaces/IERC20.sol";
import "./EnigmaVirtualMachine.sol";

interface HyperLiquidityErrors {
    error ZilchError();
    error ZeroLiquidityError();
}

interface HyperLiquidityEvents {}

/// @notice Designed to maintain collateral for the sum of virtual liquidity across all pools.
contract HyperLiquidity is HyperLiquidityErrors, HyperLiquidityEvents, EnigmaVirtualMachine {
    // --- View --- //

    /// Gets base and quote tokens entitled to argument `liquidity`.
    function getPhysicalReserves(uint256 liquidity) public view returns (uint256, uint256) {
        Pool memory pool = pools[0];
        uint256 total = uint256(pool.internalLiquidity);
        uint256 amount0 = (pool.internalBase * liquidity) / total;
        uint256 amount1 = (pool.internalQuote * liquidity) / total;
        return (amount0, amount1);
    }

    // --- Internal Functions --- //

    /// @notice Changes internal "fake" reserves of a pool with `id`.
    /// @dev    Liquidity must be credited to an address, and token amounts must be _applyDebited.
    function _addLiquidity(
        uint8 id,
        uint256 deltaBase,
        uint256 deltaQuote
    ) internal returns (uint256 deltaLiquidity) {
        Pool storage pool = pools[id];
        if (pool.blockTimestamp == 0) revert ZilchError();

        uint256 liquidity0 = (deltaBase * pool.internalLiquidity) / uint256(pool.internalBase);
        uint256 liquidity1 = (deltaQuote * pool.internalLiquidity) / uint256(pool.internalQuote);
        deltaLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;

        if (deltaLiquidity == 0) revert ZeroLiquidityError();

        pool.internalBase += uint128(deltaBase);
        pool.internalQuote += uint128(deltaQuote);
        pool.internalLiquidity += uint128(deltaLiquidity);
        pool.blockTimestamp = _blockTimestamp();

        Tokens storage token = tokens[id];
        globalReserves[token.tokenBase] += deltaBase;
        globalReserves[token.tokenQuote] += deltaQuote;

        Position storage pos = positions[msg.sender][id];
        pos.liquidity += deltaLiquidity;
        pos.blockTimestamp = _blockTimestamp();
    }

    function _removeLiquidity(uint8 id, uint256 deltaLiquidity)
        internal
        returns (uint256 deltaBase, uint256 deltaQuote)
    {
        Pool storage pool = pools[id];
        if (pool.blockTimestamp == 0) revert ZilchError();

        deltaBase = (pool.internalBase * deltaLiquidity) / pool.internalLiquidity;
        deltaQuote = (pool.internalQuote * deltaLiquidity) / pool.internalLiquidity;

        if (deltaLiquidity == 0) revert ZeroLiquidityError();

        pool.internalBase -= uint128(deltaBase);
        pool.internalQuote -= uint128(deltaQuote);
        pool.internalLiquidity -= uint128(deltaLiquidity);
        pool.blockTimestamp = _blockTimestamp();

        Tokens storage token = tokens[id];
        globalReserves[token.tokenBase] -= deltaBase;
        globalReserves[token.tokenQuote] -= deltaQuote;

        Position storage pos = positions[msg.sender][id];
        pos.liquidity -= deltaLiquidity;
        pos.blockTimestamp = _blockTimestamp();
    }
}
