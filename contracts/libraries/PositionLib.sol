// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "solmate/utils/SafeCastLib.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "./AssemblyLib.sol";

using {
    changePositionLiquidity,
    syncPositionFees,
    getTimeSinceChanged
} for PortfolioPosition global;

struct PortfolioPosition {
    uint128 freeLiquidity;
    uint32 lastTimestamp;
    uint256 invariantGrowthLast; // Increases when the invariant increases from a positive value.
    uint256 feeGrowthAssetLast;
    uint256 feeGrowthQuoteLast;
    uint128 tokensOwedAsset;
    uint128 tokensOwedQuote;
    uint128 invariantOwed; // Not used by Portfolio, but can be used by a pool controller.
}

/**
 * @dev Liquidity must be altered after syncing positions and not before.
 */
function syncPositionFees(
    PortfolioPosition storage self,
    uint256 feeGrowthAsset,
    uint256 feeGrowthQuote,
    uint256 invariantGrowth
)
    returns (
        uint256 feeAssetEarned,
        uint256 feeQuoteEarned,
        uint256 feeInvariantEarned
    )
{
    // fee growth current - position fee growth last
    uint256 differenceAsset = AssemblyLib.computeCheckpointDistance(
        feeGrowthAsset, self.feeGrowthAssetLast
    );
    uint256 differenceQuote = AssemblyLib.computeCheckpointDistance(
        feeGrowthQuote, self.feeGrowthQuoteLast
    );
    uint256 differenceInvariant = AssemblyLib.computeCheckpointDistance(
        invariantGrowth, self.invariantGrowthLast
    );

    // fee growth per liquidity * position liquidity
    feeAssetEarned =
        FixedPointMathLib.mulWadDown(differenceAsset, self.freeLiquidity);
    feeQuoteEarned =
        FixedPointMathLib.mulWadDown(differenceQuote, self.freeLiquidity);
    feeInvariantEarned =
        FixedPointMathLib.mulWadDown(differenceInvariant, self.freeLiquidity);

    self.feeGrowthAssetLast = feeGrowthAsset;
    self.feeGrowthQuoteLast = feeGrowthQuote;
    self.invariantGrowthLast = invariantGrowth;

    self.tokensOwedAsset += SafeCastLib.safeCastTo128(feeAssetEarned);
    self.tokensOwedQuote += SafeCastLib.safeCastTo128(feeQuoteEarned);
    self.invariantOwed += SafeCastLib.safeCastTo128(feeInvariantEarned);
}

function changePositionLiquidity(
    PortfolioPosition storage self,
    uint256 timestamp,
    int128 liquidityDelta
) {
    self.lastTimestamp = uint32(timestamp);
    self.freeLiquidity =
        AssemblyLib.addSignedDelta(self.freeLiquidity, liquidityDelta);
}

function getTimeSinceChanged(
    PortfolioPosition memory self,
    uint256 timestamp
) pure returns (uint256 distance) {
    return timestamp - self.lastTimestamp;
}
