// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import "solmate/utils/SafeCastLib.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "./AssemblyLib.sol";
import "./AccountLib.sol" as AccountLib;
import "./ConstantsLib.sol" as ConstantsLib;
import "./PoolLib.sol";
import "./SwapLib.sol";

error Portfolio_BeforeSwapFail();
error Portfolio_DuplicateToken();
error Portfolio_Insolvent(address token, int256 net);
error Portfolio_InsufficientLiquidity();
error Portfolio_InvalidDecimals(uint8 decimals);
error Portfolio_InvalidProtocolFee(uint256 protocolFee);
error Portfolio_InvalidPool(uint64 poolId);
error Portfolio_InvalidInvariant(int256 prev, int256 next);
error Portfolio_InvalidPairNonce();
error Portfolio_InvalidReentrancy();
error Portfolio_InvalidMulticall();
error Portfolio_InvalidSettlement();
error Portfolio_MaxAssetExceeded();
error Portfolio_MaxQuoteExceeded();
error Portfolio_MinAssetExceeded();
error Portfolio_MinQuoteExceeded();
error Portfolio_NonExistentPool(uint64 poolId);
error Portfolio_NotController();
error Portfolio_PairExists(uint24 pairId);
error Portfolio_ZeroAssetAllocate();
error Portfolio_ZeroLiquidityAllocate();
error Portfolio_ZeroLiquidityDeallocate();
error Portfolio_ZeroSwapLiquidity();
error Portfolio_ZeroSwapInput();
error Portfolio_ZeroSwapOutput();
error Portfolio_ZeroQuoteAllocate();

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

struct Payment {
    uint256 amountTransferTo; // Amount to transfer to the `msg.sender` in `settlement`, in WAD.
    uint256 amountTransferFrom; // Amount to transfer from the `msg.sender` in `settlement`, in WAD.
    uint256 balance; // Current `token.balanceOf(address(this))` in `settlement`, in native token decimals.
    address token;
}
