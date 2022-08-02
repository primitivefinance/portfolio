pragma solidity 0.8.13;

import "solstat/Gaussian.sol";
import "solstat/Invariant.sol";
import "forge-std/Test.sol";

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
        expiringTicks[tick].liquidity = 1e18;
        perpetualTicks[tick].price = price;
        perpetualTicks[tick].liquidity = 1e18;
    }

    /// @dev X = 1 - N(d1)
    /// d₁ = ( ln(S/K) + (σ²/2)τ ) / σ√τ
    /// X = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
    function assetOfTick(uint24 tick, uint48 poolId) public returns (uint256 x1, uint256 x2) {
        Curve memory curve = curves[uint32(poolId)];
        console.log("pool params");
        console.log(curve.strike);
        console.log(curve.sigma);
        unchecked {
            x1 = computeExpiryAsset(
                expiringTicks[tick].price,
                curve.strike,
                curve.sigma,
                curve.maturity - _blockTimestamp()
            );

            x2 = computeProductAsset(perpetualTicks[tick].price, perpetualTicks[tick].liquidity);
        }
    }

    error CdfErr(int256 cdf);

    function computeExpiryAsset(
        uint256 price,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal returns (uint256 x) {
        int256 ln = FixedPointMathLib.lnWad(int256(FixedPointMathLib.divWadDown(price, strike)));
        console.logInt(ln);
        uint256 sec = (tau * uint256(Gaussian.ONE)) / uint256(Invariant.YEAR);
        console.log(sec);
        uint256 doubleSigma = ((sigma * sigma) * uint256(Gaussian.ONE)) / uint256(Gaussian.TWO);
        console.log(doubleSigma);
        uint256 vol = doubleSigma * sec;
        console.log(vol);
        int256 lnOverVol = (ln * Gaussian.ONE) / int256(vol);
        console.logInt(lnOverVol);
        int256 cdf = Gaussian.cdf(lnOverVol);
        if (cdf > Gaussian.ONE) revert CdfErr(cdf);
        x = uint256(Gaussian.ONE - cdf);
    }

    /// @dev (1 - y/K)^(1/z) = x
    /// P = -(Kx)^(v^2)/(v^2x)
    /// @notice for now can do constant product? P = Y / X, X = Y / P
    function computePerpetualAsset(
        uint256 price,
        uint256 strike,
        uint256 sigma,
        uint256 rate
    ) internal returns (uint256 x) {
        /* int256 z = (Gaussian.TWO * int256(rate)) / Gaussian.ONE;
        int256 variance = (int256(sigma * sigma) * Gaussian.ONE) / 1e4;
        int256 zDenom = (z * int256(sigma * sigma)) / Gaussian.ONE;
        z = -(int(strike) *); */
    }

    /// @dev x = L / sqrt(price);
    function computeProductAsset(uint256 price, uint256 liquidity) internal returns (uint256 x) {
        uint256 sqrtPrice = FixedPointMathLib.sqrt(price);
        x = (liquidity * 1e18) / (sqrtPrice * 1e9);
    }

    function swap(uint256 amountIn, uint256 priceLimit) public {
        // Get the current price.
        uint256 price = getCurrentPrice();

        // Get the liquidity at current price.
        uint256 liquidity = getLiquidityAtPrice(price);

        // Get the next price, given the current price.
        uint256 nextPrice = getNextPrice(price);

        // Get the swap amounts and next price.
        (uint256 price0, uint256 amountIn0, uint256 amountOut) = getSwapAmounts(price, nextPrice, liquidity, amountIn);
    }

    function getCurrentPrice() public view returns (uint256) {
        return 4;
    }

    function getNextPrice(uint256 currentPrice) public view returns (uint256 nextPrice) {
        nextPrice = currentPrice * 2;
    }

    function getLiquidityAtPrice(uint256 price) public view returns (uint256 liquidity) {
        liquidity = (price * 1e10) / 2e10;
    }

    /// @dev Computes amountIn and amountOut given the change in price that has `liquidity`.
    function getSwapAmounts(
        uint256 currentPrice,
        uint256 nextPrice,
        uint256 liquidity,
        uint256 amount
    )
        public
        view
        returns (
            uint256 price,
            uint256 amountIn,
            uint256 amountOut
        )
    {}
}
