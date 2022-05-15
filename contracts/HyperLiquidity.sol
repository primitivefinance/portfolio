pragma solidity ^0.8.0;

import "@primitivefi/rmm-core/contracts/libraries/SafeCast.sol";
import "@primitivefi/rmm-core/contracts/libraries/ReplicationMath.sol";

import "./interfaces/IERC20.sol";
import "./EnigmaVirtualMachine.sol";

/// @title Hyper Liquidity
/// @notice Designed to maintain collateral for the sum of virtual liquidity across all pools.
/// @dev Processes all pool related instructions.
abstract contract HyperLiquidity is EnigmaVirtualMachine {
    using SafeCast for uint256;

    // --- View --- //

    /// @inheritdoc IEnigmaView
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

    /// @inheritdoc IEnigmaView
    function getLiquidityMinted(
        uint48 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) public view override returns (uint256 deltaLiquidity) {
        Pool memory pool = pools[poolId];
        uint256 liquidity0 = (deltaBase * pool.internalLiquidity) / uint256(pool.internalBase);
        uint256 liquidity1 = (deltaQuote * pool.internalLiquidity) / uint256(pool.internalQuote);
        deltaLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    }

    // --- Internal Functions --- //

    // --- Global --- //

    /// @dev Most important function because it manages the solvency of the Engima.
    /// @custom:security Critical. Global balances of tokens are compared with the actual `balanceOf`.
    function _increaseGlobal(address token, uint256 amount) internal {
        globalReserves[token] += amount;
        emit IncreaseGlobal(token, amount);
    }

    /// @dev Equally important to `_increaseGlobal`.
    /// @custom:security Critical. Same as above.
    function _decreaseGlobal(address token, uint256 amount) internal {
        globalReserves[token] -= amount;
        emit DecreaseGlobal(token, amount);
    }

    // --- Posiitons --- //

    /// @dev Assumes the position is properly allocated to an account by the end of the transaction.
    /// @custom:security High. Only method of increasing the liquidity held by accounts.
    function _increasePosition(uint48 poolId, uint256 deltaLiquidity) internal {
        Position storage pos = positions[msg.sender][poolId];
        pos.liquidity += deltaLiquidity.toUint128();
        pos.blockTimestamp = _blockTimestamp();

        emit IncreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    /// @dev Equally important as `_decreasePosition`.
    /// @custom:security Critical. Includes the JIT liquidity check.
    function _decreasePosition(uint48 poolId, uint256 deltaLiquidity) internal {
        Position storage pos = positions[msg.sender][poolId];
        (uint256 dist, uint256 currentTimestamp) = checkJitLiquidity(msg.sender, poolId);
        if (dist < 0) revert JitLiquidity(pos.blockTimestamp, currentTimestamp); // ToDo: Work on JIT mitigation.

        pos.liquidity -= deltaLiquidity.toUint128();
        pos.blockTimestamp = currentTimestamp.toUint128();

        emit DecreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    // --- Liquidity --- //

    /// @notice Increases internal reserves, liquidity position, and global token balance.
    /// @dev    Liquidity must be credited to an address, and token amounts must be debited.
    /// @custom:security High. Handles the state update of positions and the liquidity pool.
    function _addLiquidity(bytes calldata data) internal returns (uint48 poolId, uint256 deltaLiquidity) {
        (uint8 useMax, uint48 poolId_, uint128 deltaBase, uint128 deltaQuote) = Instructions.decodeAddLiquidity(data); // Includes opcode
        poolId = poolId_;
        // ToDo: make use of useMax flag

        if (pools[poolId].blockTimestamp == 0) revert NonExistentPool(poolId); // Pool doesn't exist.
        deltaLiquidity = getLiquidityMinted(poolId, deltaBase, deltaQuote);
        _increaseLiquidity(poolId, deltaBase, deltaQuote, deltaLiquidity);
        _increasePosition(poolId, deltaLiquidity);
    }

    /// @notice Increases the internal reserves of a pool and global reserves of the pool's token.
    /// @dev Assumes token amounts will be paid and an account's position is increased.
    /// @custom:security High. Handles the state update of the `pools` and `globalReserves` mappings.
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

        uint16 pairId = uint16(poolId >> 32); // note: first two bytes of poolId is pairId.
        Pair memory pair = pairs[pairId];

        // note: Global reserves are used at the end of instruction processing to settle transactions.
        _increaseGlobal(pair.tokenBase, deltaBase);
        _increaseGlobal(pair.tokenQuote, deltaQuote);

        emit AddLiquidity(poolId, pairId, deltaBase, deltaQuote, deltaLiquidity);
    }

    /// @notice Decreases internal pool reserves, position liquidity, and global token reserves.
    /// @dev Can revert if JIT check is triggered in `_decreasePosition`.
    /// @custom:security Critical. Most important instruction for accounts because it processes withdraws.
    function _removeLiquidity(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 deltaBase,
            uint256 deltaQuote
        )
    {
        // ToDo: make use of the useMax flag.
        // note: Does not trim the first byte (engima instruction) because the max flag is encoded in it.
        (uint8 useMax, uint48 poolId_, uint16 pairId, uint128 deltaLiquidity) = Instructions.decodeRemoveLiquidity(
            data
        );
        poolId = poolId_;

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

        Pair memory pair = pairs[pairId];
        _decreaseGlobal(pair.tokenBase, deltaBase);
        _decreaseGlobal(pair.tokenQuote, deltaQuote);

        emit RemoveLiquidity(poolId, pairId, deltaBase, deltaQuote, deltaLiquidity);
    }

    // --- Create --- //

    /// @notice Stores a set of parameters in a Curve struct at the latest `curveNonce`.
    /// @dev Sigma, maturity, and strike are validated implicitly by their limited size.
    /// @custom:security Medium. Does not handle tokens. Parameter selection is important and chosen carefully.
    function _createCurve(bytes calldata data) internal returns (uint32 curveId) {
        (uint24 sigma, uint32 maturity, uint16 fee, uint128 strike) = Instructions.decodeCreateCurve(data);
        bytes32 rawCurveId = Decoder.toBytes32(data[1:]); // note: Trim the Enigma instruction.
        curveId = getCurveIds[rawCurveId];
        if (curveId != 0) revert CurveExists(curveId);
        if (sigma == 0) revert MinSigma(sigma);
        if (strike == 0) revert MinStrike(strike);
        if (fee > MAX_POOL_FEE) revert MaxFee(fee);

        curveId = uint32(++curveNonce);
        getCurveIds[rawCurveId] = curveId; // note: This is to optimize calldata input when choosing a curve
        uint32 gamma = uint32(PERCENTAGE - fee);
        curves[curveId] = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});

        emit CreateCurve(curveId, strike, sigma, maturity, gamma);
    }

    /// @notice Stores two token address in a Pair struct at the latest `pairNonce`.
    /// @dev Pair ids that are 2 bytes are cheaper to reference than 40 bytes of two addresses.
    /// @custom:security Low. Does not handle tokens, only updates the state of the Enigma.
    function _createPair(bytes calldata data) internal returns (uint16 pairId) {
        (address base, address quote) = Instructions.decodeCreatePair(data);
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

    /// @notice A pool is composed of a pair of tokens and set of curve parameters.
    /// @dev Expects payment of tokens at the end of instruction processing.
    /// @custom:security High. Directly handles the initialization of pools including their liquidity.
    function _createPool(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 deltaBase,
            uint256 deltaQuote
        )
    {
        (uint48 poolId_, uint16 pairId, uint32 curveId, uint128 basePerLiquidity, uint128 deltaLiquidity) = Instructions
            .decodeCreatePool(data);
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
