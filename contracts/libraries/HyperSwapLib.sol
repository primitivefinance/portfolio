// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "solstat/Gaussian.sol";

/**
 * @dev Comprehensive library to compute all related functions used with swaps.
 */
library HyperSwapLib {
    uint256 public constant UNIT_WAD = 1e18;
    uint256 public constant UNIT_YEAR = 31556953;
    uint256 public constant UNIT_PERCENT = 1e4;

    /**
     * @custom:math
     */
    function computeR1WithPrice(
        uint256 prc,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 R1) {}

    /**
     * @custom:math R2 = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
     */
    function computeR2WithPrice(
        uint256 prc,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 R2) {}

    /**
     * @custom:math
     */
    function computePriceWithR1(
        uint256 R1,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 prc) {}

    /**
     * @custom:math price(R2) = Ke^(Φ^-1(1 - R2)σ√τ - 1/2σ^2τ)
     */
    function computePriceWithR2(
        uint256 R2,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 prc) {}

    // --- Utils --- //

    /**
     * @notice Changes seconds into WAD units then divides by the amount of seconds in a year.
     */
    function convertSecondsToWadYears(uint256 sec) internal pure returns (uint256 yrsWad) {
        assembly {
            yrsWad := div(mul(sec, UNIT_WAD), UNIT_YEAR)
        }
    }

    /**
     * @notice Changes percentage into WAD units then cancels the percentage units.
     */
    function convertPercentageToWad(uint256 pct) internal pure returns (uint256 pctWad) {
        assembly {
            pctWad := div(mul(pct, UNIT_WAD), UNIT_PERCENT)
        }
    }
}
