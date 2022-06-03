// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/// @title IEnigmaErrors
/// @dev All errors thrown by the Enigma and its higher level contracts.
interface IEnigmaErrors {
    // --- Decompiler --- //
    /// @dev Thrown when attempting to remove more internal token balance than owned by `msg.sender`.
    error DrawBalance();
    /// @dev Thrown when the jump pointer is further than the length of the next instruction.
    error JumpError(uint256 pointer);
    /// @dev Thrown if the instruction byte is 0x00 or does not match a valid instruction.
    error UnknownInstruction();

    // --- Default --- //
    /// @dev Thrown when the `IERC20.balanceOf` returns false or less data than expected.
    error BalanceError();
    /// @dev Re-entrany guard thrown on re-entering the external functions or fallback.
    error LockedError();

    // --- Creation --- //
    /// @dev Thrown when a pool is being created which has already been created with the same args.
    error CurveExists(uint32 curveId);
    /// @dev Thrown when interacting with a pool that has not been created.
    error NonExistentPool(uint48 poolId);
    /// @dev Thrown when creating a pair that has been created for the two addresses.
    error PairExists(uint16 pairId);
    /// @dev Thrown when a pool has been created for the pair and curve combination.
    error PoolExists();
    /// @dev Thrown when decimals of a token in a create pair operation are greater than 18 or less than 6.
    error DecimalsError(uint8 decimals);
    /// @dev Thrown if creating a pair with the same token.
    error SameTokenError();
    /// @dev Thrown if the amount of base tokens per liquidity is outside of the bounds 0 < x < 1.
    error PerLiquidityError(uint256 deltaBase);

    // --- Validation --- //
    /// @dev Thrown when creating a pool that has one side of the pool have zero tokens.
    error CalibrationError(uint256 deltaBase, uint256 deltaQuote);
    /// @dev Thrown if the fee used in pool creation is more than 1000.
    error MaxFee(uint16 fee);
    /// @dev Thrown if the sigma used in pool creation is zero.
    error MinSigma(uint24 sigma);
    /// @dev Thrown if the strike used in the pool creation is zero.
    error MinStrike(uint128 strike);
    /// @dev Thrown if attempting to create or swap in a pool which has eclipsed its maturity timestamp.
    error PoolExpiredError();
    /// @dev Thrown if adding or removing zero liquidity.
    error ZeroLiquidityError();

    // --- Special --- //
    /// @dev Thrown if the JIT liquidity condition is false.
    error JitLiquidity(uint256 lastTime, uint256 timestamp);

    // --- Swap --- //
    /// @dev Thrown if the effects of a swap put the pool in an invalid state according the the trading function.
    error InvariantError(int128 prev, int128 post);
}
