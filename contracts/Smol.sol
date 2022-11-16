// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./libraries/BrainMath.sol";
import "./libraries/Epoch.sol";
import "./libraries/GlobalDefaults.sol";
import "./libraries/Pool.sol";
import "./libraries/PoolSnapshot.sol";
import "./libraries/Position.sol";
import "./libraries/Slot.sol";
import "./libraries/SlotSnapshot.sol";

// TODO:
// - Add WETH wrapping / unwrapping
// - Add the internal balances, fund and withdraw
// - Add Multicall?
// - Fixed point library
// - Slippage checks
// - Extra function parameters
// - Epochs / staking feature
// - Auction
// - Events
// - Custom errors
// - Interface
// - Change `addLiquidity` to `updateLiquidity`
// - slots bitmap

contract Smol {
    using Epoch for Epoch.Data;
    using Pool for mapping(bytes32 => Pool.Data);
    using Pool for Pool.Data;

    Epoch.Data public epoch;

    mapping(bytes32 => Pool.Data) public pools;
    mapping(bytes32 => Position.Data) public positions;
    mapping(bytes32 => Slot) public slots;

    mapping(bytes32 => mapping(uint256 => PoolSnapshot)) public poolSnapshots;
    mapping(bytes32 => mapping(uint256 => SlotSnapshot)) public slotSnapshots;

    constructor(uint256 transitionTime) {
        require(transitionTime > block.timestamp);
        epoch = Epoch.Data({id: 0, endTime: transitionTime});
    }

    function activatePool(
        address tokenA,
        address tokenB,
        uint256 activeSqrtPriceFixedPoint
    ) public {
        epoch.sync();
        pools.activate(tokenA, tokenB, activeSqrtPriceFixedPoint);

        // TODO: emit ActivatePool event
    }

    function addLiquidity(
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        uint256 amount
    ) public {
        if (lowerSlotIndex > upperSlotIndex) revert();
        if (amount == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

        epoch.sync();

        // TODO: Optimize this code to avoid duplicated lines (maybe add a function)
        {
            bytes32 lowerSlotId = _getSlotId(poolId, lowerSlotIndex);
            Slot storage slot = slots[lowerSlotId];
            slot.liquidityDelta += int256(amount);

            if (pool.activeSlotIndex >= lowerSlotIndex) {
                slot.feeGrowthOutsideAFixedPoint = pool.feeGrowthGlobalAFixedPoint;
                slot.feeGrowthOutsideBFixedPoint = pool.feeGrowthGlobalBFixedPoint;
            }
        }

        {
            bytes32 upperSlotId = _getSlotId(poolId, upperSlotIndex);
            Slot storage slot = slots[upperSlotId];
            slot.liquidityDelta -= int256(amount);

            if (pool.activeSlotIndex >= upperSlotIndex) {
                slot.feeGrowthOutsideAFixedPoint = pool.feeGrowthGlobalAFixedPoint;
                slot.feeGrowthOutsideBFixedPoint = pool.feeGrowthGlobalBFixedPoint;
            }
        }

        (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
            PRICE_GRID_FIXED_POINT,
            amount,
            pool.activeSqrtPriceFixedPoint,
            pool.activeSlotIndex,
            lowerSlotIndex,
            upperSlotIndex
        );

        if (amountA != 0 && amountB != 0) pool.activeLiquidity += amount;

        bytes32 positionId = Position.getId(msg.sender, poolId, lowerSlotIndex, upperSlotIndex);
        Position.Data storage position = positions[positionId];

        {
            (uint256 feeGrowthInsideA, uint256 feeGrowthInsideB) = _calculateFeeGrowthInside(
                poolId,
                lowerSlotIndex,
                upperSlotIndex
            );

            uint256 changeInFeeGrowthA = feeGrowthInsideA - position.feeGrowthInsideLastAFixedPoint;
            uint256 changeInFeeGrowthB = feeGrowthInsideB - position.feeGrowthInsideLastBFixedPoint;

            position.tokensOwedAFixedPoint += PRBMathUD60x18.mul(position.liquidityOwned, changeInFeeGrowthA);
            position.tokensOwedBFixedPoint += PRBMathUD60x18.mul(position.liquidityOwned, changeInFeeGrowthB);

            position.feeGrowthInsideLastAFixedPoint = feeGrowthInsideA;
            position.feeGrowthInsideLastBFixedPoint = feeGrowthInsideB;
        }

        position.liquidityOwned += amount;

        // TODO: Flip the ticks depending on the liquidity delta
        // TODO: Update the fee growth of the tick when the tick is flipped

        // TODO: emit AddLiquidity event
    }

    struct SwapCache {
        int128 activeSlotIndex;
        uint256 slotProportionF;
        uint256 activeLiquidity;
        uint256 activePrice;
        int128 slotIndexOfNextDelta;
        int128 nextDelta;
    }

    function swap(
        address tokenA,
        address tokenB,
        uint256 tendered,
        bool direction
    ) public {
        uint256 tenderedRemaining = tendered;
        uint256 received;

        uint256 cumulativeFees;
        SwapCache memory swapCache;

        if (!direction) {} else {}
    }

    // TODO: Turn this into a global function (avoid duplicated lines)
    // TODO: Maybe we should pass directly the pool as a struct or at least the variables
    // that we need instead of passing the poolId (because it's going to reload the pool
    // one more time into the memory)
    function _calculateFeeGrowthInside(
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    ) internal view returns (uint256 feeGrowthInsideA, uint256 feeGrowthInsideB) {
        bytes32 lowerSlotId = _getSlotId(poolId, lowerSlotIndex);
        uint256 lowerSlotFeeGrowthOutsideAFixedPoint = slots[lowerSlotId].feeGrowthOutsideAFixedPoint;
        uint256 lowerSlotFeeGrowthOutsideBFixedPoint = slots[lowerSlotId].feeGrowthOutsideBFixedPoint;

        bytes32 upperSlotId = _getSlotId(poolId, upperSlotIndex);
        uint256 upperSlotFeeGrowthOutsideAFixedPoint = slots[upperSlotId].feeGrowthOutsideAFixedPoint;
        uint256 upperSlotFeeGrowthOutsideBFixedPoint = slots[upperSlotId].feeGrowthOutsideBFixedPoint;

        Pool.Data memory pool = pools[poolId];

        uint256 feeGrowthAboveA = pool.activeSlotIndex >= upperSlotIndex
            ? pool.feeGrowthGlobalAFixedPoint - upperSlotFeeGrowthOutsideAFixedPoint
            : upperSlotFeeGrowthOutsideAFixedPoint;
        uint256 feeGrowthAboveB = pool.activeSlotIndex >= upperSlotIndex
            ? pool.feeGrowthGlobalBFixedPoint - upperSlotFeeGrowthOutsideBFixedPoint
            : upperSlotFeeGrowthOutsideBFixedPoint;

        uint256 feeGrowthBelowA = pool.activeSlotIndex >= upperSlotIndex
            ? lowerSlotFeeGrowthOutsideAFixedPoint
            : pool.feeGrowthGlobalAFixedPoint - lowerSlotFeeGrowthOutsideAFixedPoint;
        uint256 feeGrowthBelowB = pool.activeSlotIndex >= upperSlotIndex
            ? lowerSlotFeeGrowthOutsideBFixedPoint
            : pool.feeGrowthGlobalBFixedPoint - lowerSlotFeeGrowthOutsideBFixedPoint;

        feeGrowthInsideA = pool.feeGrowthGlobalAFixedPoint - feeGrowthBelowA - feeGrowthAboveA;
        feeGrowthInsideB = pool.feeGrowthGlobalBFixedPoint - feeGrowthBelowB - feeGrowthAboveB;
    }
}
