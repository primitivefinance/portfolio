// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IHyperEvents {
    // --- Pairs --- //
    /// @dev Emitted on setting a new token pair in state with the key `pairId`.
    event CreatePair(
        uint16 indexed pairId,
        address indexed asset,
        address indexed quote,
        uint8 assetDecimals,
        uint8 quoteDecimals
    );

    // --- Curves --- //

    /// @dev Emitted on setting a new curve parameter set in state with key `curveId`.
    event CreateCurve(
        uint32 indexed curveId,
        uint128 strike,
        uint24 sigma,
        uint32 indexed maturity,
        uint32 indexed gamma,
        uint32 priorityGamma
    );
    // --- Balances --- //
    /// @dev A payment requested by this contract that must be paid by the `msg.sender` account.
    event DecreaseUserBalance(address indexed token, uint256 amount);
    /// @dev A payment that is paid out to the `msg.sender` account from this contract.
    event IncreaseUserBalance(address indexed token, uint256 amount);

    // --- Global Reserves --- //
    /// @dev Emitted on any pool interaction which increases one of the pool's reserves.
    /// @custom:security High. Use these to track the total value locked of a token.
    event IncreaseGlobalBalance(address indexed token, uint256 amount);
    /// @dev Emitted on any pool interaction which decreases one of the pool's reserves.
    /// @custom:security High.
    event DecreaseGlobalBalance(address indexed token, uint256 amount);

    // --- Pools --- //
    /// @dev Emitted on creating a pool for a pair and curve.
    event CreatePool(uint48 indexed poolId, uint16 indexed pairId, uint32 indexed curveId, uint256 price);

    event PoolUpdate(
        uint48 indexed poolId,
        uint256 price,
        int24 indexed tick,
        uint256 liquidity,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote
    );
    /// @dev Emitted on increasing the internal reserves of a pool.
    event AddLiquidity(
        uint48 indexed poolId,
        address indexed asset,
        address indexed quote,
        uint256 deltaAsset,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );
    /// @dev Emitted on decreasing the internal reserves of a pool.
    event RemoveLiquidity(
        uint48 indexed poolId,
        address indexed asset,
        address indexed quote,
        uint256 deltaAsset,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    // -- Auction Params -- //
    /// @dev Emitted when auction parameters for a pool are updated.
    event SetAuctionParams(uint48 indexed poolId, uint256 startPrice, uint256 endPrice, uint256 fee, uint256 length);

    // -- Positions -- //
    /// @dev Emitted on increasing liquidity or creating a pool.
    event IncreasePosition(address indexed account, uint96 indexed positionId, uint256 deltaLiquidity);
    /// @dev Emitted on removing liquidity only.
    event DecreasePosition(address indexed account, uint96 indexed positionId, uint256 deltaLiquidity);

    // - Fees - //
    event Collect(
        uint96 indexed positionId,
        address indexed to,
        uint256 tokensCollectedAsset,
        address asset,
        uint256 tokensCollectedQuote,
        address quote
    );

    // -- Swaps -- //
    /// @dev Emitted on a token swap in a single virtual pool.
    event Swap(uint48 indexed poolId, uint256 input, uint256 output, address indexed tokenIn, address indexed tokenOut);

    // - Sync pool - //
    /// @dev Emitted on external calls to `updateLastTimestamp` or `swap`. Syncs a pool's timestamp to block.timestamp.
    event UpdateLastTimestamp(uint48 indexed poolId);

    // - Slots - //
    /// @dev Emitted when entering or exiting a slot when swapping.
    event SlotTransition(uint48 indexed poolId, int24 indexed tick, int256 liquidityDelta);
}

/// @title IHyperGetters
/// @dev Public view functions exposed by the Enigma's higher level contracts.
interface IHyperGetters {
    // --- Enigma --- //
    function pairs(uint16 pairId)
        external
        view
        returns (
            address tokenasset,
            uint8 decimalsasset,
            address tokenQuote,
            uint8 decimalsQuote
        );

    function curves(uint32 curveId)
        external
        view
        returns (
            uint128 strike,
            uint24 sigma,
            uint32 maturity,
            uint32 gamma,
            uint32 priorityGamma
        );

    function epochs(uint48 poolId)
        external
        view
        returns (
            uint256 id,
            uint256 endTime,
            uint256 interval
        );

    function pools(uint48 poolId)
        external
        view
        returns (
            uint256 lastPrice,
            int24 lastTick,
            uint256 blockTimestamp,
            uint256 liquidity,
            uint256 stakedLiquidity,
            int256 epochStakedLiquidityDelta,
            address prioritySwapper,
            uint256 priorityPaymentPerSecond,
            uint256 feeGrowthGlobalAsset,
            uint256 feeGrowthGlobalQuote
        );

    function slots(uint48 poolId, int24 slot)
        external
        view
        returns (
            int256 liquidityDelta,
            int256 stakedLiquidityDelta,
            int256 epochStakedLiquidityDelta,
            uint256 totalLiquidity,
            uint256 feeGrowthOutsideAsset,
            uint256 feeGrowthOutsideQuote,
            uint256 rewardGrowthOutside,
            bool instantiated,
            uint256 timestamp
        );

    function globalReserves(address asset) external view returns (uint256);

    function getCurveId(bytes32) external view returns (uint32);

    function getCurveNonce() external view returns (uint256);

    function getPairNonce() external view returns (uint256);

    // --- Liquidity --- //

    /// @notice Computes the amount of time passed since the Position's liquidity was updated.
    /// @custom:mev Just In Time (JIT) liquidity is adding and removing liquidity as a sandwich around a transaction.
    /// It's mitigated with a distance calculated between the time it was added and removed.
    /// If the distance is non-zero, it means liquidity was allocated and removed in different blocks.
    /// @custom:security High. An incorrectly computed distance could lead to possible
    /// negative (or positive) effects to accounts interacting with the Enigma.
    function checkJitLiquidity(address account, uint48 poolId)
        external
        view
        returns (uint256 distance, uint256 timestamp);

    /// @notice Computes the pro-rata amount of liquidity minted from allocating `deltaAsset` and `deltaQuote` amounts.
    /// @dev Designed to round in a direction disadvantageous to the account minting liquidity.
    /// @custom:security High. Liquidity amounts minted have a direct impact on liquidity pools.
    function getLiquidityMinted(
        uint48 poolId,
        uint256 deltaAsset,
        uint256 deltaQuote
    ) external view returns (uint256 deltaLiquidity);

    // --- Swap --- //

    /// @notice Uses the ReplicationMath.sol trading function to check if a swap is valid.
    /// @dev Warning! Can revert if poolId references an unsynced pool. Returns a fixed point 64.64 formatted value.
    /// @custom:security Critical. The invariant check is the most important check for the Enigma.
    /// @return invariant FixedPoint64.64 invariant value denominated in `quoteToken` units.
    function getInvariant(uint48 poolId) external view returns (int128 invariant);

    /// @notice Computes amount of asset and quote tokens entitled to `liquidity` amount.
    /// @dev Can be used to fetch the expected amount of tokens withdrawn from removing `liquidity`.
    /// @custom:security Medium. Designed to round in a direction disadvantageous to the liquidity owner.
    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        external
        view
        returns (uint256 deltaAsset, uint256 deltaQuote);
}

interface IHyperActions {
    /// @dev Increases the `msg.sender` account's internal balance of `token`.
    /// @custom:security High. Calls the `token` external contract.
    function fund(address token, uint256 amount) external payable;

    /// @notice Transfers `amount` of `token` to the `to` account.
    /// @dev Decreases the `msg.sender` account's internal balance of `token`.
    /// @custom:security High. Calls the `token` external contract.
    function draw(
        address token,
        uint256 amount,
        address to
    ) external;

    /// @notice Syncs a pool with `poolId` to the current `block.timestamp`.
    /// @dev Use this method after the pool is expired or else the invariant method will revert.
    /// @custom:security Medium. Alternative method (instead of swapping) of syncing pools to the current timestamp.
    function updateLastTimestamp(uint48 poolId) external returns (uint128 blockTimestamp);

    // TODO: add collect function to collect swap fees
}

/// @title IHyper
/// @dev All the interfaces of the Enigma, so it can be imported with ease.
interface IHyper is IHyperActions, IHyperEvents, IHyperGetters {

}
