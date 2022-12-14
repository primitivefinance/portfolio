// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/utils/SafeTransferLib.sol";

import "./EnigmaTypes.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IHyper.sol";
import "./interfaces/IERC20.sol";
import "./libraries/Utils.sol";
import "./libraries/Decoder.sol";
import "./libraries/HyperSwapLib.sol";
import "./libraries/Instructions.sol";
import "./libraries/SafeCast.sol";
import "./libraries/Accounting.sol";

using {getStartTime, getEpochsPassed, getLastUpdatedId, getTimeToTransition, getTimePassedInCurrentEpoch} for Epoch;

function getStartTime(Epoch memory epoch) pure returns (uint256 startTime) {
    if(epoch.endTime < epoch.interval) startTime = 0; // todo: fix, avoids underflow
    else startTime = epoch.endTime - epoch.interval;
}

function getEpochsPassed(Epoch memory epoch, uint256 lastUpdatedTimestamp) pure returns (uint256 epochsPassed) {
    if(epoch.endTime < (lastUpdatedTimestamp + 1)) epochsPassed = 1; // todo: fix this, avoids the arthimetic undeflow
    else epochsPassed = (epoch.endTime - (lastUpdatedTimestamp + 1)) / epoch.interval;
}

function getLastUpdatedId(Epoch memory epoch, uint256 epochsPassed) pure returns (uint256 lastUpdateId) {
    if(epoch.id < epochsPassed) lastUpdateId = 0; // todo: fix, avoids underflow
    else lastUpdateId = epoch.id - epochsPassed;
}

function getTimeToTransition(Epoch memory epoch, uint256 epochsPassed, uint256 lastUpdatedTimestamp) pure returns (uint256 timeToTransition) {
    timeToTransition = epoch.endTime - (epochsPassed * epoch.interval) - lastUpdatedTimestamp;
}

function getTimePassedInCurrentEpoch(Epoch memory epoch, uint timestamp, uint256 lastUpdatedTimestamp) view returns (uint256 timePassed) {
    uint256 startTime = epoch.getStartTime();
    uint256 lastUpdateInCurrentEpoch = lastUpdatedTimestamp > startTime ? lastUpdatedTimestamp : startTime;
    timePassed = timestamp - lastUpdateInCurrentEpoch;
}

/** @dev Sends ether in `deposit` function to target address. Must validate `weth`. */
function __wrapEther(address weth) {
    IWETH(weth).deposit{value: msg.value}();
}

/** @dev Dangerously sends ether to `to` in a low-level call. */
function __dangerousUnwrapEther(
    address weth,
    address to,
    uint256 amount
) {
    IWETH(weth).withdraw(amount);
    __dangerousTransferEther(to, amount);
}

/** @dev Dangerously sends ether to `to` in a low-level call. */
function __dangerousTransferEther(address to, uint256 value) {
    (bool success, ) = to.call{value: value}(new bytes(0));
    if (!success) revert EtherTransferFail();
}

/** @dev Gas optimized. */
function __balanceOf(address token, address account) view returns (uint256) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, account));
    if (!success || data.length != 32) revert BalanceError();
    return abi.decode(data, (uint256));
}

/**
 * todo: verify this is good to go
 */
function __computeDelta(uint256 input, int256 delta) pure returns (uint256 output) {
    assembly {
        switch slt(input, 0) // input < 0 ? 1 : 0
        case 0 {
            output := add(input, delta)
        }
        case 1 {
            output := sub(input, delta)
        }
    }
}

/**
 * @notice Syncs a pool's liquidity and last updated timestamp.
 */
function __updatePoolLiquidity(
    HyperPool storage self,
    uint256 timestamp,
    int128 liquidityDelta
) {
    self.blockTimestamp = timestamp;
    self.liquidity = SafeCast.toUint128(__computeDelta(self.liquidity, liquidityDelta));
}

/**
 * @notice Syncs a position's liquidity, last updated timestamp, fees earned, and fee growth.
 */
function __updatePosition(
    HyperPosition storage self,
    HyperPool storage pool,
    uint256 timestamp,
    int256 liquidityDelta
) returns (uint256 feeAssetEarned, uint256 feeQuoteEarned) {
    self.blockTimestamp = timestamp;
    self.totalLiquidity = SafeCast.toUint128(__computeDelta(self.totalLiquidity, liquidityDelta));

    // Syncs fee growth and fees earned.
    (uint256 liquidity, uint256 feeGrowthAsset, uint256 feeGrowthQuote) = (
        pool.liquidity,
        pool.feeGrowthGlobalAsset,
        pool.feeGrowthGlobalQuote
    );

    feeAssetEarned = FixedPointMathLib.mulWadDown(feeGrowthAsset - self.feeGrowthAssetLast, liquidity);
    feeQuoteEarned = FixedPointMathLib.mulWadDown(feeGrowthQuote - self.feeGrowthQuoteLast, liquidity);

    self.feeGrowthAssetLast = feeGrowthAsset;
    self.feeGrowthQuoteLast = feeGrowthQuote;

    self.tokensOwedAsset += feeAssetEarned;
    self.tokensOwedQuote += feeQuoteEarned;
}

function __checkpoint(uint256 liveCheckpoint, uint256 checkpointChange) pure returns (uint256 nextCheckpoint) {
    nextCheckpoint = liveCheckpoint;

    if (checkpointChange != 0) {
        // overflow by design, as these are checkpoints, which can measure the distance even if overflowed.
        unchecked {
            nextCheckpoint = liveCheckpoint + checkpointChange;
        }
    }
}

// note: prettier does not have settings for file level for directives.
/* using SafeCast for uint256;
using { __updatePosition } for HyperPosition; */

/// @title Enigma Virtual Machine.
/// @notice Stores the state of the Enigma with functions to change state.
/// @dev Implements low-level internal virtual functions, re-entrancy guard and state.
contract Hyper is IHyper {
    using SafeCast for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    using HyperSwapLib for HyperSwapLib.Expiring;

    // --- Constants --- //
    string public constant VERSION = "prototype-v0.0.1";
    /// @dev Canonical Wrapped Ether contract.
    address public immutable WETH;
    /// @dev Distance between the location of prices on the price grid, so distance between price.
    int24 public constant TICK_SIZE = 256;
    /// @dev Used as the first pointer for the jump process.
    uint8 public constant JUMP_PROCESS_START_POINTER = 2;
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
    // --- State --- //
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
    /// @dev Token -> Physical Reserves.
    mapping(address => uint256) public globalReserves;
    /// @dev Base Token -> Quote Token -> Pair id
    mapping(address => mapping(address => uint16)) public getPairId;
    /// @dev User -> Token -> Internal Balance.
    mapping(address => mapping(address => uint256)) public balances;
    /// @dev User -> Position Id -> Liquidity Position.
    mapping(address => mapping(uint48 => HyperPosition)) public positions;
    /// @dev Amount of rewards globally tracked per epoch.
    mapping(uint48 => mapping(uint256 => uint256)) internal epochRewardGrowthGlobal;
    /// @dev Individual rewards of a position.
    mapping(uint48 => mapping(int24 => mapping(uint256 => uint256))) internal epochRewardGrowthOutside;

    // --- Reentrancy --- //
    modifier lock() {
        if (locked != 1) revert LockedError();

        locked = 2;
        _;
        locked = 1;
    }

    // --- Constructor --- //
    constructor(address weth) {
        WETH = weth;
    }

    // --- Fallback --- //

    /// @notice Main touchpoint for receiving calls.
    /// @dev Critical: data must be encoded properly to be processed.
    /// @custom:security Critical. Guarded against re-entrancy. This is like the bank vault door.
    /// @custom:mev Higher level security checks must be implemented by calling contract.
    fallback() external payable lock {
        if (msg.data[0] != Instructions.INSTRUCTION_JUMP) _process(msg.data);
        else _jumpProcess(msg.data);
        _settleBalances();
    }

    // --- External --- //

    // Note: Not sure if we should always revert when receiving ETH
    receive() external payable {
        if (msg.sender != WETH) revert();
    }

    /// @inheritdoc IHyperActions
    function allocate(uint48 poolId, uint amount) external lock {
      /*   bool useMax = amount == type(uint256).max; // magic variable.
        uint input = useMax ? 0 : amount;
        data = Instructions.encodeAllocate(useMax, poolId, 0x0, input); // Used as an input multiplier: 10^(0x0) = 1.
        _process(data);  */
    }

    /// @inheritdoc IHyperActions
    function unallocate(uint48 poolId, uint amount) external lock {
     /*    bool useMax = amount == type(uint256).max; // magic variable.
        uint input = useMax ? 0 : amount;
        data = Instructions.encodeUnallocate(useMax, poolId, 0x0, input); // Used as an input multiplier: 10^(0x0) = 1.
        _process(data);  */
    }

    /// @inheritdoc IHyperActions
    function stake(uint48 poolId) external lock {
      /*   data = Instructions.encodeStakePosition(poolId);
        _process(data); */
    }

    /// @inheritdoc IHyperActions
    function unstake(uint48 poolId) external lock {
       /*  data = Instructions.encodeUnstakePosition(poolId);
        _process(data); */
    }

    /// @inheritdoc IHyperActions
    function swap(uint48 poolId, bool sellAsset, uint amount, uint limit) external lock {
       /*  bool useMax = amount == type(uint256).max; // magic variable.
        uint input = useMax ? 0 : amount;
        data = Instructions.encodeSwap(useMax, poolId, 0x0, input, 0x0, limit, uint8(sellAsset)); // Used as an input multiplier: 10^(0x0) = 1.
        _process(data); */
    }

    /// @inheritdoc IHyperActions
    function draw(
        address token,
        uint256 amount,
        address to
    ) external lock {
        if (balances[msg.sender][token] < amount) revert DrawBalance(); // Only withdraw if user has enough.
        _applyDebit(token, amount);

        if (token == WETH) __dangerousUnwrapEther(WETH, to, amount);
        else SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    /// @inheritdoc IHyperActions
    function fund(address token, uint256 amount) external payable override lock {
        _applyCredit(token, amount);

        if (token == WETH) __wrapEther(WETH);
        else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
    }

    // --- Internal --- //

    /// @dev Overridable in tests.
    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }

    /// @dev Overridable in tests.
    /// @custom:mev Prevents liquidity from being added and immediately removed until policy time (seconds) has elapsed.
    function _liquidityPolicy() internal view virtual returns (uint256) {
        return JUST_IN_TIME_LIQUIDITY_POLICY;
    }

    // ===== Manipulating Positions ===== //

    /**
     * @notice Allocates liquidity to a pool.
     *
     * @custom:reverts If attempting to add liquidity to a pool that has not been created.
     * @custom:reverts If attempting to add zero liquidity.
     */
    function _allocate(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint8 useMax, uint48 poolId_, uint128 deltaLiquidity) = Instructions.decodeAllocate(data); // Packs the use max flag in the Enigma instruction code byte.
        poolId = poolId_;

        if (deltaLiquidity == 0) revert ZeroLiquidityError();
        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        _syncPoolPriceAndEpoch(poolId);

        (uint256 deltaR2, uint256 deltaR1) = getPhysicalReserves(poolId, deltaLiquidity);

        _increaseLiquidity(poolId_, deltaR1, deltaR2, deltaLiquidity);
    }

    function _increaseLiquidity(
        uint48 poolId,
        uint256 deltaR1,
        uint256 deltaR2,
        uint128 deltaLiquidity
    ) internal {
        HyperPool storage pool = pools[poolId];
        __updatePoolLiquidity(pool, _blockTimestamp(), int128(deltaLiquidity));
        _increasePosition(poolId, deltaLiquidity);

        // note: Global reserves are used at the end of instruction processing to settle transactions.
        uint16 pairId = uint16(poolId >> 32);
        Pair memory pair = pairs[pairId];
        _increaseGlobal(pair.tokenBase, deltaR2);
        _increaseGlobal(pair.tokenQuote, deltaR1);

        emit Allocate(poolId, pair.tokenBase, pair.tokenQuote, deltaR2, deltaR1, deltaLiquidity);
    }

    /// @dev Assumes the position is properly allocated to an account by the end of the transaction.
    /// @custom:security High. Only method of increasing the liquidity held by accounts.
    function _increasePosition(uint48 poolId, uint256 deltaLiquidity) internal {
        HyperPool storage pool = pools[poolId];
        HyperPosition storage pos = positions[msg.sender][poolId];
        (uint256 feeAsset, uint256 feeQuote) = __updatePosition(pos, pool, _blockTimestamp(), int256(deltaLiquidity));
        emit FeesEarned(msg.sender, poolId, feeAsset, feeQuote);
        emit IncreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    function _unallocate(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 a,
            uint256 b
        )
    {
        (uint8 useMax, uint48 poolId_, uint16 pairId, uint128 deltaLiquidity) = Instructions.decodeUnallocate(data); // Packs useMax flag into Enigma instruction code byte.
        poolId = poolId_;

        if (deltaLiquidity == 0) revert ZeroLiquidityError();
        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        // Compute amounts of tokens for the real reserves.
        HyperPool storage pool = pools[poolId_];
        __updatePoolLiquidity(pool, _blockTimestamp(), -int128(deltaLiquidity));
        _decreasePosition(poolId_, deltaLiquidity);

        // note: Global reserves are referenced at end of processing to determine amounts of token to transfer.
        (uint256 deltaR2, uint256 deltaR1) = getPhysicalReserves(poolId_, deltaLiquidity);
        Pair memory pair = pairs[pairId];
        _decreaseGlobal(pair.tokenBase, deltaR2);
        _decreaseGlobal(pair.tokenQuote, deltaR1);

        emit Unallocate(poolId_, pair.tokenBase, pair.tokenQuote, deltaR1, deltaR2, deltaLiquidity);
    }

    /// @dev Syncs a position's fee growth, fees earned, liquidity, and timestamp.
    function _decreasePosition(uint48 poolId, uint256 deltaLiquidity) internal {
        HyperPool storage pool = pools[poolId];
        HyperPosition storage pos = positions[msg.sender][poolId];
        (uint256 feeAsset, uint256 feeQuote) = __updatePosition(pos, pool, _blockTimestamp(), -int256(deltaLiquidity));
        emit FeesEarned(msg.sender, poolId, feeAsset, feeQuote);
        emit DecreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    /// @dev Reverts if liquidity was allocated within time elapsed in seconds returned by `_liquidityPolicy`.
    /// @custom:security High. Must be used in place of `_decreasePosition` in most scenarios.
    function _decreasePositionCheckJit(uint48 poolId, uint256 deltaLiquidity) internal {
        (uint256 distance, uint256 timestamp) = checkJitLiquidity(msg.sender, poolId);
        if (_liquidityPolicy() > distance) revert JitLiquidity(distance);

        _decreasePosition(poolId, deltaLiquidity);
    }

    function _stake(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint48 poolId_, uint48 positionId) = Instructions.decodeStakePosition(data);
        poolId = poolId_;

        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        HyperPosition storage pos = positions[msg.sender][positionId];
        if (pos.stakeEpochId != 0) revert PositionStakedError(positionId);
        if (pos.totalLiquidity == 0) revert PositionZeroLiquidityError(positionId);

        HyperPool storage pool = pools[poolId_];
        pool.epochStakedLiquidityDelta += int256(pos.totalLiquidity);

        Epoch storage epoch = epochs[poolId_];
        pos.stakeEpochId = epoch.id + 1;

        // note: do we need to update position blockTimestamp?

        // emit Stake Position
    }

    function _unstake(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint48 poolId_, uint48 positionId) = Instructions.decodeUnstakePosition(data);
        poolId = poolId_;

        _syncPoolPriceAndEpoch(poolId);

        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        HyperPosition storage pos = positions[msg.sender][positionId];
        if (pos.stakeEpochId == 0 || pos.unstakeEpochId != 0) revert PositionNotStakedError(positionId);

        HyperPool storage pool = pools[poolId_];
        pool.epochStakedLiquidityDelta -= int256(pos.totalLiquidity);

        Epoch storage epoch = epochs[poolId_];
        pos.unstakeEpochId = epoch.id + 1;

        // note: do we need to update position blockTimestamp?

        // emit Unstake Position
    }

    // --- Epochs --- //

    event SetEpoch(uint256 id, uint256 endTime);

    Epoch public epoch;

    /**
     * @notice Updates the current epoch.
     */
    function syncEpoch() internal {
        if (_blockTimestamp() < epoch.endTime) return;

        uint256 epochsPassed = (_blockTimestamp() - epoch.endTime) / epoch.interval;
        epoch.id += (1 + epochsPassed);
        epoch.endTime += (epoch.interval + (epochsPassed * epoch.interval));
        emit SetEpoch(epoch.id, epoch.endTime);
    }

    // ===== Swapping ===== //

    /**
     * @notice Computes the price of the pool, which changes over time. Syncs pool to new price if enough time has passed.
     *
     * @custom:reverts If pool does not exist.
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _syncPoolPriceAndEpoch(uint48 poolId) internal returns (uint256 price, int24 tick) {
        if (!_doesPoolExist(poolId)) revert NonExistentPool(poolId);

        HyperPool storage pool = pools[poolId];
        Curve memory curve = curves[uint32(poolId)];
        uint256 tau;
        if (curve.maturity > pool.blockTimestamp) tau = curve.maturity - pool.blockTimestamp; // Keeps tau at zero if pool expired.
        uint256 elapsed = _blockTimestamp() - pool.blockTimestamp;
        HyperSwapLib.Expiring memory expiring = HyperSwapLib.Expiring(curve.strike, curve.sigma, tau);

        price = expiring.computePriceWithChangeInTau(pool.lastPrice, elapsed);
        tick = HyperSwapLib.computeTickWithPrice(price);
        int256 hi = int256(pool.lastTick + TICK_SIZE);
        int256 lo = int256(pool.lastTick - TICK_SIZE);
        tick = isBetween(int256(tick), lo, hi) ? tick : pool.lastTick;

        _syncPool(poolId, tick, price, pool.liquidity, pool.feeGrowthGlobalAsset, pool.feeGrowthGlobalQuote);
    }

    SwapState state;

    error InvariantError(int256 prev, int256 aftr);
    event log(uint, uint);
    event log(uint);

    /**
     * @dev Swaps exact input of tokens for an output of tokens in the specified direction.
     *
     * @custom:reverts If input swap amount is zero.
     * @custom:reverts If pool is not initialized with a price.
     * @custom:mev Must have price limit to avoid losses from flash loan price manipulations.
     */
    function _swapExactIn(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 remainder,
            uint256 input,
            uint256 output
        )
    {
        // SwapState memory state;

        Order memory args;
        (args.useMax, args.poolId, args.input, args.limit, args.direction) = Instructions.decodeSwap(data); // Packs useMax flag into Enigma instruction code byte.

        if (args.input == 0) revert ZeroInput();
        if (!_doesPoolExist(args.poolId)) revert NonExistentPool(args.poolId);

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
            (uint256 price, int24 tick) = _syncPoolPriceAndEpoch(args.poolId);
            // Expect the caller to exhaust their entire balance of the input token.
            remainder = args.useMax == 1 ? __balanceOf(pair.tokenBase, msg.sender) : args.input;
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
            if(_blockTimestamp() > curve.maturity) revert PoolExpiredError();

            expiring = HyperSwapLib.Expiring({
                strike: curve.strike,
                sigma: curve.sigma,
                tau: curve.maturity - _blockTimestamp()
            });

            // Fetch the correct gamma to calculate the fees after pool synced.
            state.gamma = msg.sender == pool.prioritySwapper ? curve.priorityGamma : curve.gamma;
        }

        // ----- Effects ----- //
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

        emit log(4);

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
        emit Swap(args.poolId, swap.input, swap.output, pair.tokenBase, pair.tokenQuote);

        _increaseGlobal(pair.tokenBase, swap.input);
        _decreaseGlobal(pair.tokenQuote, swap.output);
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
        address FEE_SETTLEMENT_TOKEN = pairs[pairId].tokenBase;
        
        Epoch memory readEpoch = epochs[poolId];
        HyperPool storage pool = pools[poolId];

        uint256 epochsPassed = readEpoch.getEpochsPassed(pool.blockTimestamp);

        if (epochsPassed > 0) {
            uint256 lastUpdatedEpochId = readEpoch.getLastUpdatedId(epochsPassed);
        emit log(5);
            // distribute remaining proceeds in lastUpdatedEpochId
            if (pool.stakedLiquidity > 0) {
                // TODO
            }

            // save pool snapshot for lastUpdatedEpochId
            //poolSnapshots[pool.id][lastUpdatedEpochId] = getPoolSnapshot(pool);
             
            // update the pool's liquidity due to the transition
            pool.stakedLiquidity = __computeDelta(pool.stakedLiquidity, pool.epochStakedLiquidityDelta);
            pool.borrowableLiquidity = pool.stakedLiquidity;
            pool.epochStakedLiquidityDelta = int256(0);

            // TODO: Pay user

            // check if multiple epochs have passed
            if (epochsPassed > 1) {
                // update proceeds per liquidity distributed for next epoch if needed
                if (pool.stakedLiquidity > 0) {
                    // TODO
                }
                // TODO: pay user
            }
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

        pool.feeGrowthGlobalAsset = __checkpoint(pool.feeGrowthGlobalAsset, feeGrowthGlobalAsset);
        pool.feeGrowthGlobalQuote = __checkpoint(pool.feeGrowthGlobalQuote, feeGrowthGlobalQuote);

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
    function _createPool(bytes calldata data) internal returns (uint48 poolId) {
        (uint48 poolId_, uint16 pairId, uint32 curveId, uint128 price) = Instructions.decodeCreatePool(data);

        if (price == 0) revert ZeroPrice();
        if (pairId == 0) pairId = uint16(getPairNonce); // magic variable
        if (curveId == 0) curveId = uint32(getCurveNonce); // magic variable

        poolId = uint48(bytes6(abi.encodePacked(pairId, curveId)));
        if (_doesPoolExist(poolId)) revert PoolExists();

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
    function _createCurve(bytes calldata data) internal returns (uint32 curveId) {
        (uint24 sigma, uint32 maturity, uint16 fee, uint16 priorityFee, uint128 strike) = Instructions
            .decodeCreateCurve(data); // Expects Enigma encoded data.

        bytes32 rawCurveId = Decoder.toBytes32(data[1:]); // note: Trims the single byte Enigma instruction code.

        curveId = getCurveId[rawCurveId]; // Gets the nonce of this raw curve, if it was created already.
        if (curveId != 0) revert CurveExists(curveId);

        if (!isBetween(fee, MIN_POOL_FEE, MAX_POOL_FEE)) revert FeeOOB(fee);
        if (!isBetween(priorityFee, MIN_POOL_FEE, fee)) revert PriorityFeeOOB(priorityFee);
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
    function _createPair(bytes calldata data) internal returns (uint16 pairId) {
        (address asset, address quote) = Instructions.decodeCreatePair(data); // Expects Engima encoded data.
        if (asset == quote) revert SameTokenError();

        pairId = getPairId[asset][quote];
        if (pairId != 0) revert PairExists(pairId);

        (uint8 assetDecimals, uint8 quoteDecimals) = (IERC20(asset).decimals(), IERC20(quote).decimals());

        if (!_isValidDecimals(assetDecimals)) revert DecimalsError(assetDecimals);
        if (!_isValidDecimals(quoteDecimals)) revert DecimalsError(quoteDecimals);

        unchecked {
            pairId = uint16(++getPairNonce); // Increments the pair nonce, returning the nonce for this pair.
        }

        // Writes the pairId into a fetchable mapping using its tokens.
        getPairId[asset][quote] = pairId; // note: No reverse lookup, because order matters!

        // Writes the pair into Enigma state.
        pairs[pairId] = Pair({
            tokenBase: asset,
            decimalsBase: assetDecimals,
            tokenQuote: quote,
            decimalsQuote: quoteDecimals
        });

        emit CreatePair(pairId, asset, quote, assetDecimals, quoteDecimals);
    }

    // --- General Utils --- //

    function _doesPoolExist(uint48 poolId) internal view returns (bool exists) {
        exists = pools[poolId].blockTimestamp != 0;
    }

    function _isValidDecimals(uint8 decimals) internal pure returns (bool valid) {
        valid = isBetween(decimals, MIN_DECIMALS, MAX_DECIMALS);
    }

    /// @notice First byte should always be the INSTRUCTION_JUMP Enigma code.
    /// @dev Expects a special encoding method for multiple instructions.
    /// @param data Includes opcode as byte at index 0. First byte should point to next instruction.
    /// @custom:security Critical. Processes multiple instructions. Data must be encoded perfectly.
    function _jumpProcess(bytes calldata data) internal {
        uint8 length = uint8(data[1]);
        uint8 pointer = JUMP_PROCESS_START_POINTER; // note: [opcode, length, pointer, ...instruction, pointer, ...etc]
        uint256 start;

        // For each instruction set...
        for (uint256 i; i != length; ++i) {
            // Start at the index of the first byte of the next instruction.
            start = pointer;

            // Set the new pointer to the next instruction, located at the pointer.
            pointer = uint8(data[pointer]);

            // The `start:` includes the pointer byte, while the `:end` `pointer` is excluded.
            if (pointer > data.length) revert JumpError(pointer);
            bytes calldata instruction = data[start:pointer];

            // Process the instruction.
            _process(instruction[1:]); // note: Removes the pointer to the next instruction.
        }
    }

    // ===== Accounting System ===== //

    /// @dev Most important function because it manages the solvency of the Engima.
    /// @custom:security Critical. Global balances of tokens are compared with the actual `balanceOf`.
    function _increaseGlobal(address token, uint256 amount) internal {
        globalReserves[token] += amount;
        emit IncreaseGlobalBalance(token, amount);
    }

    /// @dev Equally important to `_increaseGlobal`.
    /// @custom:security Critical. Same as above. Implicitly reverts on underflow.
    function _decreaseGlobal(address token, uint256 amount) internal {
        require(globalReserves[token] >= amount, "Not enough reserves");
        globalReserves[token] -= amount;
        emit DecreaseGlobalBalance(token, amount);
    }

    /// @dev Critical array, used in jump process to track the pairs that were interacted with.
    /// @notice Cleared at end and never permanently set.
    /// @custom:security High. Without pairIds to loop through, no token amounts are settled.
    uint16[] internal _tempPairIds;

    /// @dev Token -> Touched Flag. Stored temporary to signal which token reserves were tapped.
    mapping(address => bool) internal _addressCache;

    /// @dev Flag set to `true` during `_process`. Set to `false` during `_settleToken`.
    /// @custom:security High. Referenced in settlement to pay for tokens due.
    function _cacheAddress(address token, bool flag) internal {
        _addressCache[token] = flag;
    }

    /// @dev A positive credit is a receivable paid to the `msg.sender` internal balance.
    ///      Positive credits are only applied to the internal balance of the account.
    ///      Therefore, it does not require a state change for the global reserves.
    /// @custom:security Critical. Only method which credits accounts with tokens.
    function _applyCredit(address token, uint256 amount) internal {
        balances[msg.sender][token] += amount;
        emit IncreaseUserBalance(token, amount);
    }

    /// @dev Dangerous! Calls to external contract with an inline assembly `safeTransferFrom`.
    ///      A positive debit is a cost that must be paid for a transaction to be processed.
    ///      If a balance exists for the token for the internal balance of `msg.sender`,
    ///      it will be used to pay the debit.
    ///      Else, tokens are expected to be transferred into this contract using `transferFrom`.
    ///      Externally paid debits increase the balance of the contract, so the global
    ///      reserves must be increased.
    /// @custom:security Critical. Handles the payment of tokens for all pool actions.
    function _applyDebit(address token, uint256 amount) internal {
        if (balances[msg.sender][token] >= amount) balances[msg.sender][token] -= amount;
        else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
        emit DecreaseUserBalance(token, amount);
    }

    /// @notice Single instruction processor that will forward instruction to appropriate function.
    /// @dev Critical: Every token of every pair interacted with is cached to be settled later.
    /// @param data Encoded Enigma data. First byte must be an Enigma instruction.
    /// @custom:security Critical. Directly sends instructions to be executed.
    function _process(bytes calldata data) internal {
        uint48 poolId;
        bytes1 instruction = bytes1(data[0] & 0x0f);
        if (instruction == Instructions.UNKNOWN) revert UnknownInstruction();

        if (instruction == Instructions.ALLOCATE) {
            (poolId, ) = _allocate(data);
        } else if (instruction == Instructions.UNALLOCATE) {
            (poolId, , ) = _unallocate(data);
        } else if (instruction == Instructions.SWAP) {
            (poolId, , , ) = _swapExactIn(data);
        } else if (instruction == Instructions.STAKE_POSITION) {
            (poolId, ) = _stake(data);
        } else if (instruction == Instructions.UNSTAKE_POSITION) {
            (poolId, ) = _unstake(data);
        } else if (instruction == Instructions.CREATE_POOL) {
            (poolId) = _createPool(data);
        } else if (instruction == Instructions.CREATE_CURVE) {
            _createCurve(data);
        } else if (instruction == Instructions.CREATE_PAIR) {
            _createPair(data);
        } else {
            revert UnknownInstruction();
        }

        // note: Only pool interactions have a non-zero poolId.
        if (poolId != 0) {
            uint16 pairId = uint16(poolId >> 32);
            // Add the pair to the array to track all the pairs that have been interacted with.
            _tempPairIds.push(pairId); // note: critical to push the tokens interacted with.
            // Caching the addresses to settle the pools interacted with in the fallback function.
            Pair memory pair = pairs[pairId]; // note: pairIds start at 1 because nonce is incremented first.
            if (!_addressCache[pair.tokenBase]) _cacheAddress(pair.tokenBase, true);
            if (!_addressCache[pair.tokenQuote]) _cacheAddress(pair.tokenQuote, true);
        }
    }

    /// @dev Critical level function that is responsible for handling tokens, debits and credits.
    /// @custom:security Critical. Handles token payments with `_settleToken`.
    function _settleBalances() internal {
        uint256 len = _tempPairIds.length;
        uint16[] memory ids = _tempPairIds;
        if (len == 0) return; // note: Dangerous! If pools were interacted with, this return being trigerred would be a failure.
        for (uint256 i; i != len; ++i) {
            uint16 pairId = ids[i];
            Pair memory pair = pairs[pairId];
            _settleToken(pair.tokenBase);
            _settleToken(pair.tokenQuote);
        }

        delete _tempPairIds;
    }

    /// @dev Increases the `msg.sender` internal balance of a token, or requests payment from them.
    /// @param token Target token to pay or credit.
    /// @custom:security Critical. Handles crediting accounts or requesting payment for debits.
    function _settleToken(address token) internal {
        if (!_addressCache[token]) return; // note: Early short circuit, since attempting to settle twice is common for big orders.

        // If the token is WETH, make sure to wrap any ETH sent to the contract.
        if (token == WETH && msg.value > 0) __wrapEther(WETH);

        uint256 global = globalReserves[token];
        uint256 actual = __balanceOf(token, address(this));
        if (global > actual) {
            uint256 deficit = global - actual;
            _applyDebit(token, deficit);
        } else {
            uint256 surplus = actual - global;
            _applyCredit(token, surplus);
        }

        _cacheAddress(token, false); // note: Effectively saying "any pool with this token was paid for in full".
    }

    // ===== Helpers ===== //

    // todo: check for hash collisions with instruction calldata and fix.

    function checkJitLiquidity(address account, uint48 poolId)
        public
        view
        returns (uint256 distance, uint256 timestamp)
    {
        uint48 positionId = poolId;
        uint256 previous = positions[account][positionId].blockTimestamp;
        timestamp = _blockTimestamp();
        distance = timestamp - previous;
    }

    function getLiquidityMinted(
        uint48 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) external view returns (uint256 deltaLiquidity) {}

    function getInvariant(uint48 poolId) external view returns (int128 invariant) {}

    // TODO: fix this with non-delta liquidity amount
    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        public
        view
        returns (uint256 deltaBase, uint256 deltaQuote)
    {
        uint256 timestamp = _blockTimestamp();

        // Compute amounts of tokens for the real reserves.
        Curve memory curve = curves[uint32(poolId)];
        HyperPool storage pool = pools[poolId];
        HyperSwapLib.Expiring memory info = HyperSwapLib.Expiring({
            strike: curve.strike,
            sigma: curve.sigma,
            tau: curve.maturity - timestamp
        });

        deltaBase = info.computeR2WithPrice(pool.lastPrice);
        deltaQuote = info.computeR1WithR2(deltaBase, pool.lastPrice, 0);

        deltaQuote = deltaQuote.mulWadDown(deltaLiquidity);
        deltaBase = deltaBase.mulWadDown(deltaLiquidity);
    }

    function updateLastTimestamp(uint48) external override returns (uint128 blockTimestamp) {}
}
