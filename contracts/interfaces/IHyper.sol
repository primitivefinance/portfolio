// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {HyperCurve, HyperPair} from "../HyperLib.sol";

interface IHyperEvents {
    /**
     * @dev Ether transfers into Hyper via payable `deposit` function.
     */
    event Deposit(address indexed account, uint256 amount);

    /**
     * @notice Assigns `amount` of `token` to `account`.
     * @dev Emitted on `unallocate`, `swap`, or `fund`.
     */
    event IncreaseUserBalance(address indexed account, address indexed token, uint256 amount);

    /**
     * @notice Unassigns `amount` of `token` from `account`.
     * @dev Emitted on `allocate`, `swap`, or `draw`.
     */
    event DecreaseUserBalance(address indexed account, address indexed token, uint256 amount);

    /**
     * @notice Assigns an additional `amount` of `token` to Hyper's internally tracked balance.
     * @dev Emitted on `swap`, `allocate`, and when a user is gifted surplus tokens.
     */
    event IncreaseReserveBalance(address indexed token, uint256 amount);

    /**
     * @notice Unassigns `amount` of `token` from Hyper's internally tracked balance.
     * @dev Emitted on `swap`, `unallocate`, and when paying with an internal balance.
     */
    event DecreaseReserveBalance(address indexed token, uint256 amount);

    /**
     * @dev Assigns `input` amount of `tokenIn` to Hyper's reserves.
     * Unassigns `output` amount of `tokenOut` from Hyper's reserves.
     * @param price Post-swap approximated marginal price in wad units.
     * @param feeAmountDec Amount of `tokenIn` tokens paid as a fee.
     * @param invariantWad Post-swap invariant in wad units.
     */
    event Swap(
        uint64 indexed poolId,
        uint256 price,
        address indexed tokenIn,
        uint256 input,
        address indexed tokenOut,
        uint256 output,
        uint256 feeAmountDec,
        int256 invariantWad
    );

    /**
     * @dev Assigns amount `deltaAsset` of `asset` and `deltaQuote` of `quote` tokens to `poolId.
     */
    event Allocate(
        uint64 indexed poolId,
        address indexed asset,
        address indexed quote,
        uint256 deltaAsset,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    /**
     * @dev Unassigns amount `deltaAsset` of `asset` and `deltaQuote` of `quote` tokens to `poolId.
     */
    event Unallocate(
        uint64 indexed poolId,
        address indexed asset,
        address indexed quote,
        uint256 deltaAsset,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    /** @dev Emits a `0` for unchanged parameters. */
    event ChangeParameters(uint64 indexed poolId, uint16 indexed priorityFee, uint16 indexed fee, uint16 jit);

    /**
     * @notice Reduces `feeAssetDec` amount of `asset` and `feeQuoteDec` amount of `quote` from the position's state.
     */
    event Collect(
        uint64 poolId,
        address indexed account,
        uint256 feeAssetDec,
        address indexed asset,
        uint256 feeQuoteDec,
        address indexed quote
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
    // ===== Account Getters ===== //
    function getBalance(address owner, address token) external view returns (uint256);

    function getReserve(address token) external view returns (uint256);

    function getNetBalance(address token) external view returns (int256);

    // ===== State Getters ===== //

    function VERSION() external pure returns (string memory);

    function WETH() external view returns (address);

    function getPairNonce() external view returns (uint24);

    function getPoolNonce() external view returns (uint32);

    function getPairId(address asset, address quote) external view returns (uint24 pairId);

    function pairs(
        uint24 pairId
    ) external view returns (address tokenAsset, uint8 decimalsAsset, address tokenQuote, uint8 decimalsQuote);

    /**
     * @dev Structs in memory are returned as tuples, e.g. (foo, bar...).
     */
    function pools(
        uint64 poolId
    )
        external
        view
        returns (
            uint128 virtualX,
            uint128 virtualY,
            uint128 liquidity,
            uint32 lastTimestamp,
            address controller,
            uint256 invariantGrowthGlobal,
            uint256 feeGrowthGlobalAsset,
            uint256 feeGrowthGlobalQuote,
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
            uint256 lastTimestamp,
            uint256 invariantGrowthLast,
            uint256 feeGrowthAssetLast,
            uint256 feeGrowthQuoteLast,
            uint128 tokensOwedAsset,
            uint128 tokensOwedQuote,
            uint128 invariantOwed
        );

    // ===== Hyper View ===== //

    function getLiquidityDeltas(
        uint64 poolId,
        int128 deltaLiquidity
    ) external view returns (uint128 deltaAsset, uint128 deltaQuote);

    function getMaxLiquidity(
        uint64 poolId,
        uint256 deltaAsset,
        uint256 deltaQuote
    ) external view returns (uint128 deltaLiquidity);

    /**
     * @dev Amount of tokens received if all pool liquidity was removed.
     */
    function getReserves(uint64 poolId) external view returns (uint256 deltaAsset, uint256 deltaQuote);

    /**
     * @dev Amount of tokens scaled to WAD units per WAD liquidity.
     */
    function getVirtualReservesPerLiquidity(
        uint64 poolId
    ) external view returns (uint128 deltaAsset, uint128 deltaQuote);

    // ===== Objective View ===== //

    // todo: ... missing some which use structs as args

    function getAmountOut(uint64 poolId, bool sellAsset, uint256 amountIn) external view returns (uint256);

    function getLatestEstimatedPrice(uint64 poolId) external view returns (uint256 price);
}

interface IHyperActions {
    /**
     * @dev Entrypoint to manipulate balances in Hyper.
     */
    function multiprocess(bytes calldata data) external payable;

    /**
     * @notice Assigns `amount` of `token` to `msg.sender` internal balance.
     * @dev Uses `IERC20.transferFrom`.
     */
    function fund(address token, uint256 amount) external;

    /**
     * @notice Unassigns `amount` of `token` from `msg.sender` and transfers it to the `to` address.
     * @dev Uses `IERC20.transfer`.
     */
    function draw(address token, uint256 amount, address to) external;

    /**
     * @notice Deposits ETH into the user internal balance.
     * @dev Amount of ETH must be sent as `msg.value`, the ETH will be wrapped.
     */
    function deposit() external payable;

    /**
     * @notice Updates the parameters of the pool `poolId`.
     * @dev The sender must be the pool controller, leaving a function parameter
     * as '0' will not change the pool parameter.
     * @param priorityFee New priority fee of the pool in basis points (1 = 0.01%).
     * @param fee New fee of the pool in basis points (1 = 0.01%).
     * @param jit New JIT policy of the pool in seconds (1 = 1 second).
     */
    function changeParameters(uint64 poolId, uint16 priorityFee, uint16 fee, uint16 jit) external;
}

interface IHyper is IHyperActions, IHyperEvents, IHyperGetters {}
