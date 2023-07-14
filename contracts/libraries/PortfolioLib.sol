// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "solmate/utils/SafeCastLib.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "./AssemblyLib.sol";
import "./AccountLib.sol" as AccountLib;
import "./ConstantsLib.sol" as ConstantsLib;
import "./PoolLib.sol";
import "./SwapLib.sol";

using AssemblyLib for uint256;
using FixedPointMathLib for uint256;
using FixedPointMathLib for uint128;
using FixedPointMathLib for int256;
using SafeCastLib for uint256;

error InsufficientLiquidity();
error InvalidDecimals(uint8 decimals);
error InvalidDuration(uint16);
error InvalidFee(uint16 fee);
error InvalidPriorityFee(uint16 priorityFee);
error InvalidInvariant(int256 prev, int256 next);
error InvalidPairNonce();
error InvalidReentrancy();
error InvalidMulticall();
error InvalidSettlement();
error InvalidStrike(uint128 strike);
error InvalidVolatility(uint16 sigma);
error NegativeBalance(address token, int256 net);
error NotController();
error NonExistentPool(uint64 poolId);
error NotExpiringPool();
error PairExists(uint24 pairId);
error PoolExpired();
error SameTokenError();
error SwapInputTooSmall();
error ZeroAmounts();
error ZeroInput();
error ZeroLiquidity();
error ZeroOutput();
error ZeroPrice();
error InvalidNegativeLiquidity();
error MaxDeltaReached();
error MinDeltaUnmatched();

struct PortfolioPair {
    address tokenAsset; // Base asset, referred to as "X" reserve.
    uint8 decimalsAsset;
    address tokenQuote; // Quote asset, referred to as "Y" reserve.
    uint8 decimalsQuote;
}

struct ChangeLiquidityParams {
    uint256 timestamp;
    uint256 deltaAsset; // Quantity of asset tokens in WAD units to add or remove.
    uint256 deltaQuote; // Quantity of quote tokens in WAD units to add or remove.
    int128 deltaLiquidity; // Quantity of liquidity tokens in WAD units to add or remove.
    uint64 poolId; // If allocating, setting the poolId to 0 will be a magic variable to use the `_getLastPoolId` as the poolId.
    address owner; // Address with position liquidity to change.
    address tokenAsset; // Address of the asset token.
    address tokenQuote; // Address of the quote token.
}

struct Iteration {
    int256 prevInvariant; // Invariant of the pool before the swap, after timestamp update.
    int256 nextInvariant; // Invariant of the pool after the swap.
    uint256 virtualX; // Virtual X reserves in WAD units for all liquidity.
    uint256 virtualY; // Virtual Y reserves in WAD units for all liquidity.
    uint256 remainder; // Remainder of input tokens to swap in, in WAD units.
    uint256 feeAmount; // Fee amount in WAD units.
    uint256 protocolFeeAmount; // WAD
    uint256 liquidity; // Total supply of liquidity in WAD units.
    uint256 input;
    uint256 output;
}

struct SwapState {
    uint8 decimalsInput;
    address tokenInput;
    uint8 decimalsOutput;
    address tokenOutput;
}

struct Payment {
    uint256 amountTransferTo; // Amount to transfer to the `msg.sender` in `settlement`, in WAD.
    uint256 amountTransferFrom; // Amount to transfer from the `msg.sender` in `settlement`, in WAD.
    uint256 balance; // Current `token.balanceOf(address(this))` in `settlement`, in native token decimals.
    address token;
}
