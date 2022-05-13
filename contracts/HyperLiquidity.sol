pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./interfaces/IERC20.sol";

import "./libraries/ReplicationMath.sol";
import "./libraries/SafeCast.sol";

import "./EnigmaVirtualMachine.sol";

interface HyperLiquidityErrors {
    error ZilchError();
    error ZeroLiquidityError();
    error PairExists(uint16 pairId);
    error CurveExists(uint32 curveId);
    error PoolExpiredError();
    error CalibrationError(uint256, uint256);
    error JitLiquidity(uint256 lastTime, uint256 currentTime);
}

interface HyperLiquidityEvents {
    event AddLiquidity();
    event Create(
        uint8 indexed poolId,
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 base,
        uint256 quote,
        uint256 liquidity
    );

    event CreatePool(
        uint32 indexed poolId,
        uint16 indexed pairId,
        uint32 indexed curveId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );
    event CreatePair(uint16 indexed pairId, address indexed base, address indexed quote);
    event CreateCurve(
        uint32 indexed curveId,
        uint128 strike,
        uint24 sigma,
        uint32 indexed maturity,
        uint32 indexed gamma
    );

    event IncreaseGlobal(address indexed base, address indexed quote, uint256 deltaBase, uint256 deltaQuote);
    event DecreaseGlobal(address indexed base, address indexed quote, uint256 deltaBase, uint256 deltaQuote);
}

/// @notice Designed to maintain collateral for the sum of virtual liquidity across all pools.
contract HyperLiquidity is HyperLiquidityErrors, HyperLiquidityEvents, EnigmaVirtualMachine {
    using SafeCast for uint256;

    // --- View --- //

    /// @notice Gets base and quote pairs entitled to argument `liquidity`.
    function getPhysicalReserves(uint32 poolId, uint256 liquidity) public view returns (uint256 base, uint256 quote) {
        Pool memory pool = pools[poolId];
        uint256 total = uint256(pool.internalLiquidity);
        base = (uint256(pool.internalBase) * liquidity) / total;
        quote = (uint256(pool.internalQuote) * liquidity) / total;
    }

    /// @notice Computes the pro-rata amount of liquidity minted from allocating `deltaBase` and `deltaQuote` amounts.
    function getLiquidityMinted(
        uint32 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) public view returns (uint256 deltaLiquidity) {
        Pool memory pool = pools[poolId];
        uint256 liquidity0 = (deltaBase * pool.internalLiquidity) / uint256(pool.internalBase);
        uint256 liquidity1 = (deltaQuote * pool.internalLiquidity) / uint256(pool.internalQuote);
        deltaLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    }

    /// @notice Computes the amount of time passed since the Position's liquidity was updated.
    function checkJitLiquidity(address account, uint32 posId)
        public
        view
        returns (uint256 distance, uint256 currentTime)
    {
        Position memory pos = positions[account][posId];
        // ToDo: implement jit mitigation logic.
        currentTime = _blockTimestamp();
        distance = currentTime - pos.blockTimestamp;
    }

    // --- Internal Functions --- //

    /// @dev Assumes token amounts will be paid and an account's position is increased.
    function _increaseLiquidity(
        uint32 poolId,
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

        _increaseGlobal(uint16(poolId), deltaBase, deltaQuote); // Compared against later to settle operation.
    }

    /// @dev Assumes the position is properly allocated to an account by the end of the transaction.
    function _increasePosition(uint32 posId, uint256 deltaLiquidity) internal {
        Position storage pos = positions[msg.sender][uint8(posId)]; // ToDo: work on position ids.
        pos.liquidity += deltaLiquidity.toUint128();
        pos.blockTimestamp = _blockTimestamp();
    }

    function _decreasePosition(uint32 posId, uint256 deltaLiquidity) internal {
        Position storage pos = positions[msg.sender][uint8(posId)]; // ToDo: work on position ids.
        (uint256 dist, uint256 currentTimestamp) = checkJitLiquidity(msg.sender, posId);
        if (dist < 0) revert JitLiquidity(pos.blockTimestamp, currentTimestamp); // ToDo: Work on JIT mitigation.

        pos.liquidity -= deltaLiquidity.toUint128();
        pos.blockTimestamp = currentTimestamp.toUint128();
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
    function _addLiquidity(
        uint32 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) internal returns (uint256 deltaLiquidity) {
        if (pools[poolId].blockTimestamp == 0) revert ZilchError(); // Pool doesn't exist.
        deltaLiquidity = getLiquidityMinted(poolId, deltaBase, deltaQuote);
        _increaseLiquidity(poolId, deltaBase, deltaQuote, deltaLiquidity);
        _increasePosition(poolId, deltaLiquidity);
    }

    function _removeLiquidity(uint32 poolId, uint256 deltaLiquidity)
        internal
        returns (uint256 deltaBase, uint256 deltaQuote)
    {
        Pool storage pool = pools[poolId];
        if (pool.blockTimestamp == 0) revert ZilchError();

        deltaBase = (pool.internalBase * deltaLiquidity) / pool.internalLiquidity;
        deltaQuote = (pool.internalQuote * deltaLiquidity) / pool.internalLiquidity;

        if (deltaLiquidity == 0) revert ZeroLiquidityError();

        pool.internalBase -= (deltaBase).toUint128();
        pool.internalQuote -= (deltaQuote).toUint128();
        pool.internalLiquidity -= (deltaLiquidity).toUint128();
        pool.blockTimestamp = _blockTimestamp();

        _decreasePosition(poolId, deltaLiquidity);

        // ToDo: get the pairId
        uint16 pairId = uint16(poolId);
        _decreaseGlobal(pairId, deltaBase, deltaQuote);
    }

    // --- Create --- //

    function encodePoolId(
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma
    ) public view returns (uint8) {
        return uint8(4);
    }

    uint256 public pairNonce;
    mapping(address => mapping(address => uint16)) public getPairId;
    mapping(bytes32 => uint32) public getCurveIds;

    uint256 public curveNonce;

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

    function _createCurve(bytes calldata data) internal returns (uint32 curveId) {
        (uint24 sigma, uint32 maturity, uint16 fee, uint128 strike) = Instructions.decodeCreateCurve(data);
        bytes32 rawCurveId = Decoder.toBytes32(data);
        curveId = getCurveIds[rawCurveId];
        if (curveId != 0) revert CurveExists(curveId);

        curveId = uint32(++curveNonce);
        getCurveIds[rawCurveId] = curveId; // note: this is to optimize calldata input when choosing a curve
        uint32 gamma = uint32(1e4 - fee);
        curves[curveId] = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});
        emit CreateCurve(curveId, strike, sigma, maturity, gamma);
    }

    function _createPool(bytes calldata data) internal returns (uint32 poolId) {
        (uint48 poolId, uint16 pairId, uint32 curveId) = Instructions.decodePoolId(data);
    }

    function _createPool(
        uint16 pairId,
        uint32 curveId,
        uint256 riskyPerLp,
        uint256 deltaLiquidity
    )
        internal
        returns (
            uint32 poolId,
            uint256 deltaBase,
            uint256 deltaQuote
        )
    {
        poolId = encodePoolId(11, 11, 11, 11);
        Curve memory curve = curves[curveId];
        uint128 lastTimestamp = _blockTimestamp();
        if (lastTimestamp > curve.maturity) revert PoolExpiredError();

        Pair memory pair = pairs[pairId];
        (uint256 factor0, uint256 factor1) = (10**(18 - pair.decimalsBase), 10**(18 - pair.decimalsQuote));
        require(riskyPerLp <= PRECISION / factor0, "Too much base");

        uint32 tau = curve.maturity - uint32(lastTimestamp); // time until expiry
        deltaQuote = ReplicationMath.getStableGivenRisky(
            0,
            factor0,
            factor1,
            riskyPerLp,
            curve.strike,
            curve.sigma,
            tau
        );
        deltaBase = (riskyPerLp * deltaLiquidity) / PRECISION; // riskyDecimals * 1e18 decimals / 1e18 = riskyDecimals
        deltaQuote = (deltaQuote * deltaLiquidity) / PRECISION;

        if (deltaBase == 0 || deltaQuote == 0) revert CalibrationError(deltaBase, deltaQuote);
        _increaseLiquidity(poolId, deltaBase, deltaQuote, deltaLiquidity);

        uint256 lowestDecimals = (pair.decimalsBase > pair.decimalsQuote ? pair.decimalsQuote : pair.decimalsBase);
        uint256 minLiquidity = 10**(lowestDecimals / MIN_LIQUIDITY_FACTOR);
        uint256 positionLiquidity = deltaLiquidity - minLiquidity; // Permanently burned.
        _increasePosition(poolId, positionLiquidity);

        emit CreatePool(poolId, pairId, curveId, deltaBase, deltaQuote, deltaLiquidity);
    }
}
