pragma solidity ^0.8.0;

interface IEnigmaDataStructures {
    // --- Immutable --- //

    /// @dev Immutable curve parameters.
    struct Curve {
        uint128 strike;
        uint24 sigma;
        uint32 maturity;
        uint32 gamma;
    }

    /// @dev Immutable pair data.
    struct Pair {
        address tokenBase;
        uint8 decimalsBase;
        address tokenQuote;
        uint8 decimalsQuote;
    }

    // --- Mutable --- //

    /// @dev Mutable virtual pool reserves and liquidity.
    struct Pool {
        uint128 internalBase;
        uint128 internalQuote;
        uint128 internalLiquidity;
        uint128 blockTimestamp;
    }

    /// @dev Mutable individual liquidity credits for accounts mapped to poolIds.
    struct Position {
        uint128 liquidity;
        uint128 blockTimestamp;
    }
}
