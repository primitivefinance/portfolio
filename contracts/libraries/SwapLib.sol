// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "solmate/utils/FixedPointMathLib.sol";
import "./AssemblyLib.sol";
import { PERCENTAGE_DIVISOR } from "./ConstantsLib.sol";

using { computeAdjustedSwapReserves, computeFeeAmounts } for Order global;

using FixedPointMathLib for uint128;

error Swap_FeeTooHigh();
error Swap_ProtocolFeeTooHigh();
error Swap_OutputExceedsReserves();

/**
 * @notice
 * Data structure for swap orders.
 *
 * @dev
 * Arguments required to execute a swap transaction.
 *
 * @note
 * Input and output amounts are recommended to be computed offchain. This is because
 * the pool's reserves may change between the time the order is created and executed.
 * Additionally, the input and output should be optimized to pass the invariant check.
 * Doing those optimizations onchain could be slightly wrong due to using approximations.
 *
 * @param input Quantity of asset tokens in native token decimals to swap in, adding to reserves.
 * @param output Quantity of quote tokens in native token decimals to swap out, removing from reserves.
 * @param useMax Utilizes surplus tokens in the contract's accounting system as the swap input.
 * @param poolId The pool to execute the swap against.
 * @param sellAsset 0 = quote -> asset, 1 = asset -> quote.
 */
struct Order {
    uint128 input;
    uint128 output;
    bool useMax;
    uint64 poolId;
    bool sellAsset;
}

/**
 * @notice
 * Get the fee and protocol fee amounts charged during a swap.
 *
 * @dev
 * Fee amount is rounded up to the nearest integer, it should never be zero.
 * Protocol fee amount is a proportion of the fee amount.
 *
 * @note
 * Fee amount is "reinvested" into the pool by adding it to the pool's reserves.
 * Protocol fee amount must never be added to the pool's reserves.
 *
 * @param self Swap order to compute fees for.
 * @param feeBasisPoints Fee denominated in basis points, where 1 basis point = 0.01%.
 * @param protocolFeeProportion Proportion of the fee amount to charge as a protocol fee.
 * @return feeAmount Quantity of input tokens which are considered the fee amount.
 * @return protocolFeeAmount Quantity of input tokens which are paid as the protocol fee amount.
 */
function computeFeeAmounts(
    Order memory self,
    uint256 feeBasisPoints,
    uint256 protocolFeeProportion
) pure returns (uint256 feeAmount, uint256 protocolFeeAmount) {
    // Fee amount cannot be zero, so we can use the `mulDivUp` function to round up.
    feeAmount = self.input.mulDivUp(feeBasisPoints, PERCENTAGE_DIVISOR);

    if (protocolFeeProportion != 0) {
        // Protocol fee is a proportion of the fee amount.
        protocolFeeAmount = feeAmount / protocolFeeProportion;
        // Subtract the protocol fee from the fee amount.
        feeAmount -= protocolFeeAmount;
    }
}

/**
 * @notice
 * Gets swap & fee adjusted reserves after a swap.
 *
 * @dev
 * Use this method to compute reserves after a swap which will be passed to the invariant check.
 *
 * @note
 * If the swap output exceeds the output reserves, it means a price limit has been reached for the pool.
 *
 * @param self Swap order to compute adjusted reserves for.
 * @param reserveX Total asset tokens in reserves of pool, scaled to WAD units.
 * @param reserveY Total quote tokens in reserves of pool, scaled to WAD units.
 * @param feeAmount Quantity of input tokens which are considered the fee amount.
 * @param protocolFeeAmount Quantity of input tokens which are paid as the protocol fee amount.
 * @return adjustedX Swap & fee adjusted reserve of asset tokens.
 * @return adjustedY Swap & fee adjusted reserve of quote tokens.
 */
function computeAdjustedSwapReserves(
    Order memory self,
    uint256 reserveX,
    uint256 reserveY,
    uint256 feeAmount,
    uint256 protocolFeeAmount
) returns (uint256 adjustedX, uint256 adjustedY) {
    uint256 adjustedInputReserve = self.sellAsset ? reserveX : reserveY;
    uint256 adjustedOutputReserve = self.sellAsset ? reserveY : reserveX;

    // Input amount is added to the reserves for the swap.
    adjustedInputReserve += self.input;
    // Fee amount is reinvested into the pool, but it's not considered in the invariant check, so we subtract it.
    if (feeAmount > adjustedInputReserve) revert Swap_FeeTooHigh();
    adjustedInputReserve -= feeAmount;
    // Protocol fee is subtracted, even though it's included in the fee, because protocol fees
    // do not get added to the pool's reserves.
    if (protocolFeeAmount > adjustedInputReserve) revert Swap_ProtocolFeeTooHigh(); // forgefmt: disable-line
    adjustedInputReserve -= protocolFeeAmount;
    // Output amount is removed from the reserves for the swap.
    if (self.output > adjustedOutputReserve) revert Swap_OutputExceedsReserves(); // forgefmt: disable-line
    adjustedOutputReserve -= self.output;

    // Use these adjusted reserves in the invariant check.
    adjustedX = self.sellAsset ? adjustedInputReserve : adjustedOutputReserve;
    adjustedY = self.sellAsset ? adjustedOutputReserve : adjustedInputReserve;
}
