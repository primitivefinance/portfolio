// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BrainMath.sol";
import "./Epoch.sol";
import "./GlobalDefaults.sol";

/// @title   Pool Library
/// @author  Primitive
/// @dev     Data structure library for Pools
library Pool {
    using Epoch for Epoch.Data;

    /// @notice                Stores the state of a pool
    struct Data {
        address tokenA;
        address tokenB;
        uint256 activeLiquidity;
        uint256 activeLiquidityMatured;
        int256 activeLiquidityPending;
        uint256 activeSqrtPriceFixedPoint;
        int128 activeSlotIndex;
        uint256 proceedsGrowthGlobalFixedPoint;
        uint256 feeGrowthGlobalAFixedPoint;
        uint256 feeGrowthGlobalBFixedPoint;
        uint256 proceedsPerSecondFixedPoint;
        uint256 pendingProceedsPerSecondFixedPoint;
        address arbRightOwner;
        address pendingArbRightOwner;
        uint256 lastUpdatedTimestamp;
    }

    /// @notice                Gets the identifier of a pool based on the underlying tokens.
    function getId(address tokenA, address tokenB) public pure returns (bytes32) {
        if (tokenA == tokenB) revert();
        (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    /// @notice                Updates the pool data w.r.t. time passing
    /// @dev                   Assumes epoch sync is always called before.
    function sync(Data storage pool, Epoch.Data memory epoch) internal {
        // apply any updates for previous epochs
        uint256 epochsPassed = (epoch.endTime - pool.lastUpdatedTimestamp) / EPOCH_LENGTH;
        if (epochsPassed > 0) {
            // add proceeds until epoch transition
            uint256 timeToTransition = (epoch.endTime - pool.lastUpdatedTimestamp) - (epochsPassed * EPOCH_LENGTH);
            if (pool.proceedsPerSecondFixedPoint > 0 && pool.activeLiquidityMatured > 0) {
                pool.proceedsGrowthGlobalFixedPoint += PRBMathUD60x18.div(
                    PRBMathUD60x18.mul(pool.proceedsPerSecondFixedPoint, timeToTransition),
                    pool.activeLiquidityMatured
                );
            }
            // apply epoch transition
            if (pool.activeLiquidityPending < 0) {
                pool.activeLiquidity -= uint256(pool.activeLiquidityPending);
                pool.activeLiquidityMatured -= uint256(pool.activeLiquidityPending);
            } else {
                // added pending liquidity is immediately swappable against, so only need to update matured
                pool.activeLiquidityMatured += uint256(pool.activeLiquidityPending);
            }
            pool.activeLiquidityPending = int256(0);
            // update proceeds for next epoch
            pool.proceedsPerSecondFixedPoint = pool.pendingProceedsPerSecondFixedPoint;
            pool.pendingProceedsPerSecondFixedPoint = uint256(0);
            // update arb right owner for next epoch
            pool.arbRightOwner = pool.pendingArbRightOwner;
            pool.pendingArbRightOwner = address(0);
            // TODO: save pool state snapshots
            // check if multiple epochs have passed
            if (epochsPassed > 1) {
                // add proceeds for the epoch after the transition applied above
                if (pool.proceedsPerSecondFixedPoint > 0 && pool.activeLiquidityMatured > 0) {
                    pool.proceedsGrowthGlobalFixedPoint += PRBMathUD60x18.div(
                        PRBMathUD60x18.mul(pool.proceedsPerSecondFixedPoint, EPOCH_LENGTH),
                        pool.activeLiquidityMatured
                    );
                }
                // since its been multiple epochs since the pool was touched, there were no bids for the current epoch
                pool.proceedsPerSecondFixedPoint = uint256(0);
                pool.arbRightOwner = address(0);
            }
        }

        // add proceeds for time passed in the current epoch
        uint256 timePassedInCurrentEpoch = block.timestamp - (epoch.endTime - EPOCH_LENGTH);
        if (pool.proceedsPerSecondFixedPoint > 0 && pool.activeLiquidityMatured > 0 && timePassedInCurrentEpoch > 0) {
            pool.proceedsGrowthGlobalFixedPoint += PRBMathUD60x18.div(
                PRBMathUD60x18.mul(pool.proceedsPerSecondFixedPoint, timePassedInCurrentEpoch),
                pool.activeLiquidityMatured
            );
        }
    }

    /// @notice                Activates a pool with two different tokens, A and B.
    function activate(
        mapping(bytes32 => Data) storage pools,
        address tokenA,
        address tokenB,
        uint256 activeSqrtPriceFixedPoint
    ) internal {
        Data storage pool = pools[getId(tokenA, tokenB)];

        if (pool.lastUpdatedTimestamp != 0) revert();
        pool.tokenA = tokenA;
        pool.tokenB = tokenB;
        pool.activeSqrtPriceFixedPoint = activeSqrtPriceFixedPoint;
        // TODO: set active slot index?
        pool.lastUpdatedTimestamp = block.timestamp;
    }
}
