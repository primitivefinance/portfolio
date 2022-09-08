// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/utils/SafeTransferLib.sol";

import "./prototype/EnigmaTypes.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IEnigma.sol";
import "./interfaces/IERC20.sol";
import "./libraries/Utils.sol";
import "./libraries/Decoder.sol";
import "./libraries/HyperSwapLib.sol";
import "./libraries/Instructions.sol";
import "./libraries/SafeCast.sol";

function dangerousTransferETH(address to, uint256 value) {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH transfer error");
}

/// @title Enigma Virtual Machine.
/// @notice Stores the state of the Enigma with functions to change state.
/// @dev Implements low-level internal virtual functions, re-entrancy guard and state.
contract Hyper is IEnigma {
    using SafeCast for uint256;
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

    // --- View --- //

    function _checkJitLiquidity(
        address account,
        uint48 poolId,
        int24 loTick,
        int24 hiTick
    ) internal view virtual returns (uint256 distance, uint256 timestamp) {
        uint96 positionId = uint96(bytes12(abi.encodePacked(poolId, loTick, hiTick)));
        uint256 previous = _positions[account][positionId].blockTimestamp;
        timestamp = _blockTimestamp();
        distance = timestamp - previous;
    }

    // --- Internal --- //
    /// @dev Must be implemented by the highest level contract.
    /// @notice Processing logic for instructions.
    /* function _process(bytes calldata data) internal virtual; */

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

    /// @dev Gas optimized `balanceOf` method.
    function _balanceOf(address token, address account) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, account)
        );
        if (!success || data.length != 32) revert BalanceError();
        return abi.decode(data, (uint256));
    }

    /// @dev Overridable in tests.
    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }

    /// @dev Overridable in tests.
    function _liquidityPolicy() internal view virtual returns (uint256) {
        return JUST_IN_TIME_LIQUIDITY_POLICY;
    }

    // --- Wrapped Ether --- //

    function _wrap() internal virtual {
        IWETH(WETH).deposit{value: msg.value}();
    }

    function _dangerousUnwrap(address to, uint256 amount) internal virtual {
        IWETH(WETH).withdraw(amount);

        // Marked as dangerous because it makes an external call to the `to` address.
        dangerousTransferETH(to, amount);
    }

    // --- Global --- //

    /// @dev Most important function because it manages the solvency of the Engima.
    /// @custom:security Critical. Global balances of tokens are compared with the actual `balanceOf`.
    function _increaseGlobal(address token, uint256 amount) internal {
        _globalReserves[token] += amount;
        emit IncreaseGlobal(token, amount);
    }

    /// @dev Equally important to `_increaseGlobal`.
    /// @custom:security Critical. Same as above. Implicitly reverts on underflow.
    function _decreaseGlobal(address token, uint256 amount) internal {
        _globalReserves[token] -= amount;
        emit DecreaseGlobal(token, amount);
    }

    // --- Positions --- //

    function _updatePositionFees(
        HyperPosition storage pos,
        uint48 poolId,
        uint256 feeGrowthInsideAsset,
        uint256 feeGrowthInsideQuote
    ) internal {
        uint256 tokensOwedAsset = FixedPointMathLib.divWadDown(
            feeGrowthInsideAsset - pos.feeGrowthInsideAssetLast,
            _pools[poolId].liquidity
        );

        uint256 tokensOwedQuote = FixedPointMathLib.divWadDown(
            feeGrowthInsideQuote - pos.feeGrowthInsideQuoteLast,
            _pools[poolId].liquidity
        );

        pos.feeGrowthInsideAssetLast = feeGrowthInsideAsset;
        pos.feeGrowthInsideQuoteLast = feeGrowthInsideQuote;

        pos.tokensOwedAsset += tokensOwedAsset;
        pos.tokensOwedQuote += tokensOwedQuote;
    }

    /// @dev Assumes the position is properly allocated to an account by the end of the transaction.
    /// @custom:security High. Only method of increasing the liquidity held by accounts.
    function _increasePosition(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint256 deltaLiquidity
    ) internal {
        uint96 positionId = uint96(bytes12(abi.encodePacked(poolId, loTick, hiTick)));

        HyperPosition storage pos = _positions[msg.sender][positionId];

        if (pos.totalLiquidity == 0) {
            pos.loTick = loTick;
            pos.hiTick = hiTick;
        }
        pos.totalLiquidity += deltaLiquidity.toUint128();
        pos.blockTimestamp = _blockTimestamp();

        (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) = getFeeGrowthInside(
            poolId,
            hiTick,
            loTick,
            _pools[poolId].lastTick,
            _pools[poolId].feeGrowthGlobalAsset,
            _pools[poolId].feeGrowthGlobalQuote
        );

        _updatePositionFees(pos, poolId, feeGrowthInsideAsset, feeGrowthInsideQuote);

        emit IncreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    /// @dev Equally important as `_increasePosition`.
    /// @custom:security Critical. Includes the JIT liquidity check. Implicitly reverts on liquidity underflow.
    function _decreasePosition(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint256 deltaLiquidity
    ) internal {
        uint96 positionId = uint96(bytes12(abi.encodePacked(poolId, loTick, hiTick)));

        HyperPosition storage pos = _positions[msg.sender][positionId];

        pos.totalLiquidity -= deltaLiquidity.toUint128();
        pos.blockTimestamp = _blockTimestamp();

        (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) = getFeeGrowthInside(
            poolId,
            hiTick,
            loTick,
            _pools[poolId].lastTick,
            _pools[poolId].feeGrowthGlobalAsset,
            _pools[poolId].feeGrowthGlobalQuote
        );

        _updatePositionFees(pos, poolId, feeGrowthInsideAsset, feeGrowthInsideQuote);

        emit DecreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    /// @dev Reverts if liquidity was allocated within time elapsed in seconds returned by `_liquidityPolicy`.
    /// @custom:security High. Must be used in place of `_decreasePosition` in most scenarios.
    function _decreasePositionCheckJit(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint256 deltaLiquidity
    ) internal {
        (uint256 distance, uint256 timestamp) = _checkJitLiquidity(msg.sender, poolId, loTick, hiTick);
        if (_liquidityPolicy() > distance) revert JitLiquidity(distance);

        _decreasePosition(poolId, loTick, hiTick, deltaLiquidity);
    }

    function getFeeGrowthInside(
        uint48 poolId,
        int24 hi,
        int24 lo,
        int24 current,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote
    ) internal view returns (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) {
        HyperSlot storage hiTick = _slots[poolId][hi];
        HyperSlot storage loTick = _slots[poolId][lo];

        uint256 feeGrowthBelowAsset;
        uint256 feeGrowthBelowQuote;

        if (current >= lo) {
            feeGrowthBelowAsset = loTick.feeGrowthOutsideAsset;
            feeGrowthBelowQuote = loTick.feeGrowthOutsideQuote;
        } else {
            feeGrowthBelowAsset = feeGrowthGlobalAsset - loTick.feeGrowthOutsideAsset;
            feeGrowthBelowQuote = feeGrowthGlobalQuote - loTick.feeGrowthOutsideQuote;
        }

        uint256 feeGrowthAboveAsset;
        uint256 feeGrowthAboveQuote;
        if (current < hi) {
            feeGrowthAboveAsset = hiTick.feeGrowthOutsideAsset;
            feeGrowthAboveQuote = hiTick.feeGrowthOutsideQuote;
        } else {
            feeGrowthAboveAsset = feeGrowthGlobalAsset - hiTick.feeGrowthOutsideAsset;
            feeGrowthAboveQuote = feeGrowthGlobalQuote - hiTick.feeGrowthOutsideQuote;
        }

        feeGrowthInsideAsset = feeGrowthGlobalAsset - feeGrowthBelowAsset - feeGrowthAboveAsset;
        feeGrowthInsideQuote = feeGrowthGlobalQuote - feeGrowthBelowQuote - feeGrowthAboveQuote;
    }

    // --- State --- //
    /// @dev Pool id -> Tick -> Slot has liquidity at a price.
    mapping(uint48 => mapping(int24 => HyperSlot)) internal _slots;
    mapping(uint48 => mapping(uint256 => uint256)) internal epochRewardGrowthGlobal;
    mapping(uint48 => mapping(int24 => mapping(uint256 => uint256))) internal epochRewardGrowthOutside;
    /// @dev Pool id -> Pair of a Pool.
    mapping(uint16 => Pair) internal _pairs;
    /// @dev Pool id -> HyperPool Data Structure.
    mapping(uint48 => HyperPool) internal _pools;
    /// @dev Pool id -> Epoch Data Structure.
    mapping(uint48 => Epoch) internal _epochs;
    /// @dev Pool id -> Curve Data Structure stores parameters.
    mapping(uint32 => Curve) internal _curves;
    /// @dev Raw curve parameters packed into bytes32 mapped onto a Curve id when it was deployed.
    mapping(bytes32 => uint32) internal _getCurveIds;
    /// @dev Token -> Physical Reserves.
    mapping(address => uint256) internal _globalReserves;
    /// @dev Base Token -> Quote Token -> Pair id
    mapping(address => mapping(address => uint16)) internal _getPairId;
    /// @dev User -> Token -> Interal Balance.
    mapping(address => mapping(address => uint256)) internal _balances;
    /// @dev User -> Position Id -> Liquidity Position.
    mapping(address => mapping(uint96 => HyperPosition)) internal _positions;
    /// @dev Reentrancy guard initialized to state
    uint256 private locked = 1;
    /// @dev A value incremented by one on pair creation. Reduces calldata.
    uint256 internal _pairNonce;
    /// @dev A value incremented by one on curve creation. Reduces calldata.
    uint256 internal _curveNonce;
    /// @dev Distance between the location of prices on the price grid, so distance between price.
    int24 public constant TICK_SIZE = 256;
    /// @dev Amount of seconds of available time to swap past maturity of a pool.
    uint256 internal constant BUFFER = 300;
    /// @dev Constant amount of basis points. All percentage values are integers in basis points.
    uint256 internal constant PERCENTAGE = 1e4;
    /// @dev Constant amount of 1 ether. All liquidity values have 18 decimals.
    uint256 internal constant PRECISION = 1e18;
    /// @dev Maximum pool fee. 10.00%.
    uint256 internal constant MAX_POOL_FEE = 1e3;
    /// @dev Minimum pool fee. 0.01%.
    uint256 internal constant MIN_POOL_FEE = 1;
    /// @dev Used to compute the amount of liquidity to burn on creating a pool.
    uint256 internal constant MIN_LIQUIDITY_FACTOR = 6;
    /// @dev Policy for the "wait" time in seconds between adding and removing liquidity.
    uint256 internal constant JUST_IN_TIME_LIQUIDITY_POLICY = 4;
    /// @dev Amount of seconds that an epoch lasts.
    uint256 internal constant EPOCH_INTERVAL = 300;
    /// @dev Used as the first pointer for the jump process.
    uint8 internal constant JUMP_PROCESS_START_POINTER = 2;
    uint8 internal constant MIN_DECIMALS = 6;
    uint8 internal constant MAX_DECIMALS = 18;

    address public immutable WETH;

    using HyperSwapLib for HyperSwapLib.Expiring;
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    // --- Swap --- //

    /**
     * @notice Parameters used to submit a swap order.
     * @param useMax Use the caller's total balance of the pair's token to do the swap.
     * @param poolId Identifier of the pool.
     * @param input Amount of tokens to input in the swap.
     * @param limit Maximum price paid to fill the swap order.
     * @param direction Specifies asset token in, quote token out with '0', and quote token in, asset token out with '1'.
     */
    struct Order {
        uint8 useMax;
        uint48 poolId;
        uint128 input;
        uint128 limit;
        uint8 direction;
    }

    /**
     * @notice Temporary variables utilized in the order filling loop.
     * @param tick Key of the slot being used to fill the swap at.
     * @param price Price of the slot being used to fill this swap step at.
     * @param remainder Order amount left to fill.
     * @param liquidity Liquidity available at this slot.
     * @param input Cumulative sum of input amounts for each swap step.
     * @param output Cumulative sum of output amounts for each swap step.
     */
    struct Iteration {
        int24 tick;
        uint256 price;
        uint256 remainder;
        uint256 feeAmount;
        uint256 liquidity;
        uint256 input;
        uint256 output;
    }

    /**
     * @notice Computes the price of the pool, which changes over time and write to the pool if ut of sync.
     *
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _syncExpiringPoolTimeAndPrice(uint48 poolId) internal returns (uint256 price, int24 tick) {
        // Read the pool's info.
        HyperPool storage pool = _pools[poolId];
        // Use curve parameters to compute time remaining.
        Curve memory curve = _curves[uint32(poolId)];
        // 1. Compute previous time until maturity.
        uint256 tau = curve.maturity - pool.blockTimestamp;
        // 2. Compute time elapsed since last update.
        uint256 delta = _blockTimestamp() - pool.blockTimestamp;
        // 3. Compute price using previous tau and time elapsed.
        HyperSwapLib.Expiring memory expiring = HyperSwapLib.Expiring(curve.strike, curve.sigma, tau);
        price = expiring.computePriceWithChangeInTau(pool.lastPrice, delta);
        // 4. Compute nearest tick with price.
        tick = HyperSwapLib.computeTickWithPrice(price);
        // 5. Verify tick is within tick size.
        int256 hi = int256(pool.lastTick + TICK_SIZE);
        int256 lo = int256(pool.lastTick - TICK_SIZE);
        tick = isBetween(int256(tick), lo, hi) ? tick : pool.lastTick;
        // 6. Write changes to the pool.
        _updatePool(poolId, tick, price, pool.liquidity, 0, 0);
    }

    struct SwapState {
        bool sell;
        uint256 gamma;
        uint256 feeGrowthGlobal;
    }

    SwapState state;

    /**
     * @notice Engima method to swap tokens.
     * @dev Swaps exact input of tokens for an output of tokens in the specified direction.
     *
     * @custom:reverts If order amount is zero.
     * @custom:reverts If pool has not been created.
     *
     * @custom:mev Must have price limit to avoid losses from flash loan price manipulations.
     */
    function _swapExactForExact(bytes calldata data)
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
        Pair memory pair = _pairs[uint16(args.poolId >> 32)];
        // Pool is used to fetch information and eventually have its state updated.
        HyperPool storage pool = _pools[args.poolId];

        state.feeGrowthGlobal = state.sell ? pool.feeGrowthGlobalAsset : pool.feeGrowthGlobalQuote;

        // Get the variables for first iteration of the swap.
        Iteration memory swap;
        {
            // Writes the pool after computing its updated price with respect to time elapsed since last update.
            (uint256 price, int24 tick) = _syncExpiringPoolTimeAndPrice(args.poolId);
            // Expect the caller to exhaust their entire balance of the input token.
            remainder = args.useMax == 1 ? _balanceOf(pair.tokenBase, msg.sender) : args.input;
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
            Curve memory curve = _curves[uint32(args.poolId)];

            expiring = HyperSwapLib.Expiring({
                strike: curve.strike,
                sigma: curve.sigma,
                tau: curve.maturity - _blockTimestamp()
            });

            // Fetch the correct gamma to calculate the fees after pool synced.
            state.gamma = msg.sender == pool.prioritySwapper ? curve.priorityGamma : curve.gamma;
        }

        // ----- Effects ----- //

        // --- Warning: loop --- //
        //  Loops until a condition is met:
        //  1. Order is filled.
        //  2. Limit price is met.
        // ---
        //  When the price of the asset moves upwards (becomes more valuable), towards the strike,
        //  the reserves of that asset decrease.
        //  When the price of the asset moves downwards (becomes less valuable from having more supply), away from the strike,
        //  the asset reserves decrease.
        do {
            // Input swap amount for this step.
            uint256 delta;
            // Next tick to move to if not filled and price limit not reached.
            int24 nextTick = swap.tick - TICK_SIZE; // todo: fix in direction
            // Next price derived from the next tick, or the final price of the order.
            uint256 nextPrice;
            // Virtual reserves.
            uint256 liveIndependent;
            uint256 nextIndependent;
            uint256 liveDependent;
            uint256 nextDependent;
            // Compute them conditionally based on direction in arguments.
            if (state.sell) {
                // Independent = asset, dependent = quote.
                liveIndependent = expiring.computeR2WithPrice(swap.price);
                (nextPrice, , nextIndependent) = expiring.computeReservesWithTick(nextTick);
                liveDependent = expiring.computeR1WithPrice(swap.price);
            } else {
                // Independent = quote, dependent = asset.
                liveIndependent = expiring.computeR1WithPrice(swap.price);
                (nextPrice, nextIndependent, ) = expiring.computeReservesWithTick(nextTick);
                liveDependent = expiring.computeR2WithPrice(swap.price);
            }

            // Get the max amount that can be filled for a max distance swap.
            uint256 maxInput = (nextIndependent - liveIndependent).mulWadDown(swap.liquidity); // Active liquidity acts as a multiplier.

            // Calculate the amount of fees paid at this tick.
            swap.feeAmount = (swap.remainder >= maxInput ? maxInput : swap.remainder * state.gamma) / 10_000;
            state.feeGrowthGlobal = FixedPointMathLib.divWadDown(swap.feeAmount, swap.liquidity);

            // Compute amount to swap in this step.
            // If the full tick is crossed, reduce the remainder of the trade by the max amount filled by the tick.
            if (swap.remainder >= maxInput) {
                delta = maxInput - swap.feeAmount;

                {
                    Order memory _args = args;
                    SwapState memory _state = state;
                    Iteration memory _swap = swap;
                    HyperPool storage _pool = pool;
                    // Entering or exiting the tick will transition the pool's active range.
                    (
                        int256 liquidityDelta,
                        int256 stakedLiquidityDelta,
                        int256 epochStakedLiquidityDelta
                    ) = _transitionSlot(
                            _args.poolId,
                            _swap.tick,
                            (_state.sell ? _state.feeGrowthGlobal : _pool.feeGrowthGlobalAsset),
                            (_state.sell ? _pool.feeGrowthGlobalQuote : _state.feeGrowthGlobal)
                        );

                    if (liquidityDelta > 0) _swap.liquidity += uint256(liquidityDelta);
                    else _swap.liquidity -= uint256(liquidityDelta);

                    // update _pool staked liquidity values
                    if (stakedLiquidityDelta > 0) _pool.stakedLiquidity += uint256(stakedLiquidityDelta);
                    else _pool.stakedLiquidity -= uint256(stakedLiquidityDelta);

                    _pool.epochStakedLiquidityDelta += epochStakedLiquidityDelta;
                }

                // Update variables for next iteration.
                swap.tick = nextTick; // Set the next slot.
                swap.price = nextPrice; // Set the next price according to the next slot.
                swap.remainder -= delta + swap.feeAmount; // Reduce the remainder of the order to fill.
                swap.input += delta; // Add to the total input of the swap.
            } else {
                // Reaching this block will fill the order. Set the swap input
                delta = swap.remainder - swap.feeAmount;
                nextIndependent = liveIndependent + delta.divWadDown(swap.liquidity);

                swap.remainder = 0; // Reduce the remainder to zero, as the order has been filled.
                swap.input += delta; // Add the full amount remaining to the toal.
            }

            // Compute the output of the swap by computing the difference between the dependent reserves.
            if (state.sell) nextDependent = expiring.computeR1WithR2(nextIndependent, 0, 0);
            else nextDependent = expiring.computeR2WithR1(nextIndependent, 0, 0);
            swap.output += liveDependent - nextDependent;
        } while (swap.remainder != 0 && args.limit > swap.price);

        // Update Pool State Effects
        _updatePool(
            args.poolId,
            swap.tick,
            swap.price,
            swap.liquidity,
            state.sell ? state.feeGrowthGlobal : 0,
            state.sell ? 0 : state.feeGrowthGlobal
        );
        // Update Global Balance Effects
        _increaseGlobal(pair.tokenBase, swap.input);
        _decreaseGlobal(pair.tokenQuote, swap.output);
        // Return variables and swap event.
        (remainder, input, output) = (swap.remainder, swap.input, swap.output);
        emit Swap(args.poolId, swap.input, swap.output, pair.tokenBase, pair.tokenQuote);
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
    function _updatePool(
        uint48 poolId,
        int24 tick,
        uint256 price,
        uint256 liquidity,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote
    ) internal returns (uint256 timeDelta) {
        HyperPool storage pool = _pools[poolId];
        if (pool.lastPrice != price) pool.lastPrice = price;
        if (pool.lastTick != tick) pool.lastTick = tick;
        if (pool.liquidity != liquidity) pool.liquidity = liquidity;

        Epoch storage epoch = _epochs[poolId];
        uint256 timestamp = _blockTimestamp();
        uint256 prevTimestamp = pool.blockTimestamp;
        if (prevTimestamp < epoch.endTime && timestamp >= epoch.endTime) {
            // transition epoch
            epoch.id += 1;
            epoch.endTime += epoch.interval;
            // todo: update staking reward growth
            // update staked liquidity values for new epoch
            if (pool.epochStakedLiquidityDelta > 0) {
                pool.stakedLiquidity += uint256(pool.epochStakedLiquidityDelta);
            } else {
                pool.stakedLiquidity -= uint256(pool.epochStakedLiquidityDelta);
            }
            pool.epochStakedLiquidityDelta = 0;
            // reset priority swapper since epoch ended
            pool.prioritySwapper = address(0);
            // todo: kickoff new priority auction
        }
        timeDelta = timestamp - prevTimestamp;
        pool.blockTimestamp = timestamp;

        if (feeGrowthGlobalAsset > 0) pool.feeGrowthGlobalAsset += feeGrowthGlobalAsset;
        if (feeGrowthGlobalQuote > 0) pool.feeGrowthGlobalQuote += feeGrowthGlobalQuote;

        emit PoolUpdate(
            poolId,
            pool.lastPrice,
            pool.lastTick,
            pool.liquidity,
            feeGrowthGlobalAsset,
            feeGrowthGlobalQuote
        );
    }

    /**
     * @notice Syncs a slot to a new timestamp and returns its liqudityDelta to update the pool's liquidity.
     * @dev Effects on a slot after its been transitioned to another slot.
     * @param poolId Identifier of the pool.
     * @param tick Key of the slot specified to be transitioned.
     * @return liquidityDelta Difference in amount of liquidity available before or after this slot.
     */
    function _transitionSlot(
        uint48 poolId,
        int24 tick,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote
    )
        internal
        returns (
            int256 liquidityDelta,
            int256 stakedLiquidityDelta,
            int256 epochStakedLiquidityDelta
        )
    {
        HyperSlot storage slot = _slots[poolId][tick];
        Epoch storage epoch = _epochs[poolId];
        uint256 timestamp = _blockTimestamp();
        uint256 prevTimestamp = slot.timestamp;
        // note: assumes epoch would have already been transitioned
        if (prevTimestamp < epoch.endTime - epoch.interval) {
            // if prevTimestamp was before start of current epoch, update staked liquidity values
            slot.stakedLiquidityDelta += slot.epochStakedLiquidityDelta;
            slot.epochStakedLiquidityDelta = 0;
        }
        slot.timestamp = timestamp;

        liquidityDelta = slot.liquidityDelta;
        stakedLiquidityDelta = slot.stakedLiquidityDelta;
        epochStakedLiquidityDelta = slot.epochStakedLiquidityDelta;

        // todo: update transition event

        slot.feeGrowthOutsideAsset = feeGrowthGlobalAsset - slot.feeGrowthOutsideAsset;
        slot.feeGrowthOutsideQuote = feeGrowthGlobalQuote - slot.feeGrowthOutsideQuote;

        emit SlotTransition(poolId, tick, slot.liquidityDelta);
    }

    // --- Add Liquidity --- //

    /**
     * @notice Enigma method to add liquidity to a range of prices in a pool.
     *
     * @custom:reverts If attempting to add liquidity to a pool that has not been created.
     * @custom:reverts If attempting to add zero liquidity.
     */
    function _addLiquidity(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint8 useMax, uint48 poolId_, int24 loTick, int24 hiTick, uint128 delLiquidity) = Instructions
            .decodeAddLiquidity(data); // Packs the use max flag in the Enigma instruction code byte.
        poolId = poolId_;

        if (delLiquidity == 0) revert ZeroLiquidityError();
        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        // Compute amounts of tokens for the real reserves.
        Curve memory curve = _curves[uint32(poolId_)];
        HyperSlot storage slot = _slots[poolId_][loTick];
        HyperPool storage pool = _pools[poolId_];
        uint256 timestamp = _blockTimestamp();

        // Get lower price bound using the loTick index.
        uint256 price = HyperSwapLib.computePriceWithTick(loTick);
        // Compute the current virtual reserves given the pool's lastPrice.
        uint256 currentR2 = HyperSwapLib.computeR2WithPrice(
            pool.lastPrice,
            curve.strike,
            curve.sigma,
            curve.maturity - timestamp
        );
        // Compute the real reserves given the lower price bound.
        uint256 deltaR2 = HyperSwapLib.computeR2WithPrice(price, curve.strike, curve.sigma, curve.maturity - timestamp); // todo: I don't think this is right since its (1 - (x / x(P_a)))
        // If the real reserves are zero, then the slot is at the bounds and so we should use virtual reserves.
        if (deltaR2 == 0) deltaR2 = currentR2;
        else deltaR2 = currentR2.divWadDown(deltaR2);
        uint256 deltaR1 = HyperSwapLib.computeR1WithR2(
            deltaR2,
            curve.strike,
            curve.sigma,
            curve.maturity - timestamp,
            price,
            0
        ); // todo: fix with using the hiTick.
        deltaR1 = deltaR1.mulWadDown(delLiquidity);
        deltaR2 = deltaR2.mulWadDown(delLiquidity);

        _increaseLiquidity(poolId_, loTick, hiTick, deltaR1, deltaR2, delLiquidity);
    }

    function _removeLiquidity(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 a,
            uint256 b
        )
    {
        (uint8 useMax, uint48 poolId_, uint16 pairId, int24 loTick, int24 hiTick, uint128 deltaLiquidity) = Instructions
            .decodeRemoveLiquidity(data); // Packs useMax flag into Enigma instruction code byte.

        if (deltaLiquidity == 0) revert ZeroLiquidityError();
        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        // Compute amounts of tokens for the real reserves.
        Curve memory curve = _curves[uint32(poolId_)];
        HyperPool storage pool = _pools[poolId_];
        uint256 timestamp = _blockTimestamp();
        uint256 price = HyperSwapLib.computePriceWithTick(loTick);
        uint256 currentR2 = HyperSwapLib.computeR2WithPrice(
            pool.lastPrice,
            curve.strike,
            curve.sigma,
            curve.maturity - timestamp
        );

        uint256 deltaR2 = HyperSwapLib.computeR2WithPrice(price, curve.strike, curve.sigma, curve.maturity - timestamp); // todo: I don't think this is right since its (1 - (x / x(P_a)))
        if (deltaR2 == 0) deltaR2 = currentR2;
        else deltaR2 = currentR2.divWadDown(deltaR2);

        uint256 deltaR1 = HyperSwapLib.computeR1WithR2(
            deltaR2,
            curve.strike,
            curve.sigma,
            curve.maturity - timestamp,
            price,
            0
        ); // todo: fix with using the hiTick.
        deltaR1 = deltaR1.mulWadDown(deltaLiquidity);
        deltaR2 = deltaR2.mulWadDown(deltaLiquidity);

        // Decrease amount of liquidity in each slot.
        _decreaseSlotLiquidity(poolId_, loTick, deltaLiquidity, false);
        _decreaseSlotLiquidity(poolId_, hiTick, deltaLiquidity, true);

        // Update the pool state if liquidity is within the current pool's slot.
        if (hiTick > pool.lastTick) {
            // note: need to check also greater than lower tick?
            pool.liquidity -= deltaLiquidity;
            pool.blockTimestamp = _blockTimestamp();
        }

        // Todo: delete any slots if uninstantiated.

        // Todo: update bitmap of instantiated/uninstantiated slots.

        _decreasePosition(poolId_, loTick, hiTick, deltaLiquidity);

        // note: Global reserves are referenced at end of processing to determine amounts of token to transfer.
        Pair memory pair = _pairs[pairId];
        _decreaseGlobal(pair.tokenBase, deltaR2);
        _decreaseGlobal(pair.tokenQuote, deltaR1);

        emit RemoveLiquidity(poolId_, pairId, deltaR1, deltaR2, deltaLiquidity);
    }

    function _increaseLiquidity(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint256 deltaR1,
        uint256 deltaR2,
        uint256 deltaLiquidity
    ) internal {
        if (deltaLiquidity == 0) revert ZeroLiquidityError();

        // Update the slots.
        _increaseSlotLiquidity(poolId, loTick, deltaLiquidity, false);
        _increaseSlotLiquidity(poolId, hiTick, deltaLiquidity, true);

        // Update the pool state if liquidity is within the current pool's slot.
        // Update the pool state if liquidity is within the current pool's slot.
        HyperPool storage pool = _pools[poolId];
        if (hiTick > pool.lastTick) {
            // note: need to check also greater than lower tick?
            pool.liquidity += deltaLiquidity;
            pool.blockTimestamp = _blockTimestamp();
        }

        // Todo: update bitmap of instantiated slots.

        _increasePosition(poolId, loTick, hiTick, deltaLiquidity);

        // note: Global reserves are used at the end of instruction processing to settle transactions.
        uint16 pairId = uint16(poolId >> 32);
        Pair memory pair = _pairs[pairId];
        _increaseGlobal(pair.tokenBase, deltaR2);
        _increaseGlobal(pair.tokenQuote, deltaR1);

        emit AddLiquidity(poolId, pairId, deltaR2, deltaR1, deltaLiquidity);
    }

    /**
     * @notice Updates the liquidity of a slot, and returns a bool to reflect whether its instantiation state was changed.
     */
    function _increaseSlotLiquidity(
        uint48 poolId,
        int24 tick,
        uint256 deltaLiquidity,
        bool hi
    ) internal returns (bool alterState) {
        HyperSlot storage slot = _slots[poolId][tick];

        uint256 prevLiquidity = slot.totalLiquidity;
        uint256 nextLiquidity = slot.totalLiquidity + deltaLiquidity;

        alterState = (prevLiquidity == 0 && nextLiquidity != 0); // If the liquidity started at zero but was altered.

        slot.totalLiquidity = nextLiquidity;
        if (alterState) slot.instantiated = !slot.instantiated;

        // If a slot is exited and is on the upper bound of the range, there is a "loss" of liquidity to the next slot.
        if (hi) slot.liquidityDelta -= int256(deltaLiquidity);
        else slot.liquidityDelta += int256(deltaLiquidity);
    }

    function _stakePosition(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint48 poolId_, uint96 positionId) = Instructions.decodeStakePosition(data);
        poolId = poolId_;

        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        HyperPosition storage pos = _positions[msg.sender][positionId];
        if (pos.stakeEpochId != 0) revert PositionStakedError(positionId);
        if (pos.totalLiquidity == 0) revert PositionZeroLiquidityError(positionId);

        HyperSlot storage loSlot = _slots[poolId_][pos.loTick];
        HyperSlot storage hiSlot = _slots[poolId_][pos.hiTick];

        // todo: check if slots need to be updated for epoch transition

        // add staked delta to lo tick, remove from hi tick for next epoch
        loSlot.epochStakedLiquidityDelta += int256(pos.totalLiquidity);
        hiSlot.epochStakedLiquidityDelta -= int256(pos.totalLiquidity);

        HyperPool storage pool = _pools[poolId_];
        if (pos.loTick <= pool.lastTick && pos.hiTick > pool.lastTick) {
            // if position's liquidity is in range, add to next epoch's delta
            pool.epochStakedLiquidityDelta += int256(pos.totalLiquidity);
        }

        Epoch storage epoch = _epochs[poolId_];
        pos.stakeEpochId = epoch.id + 1;

        // note: do we need to update position blockTimestamp?

        // emit Stake Position
    }

    function _unstakePosition(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint48 poolId_, uint96 positionId) = Instructions.decodeUnstakePosition(data);
        poolId = poolId_;

        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        HyperPosition storage pos = _positions[msg.sender][positionId];
        if (pos.stakeEpochId == 0 || pos.unstakeEpochId != 0) revert PositionNotStakedError(positionId);

        HyperSlot storage loSlot = _slots[poolId_][pos.loTick];
        HyperSlot storage hiSlot = _slots[poolId_][pos.hiTick];

        // todo: check if slots need to be updated for epoch transition

        // remove staked delta from lo tick, add to hi tick for next epoch
        loSlot.epochStakedLiquidityDelta -= int256(pos.totalLiquidity);
        hiSlot.epochStakedLiquidityDelta += int256(pos.totalLiquidity);

        HyperPool storage pool = _pools[poolId_];
        if (pos.loTick <= pool.lastTick && pos.hiTick > pool.lastTick) {
            // if position's liquidity is in range, add to next epoch's delta
            pool.epochStakedLiquidityDelta -= int256(pos.totalLiquidity);
        }

        Epoch storage epoch = _epochs[poolId_];
        pos.unstakeEpochId = epoch.id + 1;

        // note: do we need to update position blockTimestamp?

        // emit Unstake Position
    }

    /**
     * @notice Updates the liquidity of a slot, and returns a bool to reflect whether its instantiation state was changed.
     */
    function _decreaseSlotLiquidity(
        uint48 poolId,
        int24 tick,
        uint256 deltaLiquidity,
        bool hi
    ) internal returns (bool alterState) {
        HyperSlot storage slot = _slots[poolId][tick];

        uint256 prevLiquidity = slot.totalLiquidity;
        uint256 nextLiquidity = slot.totalLiquidity - deltaLiquidity;

        alterState = (prevLiquidity == 0 && nextLiquidity != 0) || (prevLiquidity != 0 && nextLiquidity == 0); // If there was liquidity previously and all of it was removed.

        slot.totalLiquidity = nextLiquidity;
        if (alterState) slot.instantiated = !slot.instantiated;

        // Update liquidity deltas depending on the changed amount.
        if (hi) slot.liquidityDelta += int256(deltaLiquidity);
        else slot.liquidityDelta -= int256(deltaLiquidity);
    }

    /**
     * @notice Uses a pair and curve to instantiate a pool at a price.
     *
     * @custom:reverts If price is 0.
     * @custom:reverts If pool with pair and curve has already been created.
     * @custom:reverts If an expiring pool and the current timestamp is beyond the pool's maturity parameter.
     */
    function _createPool(bytes calldata data) internal returns (uint48 poolId) {
        (uint48 poolId_, uint16 pairId, uint32 curveId, uint128 price) = Instructions.decodeCreatePool(data);

        if (price == 0) revert ZeroPrice();

        // Zero id values are magic variables, since no curve or pair can have an id of zero.
        if (pairId == 0) pairId = uint16(_pairNonce);
        if (curveId == 0) curveId = uint32(_curveNonce);
        poolId = uint48(bytes6(abi.encodePacked(pairId, curveId)));
        if (_doesPoolExist(poolId)) revert PoolExists();

        Curve memory curve = _curves[curveId];
        (uint128 strike, uint48 maturity, uint24 sigma) = (curve.strike, curve.maturity, curve.sigma);

        bool perpetual;
        assembly {
            perpetual := iszero(or(strike, or(maturity, sigma))) // Equal to (strike | maturity | sigma) == 0, which returns true if all three values are zero.
        }

        uint128 timestamp = _blockTimestamp();
        if (!perpetual && timestamp > curve.maturity) revert PoolExpiredError();

        // Write the epoch data
        _epochs[poolId] = Epoch({id: 0, endTime: timestamp + EPOCH_INTERVAL, interval: EPOCH_INTERVAL});

        // Write the pool to state with the desired price.
        _pools[poolId].lastPrice = price;
        _pools[poolId].lastTick = HyperSwapLib.computeTickWithPrice(price); // todo: implement slot and price grid.
        _pools[poolId].blockTimestamp = timestamp;

        emit CreatePool(poolId, pairId, curveId, price);
    }

    /**
     * @notice Maps a nonce to a set of curve parameters, strike, sigma, fee, priority fee, and maturity.
     * @dev Curves are used to create pools.
     * It's possible to make a perpetual pool, by only specifying the fee parameters.
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

        curveId = _getCurveIds[rawCurveId]; // Gets the nonce of this raw curve, if it was created already.
        if (curveId != 0) revert CurveExists(curveId);

        if (!isBetween(fee, MIN_POOL_FEE, MAX_POOL_FEE)) revert FeeOOB(fee);
        if (!isBetween(priorityFee, MIN_POOL_FEE, fee)) revert PriorityFeeOOB(priorityFee);

        bool perpetual;
        assembly {
            perpetual := iszero(or(strike, or(maturity, sigma))) // Equal to (strike | maturity | sigma) == 0, which returns true if all three values are zero.
        }

        if (!perpetual && sigma == 0) revert MinSigma(sigma);
        if (!perpetual && strike == 0) revert MinStrike(strike);

        unchecked {
            curveId = uint32(++_curveNonce); // note: Unlikely to reach this limit.
        }

        uint32 gamma = uint32(HyperSwapLib.UNIT_PERCENT - fee); // gamma = 100% - fee %.
        uint32 priorityGamma = uint32(HyperSwapLib.UNIT_PERCENT - priorityFee); // priorityGamma = 100% - priorityFee %.

        // Writes the curve to state with a reverse lookup.
        _curves[curveId] = Curve({
            strike: strike,
            sigma: sigma,
            maturity: maturity,
            gamma: gamma,
            priorityGamma: priorityGamma
        });
        _getCurveIds[rawCurveId] = curveId;

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

        pairId = _getPairId[asset][quote];
        if (pairId != 0) revert PairExists(pairId);

        (uint8 assetDecimals, uint8 quoteDecimals) = (IERC20(asset).decimals(), IERC20(quote).decimals());

        if (!_isValidDecimals(assetDecimals)) revert DecimalsError(assetDecimals);
        if (!_isValidDecimals(quoteDecimals)) revert DecimalsError(quoteDecimals);

        unchecked {
            pairId = uint16(++_pairNonce); // Increments the pair nonce, returning the nonce for this pair.
        }

        // Writes the pairId into a fetchable mapping using its tokens.
        _getPairId[asset][quote] = pairId; // note: No reverse lookup, because order matters!

        // Writes the pair into Enigma state.
        _pairs[pairId] = Pair({
            tokenBase: asset,
            decimalsBase: assetDecimals,
            tokenQuote: quote,
            decimalsQuote: quoteDecimals
        });

        emit CreatePair(pairId, asset, quote);
    }

    // --- General Utils --- //

    function _doesPoolExist(uint48 poolId) internal view returns (bool exists) {
        exists = _pools[poolId].blockTimestamp != 0;
    }

    function _isValidDecimals(uint8 decimals) internal pure returns (bool valid) {
        valid = isBetween(decimals, MIN_DECIMALS, MAX_DECIMALS);
    }

    // --- Receive ETH fallback --- //

    // Note: Not sure if we should always revert when receiving ETH
    receive() external payable {
        revert();
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

    // --- Private --- //

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

    // --- Internal --- //

    /// @dev A positive credit is a receivable paid to the `msg.sender` internal balance.
    ///      Positive credits are only applied to the internal balance of the account.
    ///      Therefore, it does not require a state change for the global reserves.
    /// @custom:security Critical. Only method which credits accounts with tokens.
    function _applyCredit(address token, uint256 amount) internal {
        _balances[msg.sender][token] += amount;
        emit Credit(token, amount);
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
        if (_balances[msg.sender][token] >= amount) _balances[msg.sender][token] -= amount;
        else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
        emit Debit(token, amount);
    }

    /// @notice Single instruction processor that will forward instruction to appropriate function.
    /// @dev Critical: Every token of every pair interacted with is cached to be settled later.
    /// @param data Encoded Enigma data. First byte must be an Enigma instruction.
    /// @custom:security Critical. Directly sends instructions to be executed.
    function _process(bytes calldata data) internal {
        uint48 poolId;
        bytes1 instruction = bytes1(data[0] & 0x0f);
        if (instruction == Instructions.UNKNOWN) revert UnknownInstruction();

        if (instruction == Instructions.ADD_LIQUIDITY) {
            (poolId, ) = _addLiquidity(data);
        } else if (instruction == Instructions.REMOVE_LIQUIDITY) {
            (poolId, , ) = _removeLiquidity(data);
        } else if (instruction == Instructions.SWAP) {
            (poolId, , , ) = _swapExactForExact(data);
        } else if (instruction == Instructions.STAKE_POSITION) {
            (poolId, ) = _stakePosition(data);
        } else if (instruction == Instructions.UNSTAKE_POSITION) {
            (poolId, ) = _unstakePosition(data);
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
            Pair memory pair = _pairs[pairId]; // note: pairIds start at 1 because nonce is incremented first.
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
            Pair memory pair = _pairs[pairId];
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
        if (token == WETH && msg.value > 0) _wrap();

        uint256 global = _globalReserves[token];
        uint256 actual = _balanceOf(token, address(this));
        if (global > actual) {
            uint256 deficit = global - actual;
            _applyDebit(token, deficit);
        } else {
            uint256 surplus = actual - global;
            _applyCredit(token, surplus);
        }

        _cacheAddress(token, false); // note: Effectively saying "any pool with this token was paid for in full".
    }

    // --- External --- //

    /// @inheritdoc IEnigmaActions
    function draw(
        address token,
        uint256 amount,
        address to
    ) external lock {
        // note: Would pull tokens without this conditional check.
        if (_balances[msg.sender][token] < amount) revert DrawBalance();
        _applyDebit(token, amount);

        if (token == WETH) _dangerousUnwrap(to, amount);
        else SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    /// @inheritdoc IEnigmaActions
    function fund(address token, uint256 amount) external payable override lock {
        _applyCredit(token, amount);
        if (token == WETH) _wrap();
        else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
    }

    // --- View --- //

    // todo: check for hash collisions with instruction calldata and fix.

    function slots(uint48 poolId, int24 slot) external view returns (HyperSlot memory) {
        return _slots[poolId][slot];
    }

    function pairs(uint16 pairId) external view override returns (Pair memory p) {
        p = _pairs[pairId];
    }

    function curves(uint32 curveId) external view override returns (Curve memory c) {
        c = _curves[curveId];
    }

    function pools(uint48 poolId) external view override returns (HyperPool memory p) {
        p = _pools[poolId];
    }

    function reserves(address asset) external view override returns (uint256) {
        return _globalReserves[asset];
    }

    function getCurveId(bytes32 packedCurve) external view override returns (uint32) {
        return _getCurveIds[packedCurve];
    }

    function getCurveNonce() external view override returns (uint256) {
        return _curveNonce;
    }

    function getPairNonce() external view override returns (uint256) {
        return _pairNonce;
    }

    function getPairId(address asset, address quote) external view returns (uint256) {
        return _getPairId[asset][quote];
    }

    function checkJitLiquidity(
        address,
        uint48,
        int24,
        int24
    ) external view override returns (uint256 distance, uint256 timestamp) {}

    function getLiquidityMinted(
        uint48 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) external view returns (uint256 deltaLiquidity) {}

    function getInvariant(uint48 poolId) external view returns (int128 invariant) {}

    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        external
        view
        returns (uint256 deltaBase, uint256 deltaQuote)
    {}

    function updateLastTimestamp(uint48) external override returns (uint128 blockTimestamp) {}
}
