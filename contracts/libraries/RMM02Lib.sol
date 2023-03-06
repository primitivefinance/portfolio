// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "solmate/utils/FixedPointMathLib.sol";
import {PortfolioPool} from "../PortfolioLib.sol";

/**
 * @title  RMM02Lib
 * @author Primitive™
 * @dev    Geometric mean portfolio for two tokens.
 */
library RMM02Lib {
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    /**
     * @dev Computes the invariant of the RMM-02 trading function.
     * @param self Pool instance.
     * @param R_x Quantity of `asset` reserves scaled to WAD units per WAD of liquidity.
     * @param R_y Quantity of `quote` reserves scaled to WAD units per WAD of liquidity.
     * @param weight Percentage in WAD units of the portfolio value denominated in `asset` token.
     * @return invariantWad Signed invariant scaled to WAD units.
     * @custom:math k = 1 - (R_x / w)^(w) (R_y/(1 - w))^(1 - w)
     */
    function invariantOf(
        PortfolioPool memory self,
        uint256 R_x,
        uint256 R_y,
        uint256 weight
    ) internal pure returns (int256 invariantWad) {
        self; // todo: Keeps same api as RMM01Lib, but can be changed.
        uint256 w_x = weight;
        uint256 w_y = FixedPointMathLib.WAD - weight;

        int256 p_x = int256(R_x.divWadDown(w_x)).powWad(int256(w_x)); // (R_x / w_x) ^ w_x
        int256 p_y = int256(R_y.divWadDown(w_y)).powWad(int256(w_y)); // (R_y / (1 - w_x)) ^ (1 - w_x)

        invariantWad = (p_x * p_y) / int256(FixedPointMathLib.WAD); // Rounds down.
    }

    /**
     * @dev Approximation of amount out of tokens given a swap `amountIn`.
     * @param amountIn Quantity of tokens in, units are native token decimals.
     * @param weightIn Percentage in WAD units of the portfolio's value denominated in the token being swapped in.
     * @return amountOut Quantity of tokens out, units are in native token decimals.
     */
    function getAmountOut(
        PortfolioPool memory self,
        bool sellAsset,
        uint256 amountIn,
        uint256 weightIn
    ) internal pure returns (uint256 amountOut) {
        self; // todo: Keeps same api as RMM01 lib, but can be changed.
        if (sellAsset) {
            uint256 input = uint256(self.virtualX).divWadDown(uint256(self.virtualX + amountIn));
            int256 balanceIn = int256(weightIn.divWadDown(FixedPointMathLib.WAD - weightIn));
            int256 pow = int256(input).powWad(balanceIn);
            amountOut = uint256(self.virtualY).mulWadDown(uint256(int256(FixedPointMathLib.WAD) - pow));
        } else {
            // todo: implement opposite case.
        }
    }

    /**
     * @custom:math balanceOut = reserveX * (1 - weightX) / (price * weightOut)
     */
    function computeReservesWithPrice(
        PortfolioPool memory self,
        uint256 price,
        uint256 weightX,
        uint256 reserveX
    ) internal pure returns (uint256 R_x, uint256 R_y) {
        uint256 weightOut = FixedPointMathLib.WAD - weightX;

        R_x = reserveX;
        R_y = R_x.divWadDown(price.mulWadDown(weightX.divWadDown(FixedPointMathLib.WAD - weightOut)));
    }

    /**
     * @dev Computes a `price` in WAD units given a `weight` and reserve quantities in WAD units per WAD units of liquidity.
     * @custom:math price = (R_x / w_x) * ((1 - w_x) / R_y)
     */
    function computePrice(PortfolioPool memory self, uint256 w_x) internal pure returns (uint256 price) {
        price = uint256(self.virtualX).divWadDown(w_x).mulWadDown(
            (FixedPointMathLib.WAD - w_x).divWadDown(uint256(self.virtualY))
        );
    }
}
