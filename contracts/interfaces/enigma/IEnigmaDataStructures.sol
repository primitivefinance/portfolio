// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title IEngimaDataStructures
/// @dev All the structs used by the Enigma and its higher level contracts. Returned by the mapping public getters.
interface IEnigmaDataStructures {
    // --- Immutable --- //

    /// @dev Immutable curve parameters.
    /// @param strike A wei amount of quote tokens that can purchase 1 base token at pool maturity.
    /// @param sigma Percentage value in basis points, the "implied volatility" of a curve.
    /// @param maturity Swaps are paused in this pool once the block.timestamp reaches the maturity.
    /// @param gamma Percentage value in basis points, effectively applies the swap fee using the amount in method.
    /// @param priorityGamma Percentage value in basis points for priority swapper, effectively applies the priority swap fee using the amount in method.
    struct Curve {
        uint128 strike;
        uint24 sigma;
        uint32 maturity;
        uint32 gamma;
        uint32 priorityGamma;
    }

    /// @dev Immutable pair data.
    /// @param tokenBase Main token of a pool, which is purchasable for the strike price at maturity.
    /// @param decimalsBase Decimals of every token are used to compute the invariant when swapping.
    /// @param tokenQuote Secondary token of a pool. On maturity, 100% of the pool if price of base token < strike price.
    /// @param decmialsQuote. Decimals of quote token. Used to compute invariant, so it's important.
    struct Pair {
        address tokenBase;
        uint8 decimalsBase;
        address tokenQuote;
        uint8 decimalsQuote;
    }

    // --- Mutable --- //

    /// @dev Mutable virtual pool reserves and liquidity.
    /// @param internalBase Total amount of base tokens in this pool.
    /// @param internalQuote Total amount of quote tokens in this pool.
    /// @param internalLiquidity Total liquidity supply of the pool.
    /// @param blockTimestamp Last time the pool was updated.
    struct Pool {
        uint128 internalBase;
        uint128 internalQuote;
        uint128 internalLiquidity;
        uint128 blockTimestamp;
    }

    /// @dev Mutable individual liquidity credits for accounts mapped to poolIds.
    /// @param liquidity Tracks the pro-rata ownership of liquidity allocated to a pool at a poolId.
    /// @param blockTimestamp Used to track the distance of time between allocates and removes.
    struct Position {
        uint128 liquidity;
        uint128 blockTimestamp;
    }

    struct Epoch {
        uint256 id;
        uint256 endTime;
        uint256 interval;
    }

    /**
     * @notice Individual pool state.
     */
    struct HyperPool {
        uint256 lastPrice;
        int24 lastTick;
        uint256 blockTimestamp;
        uint256 liquidity;
        uint256 stakedLiquidity;
        address prioritySwapper;
        uint256 feeGrowthGlobalAsset;
        uint256 feeGrowthGlobalQuote;
    }

    /**
     * @notice Individual position within a pool.
     */
    struct HyperPosition {
        int24 loTick;
        int24 hiTick;
        uint256 totalLiquidity;
        uint256 blockTimestamp;
        bool staked;
        uint256 unstakeEpochId;
        uint256 lastFeeGrowthQuote;
        uint256 lastFeeGrowthAsset;
    }

    /**
     * @notice Information of a slot at a tick.
     */
    struct HyperSlot {
        int256 liquidityDelta;
        int256 stakedLiquidityDelta;
        uint256 totalLiquidity;
        uint256 feeGrowthOutsideAsset;
        uint256 feeGrowthOutsideQuote;
        bool instantiated;
        uint256 timestamp;
    }
}
