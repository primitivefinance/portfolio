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
    event CreatePair(uint16 indexed pairId, address indexed base, address indexed quote);
    event CreateCurve(
        uint32 indexed curveId,
        uint128 strike,
        uint24 sigma,
        uint32 indexed maturity,
        uint32 indexed gamma
    );
}

/// @notice Designed to maintain collateral for the sum of virtual liquidity across all pools.
contract HyperLiquidity is HyperLiquidityErrors, HyperLiquidityEvents, EnigmaVirtualMachine {
    using SafeCast for uint256;

    // --- View --- //

    /// Gets base and quote pairs entitled to argument `liquidity`.
    function getPhysicalReserves(uint256 liquidity) public view returns (uint256, uint256) {
        Pool memory pool = pools[0];
        uint256 total = uint256(pool.internalLiquidity);
        uint256 amount0 = (pool.internalBase * liquidity) / total;
        uint256 amount1 = (pool.internalQuote * liquidity) / total;
        return (amount0, amount1);
    }

    // --- Internal Functions --- //

    function _getLiquidityMinted(
        uint32 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) internal view returns (uint256 deltaLiquidity) {
        Pool memory pool = pools[poolId];
        uint256 liquidity0 = (deltaBase * pool.internalLiquidity) / uint256(pool.internalBase);
        uint256 liquidity1 = (deltaQuote * pool.internalLiquidity) / uint256(pool.internalQuote);
        deltaLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    }

    function _increaseLiquidity(
        uint32 poolId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    ) internal {
        if (deltaLiquidity == 0) revert ZeroLiquidityError();
        Pool storage pool = pools[poolId];
        if (pool.blockTimestamp == 0) revert ZilchError();

        pool.internalBase += (deltaBase).toUint128();
        pool.internalQuote += (deltaQuote).toUint128();
        pool.internalLiquidity += (deltaLiquidity).toUint128();
        pool.blockTimestamp = _blockTimestamp();

        _increaseGlobal(uint16(poolId), deltaBase, deltaQuote);
    }

    function _increasePosition(uint32 posId, uint256 deltaLiquidity) internal {
        Position storage pos = positions[msg.sender][uint8(posId)]; // ToDo: work on position ids.
        pos.liquidity += (deltaLiquidity).toUint128();
        pos.blockTimestamp = _blockTimestamp();
    }

    function _increaseGlobal(
        uint16 pairId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) internal {
        Pair storage pair = pairs[pairId];
        globalReserves[pair.tokenBase] -= deltaBase;
        globalReserves[pair.tokenQuote] -= deltaQuote;
    }

    /// @notice Changes internal "fake" reserves of a pool with `poolId`.
    /// @dev    Liquidity must be credited to an address, and token amounts must be _applyDebited.
    function _addLiquidity(
        uint32 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) internal {
        uint256 deltaLiquidity = _getLiquidityMinted(poolId, deltaBase, deltaQuote);
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

        Pair storage pair = pairs[uint16(poolId)];
        globalReserves[pair.tokenBase] -= deltaBase;
        globalReserves[pair.tokenQuote] -= deltaQuote;

        Position storage pos = positions[msg.sender][poolId];
        pos.liquidity -= (deltaLiquidity).toUint128();
        pos.blockTimestamp = _blockTimestamp();
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
        (uint128 strike, uint24 sigma, uint32 maturity, uint16 fee) = Instructions.decodeCreateCurve(data);
        bytes32 rawCurveId = Decoder.toBytes32(data);
        curveId = getCurveIds[rawCurveId];
        if (curveId != 0) revert CurveExists(curveId);

        curveId = uint32(++curveNonce);
        getCurveIds[rawCurveId] = curveId; // note: this is to optimize calldata input when choosing a curve
        uint32 gamma = uint32(1e4 - fee);
        curves[curveId] = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});
        emit CreateCurve(curveId, strike, sigma, maturity, gamma);
    }

    function _createPool(bytes calldata data) internal returns (uint32 poolId) {}

    function _createPool(
        uint128 strike,
        uint24 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 riskyPerLp,
        uint256 deltaLiquidity
    )
        internal
        returns (
            uint8 poolId,
            uint256 deltaBase,
            uint256 deltaQuote
        )
    {
        // ToDo: adjust based on min token decimals.
        uint256 MIN_LIQUIDITY = 1e2;
        uint128 lastTimestamp = _blockTimestamp();

        poolId = encodePoolId(strike, sigma, maturity, gamma);
        // ToDo: Parameter validation
        Curve memory curve = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});

        if (lastTimestamp > curve.maturity) revert PoolExpiredError();
        Pair memory pair = pairs[0]; // ToDo: fix so we have a pair poolId per pool poolId?
        (uint256 factor0, uint256 factor1) = (10**(18 - pair.decimalsBase), 10**(18 - pair.decimalsQuote));
        console.log(factor0);
        require(riskyPerLp <= PRECISION / factor0, "Too much base");
        uint32 tau = curve.maturity - uint32(lastTimestamp); // time until expiry
        console.log(tau);
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
        curves[poolId] = curve; // state update

        uint256 amount = deltaLiquidity - MIN_LIQUIDITY;

        _increaseLiquidity(poolId, deltaBase, deltaQuote, deltaLiquidity);
        _increasePosition(poolId, amount);

        //emit Create(poolId, curve.strike, curve.sigma, curve.maturity, curve.gamma, deltaBase, deltaQuote, amount);
    }
}
