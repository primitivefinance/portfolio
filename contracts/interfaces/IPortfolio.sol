// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { PortfolioPair, Order } from "../libraries/PortfolioLib.sol";

interface IPortfolioEvents {
    /// @dev Ether transfers into Portfolio via a payable function.
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
     * @param tokenIn Token sold.
     * @param input Quantity of input token sold in native token decimals.
     * @param tokenOut Token bought.
     * @param output Quantity of output token bought in native token decimals.
     * @param feeAmountDec Amount of the sold tokens that are paid as a fee to LPs.
     * @param invariantWad Post-swap invariant of the new input reserve WITHOUT the fee amount included.
     */
    event Swap(
        uint64 indexed poolId,
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
     * @param strikePrice The terminal price reached upon the end of the duration.
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
        uint128 strikePrice,
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

    /// @notice Current semantic version of the Portfolio.
    function VERSION() external pure returns (string memory);

    /// @notice Wrapped Ether address initialized on creating the Portfolio.
    function WETH() external view returns (address);

    /// @notice Contract for storing canonical Portfolio deployments.
    function REGISTRY() external view returns (address);

    /// @notice Proportion of swap fee allocated to the Registry controller.
    function protocolFee() external view returns (uint256);

    /// @notice Incremented when a new pair of tokens is made and stored in the `pairs` mapping.
    function getPairNonce() external view returns (uint24);

    /// @notice Incremented when a pool is created.
    function getPoolNonce(uint24 pairNonce) external view returns (uint32);

    /**
     * @dev Reverse lookup to find the `pairId` of a given `asset` and `quote`.
     * Order matters! There can be two pairs for every two tokens.
     */
    function getPairId(
        address asset,
        address quote
    ) external view returns (uint24 pairId);

    /// @dev Tracks the amount of protocol fees collected for a given `token`.
    function protocolFees(address token) external view returns (uint256);

    function pairs(uint24 pairId)
        external
        view
        returns (
            address tokenAsset,
            uint8 decimalsAsset,
            address tokenQuote,
            uint8 decimalsQuote
        );

    /// @dev Structs in memory are returned as tuples, e.g. (foo, bar...).
    function pools(uint64 poolId)
        external
        view
        returns (
            uint128 virtualX,
            uint128 virtualY,
            uint128 liquidity,
            uint32 lastTimestamp,
            uint16 feeBasisPoints,
            uint16 priorityFeeBasisPoints,
            address controller
        );

    /**
     * @notice Amount of liquidity owned by `owner` in the pool `poolId`.
     * @param owner Address that owns the liquidity.
     * @param poolId Id of the pool to check.
     * @return liquidity Amount of liquidity.
     */
    function positions(
        address owner,
        uint64 poolId
    ) external view returns (uint128 liquidity);

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
     * @dev Amount of tokens in native token decimals that are in the virtually tracked reserves.
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
     * @return price Estimated price in wad units of `quote` tokens per `asset` token.
     * @custom:mev Vulnerable to manipulation, do not rely on this function on-chain.
     */
    function getSpotPrice(uint64 poolId)
        external
        view
        returns (uint256 price);
}

interface IPortfolioActions {
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
     * @notice Sets the `protocolFee` state value.
     * @param fee Must be within the range: 4 <= x <= 20.
     */
    function setProtocolFee(uint256 fee) external;

    /// @notice Transfers fees earned in `amount` of `token` to `REGISTRY` address.
    function claimFee(address token, uint256 amount) external;

    /**
     * @dev Increases virtual reserves and liquidity. Debits `msg.sender`.
     * @param poolId A `0` poolId is a magic variable to use `_getLastPoolId` for this allocate.
     * @param deltaLiquidity Quantity of liquidity to mint in WAD units.
     * @param maxDeltaAsset Maximum quantity of asset tokens paid in WAD units.
     * @param maxDeltaQuote Maximum quantity of quote tokens paid in WAD units.
     * @return deltaAsset Real quantity of `asset` tokens paid to pool, in native token decimals.
     * @return deltaQuote Real quantity of `quote` tokens paid to pool, in native token decimals.
     */
    function allocate(
        bool useMax,
        address recipient,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 maxDeltaAsset,
        uint128 maxDeltaQuote
    ) external payable returns (uint256 deltaAsset, uint256 deltaQuote);

    /**
     * @dev Reduces virtual reserves and liquidity. Credits `msg.sender`.
     * @param deltaLiquidity Quantity of liquidity to burn in WAD units.
     * @param minDeltaAsset Minimum quantity of asset tokens to receive in WAD units.
     * @param minDeltaQuote Minimum quantity of quote tokens to receive in WAD units.
     * @return deltaAsset Real quantity of `asset` tokens received from pool, in native token decimals.
     * @return deltaQuote Real quantity of `quote` tokens received from pool, in native token decimals.
     */
    function deallocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 minDeltaAsset,
        uint128 minDeltaQuote
    ) external payable returns (uint256 deltaAsset, uint256 deltaQuote);

    /**
     * @dev
     * Swaps in input of tokens (sellAsset == 1 = asset, sellAsset == 0 = quote)
     * for output of tokens (sellAsset == 1 = quote, sellAsset == 0 = asset).
     *
     * Fees are re-invested into the pool, increasing the value of liquidity.
     *
     * This is done via the following logic:
     * - Compute the new reserve that is being increased without the fee amount included.
     * - Check the invariant condition passes using this new reserve without the fee amount included.
     * - Update the new reserve with the fee amount included in `syncPool`.
     *
     * @param args Swap parameters, token amounts are expected to be in WAD units.
     * @return poolId Pool which had the swap happen.
     * @return input Real quantity of `input` tokens sent to pool, in native token decimals.
     * @return output Real quantity of `output` tokens sent to swapper, in native token decimals.
     */
    function swap(Order memory args)
        external
        payable
        returns (uint64 poolId, uint256 input, uint256 output);

    /**
     * @dev Creates a new pair of tokens.
     * @param asset Address of the asset token.
     * @param quote Address of the quote token.
     * @return pairId Id of the created pair.
     */
    function createPair(
        address asset,
        address quote
    ) external payable returns (uint24 pairId);

    /**
     * @param pairId Nonce of the target pair. A `0` is a magic variable to use the state variable `getPairNonce` instead.
     * @param controller An address that can change the `fee`, `priorityFee` parameters of the created pool.
     * @param priorityFee Priority fee for the pool (10,000 being 100%). This is a percentage of fees paid by the controller when swapping.
     * @param fee Fee for the pool (10,000 being 100%). This is a percentage of fees paid by the users when swapping.
     * @param volatility Expected volatility of the pool in basis points, minimum of 1 (0.01%) and maximum of 25,000 (250%).
     * @param duration Quantity of days (in units of days) until the pool "expires". Uses `type(uint16).max` as a magic variable to set `perpetual = true`.
     * @param strikePrice Terminal price of the pool once maturity is reached (expressed in the quote token), in WAD units.
     * @param price Initial price of the pool (expressed in the quote token), in WAD units.
     */
    function createPool(
        uint24 pairId,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint128 strikePrice,
        uint128 price
    ) external payable returns (uint64 poolId);

    /**
     * @notice Entry point to execute multiple function calls in one transaction.
     * Note that if one call reverts the whole transaction will revert.
     * @param data Encoded function calls in an array of bytes.
     * @return results Encoded results of each function call.
     * @custom:example
     * ```
     * // Create a new pair by calling the `multicall` function.
     * bytes[] memory data = new bytes[](1);
     * data[0] = abi.encodeCall(IPortfolioActions.createPair, (token0, token1));
     * bytes[] memory results = subject().multicall(data);
     * ```
     */
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
