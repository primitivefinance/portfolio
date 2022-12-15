// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/utils/SafeTransferLib.sol";

import "./OS.sol";
import "./CPU.sol" as CPU;
import "./Clock.sol";
import "./Assembly.sol" as asm;
import "./EnigmaTypes.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IHyper.sol";
import "./interfaces/IERC20.sol";
import "./libraries/HyperSwapLib.sol";

/**
 * @notice Syncs a pool's liquidity and last updated timestamp.
 */
function changePoolLiquidity(HyperPool storage self, uint256 timestamp, int128 liquidityDelta) {
    self.blockTimestamp = timestamp;
    self.liquidity = asm.toUint128(asm.__computeDelta(self.liquidity, liquidityDelta));
}

/**
 * @notice Syncs a position's liquidity, last updated timestamp, fees earned, and fee growth.
 */
function changePositionLiquidity(
    HyperPosition storage self,
    HyperPool storage pool,
    uint256 timestamp,
    int128 liquidityDelta
) returns (uint256 feeAssetEarned, uint256 feeQuoteEarned) {
    self.blockTimestamp = timestamp;
    self.totalLiquidity = asm.toUint128(asm.__computeDelta(self.totalLiquidity, liquidityDelta));

    (uint256 liquidity, uint256 feeGrowthAsset, uint256 feeGrowthQuote) = (
        pool.liquidity,
        pool.feeGrowthGlobalAsset,
        pool.feeGrowthGlobalQuote
    );

    (feeAssetEarned, feeQuoteEarned) = self.syncPositionFees(liquidity, feeGrowthAsset, feeGrowthQuote);
}

function syncPositionFees(
    HyperPosition storage self,
    uint liquidity,
    uint feeGrowthAsset,
    uint feeGrowthQuote
) returns (uint feeAssetEarned, uint feeQuoteEarned) {
    uint checkpointAsset = asm.__computeCheckpointDistance(feeGrowthAsset, self.feeGrowthAssetLast);
    uint checkpointQuote = asm.__computeCheckpointDistance(feeGrowthQuote, self.feeGrowthQuoteLast);

    feeAssetEarned = FixedPointMathLib.mulWadDown(feeGrowthAsset - self.feeGrowthAssetLast, liquidity);
    feeQuoteEarned = FixedPointMathLib.mulWadDown(feeGrowthQuote - self.feeGrowthQuoteLast, liquidity);

    self.feeGrowthAssetLast = feeGrowthAsset;
    self.feeGrowthQuoteLast = feeGrowthQuote;

    self.tokensOwedAsset += feeAssetEarned;
    self.tokensOwedQuote += feeQuoteEarned;
}

function exists(mapping(uint48 => HyperPool) storage pools, uint48 poolId) view returns (bool) {
    return pools[poolId].blockTimestamp != 0;
}

using {changePoolLiquidity} for HyperPool;
using {exists} for mapping(uint48 => HyperPool);
using {changePositionLiquidity, syncPositionFees} for HyperPosition;

/// @title Enigma Virtual Machine.
/// @notice Stores the state of the Enigma with functions to change state.
/// @dev Implements low-level internal virtual functions, re-entrancy guard and state.
contract Hyper is IHyper {
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    using HyperSwapLib for HyperSwapLib.Expiring;

    // ===== Account ===== //
    AccountSystem public __account__;

    // ===== Constants ===== //
    string public constant VERSION = "prototype-v0.0.1";
    /// @dev Canonical Wrapped Ether contract.
    address public immutable WETH;
    /// @dev Distance between the location of prices on the price grid, so distance between price.
    int24 public constant TICK_SIZE = 256;
    /// @dev Minimum amount of decimals supported for ERC20 tokens.
    uint8 public constant MIN_DECIMALS = 6;
    /// @dev Maximum amount of decimals supported for ERC20 tokens.
    uint8 public constant MAX_DECIMALS = 18;
    /// @dev Amount of seconds of available time to swap past maturity of a pool.
    uint256 public constant BUFFER = 300;
    /// @dev Constant amount of 1 ether. All liquidity values have 18 decimals.
    uint256 public constant PRECISION = 1e18;
    /// @dev Constant amount of basis points. All percentage values are integers in basis points.
    uint256 public constant PERCENTAGE = 1e4;
    /// @dev Minimum pool fee. 0.01%.
    uint256 public constant MIN_POOL_FEE = 1;
    /// @dev Maximum pool fee. 10.00%.
    uint256 public constant MAX_POOL_FEE = 1e3;
    /// @dev Amount of seconds that an epoch lasts.
    uint256 public constant EPOCH_INTERVAL = 300;
    /// @dev Used to compute the amount of liquidity to burn on creating a pool.
    uint256 public constant MIN_LIQUIDITY_FACTOR = 6;
    /// @dev Policy for the "wait" time in seconds between adding and removing liquidity.
    uint256 public constant JUST_IN_TIME_LIQUIDITY_POLICY = 4;

    // ===== State ===== //
    /// @dev Reentrancy guard initialized to state
    uint256 private locked = 1;
    /// @dev A value incremented by one on pair creation. Reduces calldata.
    uint256 public getPairNonce;
    /// @dev A value incremented by one on curve creation. Reduces calldata.
    uint256 public getCurveNonce;
    /// @dev Pool id -> Pair of a Pool.
    mapping(uint16 => Pair) public pairs;
    /// @dev Pool id -> Epoch Data Structure.
    mapping(uint48 => Epoch) public epochs;
    /// @dev Pool id -> Curve Data Structure stores parameters.
    mapping(uint32 => Curve) public curves;
    /// @dev Pool id -> HyperPool Data Structure.
    mapping(uint48 => HyperPool) public pools;
    /// @dev Raw curve parameters packed into bytes32 mapped onto a Curve id when it was deployed.
    mapping(bytes32 => uint32) public getCurveId;
    /// @dev Base Token -> Quote Token -> Pair id
    mapping(address => mapping(address => uint16)) public getPairId;
    /// @dev User -> Position Id -> Liquidity Position.
    mapping(address => mapping(uint48 => HyperPosition)) public positions;
    /// @dev Amount of rewards globally tracked per epoch.
    mapping(uint48 => mapping(uint256 => uint256)) internal epochRewardGrowthGlobal;
    /// @dev Individual rewards of a position.
    mapping(uint48 => mapping(int24 => mapping(uint256 => uint256))) internal epochRewardGrowthOutside;

    // ===== Reentrancy ===== //
    modifier lock() {
        if (locked != 1) revert LockedError();

        locked = 2;
        _;
        locked = 1;
    }

    modifier settle() {
        _;
        __account__.prepare();
        __account__.multiSettle(__dangerousTransferFrom__, address(this));

        if (!__account__.settled) revert InvalidSettlement();
    }

    // ===== Constructor ===== //
    constructor(address weth) {
        WETH = weth;
        __account__.settled = true;
    }

    // ===== Getters ===== //

    function getReserves(address token) public view returns (uint) {
        return __account__.reserves[token];
    }

    function getBalances(address owner, address token) public view returns (uint) {
        return __account__.balances[owner][token];
    }

    function getLiquidityMinted(
        uint48 poolId,
        uint deltaAsset,
        uint deltaQuote
    ) public view returns (uint deltaLiquidity, uint optimizedAsset, uint optimizedQuote) {
        (uint amount0, uint amount1) = _getAmounts(poolId);
        uint liquidity0 = deltaAsset.divWadDown(amount0); // If `deltaAsset` is twice as much as assets per liquidity in pool, we can mint 2 liquidity.
        uint liquidity1 = deltaQuote.divWadDown(amount1); // If this liquidity amount is lower, it means we don't have enough tokens to mint the above amount.
        deltaLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        if (deltaLiquidity == liquidity0) {
            optimizedAsset = deltaAsset;
            optimizedQuote = amount1.mulWadDown(deltaLiquidity); // Gets optimal amount of other token based on liquidity.
        } else {
            optimizedAsset = amount0.mulWadDown(deltaLiquidity);
            optimizedQuote = deltaQuote;
        }
    }

    function _maxLiquidityMinted() public view returns (uint maxLiquidity) {
        // todo: compute based on price that is updated over time
    }

    function _getAmounts(uint48 poolId) public view returns (uint256 deltaAsset, uint256 deltaQuote) {
        uint256 timestamp = _blockTimestamp();

        // Compute amounts of tokens for the real reserves.
        Curve memory curve = curves[uint32(poolId)];
        HyperPool storage pool = pools[poolId];
        HyperSwapLib.Expiring memory info = HyperSwapLib.Expiring({
            strike: curve.strike,
            sigma: curve.sigma,
            tau: curve.maturity - timestamp
        });

        deltaAsset = info.computeR2WithPrice(pool.lastPrice);
        deltaQuote = info.computeR1WithR2(deltaAsset, pool.lastPrice, 0);
    }

    // TODO: fix this with non-delta liquidity amount
    /** @dev Computes amount of phsyical reserves entitled to amount of liquidity in a pool. */
    function getPhysicalReserves(
        uint48 poolId,
        uint256 deltaLiquidity
    ) public view returns (uint256 deltaAsset, uint256 deltaQuote) {
        (deltaAsset, deltaQuote) = _getAmounts(poolId);

        deltaQuote = deltaQuote.mulWadDown(deltaLiquidity);
        deltaAsset = deltaAsset.mulWadDown(deltaLiquidity);
    }

    function getSecondsSincePositionUpdate(
        address account,
        uint48 poolId
    ) public view returns (uint256 distance, uint256 timestamp) {
        uint256 previous = positions[account][poolId].blockTimestamp;
        timestamp = _blockTimestamp();
        distance = timestamp - previous;
    }

    // ===== CPU Entrypoint ===== //

    /// @notice Main touchpoint for receiving calls.
    /// @dev Critical: data must be encoded properly to be processed.
    /// @custom:security Critical. Guarded against re-entrancy. This is like the bank vault door.
    /// @custom:mev Higher level security checks must be implemented by calling contract.
    fallback() external payable lock settle {
        CPU.__startProcess__(_process);
    }

    receive() external payable {
        if (msg.sender != WETH) revert();
    }

    function __dangerousTransferFrom__(address token, address to, uint amount) private {
        SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, to, amount);
    }

    // ===== Actions ===== //

    /// @inheritdoc IHyperActions
    function syncPool(uint48 poolId) external override returns (uint128 blockTimestamp) {
        _syncPoolPrice(poolId);
    }

    /// @inheritdoc IHyperActions
    function allocate(uint48 poolId, uint amount) external lock settle returns (uint deltaAsset, uint deltaQuote) {
        bool useMax = amount == type(uint256).max; // magic variable.
        uint128 input = asm.toUint128(useMax ? type(uint128).max : amount);
        (deltaAsset, deltaQuote) = _allocate(useMax ? 1 : 0, poolId, input);
    }

    /// @inheritdoc IHyperActions
    function unallocate(uint48 poolId, uint amount) external lock settle returns (uint deltaAsset, uint deltaQuote) {
        bool useMax = amount == type(uint256).max; // magic variable.
        uint128 input = asm.toUint128(useMax ? type(uint128).max : amount);
        (deltaAsset, deltaQuote) = _unallocate(useMax ? 1 : 0, poolId, uint16(poolId >> 32), input);
    }

    /// @inheritdoc IHyperActions
    function stake(uint48 poolId) external lock settle {
        _stake(poolId);
    }

    /// @inheritdoc IHyperActions
    function unstake(uint48 poolId) external lock settle {
        _unstake(poolId);
    }

    /// @inheritdoc IHyperActions
    function swap(
        uint48 poolId,
        bool sellAsset,
        uint amount,
        uint limit
    ) external lock settle returns (uint output, uint remainder) {
        bool useMax = amount == type(uint256).max; // magic variable.
        uint128 input = useMax ? type(uint128).max : asm.toUint128(amount);
        if (limit == type(uint256).max) limit = type(uint128).max;
        Order memory args = Order({
            useMax: useMax ? 1 : 0,
            poolId: poolId,
            input: input,
            limit: asm.toUint128(limit),
            direction: sellAsset ? 0 : 1
        });
        (, remainder, , output) = _swapExactIn(args);
    }

    /// @inheritdoc IHyperActions
    function draw(address token, uint256 amount, address to) external lock settle {
        if (__account__.balances[msg.sender][token] < amount) revert DrawBalance(); // Only withdraw if user has enough.
        _applyDebit(token, amount);

        if (token == WETH) __dangerousUnwrapEther__(WETH, to, amount);
        else SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    /// @inheritdoc IHyperActions
    function fund(address token, uint256 amount) external payable override lock settle {
        _applyCredit(token, amount);

        if (token == WETH) __wrapEther__(WETH);
        else __dangerousTransferFrom__(token, address(this), amount);
    }

    // ===== Internal ===== //

    /// @dev Overridable in tests.
    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }

    /// @dev Overridable in tests.
    /// @custom:mev Prevents liquidity from being added and immediately removed until policy time (seconds) has elapsed.
    function _liquidityPolicy() internal view virtual returns (uint256) {
        return JUST_IN_TIME_LIQUIDITY_POLICY;
    }

    // ===== Effects ===== //

    /**
     * @notice Allocates liquidity to a pool.
     *
     * @custom:reverts If attempting to add zero liquidity.
     * @custom:reverts If attempting to add liquidity to a pool that has not been created.
     */
    function _allocate(
        uint8 useMax,
        uint48 poolId,
        uint128 deltaLiquidity
    ) internal returns (uint256 deltaAsset, uint256 deltaQuote) {
        if (deltaLiquidity == 0) revert ZeroLiquidityError();
        if (!pools.exists(poolId)) revert NonExistentPool(poolId);
        _syncPoolPrice(poolId);

        Pair memory pair = pairs[uint16(poolId >> 32)];
        if (useMax == 1) {
            uint liquidity;
            // todo: consider using internal balances too, or in place of
            (liquidity, deltaAsset, deltaQuote) = getLiquidityMinted(
                poolId,
                __balanceOf__(pair.tokenAsset, msg.sender),
                __balanceOf__(pair.tokenQuote, msg.sender)
            );

            deltaLiquidity = asm.toUint128(liquidity);
        } else {
            // todo: investigate how to fix this, leads to expected reserves being less in useMax case
            (deltaAsset, deltaQuote) = getPhysicalReserves(poolId, deltaLiquidity);
        }

        _increaseLiquidity(poolId, deltaAsset, deltaQuote, deltaLiquidity);
    }

    /**
     * @notice Increases liquidity in position, which increases liquidity in pool, which increases reserve balances.
     */
    function _increaseLiquidity(
        uint48 poolId,
        uint256 deltaAsset,
        uint256 deltaQuote,
        uint128 deltaLiquidity
    ) internal {
        uint timestamp = _blockTimestamp();
        HyperPool storage pool = pools[poolId];
        pool.changePoolLiquidity(timestamp, int128(deltaLiquidity));

        HyperPosition storage pos = positions[msg.sender][poolId];
        (uint feeAsset, uint feeQuote) = pos.changePositionLiquidity(pool, timestamp, int128(deltaLiquidity));

        uint16 pairId = uint16(poolId >> 32);
        Pair memory pair = pairs[pairId];
        // note: Global reserves are used at the end of instruction processing to settle transactions.
        _increaseReserves(pair.tokenAsset, deltaAsset);
        _increaseReserves(pair.tokenQuote, deltaQuote);

        emit FeesEarned(msg.sender, poolId, feeAsset, pair.tokenAsset, feeQuote, pair.tokenQuote);
        emit IncreasePosition(msg.sender, poolId, deltaLiquidity);
        emit Allocate(poolId, pair.tokenAsset, pair.tokenQuote, deltaAsset, deltaQuote, deltaLiquidity);
    }

    function _unallocate(
        uint8 useMax,
        uint48 poolId,
        uint16 pairId,
        uint128 deltaLiquidity
    ) internal returns (uint deltaAsset, uint deltaQuote) {
        if (deltaLiquidity == 0) revert ZeroLiquidityError();
        if (!pools.exists(poolId)) revert NonExistentPool(poolId);
        if (useMax == 1) deltaLiquidity = asm.toUint128(positions[msg.sender][poolId].totalLiquidity);

        // note: Global reserves are referenced at end of processing to determine amounts of token to transfer.
        (deltaAsset, deltaQuote) = getPhysicalReserves(poolId, deltaLiquidity); // computed before changing liquidity

        // Compute amounts of tokens for the real reserves.
        HyperPool storage pool = pools[poolId];
        changePoolLiquidity(pool, _blockTimestamp(), -int128(deltaLiquidity));
        (uint feeAsset, uint feeQuote) = _decreasePosition(poolId, deltaLiquidity);

        Pair memory pair = pairs[pairId];
        _decreaseReserves(pair.tokenAsset, deltaAsset);
        _decreaseReserves(pair.tokenQuote, deltaQuote);

        emit Unallocate(poolId, pair.tokenAsset, pair.tokenQuote, deltaQuote, deltaAsset, deltaLiquidity);
    }

    /// @dev Syncs a position's fee growth, fees earned, liquidity, and timestamp.
    function _decreasePosition(uint48 poolId, uint256 deltaLiquidity) internal returns (uint feeAsset, uint feeQuote) {
        (uint256 distance, uint256 timestamp) = getSecondsSincePositionUpdate(msg.sender, poolId);
        if (_liquidityPolicy() > distance) revert JitLiquidity(distance);

        HyperPool storage pool = pools[poolId];
        HyperPosition storage pos = positions[msg.sender][poolId];

        (feeAsset, feeQuote) = pos.changePositionLiquidity(pool, _blockTimestamp(), -int128(int(deltaLiquidity)));

        uint16 pairId = uint16(poolId >> 32);
        Pair memory pair = pairs[pairId];
        emit FeesEarned(msg.sender, poolId, feeAsset, pair.tokenAsset, feeQuote, pair.tokenQuote);
        emit DecreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    /// @dev Reverts if liquidity was allocated within time elapsed in seconds returned by `_liquidityPolicy`.
    /// @custom:security High. Must be used in place of `_decreasePosition` in most scenarios.
    /* function _decreasePositionCheckJit(
        uint48 poolId,
        uint256 deltaLiquidity
    ) internal returns (uint feeAsset, uint feeQuote) {
        (feeAsset, feeQuote) = _decreasePosition(poolId, deltaLiquidity);
    } */

    function _stake(uint48 poolId) internal {
        if (!pools.exists(poolId)) revert NonExistentPool(poolId);

        HyperPosition storage pos = positions[msg.sender][poolId];
        if (pos.stakeEpochId != 0) revert PositionStakedError(poolId);
        if (pos.totalLiquidity == 0) revert PositionZeroLiquidityError(poolId);

        HyperPool storage pool = pools[poolId];
        pool.epochStakedLiquidityDelta += int256(pos.totalLiquidity);

        Epoch storage epoch = epochs[poolId];
        pos.stakeEpochId = epoch.id + 1;

        // note: do we need to update position blockTimestamp?

        // emit Stake Position
    }

    function _unstake(uint48 poolId) internal {
        _syncPoolPrice(poolId); // Reverts if pool does not exist.

        HyperPosition storage pos = positions[msg.sender][poolId];
        if (pos.stakeEpochId == 0 || pos.unstakeEpochId != 0) revert PositionNotStakedError(poolId);

        HyperPool storage pool = pools[poolId];
        pool.epochStakedLiquidityDelta -= int256(pos.totalLiquidity);

        Epoch storage epoch = epochs[poolId];
        pos.unstakeEpochId = epoch.id + 1;

        // note: do we need to update position blockTimestamp?

        // emit Unstake Position
    }

    // ===== Swaps ===== //

    /**
     * @notice Computes the price of the pool, which changes over time. Syncs pool to new price if enough time has passed.
     *
     * @custom:reverts If pool does not exist.
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _syncPoolPrice(uint48 poolId) internal returns (uint256 price, int24 tick) {
        if (!pools.exists(poolId)) revert NonExistentPool(poolId);

        HyperPool storage pool = pools[poolId];
        Curve memory curve = curves[uint32(poolId)];

        if (_blockTimestamp() <= curve.maturity) {
            uint256 tau;
            if (curve.maturity > pool.blockTimestamp) tau = curve.maturity - pool.blockTimestamp; // Keeps tau at zero if pool expired.
            uint256 elapsed = _blockTimestamp() - pool.blockTimestamp;
            HyperSwapLib.Expiring memory expiring = HyperSwapLib.Expiring(curve.strike, curve.sigma, tau);

            price = expiring.computePriceWithChangeInTau(pool.lastPrice, elapsed);
            tick = HyperSwapLib.computeTickWithPrice(price);
            int256 hi = int256(pool.lastTick + TICK_SIZE);
            int256 lo = int256(pool.lastTick - TICK_SIZE);
            tick = asm.isBetween(int256(tick), lo, hi) ? tick : pool.lastTick;

            _syncPool(poolId, tick, price, pool.liquidity, pool.feeGrowthGlobalAsset, pool.feeGrowthGlobalQuote);
        }
    }

    SwapState state;

    event log(string);

    /**
     * @dev Swaps exact input of tokens for an output of tokens in the specified direction.
     *
     * @custom:reverts If input swap amount is zero.
     * @custom:reverts If pool is not initialized with a price.
     * @custom:mev Must have price limit to avoid losses from flash loan price manipulations.
     */
    function _swapExactIn(
        Order memory args
    ) internal returns (uint48 poolId, uint256 remainder, uint256 input, uint256 output) {
        if (args.input == 0) revert ZeroInput();
        if (!pools.exists(args.poolId)) revert NonExistentPool(args.poolId);

        state.sell = args.direction == 0; // args.direction == 0 ? Swap asset for quote : Swap quote for asset.

        // Pair is used to update global reserves and check msg.sender balance.
        Pair memory pair = pairs[uint16(args.poolId >> 32)];
        // Pool is used to fetch information and eventually have its state updated.
        HyperPool storage pool = pools[args.poolId];

        state.feeGrowthGlobal = state.sell ? pool.feeGrowthGlobalAsset : pool.feeGrowthGlobalQuote;

        // Get the variables for first iteration of the swap.
        Iteration memory swap;
        {
            // Writes the pool after computing its updated price with respect to time elapsed since last update.
            (uint256 price, int24 tick) = _syncPoolPrice(args.poolId);
            // Expect the caller to exhaust their entire balance of the input token.
            remainder = args.useMax == 1
                ? __balanceOf__(state.sell ? pair.tokenAsset : pair.tokenQuote, msg.sender)
                : args.input;
            // Begin the iteration at the live price & tick, using the total swap input amount as the remainder to fill.
            swap = Iteration({
                price: price,
                tick: tick,
                feeAmount: 0,
                remainder: remainder,
                liquidity: pool.liquidity,
                input: 0,
                output: 0
            });
        }

        // Store the pool transiently, then delete after the swap.
        HyperSwapLib.Expiring memory expiring;
        {
            // Curve stores the parameters of the trading function.
            Curve memory curve = curves[uint32(args.poolId)];
            if (_blockTimestamp() > curve.maturity) revert PoolExpiredError(); // todo: add buffer

            expiring = HyperSwapLib.Expiring({
                strike: curve.strike,
                sigma: curve.sigma,
                tau: curve.maturity - _blockTimestamp()
            });

            // Fetch the correct gamma to calculate the fees after pool synced.
            state.gamma = msg.sender == pool.prioritySwapper ? curve.priorityGamma : curve.gamma;
        }

        // =====-- Effects =====-- //
        uint256 liveIndependent;
        uint256 nextIndependent;
        uint256 liveDependent;
        uint256 nextDependent;

        {
            // Input swap amount for this step.
            uint256 delta;

            // Virtual reserves.
            // Compute them conditionally based on direction in arguments.
            if (state.sell) {
                liveIndependent = expiring.computeR2WithPrice(swap.price);
                liveDependent = expiring.computeR1WithPrice(swap.price);
            } else {
                liveIndependent = expiring.computeR1WithPrice(swap.price);
                liveDependent = expiring.computeR2WithPrice(swap.price);
            }

            // todo: get the next tick with active liquidity.

            // Get the max amount that can be filled for a max distance swap.
            uint256 maxInput;
            if (state.sell) {
                maxInput = (PRECISION - liveIndependent).mulWadDown(swap.liquidity); // There can be maximum 1:1 ratio between assets and liqudiity.
            } else {
                maxInput = (expiring.strike - liveIndependent).mulWadDown(swap.liquidity); // There can be maximum strike:1 liquidity ratio between quote and liquidity.
            }

            // Calculate the amount of fees paid at this tick.
            swap.feeAmount = ((swap.remainder >= maxInput ? maxInput : swap.remainder) * (1e4 - state.gamma)) / 10_000;
            state.feeGrowthGlobal = FixedPointMathLib.divWadDown(swap.feeAmount, swap.liquidity);

            // If max tokens are being swapped in...
            if (swap.remainder >= maxInput) {
                delta = maxInput - swap.feeAmount;
                swap.remainder -= delta + swap.feeAmount; // Reduce the remainder of the order to fill.
                nextIndependent = liveIndependent + delta.divWadDown(swap.liquidity);
            } else {
                // Reaching this block will fill the order. Set the swap input
                delta = swap.remainder - swap.feeAmount;
                nextIndependent = liveIndependent + delta.divWadDown(swap.liquidity);

                delta = swap.remainder; // the swap input should increment the non-fee applied amount
                swap.remainder = 0; // Reduce the remainder to zero, as the order has been filled.
            }

            // Compute the output of the swap by computing the difference between the dependent reserves.
            if (state.sell)
                nextDependent = expiring.computeR1WithR2(nextIndependent, 0, 0); // note: price variable not used here! add invariant too
            else nextDependent = expiring.computeR2WithR1(nextIndependent, 0, 0); // note: price variable not used here! add invariant too

            swap.input += delta; // Add to the total input of the swap.
            swap.output += liveDependent - nextDependent;
        }

        {
            int256 liveInvariant;
            int256 nextInvariant;
            uint256 nextPrice;
            if (state.sell) {
                liveInvariant = Invariant.invariant(
                    liveDependent,
                    liveIndependent,
                    expiring.strike,
                    expiring.sigma,
                    expiring.tau
                );
                nextInvariant = Invariant.invariant(
                    nextDependent,
                    nextIndependent,
                    expiring.strike,
                    expiring.sigma,
                    expiring.tau
                );
                nextPrice = HyperSwapLib.computePriceWithR2(
                    liveIndependent,
                    expiring.strike,
                    expiring.sigma,
                    expiring.tau
                );
            } else {
                liveInvariant = Invariant.invariant(
                    liveIndependent,
                    liveDependent,
                    expiring.strike,
                    expiring.sigma,
                    expiring.tau
                );
                nextInvariant = Invariant.invariant(
                    nextIndependent,
                    nextDependent,
                    expiring.strike,
                    expiring.sigma,
                    expiring.tau
                );
                nextPrice = HyperSwapLib.computePriceWithR2(
                    liveDependent,
                    expiring.strike,
                    expiring.sigma,
                    expiring.tau
                );
            }

            swap.price = nextPrice;

            // TODO: figure out invariant stuff
            //if (nextInvariant < liveInvariant) revert InvariantError(liveInvariant, nextInvariant);
        }

        // Update Pool State Effects
        _syncPool(
            args.poolId,
            HyperSwapLib.computeTickWithPrice(swap.price),
            swap.price,
            swap.liquidity,
            state.sell ? state.feeGrowthGlobal : 0,
            state.sell ? 0 : state.feeGrowthGlobal
        );

        // Update Global Balance Effects
        // Return variables and swap event.
        //(poolId, remainder, input, output) = (args.poolId, swap.remainder, swap.input, swap.output);
        emit Swap(args.poolId, swap.input, swap.output, pair.tokenAsset, pair.tokenQuote);

        _increaseReserves(pair.tokenAsset, swap.input);
        _decreaseReserves(pair.tokenQuote, swap.output);
    }

    /**
     * @notice Syncs the specified pool to a set of slot variables
     * @dev Effects on a Pool after a successful swap order condition has been met.
     * @param poolId Identifer of pool.
     * @param tick Key of the slot specified as the now active slot to sync the pool to.
     * @param price Actual price to sync the pool to, should be around the actual slot price.
     * @param liquidity Active liquidity available in the slot to sync the pool to.
     * @return timeDelta Amount of time passed since the last update to the pool.
     */
    function _syncPool(
        uint48 poolId,
        int24 tick,
        uint256 price,
        uint256 liquidity,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote
    ) internal returns (uint256 timeDelta) {
        uint256 timestamp = _blockTimestamp();
        uint16 pairId = uint16(poolId >> 32);
        address FEE_SETTLEMENT_TOKEN = pairs[pairId].tokenAsset;

        Epoch memory readEpoch = epochs[poolId];
        HyperPool storage pool = pools[poolId];

        uint256 epochsPassed = readEpoch.getEpochsPassed(pool.blockTimestamp);

        if (epochsPassed > 0) {
            uint256 lastUpdatedEpochId = readEpoch.getLastUpdatedId(epochsPassed);
            // distribute remaining proceeds in lastUpdatedEpochId
            /* if (pool.stakedLiquidity > 0) {
                // TODO
            } */

            // save pool snapshot for lastUpdatedEpochId
            //poolSnapshots[pool.id][lastUpdatedEpochId] = getPoolSnapshot(pool);

            // update the pool's liquidity due to the transition
            pool.stakedLiquidity = asm.__computeDelta(pool.stakedLiquidity, pool.epochStakedLiquidityDelta);
            pool.borrowableLiquidity = pool.stakedLiquidity;
            pool.epochStakedLiquidityDelta = int256(0);

            // TODO: Pay user

            // check if multiple epochs have passed
            /* if (epochsPassed > 1) {
                // update proceeds per liquidity distributed for next epoch if needed
                if (pool.stakedLiquidity > 0) {
                    // TODO
                }
                // TODO: pay user
            } */
        }

        // add proceeds for time passed in the current epoch
        if (pool.stakedLiquidity > 0) {
            uint256 timePassedInCurrentEpoch = readEpoch.getTimePassedInCurrentEpoch(pool.blockTimestamp, timestamp);
            if (timePassedInCurrentEpoch > 0) {
                // TODO
            }
        }

        if (pool.lastPrice != price) pool.lastPrice = price;
        if (pool.lastTick != tick) pool.lastTick = tick;
        if (pool.liquidity != liquidity) pool.liquidity = liquidity;

        Epoch storage epoch = epochs[poolId];

        uint256 lastUpdateTime = pool.blockTimestamp;

        timeDelta = timestamp - lastUpdateTime;
        pool.blockTimestamp = timestamp;

        pool.feeGrowthGlobalAsset = asm.__computeCheckpoint(pool.feeGrowthGlobalAsset, feeGrowthGlobalAsset);
        pool.feeGrowthGlobalQuote = asm.__computeCheckpoint(pool.feeGrowthGlobalQuote, feeGrowthGlobalQuote);

        emit PoolUpdate(
            poolId,
            pool.lastPrice,
            pool.lastTick,
            pool.liquidity,
            feeGrowthGlobalAsset,
            feeGrowthGlobalQuote
        );
    }

    // ===== Initializing Pools ===== //

    /**
     * @notice Uses a pair and curve to instantiate a pool at a price.
     *
     * @custom:magic If pairId is 0, uses current pair nonce.
     * @custom:magic If curveId is 0, uses current curve nonce.
     * @custom:reverts If price is 0.
     * @custom:reverts If pool with pair and curve has already been created.
     * @custom:reverts If an expiring pool and the current timestamp is beyond the pool's maturity parameter.
     */
    function _createPool(uint48 poolId, uint16 pairId, uint32 curveId, uint128 price) internal {
        if (price == 0) revert ZeroPrice();
        if (pairId == 0) pairId = uint16(getPairNonce); // magic variable
        if (curveId == 0) curveId = uint32(getCurveNonce); // magic variable

        poolId = uint48(bytes6(abi.encodePacked(pairId, curveId)));
        if (pools.exists(poolId)) revert PoolExists();

        Curve memory curve = curves[curveId];
        uint128 timestamp = _blockTimestamp();
        if (timestamp > curve.maturity) revert PoolExpiredError();

        // Write the epoch data.
        epochs[poolId] = Epoch({id: 0, endTime: timestamp + EPOCH_INTERVAL, interval: EPOCH_INTERVAL});

        // Write the pool to state with the desired price.
        pools[poolId].lastPrice = price;
        pools[poolId].lastTick = HyperSwapLib.computeTickWithPrice(price);
        pools[poolId].blockTimestamp = timestamp;

        emit CreatePool(poolId, pairId, curveId, price);
    }

    /**
     * @notice Maps a nonce to a set of curve parameters, strike, sigma, fee, priority fee, and maturity.
     * @dev Curves are used to create pools.
     *
     * @custom:reverts If set parameters have already been used to create a curve.
     * @custom:reverts If fee parameter is outside the bounds of 0.01% to 10.00%, inclusive.
     * @custom:reverts If priority fee parameter is outside the bounds of 0.01% to fee parameter, inclusive.
     * @custom:reverts If one of the non-fee parameters is zero, but the others are not zero.
     */
    function _createCurve(
        uint24 sigma,
        uint32 maturity,
        uint16 fee,
        uint16 priorityFee,
        uint128 strike
    ) internal returns (uint32 curveId) {
        bytes32 rawCurveId = CPU.toBytes32(abi.encodePacked(sigma, maturity, fee, priorityFee, strike));

        curveId = getCurveId[rawCurveId]; // Gets the nonce of this raw curve, if it was created already.
        if (curveId != 0) revert CurveExists(curveId);

        if (!asm.isBetween(fee, MIN_POOL_FEE, MAX_POOL_FEE)) revert FeeOOB(fee);
        if (!asm.isBetween(priorityFee, MIN_POOL_FEE, fee)) revert PriorityFeeOOB(priorityFee);
        if (sigma == 0) revert MinSigma(sigma);
        if (strike == 0) revert MinStrike(strike);

        unchecked {
            curveId = uint32(++getCurveNonce); // note: Unlikely to reach this limit.
        }

        uint32 gamma = uint32(HyperSwapLib.UNIT_PERCENT - fee); // gamma = 100% - fee %.
        uint32 priorityGamma = uint32(HyperSwapLib.UNIT_PERCENT - priorityFee); // priorityGamma = 100% - priorityFee %.

        // Writes the curve to state with a reverse lookup.
        curves[curveId] = Curve({
            strike: strike,
            sigma: sigma,
            maturity: maturity,
            gamma: gamma,
            priorityGamma: priorityGamma
        });
        getCurveId[rawCurveId] = curveId;

        emit CreateCurve(curveId, strike, sigma, maturity, gamma, priorityGamma);
    }

    /**
     * @notice Maps a nonce to a pair of token addresses and their decimal places.
     * @dev Pairs are used in pool creation to determine the pool's underlying tokens.
     *
     * @custom:reverts If decoded addresses are the same.
     * @custom:reverts If __ordered__ pair of addresses has already been created and has a non-zero pairId.
     * @custom:reverts If decimals of either token are not between 6 and 18, inclusive.
     */
    function _createPair(address asset, address quote) internal returns (uint16 pairId) {
        if (asset == quote) revert SameTokenError();

        pairId = getPairId[asset][quote];
        if (pairId != 0) revert PairExists(pairId);

        (uint8 decimalsAsset, uint8 decimalsQuote) = (IERC20(asset).decimals(), IERC20(quote).decimals());

        if (!asm.isBetween(decimalsAsset, MIN_DECIMALS, MAX_DECIMALS)) revert DecimalsError(decimalsAsset);
        if (!asm.isBetween(decimalsQuote, MIN_DECIMALS, MAX_DECIMALS)) revert DecimalsError(decimalsQuote);

        unchecked {
            pairId = uint16(++getPairNonce); // Increments the pair nonce, returning the nonce for this pair.
        }

        // Writes the pairId into a fetchable mapping using its tokens.
        getPairId[asset][quote] = pairId; // note: No reverse lookup, because order matters!

        // Writes the pair into Enigma state.
        pairs[pairId] = Pair({
            tokenAsset: asset,
            decimalsBase: decimalsAsset,
            tokenQuote: quote,
            decimalsQuote: decimalsQuote
        });

        emit CreatePair(pairId, asset, quote, decimalsAsset, decimalsQuote);
    }

    // ===== Accounting System ===== //

    /// @dev Most important function because it manages the solvency of the Engima.
    /// @custom:security Critical. Global balances of tokens are compared with the actual `balanceOf`.
    function _increaseReserves(address token, uint256 amount) internal {
        __account__.deposit(token, amount);
        emit IncreaseReserveBalance(token, amount);
    }

    /// @dev Equally important to `_increaseReserves`.
    /// @custom:security Critical. Same as above. Implicitly reverts on underflow.
    function _decreaseReserves(address token, uint256 amount) internal {
        __account__.withdraw(token, amount);
        emit DecreaseReserveBalance(token, amount);
    }

    /// @dev A positive credit is a receivable paid to the `msg.sender` internal balance.
    ///      Positive credits are only applied to the internal balance of the account.
    ///      Therefore, it does not require a state change for the global reserves.
    /// @custom:security Critical. Only method which credits accounts with tokens.
    function _applyCredit(address token, uint256 amount) internal {
        __account__.credit(msg.sender, token, amount);
        emit IncreaseUserBalance(token, amount);
    }

    /// @dev A positive debit is a cost that must be paid for a transaction to be processed.
    ///      If a balance exists for the token for the internal balance of `msg.sender`,
    ///      it will be used to pay the debit. Else, the contract expects tokens to be transferred in.
    /// @custom:security Critical. Handles the payment of tokens for all pool actions.
    function _applyDebit(address token, uint256 amount) internal {
        __account__.debit(msg.sender, token, amount);
        emit DecreaseUserBalance(token, amount);
    }

    /// @notice Single instruction processor that will forward instruction to appropriate function.
    /// @dev Critical: Every token of every pair interacted with is cached to be settled later.
    /// @param data Encoded Enigma data. First byte must be an Enigma instruction.
    /// @custom:security Critical. Directly sends CPU to be executed.
    function _process(bytes calldata data) internal {
        uint48 poolId;
        bytes1 instruction = bytes1(data[0] & 0x0f);
        if (instruction == CPU.UNKNOWN) revert UnknownInstruction();

        if (instruction == CPU.ALLOCATE) {
            (uint8 useMax, uint48 poolId_, uint128 deltaLiquidity) = CPU.decodeAllocate(data); // Packs the use max flag in the Enigma instruction code byte.
            _allocate(useMax, poolId_, deltaLiquidity);
        } else if (instruction == CPU.UNALLOCATE) {
            (uint8 useMax, uint48 poolId_, uint16 pairId, uint128 deltaLiquidity) = CPU.decodeUnallocate(data); // Packs useMax flag into Enigma instruction code byte.
            _unallocate(useMax, poolId_, pairId, deltaLiquidity);
        } else if (instruction == CPU.SWAP) {
            Order memory args;
            (args.useMax, args.poolId, args.input, args.limit, args.direction) = CPU.decodeSwap(data); // Packs useMax flag into Enigma instruction code byte.
            (poolId, , , ) = _swapExactIn(args);
        } else if (instruction == CPU.STAKE_POSITION) {
            uint48 poolId_ = CPU.decodeStakePosition(data);
            _stake(poolId_);
        } else if (instruction == CPU.UNSTAKE_POSITION) {
            uint48 poolId_ = CPU.decodeUnstakePosition(data);
            _unstake(poolId_);
        } else if (instruction == CPU.CREATE_POOL) {
            (uint48 poolId_, uint16 pairId, uint32 curveId, uint128 price) = CPU.decodeCreatePool(data);
            _createPool(poolId_, pairId, curveId, price);
        } else if (instruction == CPU.CREATE_CURVE) {
            (uint24 sigma, uint32 maturity, uint16 fee, uint16 priorityFee, uint128 strike) = CPU.decodeCreateCurve(
                data
            );
            _createCurve(sigma, maturity, fee, priorityFee, strike);
        } else if (instruction == CPU.CREATE_PAIR) {
            (address asset, address quote) = CPU.decodeCreatePair(data);
            _createPair(asset, quote);
        } else {
            revert UnknownInstruction();
        }
    }
}
