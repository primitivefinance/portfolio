// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UD60x18, fromUD60x18, toUD60x18} from "@prb/math/UD60x18.sol";

import {PoolId, PoolSnapshot} from "./Pool.sol";
import {SlotSnapshot} from "./Slot.sol";

using {updatePerLiquiditiesInside} for Position global;
using {getPerLiquiditiesInside, getEarnings} for Position;

type PositionId is bytes32;

struct PerLiquiditiesInside {
    UD60x18 proceedsPerLiquidityInside;
    UD60x18 feesAPerLiquidityInside;
    UD60x18 feesBPerLiquidityInside;
}

struct Position {
    PositionId id;
    int24 lowerSlotIndex;
    int24 upperSlotIndex;
    uint256 swapLiquidity;
    uint256 maturedLiquidity;
    int256 pendingLiquidity;
    UD60x18 proceedsPerLiquidityInsideLast;
    UD60x18 feesAPerLiquidityInsideLast;
    UD60x18 feesBPerLiquidityInsideLast;
    uint256 lastUpdatedTimestamp;
}

function getPositionId(
    address owner,
    PoolId poolId,
    int24 lowerSlotIndex,
    int24 upperSlotIndex
) pure returns (PositionId) {
    return PositionId.wrap(keccak256(abi.encodePacked(owner, poolId, lowerSlotIndex, upperSlotIndex)));
}

function updatePerLiquiditiesInside(
    Position storage position,
    PoolSnapshot memory poolSnapshot,
    SlotSnapshot memory lowerSlotSnapshot,
    SlotSnapshot memory upperSlotSnapshot
) returns (
        uint256 amountA,
        uint256 amountB,
        uint256 amountC
    ) {
    Position memory _position = position;
    PerLiquiditiesInside memory perLiquiditiesInside = _position.getPerLiquiditiesInside(
        poolSnapshot,
        lowerSlotSnapshot,
        upperSlotSnapshot
    );
    (amountA, amountB, amountC) = _position.getEarnings(
        perLiquiditiesInside.proceedsPerLiquidityInside,
        perLiquiditiesInside.feesAPerLiquidityInside,
        perLiquiditiesInside.feesBPerLiquidityInside
    );
    position.proceedsPerLiquidityInsideLast = perLiquiditiesInside.proceedsPerLiquidityInside;
    position.feesAPerLiquidityInsideLast = perLiquiditiesInside.feesAPerLiquidityInside;
    position.feesBPerLiquidityInsideLast = perLiquiditiesInside.feesBPerLiquidityInside;
}

function getPerLiquiditiesInside(
    Position memory position,
    PoolSnapshot memory poolSnapshot,
    SlotSnapshot memory lowerSlotSnapshot,
    SlotSnapshot memory upperSlotSnapshot
) pure returns (PerLiquiditiesInside memory perLiquiditiesInside) {
    {
        UD60x18 proceedsPerLiquidityAbove = poolSnapshot.slotIndex >= position.upperSlotIndex
            ? poolSnapshot.proceedsPerLiquidity.sub(upperSlotSnapshot.proceedsPerLiquidityOutside)
            : upperSlotSnapshot.proceedsPerLiquidityOutside;
        UD60x18 proceedsPerLiquidityBelow = poolSnapshot.slotIndex >= position.lowerSlotIndex
            ? lowerSlotSnapshot.proceedsPerLiquidityOutside
            : poolSnapshot.proceedsPerLiquidity.sub(lowerSlotSnapshot.proceedsPerLiquidityOutside);
        perLiquiditiesInside.proceedsPerLiquidityInside = poolSnapshot
            .proceedsPerLiquidity
            .sub(proceedsPerLiquidityBelow)
            .sub(proceedsPerLiquidityAbove);
    }
    {
        UD60x18 feesAPerLiquidityAbove = poolSnapshot.slotIndex >= position.upperSlotIndex
            ? poolSnapshot.feesAPerLiquidity.sub(upperSlotSnapshot.feesAPerLiquidityOutside)
            : upperSlotSnapshot.feesAPerLiquidityOutside;
        UD60x18 feesAPerLiquidityBelow = poolSnapshot.slotIndex >= position.lowerSlotIndex
            ? lowerSlotSnapshot.feesAPerLiquidityOutside
            : poolSnapshot.feesAPerLiquidity.sub(lowerSlotSnapshot.feesAPerLiquidityOutside);
        perLiquiditiesInside.feesAPerLiquidityInside = poolSnapshot.feesAPerLiquidity.sub(feesAPerLiquidityBelow).sub(
            feesAPerLiquidityAbove
        );
    }
    {
        UD60x18 feesBPerLiquidityAbove = poolSnapshot.slotIndex >= position.upperSlotIndex
            ? poolSnapshot.feesBPerLiquidity.sub(upperSlotSnapshot.feesBPerLiquidityOutside)
            : upperSlotSnapshot.feesBPerLiquidityOutside;
        UD60x18 feesBPerLiquidityBelow = poolSnapshot.slotIndex >= position.lowerSlotIndex
            ? lowerSlotSnapshot.feesBPerLiquidityOutside
            : poolSnapshot.feesBPerLiquidity.sub(lowerSlotSnapshot.feesBPerLiquidityOutside);
        perLiquiditiesInside.feesBPerLiquidityInside = poolSnapshot.feesBPerLiquidity.sub(feesBPerLiquidityBelow).sub(
            feesBPerLiquidityAbove
        );
    }
}

function getEarnings(
    Position memory position,
    UD60x18 proceedsPerLiquidityInside,
    UD60x18 feesAPerLiquidityInside,
    UD60x18 feesBPerLiquidityInside
)
    pure
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 amountC
    )
{
    UD60x18 swapLiquidity = toUD60x18(position.swapLiquidity);

    amountA = fromUD60x18(swapLiquidity.mul(feesAPerLiquidityInside.sub(position.feesAPerLiquidityInsideLast)));
    amountB = fromUD60x18(swapLiquidity.mul(feesBPerLiquidityInside.sub(position.feesBPerLiquidityInsideLast)));
    if (position.maturedLiquidity > 0) {
        amountC = fromUD60x18(
            toUD60x18(position.maturedLiquidity).mul(
                proceedsPerLiquidityInside.sub(position.proceedsPerLiquidityInsideLast)
            )
        );
    }
}
