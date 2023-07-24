// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
    PortfolioPool, PortfolioPair, Order
} from "../libraries/PortfolioLib.sol";

interface IPortfolioEvents {
    /// @dev Ether transfers into Portfolio via a payable function.
    event Deposit(address indexed account, uint256 amount);

    /**
     * @notice
     * Assigns an additional `amount` of `token` to Portfolio's internal accounting system.
     *
     * @dev
     * Emitted on `swap` and `allocate`.
     *
     * @param amount Quantity of token in WAD units.
     */
    event IncreaseReserveBalance(address indexed token, uint256 amount);

    /**
     * @notice
     * Unassigns `amount` of `token` from Portfolio's internal accounting system.
     *
     * @dev
     * Emitted on `swap` and `deallocate`.
     *
     * @param amount Quantity of token in WAD units.
     */
    event DecreaseReserveBalance(address indexed token, uint256 amount);

    /**
     * @notice
     * Swapping in a pool.
     *
     * @dev
     * Swaps `input` amount of `tokenIn` for `output` amount of `tokenOut` in pool with `poolId`.
     *
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
     * @notice
     * Adding liquidity to the pool.
     *
     * @dev
     * Assigns amount `deltaAsset` of `asset` and `deltaQuote` of `quote` tokens to `poolId`.
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
     * @notice
     * Changing one of the fee parameters of a pool.
     *
     * @dev
     * Emits a `0` for unchanged parameters.
     *
     * @param poolId Unique identifier for the pool that is being updated.
     * @param priorityFee Fee percentage paid by the pool controller (if any).
     * @param fee Fee percentage paid by swappers.
     */
    event ChangeParameters(
        uint64 indexed poolId, uint16 indexed priorityFee, uint16 indexed fee
    );

    /**
     * @notice
     * Adding a new pair to Portfolio's state.
     *
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
     * @notice
     * Instantiating a new pool at a desired price, with custom strategy arguments.
     *
     * @dev
     * Emitted on pool creation.
     *
     * @param poolId Unique identifier for the pool that is being created.
     * @param asset Token that is being paired.
     * @param quote Token that is being paired.
     */
    event CreatePool(
        uint64 indexed poolId,
        address indexed asset,
        address indexed quote,
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint16 feeBasisPoints,
        uint16 priorityFeeBasisPoints,
        address controller,
        address strategy
    );

    /**
     * @notice
     * Registry controller adjustment to the protocol fee charged on swaps.
     *
     * @dev
     * Fees are adjusted by the Registry's `controller()` address.
     *
     * @param prevFee Previous protocol fee portion of the swap fee.
     * @param nextFee Next protocol fee portion of the swap fee.
     */
    event UpdateProtocolFee(uint256 prevFee, uint256 nextFee);

    /**
     * @notice
     * Withdraw tokens earned from protocol fees to the Registry controller.
     *
     * @dev
     * Emitted when the REGISTRY claims protocol fees.
     *
     * @param token Token that is being claimed.
     * @param amount Amount of token claimed in native token decimals.
     */
    event ClaimFees(address indexed token, uint256 amount);
}

interface IPortfolioAccounting {
    /**
     * @notice
     * Portfolio's balance of a `token`.
     *
     * @dev
     * Sum of all pools' balances which have `token` in the pool's pair.
     *
     * @return Global balance held in WAD units.
     */
    function getReserve(address token) external view returns (uint256);

    /**
     * @notice
     * Portfolio's solvency of a `token`.
     *
     * @dev
     * Critical system invariant. Must always return greater than or equal to zero.
     *
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
     *
     * @return Net balance held in native token decimals.
     */
    function getNetBalance(address token) external view returns (int256);
}

interface IPortfolioState {
    /// @notice Current semantic version of the Portfolio smart contract.
    function VERSION() external pure returns (string memory);

    /// @notice Wrapped Ether address initialized on creating the Portfolio.
    function WETH() external view returns (address);

    /// @notice Contract for storing canonical Portfolio deployments.
    function REGISTRY() external view returns (address);

    /// @notice Contract for rendering position tokens.
    function POSITION_RENDERER() external view returns (address);

    /// @notice Default strategy contract used in pool creation.
    function DEFAULT_STRATEGY() external view returns (address);

    /// @notice Proportion of swap fee allocated to the Registry controller.
    function protocolFee() external view returns (uint256);

    /// @notice Incremented when a new pair of tokens is made and stored in the `pairs` mapping.
    function getPairNonce() external view returns (uint24);

    /// @notice Incremented when a pool is created.
    function getPoolNonce(uint24 pairNonce) external view returns (uint32);

    /**
     * @notice
     * Get the id of the stored pair of two tokens, if it exists.
     *
     * @dev
     * Reverse lookup to find the `pairId` of a given `asset` and `quote`.
     *
     * note
     * Order matters! There can be two pairs for every two tokens.
     */
    function getPairId(
        address asset,
        address quote
    ) external view returns (uint24 pairId);

    /// @dev Tracks the amount of protocol fees collected for a given `token`.
    function protocolFees(address token) external view returns (uint256);

    /// @dev Data structure of the state that holds token pair information. All immutable.
    function pairs(uint24 pairId)
        external
        view
        returns (
            address tokenAsset,
            uint8 decimalsAsset,
            address tokenQuote,
            uint8 decimalsQuote
        );

    /// @dev Data structure of the state of pools. Only controller is immutable.
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
            address controller,
            address strategy
        );
}

interface IPortfolioStrategy {
    /**
     * @notice
     * Get amount of tokens out in a swap given amount of tokens in.
     *
     * @dev
     * Computes an amount out of tokens given an `amountIn`.
     *
     * @custom:warning
     * This function returns a value that makes it vulnerable to manipulation onchain.
     * Do not rely on the function of this output for any critical logic onchain.
     * Use this functions offchain to approximate the output amount of a swap.
     * This uses approximated math functions, which can lead to error and thus
     * produce swap orders that are mispriced.
     *
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
     * @notice
     * Get the spot price of the pool's `asset` token in terms of the `quote` token.
     *
     * @dev
     * Approximates the spot price using approximated math functions.
     * Returns a price in WAD units, not native decimals. The result must be scaled.
     * todo: Maybe scale the result to native decimals in quote tokens?
     *
     * @custom:mev
     * Vulnerable to manipulation, do not use this inside write functions to avoid
     * read re-entrancy attacks.
     *
     * @return price Estimated price in WAD units of `quote` tokens per `asset` token.
     */
    function getSpotPrice(uint64 poolId)
        external
        view
        returns (uint256 price);

    /**
     * @notice
     * Gets the maximum swap input and output amounts for a given `poolId`.
     *
     * @dev
     * The maximum input amount is the amount of `asset` tokens that can be sold.
     * The maximum output amount is the amount of `quote` tokens that can be bought.
     *
     * note
     * The maximum input and output amounts should most likely not be used in a swap.
     *
     */
    function getMaxOrder(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external view returns (Order memory);

    /**
     * @notice
     * Gets the invariants pre- and post- swap for a given swap order.
     *
     * @dev
     * The pre- and post- swap invariants are used to check if the swap is valid.
     * The post- invariant must grow by at least 1 wei.
     *
     * @param order Swap order arguments including input and output amounts.
     * @param timestamp Expected block.timestamp of execution. Overestimate to overestimate the swap.
     * @param swapper Address that will execute the swap, affects the swap fee paid.
     */
    function simulateSwap(
        Order memory order,
        uint256 timestamp,
        address swapper
    )
        external
        view
        returns (bool success, int256 prevInvariant, int256 postInvariant);

    /**
     * @notice
     * Get the invariant result of a pool with its current state.
     *
     * @dev
     * Use this invariant value as a sanity check but not as a pre-invariant value
     * for swaps.
     *
     * @return invariant Signed invariant value of the pool.
     */
    function getInvariant(uint64 poolId) external view returns (int256);
}

interface IPortfolioView {
    /**
     * @notice
     * Get the external strategy contract a pool relies on to verify swaps and pool creation.
     *
     * @dev
     * Strategy contracts implement the `beforeSwap` and `afterCreate` state changing hooks.
     * Along with the `verifySwap` and `verifyPool` hooks that handle critical validations.
     *
     * @return strategy Address of the external strategy contract.
     */
    function getStrategy(uint64 poolId) external view returns (address);

    /**
     * @notice
     * Get amount of tokens that underly a given amount of liquidity.
     *
     * @dev
     * Computes the amount of tokens needed to allocate a given amount of liquidity, rounding up.
     * Computes the amount of tokens deallocated from a given amount of liquidity, rounding down.
     *
     * note
     * Rounding direction is important because it affects the inflows and outflows of tokens.
     * The rounding direction is chosen to favor the pool, not the user. This prevents
     * users from taking advantage of the rounding to extract tokens from the pool.
     *
     * @param deltaLiquidity Quantity of liquidity to allocate (+) or deallocate (-),  in WAD.
     * @return deltaAsset Real `asset` tokens underlying `deltaLiquidity`, denominated in WAD.
     * @return deltaQuote Real `quote` tokens underlying `deltaLiquidity`, denominated in WAD.
     */
    function getLiquidityDeltas(
        uint64 poolId,
        int128 deltaLiquidity
    ) external view returns (uint128 deltaAsset, uint128 deltaQuote);

    /**
     * @notice
     * Get the amount of liquidity that can be allocated with a given amount of tokens.
     *
     * @dev
     * Computes the maximum amount of liquidity that can be allocated given an amount of asset and quote tokens.
     * Must be used offchain, or else the pool's reserves can be manipulated to
     * take advantage of this function's reliance on the reserves.
     * This function can be used in conjuction with `getPoolLiquidityDeltas` to compute the maximum `allocate()` for a user.
     *
     * @param deltaAsset Desired amount of `asset` to allocate, denominated in WAD.
     * @param deltaQuote Desired amount of `quote` to allocate, denominated in WAD.
     * @return deltaLiquidity Maximum amount of liquidity that can be minted, denominated in WAD.
     */
    function getMaxLiquidity(
        uint64 poolId,
        uint256 deltaAsset,
        uint256 deltaQuote
    ) external view returns (uint128 deltaLiquidity);

    /**
     * @notice
     * Get reserves of a pool.
     *
     * @dev
     * Computes the real amount of asset and quote tokens in a pool's reserves by getting
     * the amounts removed from the pool if all liquidity was deallocated.
     *
     * note All reserves for all tokens are in WAD units.
     * Scale the output by the token's decimals to get the real amount of tokens in the pool.
     *
     * @return deltaAsset Real `asset` tokens removed from pool, denominated in WAD.
     * @return deltaQuote Real `quote` tokens removed from pool, denominated in WAD.
     */
    function getPoolReserves(uint64 poolId)
        external
        view
        returns (uint256 deltaAsset, uint256 deltaQuote);
}

interface IPortfolioRegistryActions {
    /// @notice Transfers fees earned in `amount` of `token` to `REGISTRY` address.
    function claimFee(address token, uint256 amount) external;

    /**
     * @notice
     * Sets the `protocolFee`.
     *
     * @dev
     * Proportion of the swap fee that can be withdrawn by the REGISTRY contract.
     *
     * @param fee Must be within the range: 4 <= x <= 20.
     */
    function setProtocolFee(uint256 fee) external;
}

interface IPortfolioActions is IPortfolioRegistryActions {
    /**
     * @notice
     * Updates the priority fee and/or fee of a pool.
     *
     * @dev
     * The sender must be the pool controller.
     * Leaving a function parameter as '0' will not change the pool parameter.
     *
     * @param priorityFee New priority fee of the pool in basis points (1 = 0.01%).
     * @param fee New fee of the pool in basis points (1 = 0.01%).
     */
    function changeParameters(
        uint64 poolId,
        uint16 priorityFee,
        uint16 fee
    ) external;

    /**
     * @notice
     * Add liquidity to a pool.
     *
     * @dev
     * Increases virtual reserves and liquidity. Debits `msg.sender`.
     *
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
     * @notice
     * Remove liquidity from a pool.
     *
     * @dev
     * Reduces virtual reserves and liquidity. Credits `msg.sender`.
     *
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
     * @notice
     * Swap tokens of a pool.
     *
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
     * @notice
     * Create a pair to use in pool creation.
     *
     * @dev
     * Stores the pair's token data in a single storage slot to save on gas.
     *
     * @param asset Address of the asset token.
     * @param quote Address of the quote token.
     * @return pairId Id of the created pair.
     */
    function createPair(
        address asset,
        address quote
    ) external payable returns (uint24 pairId);

    /**
     * @notice
     * Instantiate a pool at a desired price with custom fees and arguments.
     *
     * @param pairId Nonce of the target pair. A `0` is a magic variable to use the state variable `getPairNonce` instead.
     */
    function createPool(
        uint24 pairId,
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint16 feeBasisPoints,
        uint16 priorityFeeBasisPoints,
        address controller,
        address strategy,
        bytes calldata strategyArgs
    ) external payable returns (uint64 poolId);

    /**
     * @notice
     * Execute multiple actions on Portfolio in a single call.
     *
     * @dev
     * Entry point to atomically execute multiple actions and
     * settle the credit and debits at the end.
     *
     * note
     * If one call reverts the whole transaction will revert.
     *
     * @custom:example
     * ```
     * // Create a new pair by calling the `multicall` function.
     * bytes[] memory data = new bytes[](1);
     * data[0] = abi.encodeCall(IPortfolioActions.createPair, (token0, token1));
     * bytes[] memory results = subject().multicall(data);
     * ```
     *
     * @param data Abi-encoded function calls in an array of bytes.
     * @return results Abi-encoded results of each function call.
     */
    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
}

/**
 * @notice
 * Returns Portfolio's key data structures as the types they are stored in.
 */
interface IPortfolioStruct {
    function pairs(uint24 pairId)
        external
        view
        returns (PortfolioPair memory);

    function pools(uint64 poolId)
        external
        view
        returns (PortfolioPool memory);
}

/**
 * @notice
 * Portfolio state, helpers, and strategy information.
 */
interface IPortfolioGetters is
    IPortfolioAccounting,
    IPortfolioState,
    IPortfolioStrategy,
    IPortfolioView
{ }

/**
 * @notice
 * Portfolio events, getters, and actions.
 */
interface IPortfolio is
    IPortfolioActions,
    IPortfolioEvents,
    IPortfolioGetters
{ }
