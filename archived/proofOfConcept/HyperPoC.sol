// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@primitivefi/rmm-core/contracts/libraries/ReplicationMath.sol";

import "./EnigmaVirtualMachinePoc.sol";
import "../../contracts/interfaces/IERC20.sol";

contract HyperPoC is EnigmaVirtualMachinePoc {
    using SafeCast for uint256;

    // ----- Liquidity ----- //

    // --- View --- //

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

    // --- Liquidity --- //

    /// @notice Increases internal reserves, liquidity position, and global token balances.
    /// @dev    Liquidity must be credited to an address, and token amounts must be debited.
    /// @custom:security High. Handles the state update of positions and the liquidity pool.
    /// @custom:mev Higher level peripheral contract should implement checks that desired liquidity is received.
    function _addLiquidity(bytes calldata data) internal returns (uint48 poolId, uint256 deltaLiquidity) {
        (uint8 useMax, uint48 poolId_, uint128 deltaBase, uint128 deltaQuote) = InstructionsPoc.decodeAddLiquidity(
            data
        );
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
        (uint8 useMax, uint48 poolId_, uint16 pairId, uint128 deltaLiquidity) = InstructionsPoc.decodeRemoveLiquidity(
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

        _decreasePositionCheckJit(poolId, deltaLiquidity);

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
        (uint24 sigma, uint32 maturity, uint16 fee, uint128 strike) = InstructionsPoc.decodeCreateCurve(data);
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
        (address base, address quote) = InstructionsPoc.decodeCreatePair(data);
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
        (
            uint48 poolId_,
            uint16 pairId,
            uint32 curveId,
            uint128 basePerLiquidity,
            uint128 deltaLiquidity
        ) = InstructionsPoc.decodeCreatePool(data);
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

    // ----- Swap ----- //

    // --- View --- //

    /// @dev Expects the latest timestamp of a pool as an argument to compute the elapsed time since maturity.
    function checkSwapMaturityCondition(uint128 lastTimestamp) public view returns (uint256 elapsed) {
        uint128 current = _blockTimestamp();
        if (current > lastTimestamp) elapsed = current - lastTimestamp; // note: Zero if not passed maturity.
    }

    /// @inheritdoc IEnigmaView
    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        public
        view
        override
        returns (uint256 deltaBase, uint256 deltaQuote)
    {
        Pool memory pool = pools[poolId];
        uint256 total = uint256(pool.internalLiquidity);
        deltaBase = (uint256(pool.internalBase) * deltaLiquidity) / total;
        deltaQuote = (uint256(pool.internalQuote) * deltaLiquidity) / total;
    }

    /// @inheritdoc IEnigmaView
    function getInvariant(uint48 poolId) public view override returns (int128 invariant) {
        Curve memory curve = curves[uint32(poolId)]; // note: Purposefully removes first two bytes through explicit conversion.
        uint32 tau = curve.maturity - uint32(pools[poolId].blockTimestamp); // note: Curve maturity can never be less than lastTimestamp.
        (uint256 basePerLiquidity, uint256 quotePerLiquidity) = getPhysicalReserves(poolId, PRECISION); // One liquidity unit.

        Pair memory pair = pairs[uint16(poolId >> 32)];
        uint256 scaleFactorBase = 10**(18 - pair.decimalsBase);
        uint256 scaleFactorQuote = 10**(18 - pair.decimalsQuote);
        invariant = ReplicationMath.calcInvariant(
            scaleFactorBase,
            scaleFactorQuote,
            basePerLiquidity,
            quotePerLiquidity,
            curve.strike,
            curve.sigma,
            tau
        );
    }

    // --- Internal --- //

    /// @dev Replaces the desired `deltaIn` amount with the `balanceOf` the `msg.sender` if the `useMax` flag is 1.
    function _swapExactForExact(bytes calldata data) internal returns (uint48 poolId, uint256 deltaOut) {
        (uint8 useMax, uint48 poolId_, uint128 deltaIn, uint128 deltaOut_, uint8 dir) = InstructionsPoc.decodeSwap(
            data
        );
        poolId = poolId_;
        deltaOut = deltaOut_;

        if (useMax == 1) {
            Pair memory pair = pairs[uint16(poolId >> 32)];
            if (dir == 0) deltaIn = _balanceOf(pair.tokenBase, msg.sender).toUint128();
            else deltaIn = _balanceOf(pair.tokenQuote, msg.sender).toUint128();
        }

        _swap(poolId, dir, deltaIn, deltaOut);
    }

    /// @notice Updates the reserves and latest timestamp of the pool at `poolId`.
    /// @dev Updates the virtual reserves and checks the pre and post invariants.
    /// @param direction Simple way to express the desired swap path. 0 = base -> quote, 1 = quote -> base.
    /// @custom:security Critical. Directly handles token amounts by altering the reserves of pools.
    /// @custom:mev Higher level peripheral contract should implement checks that desired tokens are received.
    function _swap(
        uint48 poolId,
        uint8 direction,
        uint256 input,
        uint256 output
    ) internal {
        Pool storage pool = pools[poolId];

        uint128 lastTimestamp = _updateLastTimestamp(poolId);
        uint256 secondsPastMaturity = checkSwapMaturityCondition(lastTimestamp);
        if (secondsPastMaturity > BUFFER) revert PoolExpiredError();

        int128 invariantX64 = getInvariant(poolId);
        Pair memory pair = pairs[uint16(poolId >> 32)];
        {
            Curve memory curve = curves[uint32(poolId)]; // note: Explicit conversion removes first two bytes.
            uint32 tau = curve.maturity - uint32(pool.blockTimestamp); // note: Cannot underflow.
            uint256 amountInFee = (input * curve.gamma) / PERCENTAGE;
            uint256 adjustedBase;
            uint256 adjustedQuote;

            if (direction == 0) {
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

            if (invariantX64 > invariantAfter) revert InvariantError(invariantX64, invariantAfter);

            if (direction == 0) {
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
            poolId,
            input,
            output,
            direction == 0 ? pair.tokenBase : pair.tokenQuote,
            direction == 0 ? pair.tokenQuote : pair.tokenBase
        );
    }

    /// @dev First step in a swap is to sync the pool to the block timestamp, which is used to compute the time until maturity.
    function _updateLastTimestamp(uint48 poolId) internal virtual returns (uint128 blockTimestamp) {
        Pool storage pool = pools[poolId];
        if (pool.blockTimestamp == 0) revert NonExistentPool(poolId);

        uint32 curveId = uint32(poolId); // note: Purposefully uses explicit conversion to get last 4 bytes.
        Curve storage curve = curves[curveId];
        uint32 maturity = curve.maturity;
        blockTimestamp = _blockTimestamp();
        if (blockTimestamp > maturity) blockTimestamp = maturity; // If expired, set to the maturity.

        pool.blockTimestamp = blockTimestamp; // Updates the state of the pool.
        emit UpdateLastTimestamp(poolId);
    }

    // --- External --- //

    /// @inheritdoc IEnigmaActions
    function updateLastTimestamp(uint48 poolId) external override lock returns (uint128 blockTimestamp) {
        blockTimestamp = _updateLastTimestamp(poolId);
    }
}
