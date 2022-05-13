pragma solidity ^0.8.0;

import "./libraries/ReplicationMath.sol";
import "./EnigmaVirtualMachine.sol";
import "hardhat/console.sol";
import "./interfaces/IERC20.sol";

interface HyperCreateEvents {
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

interface HyperCreateErrors {
    error PairExists(uint16 pairId);
    error CurveExists(uint32 curveId);
    error PoolExpiredError();
    error CalibrationError(uint256, uint256);
}

contract HyperCreate is HyperCreateEvents, HyperCreateErrors, EnigmaVirtualMachine {
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

    function _createPool(
        uint128 strike,
        uint24 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 riskyPerLp,
        uint256 delLiquidity
    )
        internal
        returns (
            uint8 poolId,
            uint256 delRisky,
            uint256 delStable
        )
    {
        // ToDo: adjust based on min token decimals.
        uint256 MIN_LIQUIDITY = 1e2;
        uint128 lastTimestamp = _blockTimestamp();

        poolId = encodePoolId(strike, sigma, maturity, gamma);
        // ToDo: Parameter validation
        Curve memory curve = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});

        if (lastTimestamp > curve.maturity) revert PoolExpiredError();
        Pair memory pair = pairs[0]; // ToDo: fix so we have a pair id per pool id?
        (uint256 factor0, uint256 factor1) = (10**(18 - pair.decimalsBase), 10**(18 - pair.decimalsQuote));
        console.log(factor0);
        require(riskyPerLp <= PRECISION / factor0, "Too much base");
        uint32 tau = curve.maturity - uint32(lastTimestamp); // time until expiry
        console.log(tau);
        delStable = ReplicationMath.getStableGivenRisky(
            0,
            factor0,
            factor1,
            riskyPerLp,
            curve.strike,
            curve.sigma,
            tau
        );
        delRisky = (riskyPerLp * delLiquidity) / PRECISION; // riskyDecimals * 1e18 decimals / 1e18 = riskyDecimals
        delStable = (delStable * delLiquidity) / PRECISION;

        if (delRisky == 0 || delStable == 0) revert CalibrationError(delRisky, delStable);
        curves[poolId] = curve; // state update

        Position storage pos = positions[msg.sender][poolId];
        uint256 amount = delLiquidity - MIN_LIQUIDITY;
        pos.liquidity += amount; // burn min liquidity, at cost of msg.sender
        pos.blockTimestamp = lastTimestamp;

        Pool storage pool = pools[poolId];
        pool.internalBase += uint128(delRisky);
        pool.internalQuote += uint128(delStable);
        pool.internalLiquidity += uint128(delLiquidity);
        pool.blockTimestamp = lastTimestamp;

        //emit Create(poolId, curve.strike, curve.sigma, curve.maturity, curve.gamma, delRisky, delStable, amount);
    }
}
