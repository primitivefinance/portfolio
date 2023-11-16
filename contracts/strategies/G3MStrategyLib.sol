// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import "solmate/utils/FixedPointMathLib.sol";

using FixedPointMathLib for uint256;
using FixedPointMathLib for int256;

library G3MStrategyLib {
    /**
     * @dev Computes the invariant of the pool (rounding down) using the
     * following formula:
     *
     *        ⎛  wX⎞   ⎛  wY⎞
     *    k = ⎝rX  ⎠ ⋅ ⎝rY  ⎠
     *
     * @param reserveX Reserve of token X
     * @param weightX Weight of token X
     * @param reserveY Reserve of token Y
     * @param weightY Weight of token Y
     * @return k Invariant of the pool
     */
    function computeInvariant(
        uint256 reserveX,
        uint256 weightX,
        uint256 reserveY,
        uint256 weightY
    ) internal pure returns (uint256 k) {
        k = uint256(
            uint256(int256(reserveX).powWad(int256(weightX))).mulWadDown(
                uint256(int256(reserveY).powWad(int256(weightY)))
            )
        );
    }

    /**
     * @dev Computes the spot price of a pool using the following formula:
     *
     *       rO
     *       ──
     *       wO
     * p =  ────
     *       rI
     *       ──
     *       wI
     *
     * @param reserveOut Reserve of the output token
     * @param weightOut Weight of the output token
     * @param reserveIn Reserve of the input token
     * @param weightIn Weight of the input token
     * @return p Spot price of the pool
     */
    function computeSpotPrice(
        uint256 reserveIn,
        uint256 weightIn,
        uint256 reserveOut,
        uint256 weightOut
    ) internal pure returns (uint256 p) {
        p = reserveOut.divWadDown(weightOut).divWadDown(
            reserveIn.divWadDown(weightIn)
        );
    }

    function computeAmountInGivenExactLiquidity(
        uint256 liquidity,
        uint256 deltaLiquidity,
        uint256 reserveIn
    ) internal pure returns (uint256 amountIn) {
        amountIn = (
            (liquidity + deltaLiquidity).divWadDown(liquidity)
                - FixedPointMathLib.WAD
        ).mulWadUp(reserveIn);
    }

    function computeAmountOutGivenExactLiquidity(
        uint256 liquidity,
        uint256 deltaLiquidity,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        amountOut = (
            FixedPointMathLib.WAD
                - (liquidity - deltaLiquidity).divWadDown(liquidity)
        ).mulWadDown(reserveOut);
    }
}
