// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "solmate/utils/FixedPointMathLib.sol";
import {PortfolioPool, AssemblyLib, PERCENTAGE} from "../PortfolioLib.sol";

/**
 * @title  RMM03Lib
 * @author Primitive™
 * @dev    Constant sum portfolio for two tokens.
 */
library RMM03Lib {
    using AssemblyLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    int256 internal constant DEFAULT_INVARIANT = int256(1 ether); // k = 1

    /**
     * @dev Computes the invariant of the RMM-03 trading function.
     * @param self Pool instance.
     * @param R_x Quantity of `asset` reserves scaled to WAD units per WAD of liquidity.
     * @param R_y Quantity of `quote` reserves scaled to WAD units per WAD of liquidity.
     * @return invariantWad Signed invariant scaled to WAD units.
     * @custom:math k = R_x + R_y / P
     */
    function invariantOf(
        PortfolioPool memory self,
        uint256 R_x,
        uint256 R_y
    ) internal pure returns (int256 invariantWad) {
        // stores price in maxPrice parameter
        invariantWad = int256(R_x) + int256(R_y.divWadDown(self.params.maxPrice));
    }

    /**
     * @dev Approximation of amount out of tokens given a swap `amountIn`.
     * @param amountIn Quantity of tokens in, units are native token decimals.
     * @return amountOut Quantity of tokens out, units are in native token decimals.
     */
    function getAmountOut(
        PortfolioPool memory self,
        bool sellAsset,
        uint256 amountIn
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInScaled = amountIn.scaleToWad(sellAsset ? self.pair.decimalsAsset : self.pair.decimalsQuote);
        uint256 feeAmount = (amountInScaled * self.params.fee) / PERCENTAGE;
        uint256 amountInFeeApplied = amountInScaled - feeAmount;

        uint256 reserveIn = self.virtualX + amountInFeeApplied;
        // y = -Px + Pk
        uint256 reserveOut = self.virtualY - amountInFeeApplied.mulWadDown(self.params.maxPrice);
        amountOut = self.virtualY - reserveOut;
        amountOut = amountOut.scaleFromWadDown(sellAsset ? self.pair.decimalsAsset : self.pair.decimalsQuote);
    }

    /**
     * @custom:math Px + y = Pk
     * Set L = k ?
     * Px - Pk = y, P(x - k) = y, P = y / (x - k)
     * (Px + y) / P = k, x + y / P = k
     * P = 10, k = 1, 10x + y = 10
     * y = -10x + 10
     * x = 1 / 2
     * y = -10(0.5) + 10
     * y = 5
     * OR
     * k = 0, P = 10, then 10x + y = 0, y = -10x, x = 0 / 2 = 0, y = 0
     * k = 2, P = 10, then 10x + y = 20, y = -10x + 20, x = 2 / 2 = 1, y = -10(1) + 20 = 10
     */
    function computeReservesWithPrice(
        PortfolioPool memory self,
        uint256 price
    ) internal pure returns (uint256 R_x, uint256 R_y) {
        int256 invariant;
        // When a pool is created, the virtual reserves will be unset.
        // In this case, default invariant should be used.
        if (self.virtualX == 0 && self.virtualY == 0) {
            invariant = DEFAULT_INVARIANT;
        } else {
            // k = x + y / P
            invariant = int256(uint256(self.virtualX) + uint256(self.virtualY).divWadDown(price));
        }

        int256 pk = int256(price.mulWadDown(uint256(invariant)));
        R_x = uint256(invariant * 1 ether / 2 ether); // x = k / 2
        R_y = uint256(-int256(price) * int256(R_x) / 1 ether + pk); // y = -Px + Pk
    }

    /**
     * @dev Computes a `price` in WAD units given reserve quantities in WAD units per WAD units of liquidity.
     * @custom:math price = R_y / (R_x - invariant)
     */
    function computePrice(PortfolioPool memory self) internal pure returns (uint256 price) {
        int256 denominator = int256(uint256(self.virtualX)) - invariantOf(self, self.virtualX, self.virtualY);

        price = uint256(self.virtualY).divWadDown(denominator < 0 ? uint256(-denominator) : uint256(denominator));
    }
}
