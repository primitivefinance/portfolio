// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title IEnigmaEvents
/// @dev All events emitted from the Enigma and its higher level contracts.
interface IEnigmaEvents {
    // --- Accounts --- //
    /// @dev Emitted on increasing liquidity or creating a pool.
    /// @param account The address of the account which owns the position.
    /// @param poolId The poolId of the pool which the position exists on.
    /// @param deltaLiquidity The amount of liquidity provided to the position.

    event IncreasePosition(address indexed account, uint48 indexed poolId, uint256 deltaLiquidity);
    /// @dev Emitted on removing liquidity only.
    /// @param account The address of the account which owns the position.
    /// @param poolId The poolId of the pool which the position exists on.
    /// @param deltaLiquidity The amount of liquidity removed from the position.
    event DecreasePosition(address indexed account, uint48 indexed poolId, uint256 deltaLiquidity);

    // --- Critical --- //
    /// @dev Emitted on any pool interaction which increases one of the pool's reserves.
    /// @param token The address of the token which had liquidity provided.
    /// @param amount The amount of liquidity provided.
    /// @custom:security High. Use these to track the total value locked of a token.
    event IncreaseGlobal(address indexed token, uint256 amount);

    /// @dev Emitted on any pool interaction which decreases one of the pool's reserves.
    /// @custom:security High.
    /// @param token The address of the token which had liquidity removed.
    /// @param amount The amount of liquidity removed.
    event DecreaseGlobal(address indexed token, uint256 amount);

    // --- Decompiler --- //

    /// @dev A payment requested by this contract that must be paid by the `msg.sender` account.
    /// @param token The address of the token that is requested from `msg.sender`.
    /// @param amount The amount that is requested from `msg.sender`.
    event Debit(address indexed token, uint256 amount);

    /// @dev A payment that is paid out to the `msg.sender` account from this contract.
    /// @param token The address of the token that is being paid to `msg.sender`.
    /// @param amount The amount that is paid to `msg.sender`.
    event Credit(address indexed token, uint256 amount);

    // --- Liquidity --- //
    /// @dev Emitted on increasing the internal reserves of a pool.
    /// @param poolId The poolId of the pool which liquidity has been added to.
    /// @param pairId The pairId of the pair which liquidity has been provided to.
    /// @param deltaBase The amount of base token provided.
    /// @param deltaQuote The amount of quote token provided.
    /// @param deltaLiquidity The amount of liquidity tokens provided.
    event AddLiquidity(
        uint48 indexed poolId,
        uint16 indexed pairId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    /// @dev Emitted on decreasing the internal reserves of a pool.
    /// @param poolId The poolId of the pool which liquidity has been removed from.
    /// @param pairId The pairId of the pair which liquidity has been removed from.
    /// @param deltaBase The amount of base token removed.
    /// @param deltaQuote The amount of quote token removed.
    /// @param deltaLiquidity The amount of liquidity tokens removed.
    event RemoveLiquidity(
        uint48 indexed poolId,
        uint16 indexed pairId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    // --- Uncommon --- //
    /// @dev Emitted on setting a new curve parameter set in state with key `curveId`.
    /// @param curveId The id of the curve that was created.
    /// @param strike The strike (K) value of the curve that was created.
    /// @param sigma The sigma () value of the curve that was created.
    /// @param maturity The maturity () value of the curve that was created.
    /// @param gamma The gamma value of the curve that was created.
    event CreateCurve(
        uint32 indexed curveId,
        uint128 strike,
        uint24 sigma,
        uint32 indexed maturity,
        uint32 indexed gamma
    );

    /// @dev Emitted on setting a new token pair in state with the key `pairId`.
    /// @param pairId The id of the pair that was created.
    /// @param base The address for the base token of the pair.
    /// @param quote The address of the quote token of the pair.
    event CreatePair(uint16 indexed pairId, address indexed base, address indexed quote);

    /// @dev Emitted on creating a pool for a pair and curve.
    /// @param poolId The id of the Pool that was created.
    /// @param pairId The id of the Pair which the pool uses.
    /// @param curveId The id of the Curve that the pool was created on.
    /// @param deltaBase The amount of the base token the pool was initialized with.
    /// @param deltaQuote The amount of the quote token the pool was initialized with.
    /// @param deltaLiquidity The amount of the liquidity the pool was initialized with.
    event CreatePool(
        uint48 indexed poolId,
        uint16 indexed pairId,
        uint32 indexed curveId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    // --- Swap --- //
    /// @dev Emitted on a token swap in a single virtual pool.
    /// @param id The id of the pool which the swap occurred on.
    /// @param input The amount of token swapped in.
    /// @param output The amount of token swapped out.
    /// @param tokenIn The address of token swapped in.
    /// @param tokenOut The address of token swapped in.
    event Swap(uint256 id, uint256 input, uint256 output, address tokenIn, address tokenOut);

    /// @dev Emitted on external calls to `updateLastTimestamp` or `swap`. Syncs a pool's timestamp to block.timestamp.
    /// @param poolId The id of the pool which will have its timestamp updated.
    event UpdateLastTimestamp(uint48 poolId);
}
