// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@primitivefi/rmm-core/contracts/libraries/ReplicationMath.sol";
import "@primitivefi/rmm-core/contracts/libraries/SafeCast.sol";

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
        returns (uint256 distance, uint256 timestamp)
    {
        Position memory pos = positions[account][poolId];
        timestamp = _blockTimestamp();
        distance = timestamp - pos.blockTimestamp;
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

    // --- Internal --- //

    // --- Global --- //

    /// @dev Most important function because it manages the solvency of the Engima.
    /// @custom:security Critical. Global balances of tokens are compared with the actual `balanceOf`.
    function _increaseGlobal(address token, uint256 amount) internal {
        globalReserves[token] += amount;
        emit IncreaseGlobal(token, amount);
    }

    /// @dev Equally important to `_increaseGlobal`.
    /// @custom:security Critical. Same as above. Implicitly reverts on underflow.
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
    /// @custom:security Critical. Includes the JIT liquidity check. Implicitly reverts on liquidity underflow.
    function _decreasePosition(uint48 poolId, uint256 deltaLiquidity) internal {
        Position storage pos = positions[msg.sender][poolId];
        (uint256 distance, uint256 timestamp) = checkJitLiquidity(msg.sender, poolId);
        if (_liquidityPolicy() > distance) revert JitLiquidity(pos.blockTimestamp, timestamp);

        pos.liquidity -= deltaLiquidity.toUint128();
        pos.blockTimestamp = timestamp.toUint128();

        emit DecreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    // --- Liquidity --- //

    /// @notice Increases internal reserves, liquidity position, and global token balances.
    /// @dev    Liquidity must be credited to an address, and token amounts must be debited.
    /// @custom:security High. Handles the state update of positions and the liquidity pool.
    /// @custom:mev Higher level peripheral contract should implement checks that desired liquidity is received.
    function _addLiquidity(bytes calldata data) internal returns (uint48 poolId, uint256 deltaLiquidity) {
        (uint8 useMax, uint48 poolId_, uint128 deltaBase, uint128 deltaQuote) = Instructions.decodeAddLiquidity(data);
        poolId = poolId_;

        if (pools[poolId].blockTimestamp == 0) revert NonExistentPool(poolId);

        if (useMax == 1) {
            Pair memory pair = pairs[uint16(poolId >> 32)];
            deltaBase = _balanceOf(pair.tokenBase, msg.sender).toUint128();
            deltaQuote = _balanceOf(pair.tokenQuote, msg.sender).toUint128();
        }

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

        Pool storage pool = pools[poolId]; // note: Dangerous! Expects the pool is being created or it was previously checked that the pool exists.
        pool.internalBase += deltaBase.toUint128();
        pool.internalQuote += deltaQuote.toUint128();
        pool.internalLiquidity += deltaLiquidity.toUint128();
        pool.blockTimestamp = _blockTimestamp();

        uint16 pairId = uint16(poolId >> 32);
        Pair memory pair = pairs[pairId];

        // note: Global reserves are used at the end of instruction processing to settle transactions.
        _increaseGlobal(pair.tokenBase, deltaBase);
        _increaseGlobal(pair.tokenQuote, deltaQuote);

        emit AddLiquidity(poolId, pairId, deltaBase, deltaQuote, deltaLiquidity);
    }

    /// @notice Decreases internal pool reserves, position liquidity, and global token reserves.
    /// @dev Rounding happens in favor of contract. Can revert if JIT check is triggered in `_decreasePosition`.
    /// @custom:security Critical. Most important instruction for accounts because it processes withdraws.
    function _removeLiquidity(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 deltaBase,
            uint256 deltaQuote
        )
    {
        (uint8 useMax, uint48 poolId_, uint16 pairId, uint128 deltaLiquidity) = Instructions.decodeRemoveLiquidity(
            data
        );
        poolId = poolId_;
        Pool storage pool = pools[poolId];
        if (pool.blockTimestamp == 0) revert NonExistentPool(poolId);

        if (useMax == 1) {
            deltaLiquidity = positions[msg.sender][poolId].liquidity;
        }

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
    /// @custom:security Medium. Does not handle tokens. Parameter selection is important, so choose carefully.
    function _createCurve(bytes calldata data) internal returns (uint32 curveId) {
        (uint24 sigma, uint32 maturity, uint16 fee, uint128 strike) = Instructions.decodeCreateCurve(data);
        bytes32 rawCurveId = Decoder.toBytes32(data[1:]); // note: Trims the Enigma instruction.
        curveId = getCurveIds[rawCurveId];

        if (curveId != 0) revert CurveExists(curveId);
        if (sigma == 0) revert MinSigma(sigma);
        if (strike == 0) revert MinStrike(strike);
        if (fee > MAX_POOL_FEE) revert MaxFee(fee);

        curveId = uint32(++curveNonce); // note: Unlikely to reach this limit, but possible on high tps networks.
        getCurveIds[rawCurveId] = curveId; // note: This is to optimize calldata input when choosing a curve.
        uint32 gamma = uint32(PERCENTAGE - fee);
        curves[curveId] = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});

        emit CreateCurve(curveId, strike, sigma, maturity, gamma);
    }

    /// @notice Stores two token address in a Pair struct at the latest `pairNonce`.
    /// @dev Pair ids that are 2 bytes are cheaper to reference in calldata than 40 bytes.
    /// @custom:security Low. Does not handle tokens, only updates the state of the Enigma.
    function _createPair(bytes calldata data) internal returns (uint16 pairId) {
        (address base, address quote) = Instructions.decodeCreatePair(data);
        if (base == quote) revert SameTokenError();

        pairId = getPairId[base][quote];
        if (pairId != 0) revert PairExists(pairId);

        uint8 decimalsBase = IERC20(base).decimals();
        uint8 decimalsQuote = IERC20(quote).decimals();
        if (decimalsBase > 18 || decimalsBase < 6) revert DecimalsError(decimalsBase);
        if (decimalsQuote > 18 || decimalsQuote < 6) revert DecimalsError(decimalsQuote);

        pairId = uint16(++pairNonce);
        getPairId[base][quote] = pairId; // note: No reverse lookup, because order matters!
        pairs[pairId] = Pair({
            tokenBase: base,
            decimalsBase: decimalsBase,
            tokenQuote: quote,
            decimalsQuote: decimalsQuote
        });

        emit CreatePair(pairId, base, quote);
    }

    /// @notice A pool is composed of a pair of tokens and set of curve parameters.
    /// @dev Expects payment of tokens at the end of instruction processing. Burns a min amount of liquidity.
    /// @custom:security High. Directly handles the initialization of pools, including their liquidity.
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
        if (pools[poolId].blockTimestamp != 0) revert PoolExists();

        Curve memory curve = curves[curveId];
        uint128 timestamp = _blockTimestamp();
        if (timestamp > curve.maturity) revert PoolExpiredError();

        uint256 minLiquidity;
        {
            Pair memory pair = pairs[pairId];
            (uint256 factor0, uint256 factor1) = (10**(18 - pair.decimalsBase), 10**(18 - pair.decimalsQuote));
            if (basePerLiquidity > PRECISION / factor0 || basePerLiquidity == 0)
                revert PerLiquidityError(basePerLiquidity);

            uint256 lowestDecimals = (pair.decimalsBase > pair.decimalsQuote ? pair.decimalsQuote : pair.decimalsBase);
            minLiquidity = 10**(lowestDecimals / MIN_LIQUIDITY_FACTOR);

            uint32 tau = curve.maturity - uint32(timestamp); // Time until maturity in seconds.
            deltaQuote = ReplicationMath.getStableGivenRisky(
                0,
                factor0,
                factor1,
                basePerLiquidity,
                curve.strike,
                curve.sigma,
                tau
            );
            deltaBase = (basePerLiquidity * deltaLiquidity) / PRECISION;
            deltaQuote = (deltaQuote * deltaLiquidity) / PRECISION;
        }

        if (deltaBase == 0 || deltaQuote == 0) revert CalibrationError(deltaBase, deltaQuote);
        _increaseLiquidity(poolId, deltaBase, deltaQuote, deltaLiquidity);

        uint256 positionLiquidity = deltaLiquidity - minLiquidity; // note: Permanently burned.
        _increasePosition(poolId, positionLiquidity);

        emit CreatePool(poolId, pairId, curveId, deltaBase, deltaQuote, deltaLiquidity);
    }
}
