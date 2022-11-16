// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./GlobalDefaults.sol";

/// @title   Pool Library
/// @author  Primitive
/// @dev     Data structure library for Pools
library Pool {
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
        address arbRightOwner;
        uint256 lastUpdatedTimestamp;
    }

    /// @notice                Gets the identifier of a pool based on the underlying tokens.
    function getId(address tokenA, address tokenB) public pure returns (bytes32) {
        if (tokenA == tokenB) revert();
        (tokenA, tokenB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    /// @notice                Updates the pool data w.r.t. time passing
    function sync(Data storage pool) internal {}

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
