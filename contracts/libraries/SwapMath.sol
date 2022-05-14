pragma solidity ^0.8.0;

import "./ReplicationMath.sol";
import "./Newton.sol";
import "./Units.sol";
import "./CumulativeNormalDistribution.sol";
import "hardhat/console.sol";

library SwapMath {
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;
    using CumulativeNormalDistribution for int128;
    using Units for uint256;
    using Units for int128;

    /// @notice                 Uses stablePerLiquidity and invariant to calculate riskyPerLiquidity
    /// @dev                    Converts unsigned 256-bit values to fixed point 64.64 numbers w/ decimals of precision
    /// @param   invariantLastX64   Signed 64.64 fixed point number. Calculated w/ same `tau` as the parameter `tau`
    /// @param   scaleFactorRisky   Unsigned 256-bit integer scaling factor for `risky`, 10^(18 - risky.decimals())
    /// @param   scaleFactorStable  Unsigned 256-bit integer scaling factor for `stable`, 10^(18 - stable.decimals())
    /// @param   stablePerLiquidity Unsigned 256-bit integer of Pool's stable reserves *per liquidity*, 0 <= x <= strike
    /// @param   strike         Unsigned 256-bit integer value with precision equal to 10^(18 - scaleFactorStable)
    /// @param   sigma          Volatility of the Pool as an unsigned 256-bit integer w/ precision of 1e4, 10000 = 100%
    /// @param   tau            Time until expiry in seconds as an unsigned 256-bit integer
    /// @return  riskyPerLiquidity = 1 - CDF(CDF^-1((stablePerLiquidity - invariantLastX64)/K) + sigma*sqrt(tau))
    function getRiskyGivenStable(
        int128 invariantLastX64,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint256 stablePerLiquidity,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal pure returns (uint256 riskyPerLiquidity) {
        int128 strikeX64 = strike.scaleToX64(scaleFactorStable);
        int128 volX64 = ReplicationMath.getProportionalVolatility(sigma, tau);
        int128 stableX64 = stablePerLiquidity.scaleToX64(scaleFactorStable);
        int128 phi = stableX64.sub(invariantLastX64).div(strikeX64).getInverseCDF();
        int128 input = phi.add(volX64);
        int128 riskyX64 = ReplicationMath.ONE_INT.sub(input.getCDF());
        riskyPerLiquidity = riskyX64.scaleFromX64(scaleFactorRisky);
    }
}
