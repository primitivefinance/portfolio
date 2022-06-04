pragma solidity 0.8.13;

import "solstat/Gaussian.sol";
import "solstat/Invariant.sol";

import "./EnigmaVirtualMachine.sol";

/// @dev Liquidity allocated to price space for either curve type, perpetual or expiring.
abstract contract HyperTick is EnigmaVirtualMachine {
    struct ExpiryTick {
        uint256 price;
        uint256 liquidity;
    }

    struct PerpetualTick {
        uint256 price;
        uint256 liquidity;
    }

    mapping(uint24 => ExpiryTick) public expiringTicks;
    mapping(uint24 => PerpetualTick) public perpetualTicks;

    function setPrice(uint24 tick, uint256 price) public {
        expiringTicks[tick].price = price;
    }

    /// @dev X = 1 - N(d1)
    /// d₁ = ( ln(S/K) + (σ²/2)τ ) / σ√τ
    /// X = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
    function assetOfTick(uint24 tick, uint48 poolId) public returns (uint256 x1, uint256 x2) {
        Curve memory curve = curves[uint32(poolId)];
        x1 = computeExpiryAsset(tick.price, curve.strike, curve.sigma, curve.tau);
    }

    function computeExpiryAsset(
        uint256 price,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal returns (uint256 x) {
        uint256 ln = FixedPointMathLib.lnWad(FixedPointMathLib.mulDivWad(price, 1e18, strike));
        uint256 vol = ((sigma * sigma) / Gaussian.TWO) * (tau / Gaussian.YEAR);
        uint256 lnOverVol = (ln * Gaussian.ONE) / vol;
        x = Gaussian.ONE - Gaussian.cdf(lnOverVol);
    }
}
