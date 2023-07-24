// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import "solmate/utils/FixedPointMathLib.sol";
import "./AssemblyLib.sol";
import { BASIS_POINT_DIVISOR } from "./ConstantsLib.sol";

using {
    computeAdjustedSwapReserves,
    computeFeeAmounts,
    computeSwapResult
} for Order global;

using AssemblyLib for uint256;
using FixedPointMathLib for uint128;

error SwapLib_FeeTooHigh();
error SwapLib_ProtocolFeeTooHigh();
error SwapLib_OutputExceedsReserves();

/**
 * @notice
 * Data structure for swap orders.
 *
 * @dev
 * Arguments required to execute a swap transaction.
 *
 * note
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
 * note
 * Fee amount is "reinvested" into the pool by adding it to the pool's reserves.
 * Protocol fee amount must never be added to the pool's reserves.
 *
 * @param self Swap order to compute fees for.
 * @param feeBasisPoints Fee denominated in basis points, where 1 basis point = 0.01%.
 * @param protocolFeeProportion Proportion of the fee amount to charge as a protocol fee.
 * @return feeAmountUnit Quantity of input tokens which are considered the fee amount, in units equivalent to `self.input`.
 * @return protocolFeeAmountUnit Quantity of input tokens which are paid as the protocol fee amount, in units equivalent to `self.input`.
 */
function computeFeeAmounts(
    Order memory self,
    uint256 feeBasisPoints,
    uint256 protocolFeeProportion
) pure returns (uint256 feeAmountUnit, uint256 protocolFeeAmountUnit) {
    // Fee amount cannot be zero, so we can use the `mulDivUp` function to round up.
    feeAmountUnit = self.input.mulDivUp(feeBasisPoints, BASIS_POINT_DIVISOR);

    if (protocolFeeProportion != 0) {
        // Protocol fee is a proportion of the fee amount.
        protocolFeeAmountUnit = feeAmountUnit / protocolFeeProportion;
        // Subtract the protocol fee from the fee amount.
        feeAmountUnit -= protocolFeeAmountUnit;
    }
}

/**
 * @notice
 * Gets swap & fee adjusted reserves after a swap.
 *
 * @dev
 * Use this method to compute reserves after a swap which will be passed to the invariant check.
 *
 * note
 * If the swap output exceeds the output reserves, it means a price limit has been reached for the pool.
 *
 * @custom:warning
 * If the `self.input` and `self.output` quantities are not in WAD units, this computation could be incorrect.
 *
 * @param self Swap order to compute adjusted reserves for. Input and Output must be WAD units.
 * @param reserveXUnit Total asset tokens in reserves of pool, Unit = input/output units.
 * @param reserveYUnit Total quote tokens in reserves of pool, Unit = input/output units.
 * @param feeAmountUnit Quantity of input tokens which are considered the fee amount, Unit = input units.
 * @param protocolFeeAmountUnit Quantity of input tokens which are paid as the protocol fee amount, Unit = input units.
 * @return adjustedX Swap & fee adjusted reserve of asset tokens.
 * @return adjustedY Swap & fee adjusted reserve of quote tokens.
 */
function computeAdjustedSwapReserves(
    Order memory self,
    uint256 reserveXUnit,
    uint256 reserveYUnit,
    uint256 feeAmountUnit,
    uint256 protocolFeeAmountUnit
) pure returns (uint256 adjustedX, uint256 adjustedY) {
    uint256 adjustedInputReserveWad =
        self.sellAsset ? reserveXUnit : reserveYUnit;
    uint256 adjustedOutputReserveWad = self.sellAsset ? reserveYUnit : reserveXUnit; // forgefmt: disable-line

    // Input amount is added to the reserves for the swap.
    adjustedInputReserveWad += self.input;
    // Fee amount is reinvested into the pool, but it's not considered in the invariant check, so we subtract it.
    if (feeAmountUnit > adjustedInputReserveWad) revert SwapLib_FeeTooHigh();
    adjustedInputReserveWad -= feeAmountUnit;
    // Protocol fee is subtracted, even though it's included in the fee, because protocol fees
    // do not get added to the pool's reserves.
    if (protocolFeeAmountUnit > adjustedInputReserveWad) revert SwapLib_ProtocolFeeTooHigh(); // forgefmt: disable-line
    adjustedInputReserveWad -= protocolFeeAmountUnit;
    // Output amount is removed from the reserves for the swap.
    if (self.output > adjustedOutputReserveWad) revert SwapLib_OutputExceedsReserves(); // forgefmt: disable-line
    adjustedOutputReserveWad -= self.output;

    // Use these adjusted reserves in the invariant check.
    adjustedX = self.sellAsset ? adjustedInputReserveWad : adjustedOutputReserveWad; // forgefmt: disable-line
    adjustedY = self.sellAsset ? adjustedOutputReserveWad : adjustedInputReserveWad; // forgefmt: disable-line
}

/**
 * @notice
 * Get the new reserves and fee amounts paid after a swap.
 *
 * @dev
 * Use this method to compute the new reserves for the invariant check,
 * to confirm a swap will be validated.
 *
 * @param self Swap order to compute swap result for.
 * @param reserveXUnit Total asset tokens in reserves of pool, Unit = input/output units.
 * @param reserveYUnit Total quote tokens in reserves of pool, Unit = input/output units.
 * @param feeBps Fee denominated in basis points, where 1 basis point = 0.01%.
 * @param protocolFee Proportion of the fee amount to charge as a protocol fee.
 * @return feeAmount Quantity of input tokens which are considered the fee amount.
 * @return protocolFeeAmount Quantity of input tokens which are paid as the protocol fee amount.
 * @return adjustedX Swap & fee adjusted reserve of asset tokens.
 * @return adjustedY Swap & fee adjusted reserve of quote tokens.
 */
function computeSwapResult(
    Order memory self,
    uint256 reserveXUnit,
    uint256 reserveYUnit,
    uint256 feeBps,
    uint256 protocolFee
)
    pure
    returns (
        uint256 feeAmount,
        uint256 protocolFeeAmount,
        uint256 adjustedX,
        uint256 adjustedY
    )
{
    (feeAmount, protocolFeeAmount) = self.computeFeeAmounts(feeBps, protocolFee);
    (adjustedX, adjustedY) = self.computeAdjustedSwapReserves(
        reserveXUnit, reserveYUnit, feeAmount, protocolFeeAmount
    );
}

/**
 * @notice
 * Intermediary state during a swap() call.
 *
 * @dev
 * This struct helps avoid stack too deep errors during swap.
 *
 * @param prevInvariant Invariant of the pool before the swap, after timestamp update.
 * @param nextInvariant Invariant of the pool after the swap, returned from validateSwap.
 * @param feeAmountUnit Absolute fee amount of input token, Unit = input units.
 * @param protocolFeeAmountUnit Absolute protocol fee amount of input token, Unit = input units.
 * @param amountInputUnit Quantity of tokens added to reserves, Unit = input units.
 * @param amountOutputUnit Quantity of tokens removed from reserves, Unit = output units.
 * @param tokenInput Address of the token being added to the pool.
 * @param tokenOutput Address of the token being removed from the pool.
 * @param decimalsInput Decimals of the token being added to the pool.
 * @param decimalsOutput Decimals of the token being removed from the pool.
 */
struct SwapState {
    int256 prevInvariant;
    int256 nextInvariant;
    uint256 feeAmountUnit;
    uint256 protocolFeeAmountUnit;
    uint256 amountInputUnit;
    uint256 amountOutputUnit;
    address tokenInput;
    address tokenOutput;
    uint8 decimalsInput;
    uint8 decimalsOutput;
}

using { toWad, fromWad } for SwapState global;

/// @dev Converts native token decimal units to WAD units, assumes inputs are already in native token decimal units.
function toWad(SwapState memory self) pure returns (SwapState memory) {
    self.feeAmountUnit = self.feeAmountUnit.scaleToWad(self.decimalsInput);
    self.protocolFeeAmountUnit =
        self.protocolFeeAmountUnit.scaleToWad(self.decimalsInput);
    self.amountInputUnit = self.amountInputUnit.scaleToWad(self.decimalsInput);
    self.amountOutputUnit =
        self.amountOutputUnit.scaleToWad(self.decimalsOutput);
    return self;
}

/// @dev Converts WAD units to native token decimal units.
function fromWad(SwapState memory self) pure returns (SwapState memory) {
    // Assuming these quantities are originally scaled to WAD units in swap(),
    // scaling them down and rounding down should lead to no information loss.
    self.feeAmountUnit = self.feeAmountUnit.scaleFromWadDown(self.decimalsInput);
    self.protocolFeeAmountUnit =
        self.protocolFeeAmountUnit.scaleFromWadDown(self.decimalsInput);
    self.amountInputUnit =
        self.amountInputUnit.scaleFromWadDown(self.decimalsInput);
    self.amountOutputUnit =
        self.amountOutputUnit.scaleFromWadDown(self.decimalsOutput);
    return self;
}
