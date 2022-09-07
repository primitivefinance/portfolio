// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title IEnigmaEvents
/// @dev All events emitted from the Enigma and its higher level contracts.
interface IEnigmaEvents {
    // --- Accounts --- //
    /// @dev Emitted on increasing liquidity or creating a pool.
    event IncreasePosition(address indexed account, uint48 indexed poolId, uint256 deltaLiquidity);
    /// @dev Emitted on removing liquidity only.
    event DecreasePosition(address indexed account, uint48 indexed poolId, uint256 deltaLiquidity);

    // --- Pools and Slots --- //
    event PoolUpdate(
        uint48 indexed poolId,
        uint256 price,
        int24 indexed tick,
        uint256 liquidity,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote
    );

    // --- Critical --- //
    /// @dev Emitted on any pool interaction which increases one of the pool's reserves.
    /// @custom:security High. Use these to track the total value locked of a token.
    event IncreaseGlobal(address indexed token, uint256 amount);
    /// @dev Emitted on any pool interaction which decreases one of the pool's reserves.
    /// @custom:security High.
    event DecreaseGlobal(address indexed token, uint256 amount);

    // --- Decompiler --- //
    /// @dev A payment requested by this contract that must be paid by the `msg.sender` account.
    event Debit(address indexed token, uint256 amount);
    /// @dev A payment that is paid out to the `msg.sender` account from this contract.
    event Credit(address indexed token, uint256 amount);

    // --- Liquidity --- //
    /// @dev Emitted on increasing the internal reserves of a pool.
    event AddLiquidity(
        uint48 indexed poolId,
        uint16 indexed pairId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );
    /// @dev Emitted on decreasing the internal reserves of a pool.
    event RemoveLiquidity(
        uint48 indexed poolId,
        uint16 indexed pairId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    // --- Uncommon --- //
    /// @dev Emitted on setting a new curve parameter set in state with key `curveId`.
    event CreateCurve(
        uint32 indexed curveId,
        uint128 strike,
        uint24 sigma,
        uint32 indexed maturity,
        uint32 indexed gamma,
        uint32 priorityGamma
    );
    /// @dev Emitted on setting a new token pair in state with the key `pairId`.
    event CreatePair(uint16 indexed pairId, address indexed base, address indexed quote);
    /// @dev Emitted on creating a pool for a pair and curve.
    event CreatePool(uint48 indexed poolId, uint16 indexed pairId, uint32 indexed curveId, uint256 price);

    // --- Swap --- //
    /// @dev Emitted on a token swap in a single virtual pool.
    event Swap(uint256 id, uint256 input, uint256 output, address tokenIn, address tokenOut);
    /// @dev Emitted on external calls to `updateLastTimestamp` or `swap`. Syncs a pool's timestamp to block.timestamp.
    event UpdateLastTimestamp(uint48 poolId);
    /// @dev Emitted when entering or exiting a slot when swapping.
    event SlotTransition(uint48 indexed poolId, int24 indexed tick, int256 liquidityDelta);

    // --- Fees --- ///
    event Collect(uint96 indexed positionId, address to, uint256 tokensCollectedAsset, uint256 tokensCollectedQuote);
}
