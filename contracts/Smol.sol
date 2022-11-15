// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./libraries/BrainMath.sol";

struct Pool {
    address tokenA;
    address tokenB;
    uint256 activeLiquidity;
    uint256 activePriceFixedPoint;
    int128 activeSlotIndex;
    uint256 feeGrowthGlobalAFixedPoint;
    uint256 feeGrowthGlobalBFixedPoint;
    address arbRightOwner;
    uint256 lastUpdatedTimestamp;
}

struct Slot {
    int256 liquidityDelta;
    uint256 feeGrowthOutsideAFixedPoint;
    uint256 feeGrowthOutsideBFixedPoint;
}

struct Position {
    int128 lowerSlotIndex;
    int128 upperSlotIndex;
    uint256 liquidityOwned;
    uint256 feeGrowthInsideLastAFixedPoint;
    uint256 feeGrowthInsideLastBFixedPoint;
    // TODO: Should we track these fees with precision or nah?
    uint256 feesOwedAFixedPoint;
    uint256 feesOwedBFixedPoint;
}

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
    uint256 public priceGridFixedPoint = 1000100000000000000; // 1.0001
    uint256 public epochLength;
    uint256 public auctionLength;
    address public auctionSettlementToken;
    uint256 public auctionFee;
    uint256 public publicSwapFee;

    mapping(bytes32 => Pool) public pools;
    mapping(bytes32 => Position) public positions;
    mapping(bytes32 => Slot) public slots;

    function initiatePool(
        address tokenA,
        address tokenB,
        uint256 activePriceFixedPoint
    ) public {
        if (tokenA == tokenB) revert();
        (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        Pool storage pool = pools[_getPoolId(tokenA, tokenB)];

        if (pool.lastUpdatedTimestamp != 0) revert();
        pool.activePriceFixedPoint = activePriceFixedPoint;
        pool.lastUpdatedTimestamp = block.timestamp;

        // TODO: emit InitiatePool event
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        uint256 amount
    ) public {
        if (lowerSlotIndex > upperSlotIndex) revert();
        if (amount == 0) revert();

        (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        bytes32 poolId = _getPoolId(tokenA, tokenB);
        Pool storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

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
            priceGridFixedPoint,
            amount,
            pool.activePriceFixedPoint,
            pool.activeSlotIndex,
            lowerSlotIndex,
            upperSlotIndex
        );

        if (amountA != 0 && amountB != 0) pool.activeLiquidity += amount;

        bytes32 positionId = _getPositionId(msg.sender, poolId, lowerSlotIndex, upperSlotIndex);
        Position storage position = positions[positionId];

        {
            (uint256 feeGrowthInsideA, uint256 feeGrowthInsideB) = _calculateFeeGrowthInside(
                poolId,
                lowerSlotIndex,
                upperSlotIndex
            );

            uint256 changeInFeeGrowthA = feeGrowthInsideA - position.feeGrowthInsideLastAFixedPoint;
            uint256 changeInFeeGrowthB = feeGrowthInsideB - position.feeGrowthInsideLastBFixedPoint;

            position.feesOwedAFixedPoint += PRBMathUD60x18.mul(position.liquidityOwned, changeInFeeGrowthA);
            position.feesOwedBFixedPoint += PRBMathUD60x18.mul(position.liquidityOwned, changeInFeeGrowthB);

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

        Pool memory pool = pools[poolId];

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

    function _getPoolId(address tokenA, address tokenB) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    function _getSlotId(bytes32 poolId, int128 slotIndex) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(poolId, slotIndex));
    }

    function _getPositionId(
        address owner,
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, poolId, lowerSlotIndex, upperSlotIndex));
    }
}
