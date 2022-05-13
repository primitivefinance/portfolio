pragma solidity ^0.8.0;

import "./EnigmaVirtualMachine.sol";
import "./interfaces/IERC20.sol";
import "./libraries/ReplicationMath.sol";
import "./libraries/SafeCast.sol";

/// @notice Designed to maintain collateral for the sum of virtual liquidity across all pools.
contract HyperLiquidity is EnigmaVirtualMachine {
    using SafeCast for uint256;

    // --- View --- //

    /// @notice Computes the pro-rata amount of liquidity minted from allocating `deltaBase` and `deltaQuote` amounts.
    function getLiquidityMinted(
        uint48 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) public view returns (uint256 deltaLiquidity) {
        Pool memory pool = pools[poolId];
        uint256 liquidity0 = (deltaBase * pool.internalLiquidity) / uint256(pool.internalBase);
        uint256 liquidity1 = (deltaQuote * pool.internalLiquidity) / uint256(pool.internalQuote);
        deltaLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    }

    /// @notice Computes the amount of time passed since the Position's liquidity was updated.
    function checkJitLiquidity(address account, uint48 poolId)
        public
        view
        returns (uint256 distance, uint256 currentTime)
    {
        Position memory pos = positions[account][poolId];
        // ToDo: implement jit mitigation logic.
        currentTime = _blockTimestamp();
        distance = currentTime - pos.blockTimestamp;
    }

    // --- Internal Functions --- //

    /// @dev Assumes token amounts will be paid and an account's position is increased.
    function _increaseLiquidity(
        uint48 poolId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    ) internal {
        if (deltaLiquidity == 0) revert ZeroLiquidityError();

        Pool storage pool = pools[poolId]; // note: Dangerous! If we get here before creating a pool that's bad.
        pool.internalBase += deltaBase.toUint128();
        pool.internalQuote += deltaQuote.toUint128();
        pool.internalLiquidity += deltaLiquidity.toUint128();
        pool.blockTimestamp = _blockTimestamp();

        uint16 pairId = uint16(poolId >> 32); // ToDo: use actual pair
        _increaseGlobal(pairId, deltaBase, deltaQuote); // Compared against later to settle operation.

        emit AddLiquidity(poolId, pairId, deltaBase, deltaQuote, deltaLiquidity);
    }

    /// @dev Assumes the position is properly allocated to an account by the end of the transaction.
    function _increasePosition(uint48 poolId, uint256 deltaLiquidity) internal {
        Position storage pos = positions[msg.sender][poolId];
        pos.liquidity += deltaLiquidity.toUint128();
        pos.blockTimestamp = _blockTimestamp();

        emit IncreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    function _decreasePosition(uint48 poolId, uint256 deltaLiquidity) internal {
        Position storage pos = positions[msg.sender][poolId];
        (uint256 dist, uint256 currentTimestamp) = checkJitLiquidity(msg.sender, poolId);
        if (dist < 0) revert JitLiquidity(pos.blockTimestamp, currentTimestamp); // ToDo: Work on JIT mitigation.

        pos.liquidity -= deltaLiquidity.toUint128();
        pos.blockTimestamp = currentTimestamp.toUint128();

        emit DecreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    /// @dev Most important function because it manages the solvency of the Engima.
    function _increaseGlobal(
        uint16 pairId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) internal {
        Pair memory pair = pairs[pairId];
        globalReserves[pair.tokenBase] += deltaBase;
        globalReserves[pair.tokenQuote] += deltaQuote;
        emit IncreaseGlobal(pair.tokenBase, pair.tokenQuote, deltaBase, deltaQuote);
    }

    /// @dev Most important function because it manages the solvency of the Engima.
    function _decreaseGlobal(
        uint16 pairId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) internal {
        Pair memory pair = pairs[pairId];
        globalReserves[pair.tokenBase] -= deltaBase.toUint128();
        globalReserves[pair.tokenQuote] -= deltaQuote.toUint128();
        emit DecreaseGlobal(pair.tokenBase, pair.tokenQuote, deltaBase, deltaQuote);
    }

    /// @notice Changes internal "fake" reserves of a pool with `poolId`.
    /// @dev    Liquidity must be credited to an address, and token amounts must be _applyDebited.
    function _addLiquidity(bytes calldata data) internal returns (uint256 deltaLiquidity) {
        (uint8 useMax, uint48 poolId, uint128 deltaBase, uint128 deltaQuote) = Instructions.decodeAddLiquidity(data); // Includes opcode
        // ToDo: make use of useMax flag

        if (pools[poolId].blockTimestamp == 0) revert NonExistentPool(poolId); // Pool doesn't exist.
        deltaLiquidity = getLiquidityMinted(poolId, deltaBase, deltaQuote);
        _increaseLiquidity(poolId, deltaBase, deltaQuote, deltaLiquidity);
        _increasePosition(poolId, deltaLiquidity);
    }

    function _removeLiquidity(bytes calldata data) internal returns (uint256 deltaBase, uint256 deltaQuote) {
        // ToDo: make use of the useMax flag.
        // note: Does not trim the first byte (engima instruction) because the max flag is encoded in it.
        (uint8 useMax, uint48 poolId, uint16 pairId, uint128 deltaLiquidity) = Instructions.decodeRemoveLiquidity(data);

        Pool storage pool = pools[poolId];
        if (pool.blockTimestamp == 0) revert NonExistentPool(poolId);

        deltaBase = (pool.internalBase * deltaLiquidity) / pool.internalLiquidity;
        deltaQuote = (pool.internalQuote * deltaLiquidity) / pool.internalLiquidity;

        if (deltaLiquidity == 0) revert ZeroLiquidityError();

        pool.internalBase -= deltaBase.toUint128();
        pool.internalQuote -= deltaQuote.toUint128();
        pool.internalLiquidity -= deltaLiquidity;
        pool.blockTimestamp = _blockTimestamp();

        _decreasePosition(poolId, deltaLiquidity);
        _decreaseGlobal(pairId, deltaBase, deltaQuote);

        emit RemoveLiquidity(poolId, pairId, deltaBase, deltaQuote, deltaLiquidity);
    }

    // --- Create --- //

    function _createPair(bytes calldata data) internal returns (uint16 pairId) {
        (address base, address quote) = Instructions.decodeCreatePair(data[1:]);
        pairId = getPairId[base][quote];
        if (pairId != 0) revert PairExists(pairId);

        pairId = uint16(++pairNonce);
        getPairId[base][quote] = pairId; // note: no reverse lookup, because order matters!
        pairs[pairId] = Pair({
            tokenBase: base,
            decimalsBase: IERC20(base).decimals(),
            tokenQuote: quote,
            decimalsQuote: IERC20(quote).decimals()
        });

        emit CreatePair(pairId, base, quote);
    }

    /// @dev Sets a Curve at the `curveId`. Sigma, maturity, and strike are validated implicitly by their limited size.
    function _createCurve(bytes calldata data) internal returns (uint32 curveId) {
        (uint24 sigma, uint32 maturity, uint16 fee, uint128 strike) = Instructions.decodeCreateCurve(data[1:]);
        bytes32 rawCurveId = Decoder.toBytes32(data[1:]); // note: trim the enigma instruction.
        curveId = getCurveIds[rawCurveId];
        if (curveId != 0) revert CurveExists(curveId);
        if (sigma == 0) revert MinSigma(sigma);
        if (strike == 0) revert MinStrike(strike);
        if (fee > MAX_POOL_FEE) revert MaxFee(fee);

        curveId = uint32(++curveNonce);
        getCurveIds[rawCurveId] = curveId; // note: this is to optimize calldata input when choosing a curve
        uint32 gamma = uint32(PERCENTAGE - fee);
        curves[curveId] = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});

        emit CreateCurve(curveId, strike, sigma, maturity, gamma);
    }

    function _createPool(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 deltaBase,
            uint256 deltaQuote
        )
    {
        // note: slices the instruction byte.
        (uint48 poolId_, uint16 pairId, uint32 curveId, uint128 basePerLiquidity, uint128 deltaLiquidity) = Instructions
            .decodeCreatePool(data[1:]);
        poolId = poolId_;

        Curve memory curve = curves[curveId];
        if (pools[poolId].blockTimestamp != 0) revert PoolExists();
        uint128 blockTimestamp = _blockTimestamp();
        if (blockTimestamp > curve.maturity) revert PoolExpiredError();
        uint256 minLiquidity;

        {
            Pair memory pair = pairs[pairId];
            (uint256 factor0, uint256 factor1) = (10**(18 - pair.decimalsBase), 10**(18 - pair.decimalsQuote));
            require(basePerLiquidity <= PRECISION / factor0, "Too much base");
            uint256 lowestDecimals = (pair.decimalsBase > pair.decimalsQuote ? pair.decimalsQuote : pair.decimalsBase);
            minLiquidity = 10**(lowestDecimals / MIN_LIQUIDITY_FACTOR);

            uint32 tau = curve.maturity - uint32(blockTimestamp); // time until expiry
            deltaQuote = ReplicationMath.getStableGivenRisky(
                0,
                factor0,
                factor1,
                basePerLiquidity,
                curve.strike,
                curve.sigma,
                tau
            );
            deltaBase = (basePerLiquidity * deltaLiquidity) / PRECISION; // riskyDecimals * 1e18 decimals / 1e18 = riskyDecimals
            deltaQuote = (deltaQuote * deltaLiquidity) / PRECISION;
        }

        if (deltaBase == 0 || deltaQuote == 0) revert CalibrationError(deltaBase, deltaQuote);
        _increaseLiquidity(poolId, deltaBase, deltaQuote, deltaLiquidity);

        uint256 positionLiquidity = deltaLiquidity - minLiquidity; // Permanently burned.
        _increasePosition(poolId, positionLiquidity);

        emit CreatePool(poolId, pairId, curveId, deltaBase, deltaQuote, deltaLiquidity);
    }
}
