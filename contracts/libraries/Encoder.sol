// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./Instructions.sol";
import "./Utils.sol";

/// @title    Hyper Decoder Library
/// @dev      Solidity library to encode the calls to Hyper
/// @author   Primitive
library Encoder {
    // --- Encoding & Decoding --- //

    function encodePoolId(uint16 pairId, uint32 curveId) internal pure returns (uint48 poolId) {
        bytes memory data = abi.encodePacked(pairId, curveId);
        poolId = uint48(bytes6(data));
    }

    function encodePositionId(
        uint48 poolId,
        int24 loTick,
        int24 hiTick
    ) internal pure returns (uint96 positionId) {
        bytes memory data = abi.encodePacked(poolId, loTick, hiTick);
        positionId = uint96(bytes12(data));
    }

    /// @dev Encodes the arguments for the CREATE_PAIR instruction.
    function encodeCreatePair(address token0, address token1) internal pure returns (bytes memory data) {
        data = abi.encodePacked(Instructions.CREATE_PAIR, token0, token1);
    }

    /// @dev Encodes the arguments for the CREATE_POOL instruction.
    function encodeCreatePool(uint48 poolId, uint128 price) internal pure returns (bytes memory data) {
        data = abi.encodePacked(Instructions.CREATE_POOL, poolId, price);
    }

    function encodeAddLiquidity(
        uint8 useMax,
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint8 power,
        uint8 amount
    ) internal pure returns (bytes memory data) {
        data = abi.encodePacked(
            pack(bytes1(useMax), Instructions.ADD_LIQUIDITY),
            poolId,
            loTick,
            hiTick,
            power,
            amount
        );
    }

    function encodeRemoveLiquidity(
        uint8 useMax,
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint8 power,
        uint8 amount
    ) internal pure returns (bytes memory data) {
        data = abi.encodePacked(
            pack(bytes1(useMax), Instructions.REMOVE_LIQUIDITY),
            poolId,
            loTick,
            hiTick,
            power,
            amount
        );
    }

    function encodeSwap(
        uint8 useMax,
        uint48 poolId,
        uint8 power0,
        uint8 amount0,
        uint8 power1,
        uint8 amount1,
        uint8 direction
    ) internal pure returns (bytes memory data) {
        uint8 pointer = 0x0a;
        data = abi.encodePacked(
            pack(bytes1(useMax), Instructions.SWAP),
            poolId,
            pointer,
            power0,
            amount0,
            power1,
            amount1,
            direction
        );
    }

    function encodeStakePosition(uint96 positionId) internal pure returns (bytes memory data) {
        data = abi.encodePacked(Instructions.STAKE_POSITION, positionId);
    }

    function encodeFillPriorityAuction(
        uint48 poolId,
        address priorityOwner,
        uint8 limitPower,
        uint8 limitAmount
    ) internal pure returns (bytes memory data) {
        data = abi.encodePacked(Instructions.FILL_PRIORITY_AUCTION, poolId, priorityOwner, limitPower, limitAmount);
    }

    function encodeUnstakePosition(uint96 positionId) internal pure returns (bytes memory data) {
        data = abi.encodePacked(Instructions.UNSTAKE_POSITION, positionId);
    }

    function encodeCollectFees(
        uint96 positionId,
        uint8 power0,
        uint128 amountAssetRequested,
        uint8 power1,
        uint128 amountQuoteRequested
    ) internal pure returns (bytes memory data) {
        uint8 pointer = 31;

        data = abi.encodePacked(
            bytes1(0x04),
            positionId,
            pointer,
            power0,
            amountAssetRequested,
            power1,
            amountQuoteRequested
        );
    }

    function encodeDraw(
        address to,
        address token,
        bytes memory amount
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes1(0x04), to, token, amount);
    }
}
