// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { PortfolioCurve, PortfolioPair, Order } from "../PortfolioLib.sol";

interface IPortfolioEvents {
    /**
     * @dev Ether transfers into Portfolio via payable `multiprocess` function.
     */
    event Deposit(address indexed account, uint256 amount);

    /**
     * @notice Assigns an additional `amount` of `token` to Portfolio's internal accounting system.
     * @dev Emitted on `swap` and `allocate`.
     * @param amount Quantity of token in WAD units.
     */
    event IncreaseReserveBalance(address indexed token, uint256 amount);

    /**
     * @notice Unassigns `amount` of `token` from Portfolio's internal accounting system.
     * @dev Emitted on `swap` and `deallocate`.
     * @param amount Quantity of token in WAD units.
     */
    event DecreaseReserveBalance(address indexed token, uint256 amount);

    /**
     * @dev Swaps `input` amount of `tokenIn` for `output` amount of `tokenOut` in pool with `poolId`.
     * @param price Post-swap approximated marginal price in wad units.
     * @param tokenIn Token sold.
     * @param input Quantity of input token sold in native token decimals.
     * @param tokenOut Token bought.
     * @param output Quantity of output token bought in native token decimals.
     * @param feeAmountDec Amount of the sold tokens that are paid as a fee to LPs.
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
     * @dev Assigns amount `deltaAsset` of `asset` and `deltaQuote` of `quote` tokens to `poolId`.
     * Units are in the respective tokens' native decimals. Units for `deltaLiquidity` are WAD.
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
     * @dev Unassigns amount `deltaAsset` of `asset` and `deltaQuote` of `quote` tokens to `poolId`.
     * Units are in the respective tokens' native decimals. Units for `deltaLiquidity` are WAD.
     */
    event Deallocate(
        uint64 indexed poolId,
        address indexed asset,
        address indexed quote,
        uint256 deltaAsset,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    /**
     * @dev Emits a `0` for unchanged parameters.
     * @param poolId Unique identifier for the pool that is being updated.
     * @param priorityFee Fee percentage paid by the pool controller (if any).
     * @param fee Fee percentage paid by swappers.
     */
    event ChangeParameters(
        uint64 indexed poolId, uint16 indexed priorityFee, uint16 indexed fee
    );

    /**
     * @notice Emitted on pair creation.
     * @param pairId Unique nonce for the pair that is being created.
     * @param asset Token that is being paired.
     * @param quote Token that is being paired.
     * @param decimalsAsset Decimals of the asset token.
     * @param decimalsQuote Decimals of the quote token.
     */
    event CreatePair(
        uint24 indexed pairId,
        address indexed asset,
        address indexed quote,
        uint8 decimalsAsset,
        uint8 decimalsQuote
    );

    /**
     * @dev Emitted on pool creation.
     * @param poolId Unique identifier for the pool that is being created.
     * @param asset Token that is being paired.
     * @param quote Token that is being paired.
     * @param controller Address that can call `changeParameters` on the pool.
     * @param maxPrice The terminal price reached upon the end of the duration.
     * @param fee Fee percentage paid by swappers.
     * @param duration Days until the pool cannot be swapped in anymore.
     * @param volatility Volatility in basis points which determines price impact of swaps.
     * @param priorityFee Fee percentage paid by the pool controller (if any).
     */
    event CreatePool(
        uint64 indexed poolId,
        address indexed asset,
        address indexed quote,
        address controller,
        uint128 maxPrice,
        uint16 fee,
        uint16 duration,
        uint16 volatility,
        uint16 priorityFee
    );

    /**
     * @dev Emitted on updating the `protocolFee` state value.
     * @param prevFee Previous protocol fee portion of the swap fee.
     * @param nextFee Next protocol fee portion of the swap fee.
     */
    event UpdateProtocolFee(uint256 prevFee, uint256 nextFee);

    /**
     * @dev Emitted when the REGISTRY claims protocol fees.
     * @param token Token that is being claimed.
     * @param amount Amount of token claimed in native token decimals.
     */
    event ClaimFees(address indexed token, uint256 amount);
}

interface IPortfolioGetters {
    // ===== Account Getters ===== //

    /**
     * @dev Internally tracked global balance of all `token`s assigned to an address or a pool.
     * @return Global balance held in WAD units.
     */
    function getReserve(address token) external view returns (uint256);

    /**
     * @notice Difference of `token.balanceOf(this)` and internally tracked reserve balance.
     * @dev Critical system invariant. Must always return greater than or equal to zero.
     * @return Net balance held in native token decimals.
     * @custom:example Assumes token is 18 decimals.
     * ```
     * uint256 previousReserve = getReserve(token);
     * uint256 previousBalance = token.balanceOf(portfolio);
     * assertEq(previousReserve, 1);
     * assertEq(previousBalance, 1);
     * token.transfer(portfolio, 10);
     * uint256 netBalance = getNetBalance(token);
     * assertEq(netBalance, 10);
     * ```
     */
    function getNetBalance(address token) external view returns (int256);

    // ===== State Getters ===== //

    /**
     * @dev Current semantic version of the Portfolio.
     */
    function VERSION() external pure returns (string memory);

    /**
     * @dev Wrapped Ether address initialized on creating the Portfolio.
     */
    function WETH() external view returns (address);

    /**
     * @dev Contract for storing canonical Portfolio deployments.
     */
    function REGISTRY() external view returns (address);

    /**
     * @dev Incremented when a new pair of tokens is made and stored in the `pairs` mapping.
     */
    function getPairNonce() external view returns (uint24);

    /**
     * @dev Incremented when a pool is created.
     */
    function getPoolNonce(uint24 pairNonce) external view returns (uint32);

    /**
     * @dev Reverse lookup to find the `pairId` of a given `asset` and `quote`.
     * Order matters! There can be two pairs for every two tokens.
     */
    function getPairId(
        address asset,
        address quote
    ) external view returns (uint24 pairId);

    function pairs(uint24 pairId)
        external
        view
        returns (
            address tokenAsset,
            uint8 decimalsAsset,
            address tokenQuote,
            uint8 decimalsQuote
        );

    /**
     * @dev Structs in memory are returned as tuples, e.g. (foo, bar...).
     */
    function pools(uint64 poolId)
        external
        view
        returns (
            uint128 virtualX,
            uint128 virtualY,
            uint128 liquidity,
            uint32 lastTimestamp,
            address controller,
            PortfolioCurve memory,
            PortfolioPair memory
        );

    function positions(
        address owner,
        uint64 poolId
    ) external view returns (uint128 freeLiquidity, uint32 lastTimestamp);

    // ===== Portfolio View ===== //

    /**
     * @dev Computes amount of `deltaAsset` and `deltaQuote` that must be paid for to
     * mint `deltaLiquidity`.
     * @return deltaAsset Real quantity of `asset` tokens underlying `deltaLiquidity`, in native decimal units.
     * @return deltaQuote Real quantity of `quote` tokens underlying `deltaLiquidity`, in native decimal units.
     */
    function getLiquidityDeltas(
        uint64 poolId,
        int128 deltaLiquidity
    ) external view returns (uint128 deltaAsset, uint128 deltaQuote);

    /**
     * @dev Computes the optimal and max amount of `deltaLiquidity` given two
     * amounts of `deltaAsset` and `deltaQuote`.
     * @param deltaAsset Quantity of `asset` tokens in native decimal units.
     * @param deltaQuote Quantity of `quote` tokens in native decimal units.
     * @return deltaLiquidity Quantity of liquidity minted in wad units.
     */
    function getMaxLiquidity(
        uint64 poolId,
        uint256 deltaAsset,
        uint256 deltaQuote
    ) external view returns (uint128 deltaLiquidity);

    /**
     * @dev Amount of tokens received if all `pool.liquidity` is removed.
     * @return deltaAsset Quantity of `asset` tokens in native decimal units.
     * @return deltaQuote Quantity of `quote` tokens in native decimal units.
     */
    function getPoolReserves(uint64 poolId)
        external
        view
        returns (uint256 deltaAsset, uint256 deltaQuote);

    /**
     * @dev Amount of tokens in native token decimals.
     * @return deltaAsset Quantity of `asset` tokens in native decimal units.
     * @return deltaQuote Quantity of `quote` tokens in native decimal units.
     */
    function getVirtualReservesDec(uint64 poolId)
        external
        view
        returns (uint128 deltaAsset, uint128 deltaQuote);

    // ===== Objective View ===== //

    /**
     * @dev Computes an amount out of tokens given an `amountIn`.
     * @param sellAsset If true, swap `asset` for `quote` tokens.
     * @param amountIn Quantity of tokens to swap in, denominated in native token decimal units.
     * @param swapper Address that will execute the swap.
     * @return amountOut of tokens in native token decimal units.
     */
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) external view returns (uint256);

    /**
     * @dev Computes an estimated on-chain price of the `poolId`.
     * @custom:mev Vulnerable to manipulation, do not rely on this function on-chain.
     * @return price Estimated price in wad units of `quote` tokens per `asset` token.
     */
    function getSpotPrice(uint64 poolId)
        external
        view
        returns (uint256 price);
}

interface IPortfolioActions {
    /**
     * @notice Entrypoint to allocate, deallocate, or swap in Portfolio.
     * @dev Multiprocess expects custom encoded data that can be built off-chain
     * or on-chain using the `FVMLib` library. This function is similar to
     * multicall, which sends calldata to a target by looping over an array of
     * calldatas and targets.
     *
     * The difference is that the transactions in a multicall
     * must setttle token amounts in each call.
     * In multiprocess, token amounts are settled after all calls
     * have been processed.
     *
     * This means that token deficits can be carried over between calls
     * and paid by future ones (within the same multiprocess transaction)!
     */
    // function multiprocess(bytes calldata data) external payable;

    /**
     * @notice Updates the parameters of the pool `poolId`.
     * @dev The sender must be the pool controller, leaving a function parameter
     * as '0' will not change the pool parameter.
     * @param priorityFee New priority fee of the pool in basis points (1 = 0.01%).
     * @param fee New fee of the pool in basis points (1 = 0.01%).
     */
    function changeParameters(
        uint64 poolId,
        uint16 priorityFee,
        uint16 fee
    ) external;

    /**
     * @dev Sets the `protocolFee` state value.
     * @param fee Must be within the range: 4 <= x <= 20.
     */
    function setProtocolFee(uint256 fee) external;

    /**
     * @dev Transfers fees earned in `amount` of `token` to `REGISTRY` address.
     */
    function claimFee(address token, uint256 amount) external;

    function allocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 maxDeltaAsset,
        uint128 maxDeltaQuote
    ) external payable returns (uint256 deltaAsset, uint256 deltaQuote);

    function deallocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 minDeltaAsset,
        uint128 minDeltaQuote
    ) external payable returns (uint256 deltaAsset, uint256 deltaQuote);

    function swap(Order memory args)
        external
        payable
        returns (uint64 poolId, uint256 input, uint256 output);

    function createPair(
        address asset,
        address quote
    ) external payable returns (uint24 pairId);

    function createPool(
        uint24 pairId,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint128 maxPrice,
        uint128 price
    ) external payable returns (uint64 poolId);

    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
}

interface IPortfolio is
    IPortfolioActions,
    IPortfolioEvents,
    IPortfolioGetters
{ }
