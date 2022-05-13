pragma solidity ^0.8.0;

interface IEnigmaErrors {
    // --- Default --- //
    error BalanceError();
    error LockedError();

    // --- Creation --- //
    error CurveExists(uint32 curveId);
    error NonExistentPool(uint48 poolId);
    error PairExists(uint16 pairId);
    error PoolExists();

    // --- Validation --- //
    error CalibrationError(uint256 deltaBase, uint256 deltaQuote);
    error MaxFee(uint16 fee);
    error MinSigma(uint24 sigma);
    error MinStrike(uint128 strike);
    error PoolExpiredError();
    error ZeroLiquidityError();

    // --- Special --- //
    error JitLiquidity(uint256 lastTime, uint256 currentTime);

    // --- Swap --- //
    error InvariantError(int128 prev, int128 post);
}
