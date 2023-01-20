// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {HyperCurve, HyperPair} from "../HyperLib.sol";

interface IHyperEvents {
    event Deposit(address indexed account, uint amount);
    event DecreaseUserBalance(address indexed account, address indexed token, uint256 amount);
    event DecreaseReserveBalance(address indexed token, uint256 amount);
    event IncreaseUserBalance(address indexed account, address indexed token, uint256 amount);
    event IncreaseReserveBalance(address indexed token, uint256 amount);
    event Swap(
        uint64 indexed poolId,
        uint256 price,
        address indexed tokenIn,
        uint256 input,
        address indexed tokenOut,
        uint256 output
    );
    event Stake(uint64 indexed poolId, address indexed owner, uint deltaLiquidity);
    event Unstake(uint64 indexed poolId, address indexed owner, uint deltaLiquidity);
    event Allocate(
        uint64 indexed poolId,
        address indexed asset,
        address indexed quote,
        uint256 deltaAsset,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );
    event Unallocate(
        uint64 indexed poolId,
        address indexed asset,
        address indexed quote,
        uint256 deltaAsset,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    event ChangeParameters(
        uint64 indexed poolId,
        uint16 priorityFee,
        uint16 indexed fee,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        int24 indexed maxTick
    );
    event Collect(
        uint64 poolId,
        address account,
        uint feeAsset,
        address indexed asset,
        uint feeQuote,
        address indexed quote,
        uint feeReward,
        address indexed reward
    );
    event CreatePair(
        uint24 indexed pairId,
        address indexed asset,
        address indexed quote,
        uint8 decimalsAsset,
        uint8 decimalsQuote
    );
    event CreatePool(
        uint64 indexed poolId,
        bool isMutable,
        address indexed asset,
        address indexed quote,
        uint256 price
    );
}

interface IHyperGetters {
    function getNetBalance(address token) external view returns (int);

    function getReserve(address token) external view returns (uint);

    function getBalance(address owner, address token) external view returns (uint);

    function pairs(
        uint24 pairId
    ) external view returns (address tokenAsset, uint8 decimalsAsset, address tokenQuote, uint8 decimalsQuote);

    function pools(
        uint64 poolId
    )
        external
        view
        returns (
            int24 lastTick,
            uint32 lastTimestamp,
            address controller,
            uint256 feeGrowthGlobalReward,
            uint256 feeGrowthGlobalAsset,
            uint256 feeGrowthGlobalQuote,
            uint128 lastPrice,
            uint128 liquidity,
            uint128 stakedLiquidity,
            int128 stakedLiquidityDelta,
            HyperCurve memory,
            HyperPair memory
        );

    function positions(
        address owner,
        uint64 poolId
    )
        external
        view
        returns (
            uint128 freeLiquidity,
            uint128 stakedLiquidity,
            uint256 lastTimestamp,
            uint256 stakeTimestamp,
            uint256 unstakeTimestamp,
            uint256 feeGrowthRewardLast,
            uint256 feeGrowthAssetLast,
            uint256 feeGrowthQuoteLast,
            uint128 tokensOwedAsset,
            uint128 tokensOwedQuote,
            uint128 tokensOwedReward
        );

    function getPairNonce() external view returns (uint24);

    function getPoolNonce() external view returns (uint32);

    function getAmounts(uint64 poolId) external view returns (uint256 deltaAsset, uint256 deltaQuote);

    function getAmountOut(uint64 poolId, bool sellAsset, uint amountIn) external view returns (uint);

    function getVirtualReserves(uint64 poolId) external view returns (uint128 deltaAsset, uint128 deltaQuote);

    function getMaxLiquidity(
        uint64 poolId,
        uint deltaAsset,
        uint deltaQuote
    ) external view returns (uint128 deltaLiquidity);

    function getLiquidityDeltas(
        uint64 poolId,
        int128 deltaLiquidity
    ) external view returns (uint128 deltaAsset, uint128 deltaQuote);

    function getLatestPrice(uint64 poolId) external view returns (uint price);
}

interface IHyperActions {
    function allocate(uint64 poolId, uint deltaLiquidity) external returns (uint deltaAsset, uint deltaQuote);

    function unallocate(uint64 poolId, uint amount) external returns (uint deltaAsset, uint deltaQuote);

    function stake(uint64 poolId, uint128 deltaLiquidity) external;

    function unstake(uint64 poolId, uint128 deltaLiquidity) external;

    function swap(
        uint64 poolId,
        bool sellAsset,
        uint amount,
        uint limit
    ) external returns (uint output, uint remainder);

    function fund(address token, uint256 amount) external;

    function draw(address token, uint256 amount, address to) external;

    function deposit() external payable;

    function changeParameters(
        uint64 poolId,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        int24 maxTick
    ) external;
}

interface IHyper is IHyperActions, IHyperEvents, IHyperGetters {}
