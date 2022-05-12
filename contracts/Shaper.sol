pragma solidity ^0.8.0;

import "./libraries/ReplicationMath.sol";
import "./EnigmaVirtualMachine.sol";
import "hardhat/console.sol";

interface ShaperEvents {
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
}

interface ShaperErrors {
    error PoolExpiredError();
    error CalibrationError(uint256, uint256);
}

contract Shaper is ShaperEvents, ShaperErrors, EnigmaVirtualMachine {
    function encodePoolId(
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma
    ) public view returns (uint8) {
        return uint8(4);
    }

    function _createPair(address base, address quote) internal returns (uint8) {}

    function _create(
        uint128 strike,
        uint32 sigma,
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
        Tokens memory tkns = tokens[0]; // ToDo: fix so we have a pair id per pool id?
        (uint256 factor0, uint256 factor1) = (10**(18 - tkns.decimalsBase), 10**(18 - tkns.decimalsQuote));
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
