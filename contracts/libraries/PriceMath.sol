// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "solstat/Gaussian.sol";

/**
 * @dev Comprehensive library to compute x(P, L) and y(P, L)
 * given P = reported price, L = liquidity, x(g) = reserve x, y(g) = reserve y.
 */
library PriceMath {
    uint256 public constant TWO = 2;
    uint256 public constant SCALAR = 1e18;
    uint256 public constant TWO_SCALAR = 2e18;

    /**
     * @dev Computes amount of x in reserves given a price for the perpetual curve.
     * @custom:math x' = ( (P') / (aK) ) ^ (1 / (a - 1)), a = ( 2r / (2r + \sigma) )
     */
    function deltaXPerpetual(
        uint256 price,
        uint256 strike,
        uint256 sigma,
        uint256 rate
    )
        internal
        view
        returns (
            int256 res,
            int256 exponent,
            uint256 z
        )
    {
        uint256 twoR = rate * TWO;
        uint256 a = (twoR * SCALAR) / (twoR + sigma);
        z = (price * SCALAR) / ((a * strike) / SCALAR);
        exponent = (int256(SCALAR) * int256(SCALAR)) / (int256(a) - int256(SCALAR));
        res = FixedPointMathLib.powWad(int256(z), exponent);
    }

    function deltaYPerpetual() internal view returns (uint256) {}

    function deltaXExpiring() internal view returns (uint256) {}

    function deltaYExpiring() internal view returns (uint256) {}
}
