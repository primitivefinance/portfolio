pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./HyperLiquidity.sol";
import "./EnigmaVirtualMachine.sol";
import "./libraries/ReplicationMath.sol";

interface HyperSwapErrors {
    error PoolZilchError();
    error InvariantError(int128 prev, int128 post);
}

interface HyperSwapEvents {
    event UpdateLastTimestamp(uint128 timestamp);
    event Swap(uint256 id, uint256 input, uint256 output, address tokenIn, address tokenOut);
}

/// @notice Executes trading on a target curve.
contract HyperSwap is HyperSwapEvents, HyperSwapErrors, EnigmaVirtualMachine {
    // --- View --- //

    function getInvariant(uint8 id) public view returns (int128) {
        Pool memory pool = pools[id];
        return int128(1);
    }

    // --- Internals --- //

    function _updateLastTimestamp(uint8 id) internal virtual returns (uint128 blockTimestamp) {
        Pool storage pool = pools[id];
        if (pool.blockTimestamp == 0) revert PoolZilchError();

        Curve storage curve = curves[id];
        uint32 maturity = curve.maturity;
        blockTimestamp = _blockTimestamp();
        if (blockTimestamp > maturity) blockTimestamp = maturity; // if expired, set to the maturity

        pool.blockTimestamp = blockTimestamp; // set state
        emit UpdateLastTimestamp(id);
    }

    /// @param dir 0 = base -> quote, 1 = quote -> base
    function _swap(
        uint8 id,
        uint8 dir,
        uint256 input,
        uint256 output
    ) internal returns (uint256) {
        Pool storage pool = pools[id];

        uint128 lastTimestamp = _updateLastTimestamp(id);
        // todo: swap maturity buffer logic implementation
        int128 invariant = getInvariant(id);

        Pair memory pair = pairs[id];

        {
            // swap logic
            Curve memory curve = curves[id];
            uint32 tau = curve.maturity - uint32(pool.blockTimestamp);
            uint256 amountInFee = (input * curve.gamma) / PERCENTAGE;
            uint256 adjustedBase;
            uint256 adjustedQuote;

            if (dir == 0) {
                adjustedBase = uint256(pool.internalBase) + amountInFee;
                adjustedQuote = uint256(pool.internalQuote) - output;
            } else {
                adjustedBase = uint256(pool.internalBase) - output;
                adjustedQuote = uint256(pool.internalQuote) + amountInFee;
            }

            adjustedBase = (adjustedBase * PRECISION) / pool.internalLiquidity;
            adjustedQuote = (adjustedQuote * PRECISION) / pool.internalLiquidity;

            int128 invariantAfter = ReplicationMath.calcInvariant(
                10**(18 - pair.decimalsBase),
                10**(18 - pair.decimalsQuote),
                adjustedBase,
                adjustedQuote,
                curve.strike,
                curve.sigma,
                tau
            );
            // invariant check
            if (invariantAfter < invariant) revert InvariantError(invariant, invariantAfter);

            // Commit swap update and settle
            if (dir == 0) {
                pool.internalBase += uint128(input);
                pool.internalQuote -= uint128(output);
                globalReserves[pair.tokenBase] += uint128(input);
                globalReserves[pair.tokenQuote] -= uint128(output);
            } else {
                pool.internalBase -= uint128(output);
                pool.internalQuote += uint128(input);
                globalReserves[pair.tokenBase] -= uint128(output);
                globalReserves[pair.tokenQuote] += uint128(input);
            }

            pool.blockTimestamp = lastTimestamp;
        }

        emit Swap(
            id,
            input,
            output,
            dir == 0 ? pair.tokenBase : pair.tokenQuote,
            dir == 0 ? pair.tokenQuote : pair.tokenBase
        );
    }

    // --- External --- //

    // --- Storage --- //
}
