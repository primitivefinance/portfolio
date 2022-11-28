// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IHyper {
    // ===== View =====

    function epoch() external view returns (uint256 id, uint256 endTime);

    function internalBalances(address owner, address token) external view returns (uint256);

    function auctionFeeCollector() external view returns (address);

    function getGlobalDefaults()
        external
        view
        returns (
            uint256 publicSwapFee,
            uint256 epochLength,
            uint256 auctionLength,
            address auctionSettlementToken,
            uint256 auctionFee
        );

    function pools(bytes32 poolId)
        external
        view
        returns (
            address tokenA,
            address tokenB,
            uint256 swapLiquidity,
            uint256 maturedLiquidity,
            int256 pendingLiquidity,
            uint256 sqrtPriceFixedPoint,
            int128 slotIndex,
            uint256 proceedsPerLiquidityFixedPoint,
            uint256 feesAPerLiquidityFixedPoint,
            uint256 feesBPerLiquidityFixedPoint,
            uint256 lastUpdatedTimestamp
        );

    function slots(bytes32 slotId)
        external
        view
        returns (
            uint256 liquidityGross,
            int256 pendingLiquidityGross,
            int256 swapLiquidityDelta,
            int256 maturedLiquidityDelta,
            int256 pendingLiquidityDelta,
            uint256 proceedsPerLiquidityOutsideFixedPoint,
            uint256 feesAPerLiquidityOutsideFixedPoint,
            uint256 feesBPerLiquidityOutsideFixedPoint,
            uint256 lastUpdatedTimestamp
        );

    function positions(bytes32 positionId)
        external
        view
        returns (
            int128 lowerSlotIndex,
            int128 upperSlotIndex,
            uint256 swapLiquidity,
            uint256 maturedLiquidity,
            int256 pendingLiquidity,
            uint256 proceedsPerLiquidityInsideLastFixedPoint,
            uint256 feesAPerLiquidityInsideLastFixedPoint,
            uint256 feesBPerLiquidityInsideLastFixedPoint,
            uint256 lastUpdatedTimestamp
        );

    function getLeadingBid(bytes32 poolId, uint256 epochId)
        external
        view
        returns (
            address refunder,
            address swapper,
            uint256 amount,
            uint256 proceedsPerSecondFixedPoint
        );
}
