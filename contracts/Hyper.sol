// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/**

  ------------------------------------

  Hyper is a replicating market maker.

  ------------------------------------

  Primitive™

 */

import "./HyperLib.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IHyper.sol";
import "./interfaces/IERC20.sol";

contract Hyper is IHyper {
    using Price for Price.RMM;
    using SafeCastLib for uint;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    using {Assembly.isBetween} for uint8;
    using {Assembly.scaleFromWadDownSigned} for int;
    using {Assembly.scaleFromWadDown, Assembly.scaleFromWadUp, Assembly.scaleToWad} for uint;

    function VERSION() public pure returns (string memory) {
        assembly {
            // Load 0x20 (32) in memory at slot 0x00, this corresponds to the
            // offset location of the next data.
            mstore(0x00, 0x20)

            // Then we load both the length of our string (11 bytes, 0x0b in hex) and its
            // actual hex value (0x626574612d76302e312e30) using the offset 0x2b. Using this
            // particular offset value will right pad the length at the end of the slot
            // and left pad the string at the beginning of the next slot, assuring the
            // right ABI format to return a string.
            mstore(0x2b, 0x0b626574612d76302e312e30) // "beta-v0.1.0"

            // Return all the 96 bytes (0x60) of data that was loaded into the memory.
            return(0x00, 0x60)
        }
    }

    OS.AccountSystem public __account__;

    address public immutable WETH;
    uint24 public getPairNonce;
    uint32 public getPoolNonce;

    mapping(uint24 => HyperPair) public pairs;
    mapping(uint64 => HyperPool) public pools;
    mapping(address => mapping(address => uint24)) public getPairId;
    mapping(address => mapping(uint64 => HyperPosition)) public positions;

    uint256 public locked = 1;
    Payment[] private _payments;
    SwapState private _state;

    modifier lock() {
        if (locked != 1) revert InvalidReentrancy();

        locked = 2;
        _;
        locked = 1;
    }

    /**
     * @dev
     * Used on external functions to handle settlement of outstanding token balances.
     *
     * @notice
     * Tokens sent to this contract are lost.
     *
     * @custom:guide
     * Step 1. Enter `locked` re-entrancy guard.
     * Step 2. Validate Hyper's account system has not already been entered.
     * Step 3. Wrap the entire ether balance of this contract and credit the wrapped ether to the msg.sender account.
     * Step 4. Enter the re-entrancy guard of Hyper's account system.
     * Step 5. Execute the function logic.
     * Step 6. Exit the re-entrancy guard of Hyper's account system.
     * Step 7. Enter the settlement function, requesting token payments or sending them out to msg.sender.
     * Step 8. Validate Hyper's account system was settled.
     * Step 9. Exit interactions modifier.
     * Step 10. Exit `locked` re-entrancy guard.
     */
    modifier interactions() {
        if (__account__.prepared) revert InvalidReentrancy();
        __account__.__wrapEther__(WETH); // Deposits msg.value ether, this contract receives WETH.
        __account__.prepared = false;
        _;
        __account__.prepared = true;

        _settlement();

        if (!__account__.settled) revert InvalidSettlement();
    }

    /**
     * @dev
     * Failing to pass a valid WETH contract that implements the `deposit()` function,
     * will cause all transactions with Hyper to fail once address(this).balance > 0.
     *
     * @notice
     * Tokens sent to this contract are lost.
     */
    constructor(address weth) {
        WETH = weth;
        __account__.settled = true;
    }

    receive() external payable {
        if (msg.sender != WETH) revert();
    }

    /**  @dev Alternative entrypoint to process operations using encoded calldata transferred directly as `msg.data`. */
    fallback() external payable lock interactions {
        Enigma.__startProcess__(_process);
    }

    /** @dev balanceOf(token) - getReserve(token). If negative, you win. */
    function getNetBalance(address token) public view returns (int256) {
        return __account__.getNetBalance(token, address(this));
    }

    /** @dev Virtual balance of `token`. */
    function getReserve(address token) public view returns (uint) {
        return __account__.reserves[token];
    }

    /** @dev Internal balance of `owner` of `token`. */
    function getBalance(address owner, address token) public view returns (uint) {
        return __account__.balances[owner][token];
    }

    /** @dev Transient stored tokens */
    function getWarm() public view returns (address[] memory warm) {
        return __account__.warm;
    }

    // ===== Actions ===== //

    /// @inheritdoc IHyperActions
    function allocate(
        uint64 poolId,
        uint amount
    ) external lock interactions returns (uint deltaAsset, uint deltaQuote) {
        bool useMax = amount == type(uint).max;
        (deltaAsset, deltaQuote) = _allocate(useMax, poolId, (useMax ? 1 : amount).safeCastTo128());
    }

    /// @inheritdoc IHyperActions
    function unallocate(
        uint64 poolId,
        uint amount
    ) external lock interactions returns (uint deltaAsset, uint deltaQuote) {
        bool useMax = amount == type(uint).max;
        (deltaAsset, deltaQuote) = _unallocate(useMax, poolId, (useMax ? 1 : amount).safeCastTo128());
    }

    /// @inheritdoc IHyperActions
    function stake(uint64 poolId, uint128 deltaLiquidity) external lock interactions {
        _stake(poolId, deltaLiquidity);
    }

    /// @inheritdoc IHyperActions
    function unstake(uint64 poolId, uint128 deltaLiquidity) external lock interactions {
        _unstake(poolId, deltaLiquidity);
    }

    /// @inheritdoc IHyperActions
    function swap(
        uint64 poolId,
        bool sellAsset,
        uint amount,
        uint limit
    ) external lock interactions returns (uint output, uint remainder) {
        if (limit == type(uint256).max) limit = type(uint128).max;
        bool useMax = amount == type(uint256).max; // magic variable.
        uint128 input = useMax ? type(uint128).max : amount.safeCastTo128();
        (, remainder, , output) = _swapExactIn(
            Order({
                useMax: useMax ? 1 : 0,
                poolId: poolId,
                input: input,
                output: limit.safeCastTo128(),
                direction: sellAsset ? 0 : 1
            })
        );
    }

    /// @inheritdoc IHyperActions
    function draw(address token, uint256 amount, address to) external lock interactions {
        if (to == address(this)) revert InvalidTransfer(); // todo: Investigate attack vectors if this was not here.
        if (amount > getBalance(msg.sender, token)) revert DrawBalance();

        _applyDebit(token, amount);
        _decreaseReserves(token, amount);

        if (token == WETH) OS.__dangerousUnwrapEther__(WETH, to, amount);
        else OS.SafeTransferLib.safeTransfer(OS.ERC20(token), to, amount);
    }

    /// @inheritdoc IHyperActions
    function fund(address token, uint256 amount) external override lock interactions {
        __account__.dangerousFund(token, address(this), amount); // transferFrom(msg.sender)
    }

    /// @inheritdoc IHyperActions
    function deposit() external payable override lock interactions {
        if (msg.value == 0) revert ZeroValue();
        emit Deposit(msg.sender, msg.value);
        // interactions modifier does the work.
    }

    function claim(uint64 poolId, uint deltaAsset, uint deltaQuote) external lock interactions {
        HyperPool memory pool = pools[poolId];
        HyperPosition storage pos = positions[msg.sender][poolId];
        if (pos.lastTimestamp == 0) revert NonExistentPosition(msg.sender, poolId);

        uint256 positionLiquidity = pos.freeLiquidity + pos.stakedLiquidity;
        pos.syncPositionFees(positionLiquidity, pool.feeGrowthGlobalAsset, pool.feeGrowthGlobalQuote);

        // 2^256 is a magic variable to claim the maximum amount of owed tokens after it has been synced.
        uint256 claimedAssets = deltaAsset == type(uint256).max ? pos.tokensOwedAsset : deltaAsset;
        uint256 claimedQuotes = deltaQuote == type(uint256).max ? pos.tokensOwedQuote : deltaQuote;

        pos.tokensOwedAsset -= claimedAssets.safeCastTo128();
        pos.tokensOwedQuote -= claimedQuotes.safeCastTo128();

        if (claimedAssets > 0) _applyCredit(pool.pair.tokenAsset, claimedAssets);
        if (claimedQuotes > 0) _applyCredit(pool.pair.tokenQuote, claimedQuotes);

        pos.syncPositionStakedFees(pool.stakedLiquidity, pool.feeGrowthGlobalReward);
        uint128 deltaReward = pos.tokensOwedReward;
        pos.tokensOwedReward -= deltaReward;

        // todo: a hack that utilizes Hyper contract as a fee bucket for priority swaps.
        // Currently uses WETH as the reward token. However, these priority fees
        // are paid based on liquidity.
        // If 1 WAD of liquidity is worth a small amount, the priority fee cost
        // a lot relative to the liquidity's value.
        // A better change is making this reward token configurable.
        if (deltaReward > 0) {
            _applyCredit(WETH, deltaReward); // gift to `msg.sender`.
            if (getBalance(address(this), WETH) < deltaReward) revert InvalidReward();
            __account__.debit(address(this), WETH, deltaReward); // only place hyper's balance is used
        }

        emit Collect(
            poolId,
            msg.sender,
            claimedAssets,
            pool.pair.tokenAsset,
            claimedQuotes,
            pool.pair.tokenQuote,
            deltaReward,
            WETH
        );
    }

    // ===== Effects ===== //

    /** @dev Increases virtal reserves and liquidity. Debits `msg.sender`. */
    function _allocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity
    ) internal returns (uint256 deltaAsset, uint256 deltaQuote) {
        HyperPool memory pool = pools[poolId];
        if (!pool.exists()) revert NonExistentPool(poolId);

        if (useMax) {
            deltaLiquidity = pool.getMaxLiquidity({
                deltaAsset: getBalance(msg.sender, pool.pair.tokenAsset),
                deltaQuote: getBalance(msg.sender, pool.pair.tokenQuote)
            });
        }

        if (deltaLiquidity == 0) revert ZeroLiquidity();
        (deltaAsset, deltaQuote) = pool.getLiquidityDeltas(toInt128(deltaLiquidity)); // note: rounds up.

        ChangeLiquidityParams memory args = ChangeLiquidityParams({
            owner: msg.sender,
            poolId: poolId,
            timestamp: _blockTimestamp(),
            deltaAsset: deltaAsset,
            deltaQuote: deltaQuote,
            tokenAsset: pool.pair.tokenAsset,
            tokenQuote: pool.pair.tokenQuote,
            deltaLiquidity: toInt128(deltaLiquidity)
        });

        _changeLiquidity(args);
        emit Allocate(poolId, pool.pair.tokenAsset, pool.pair.tokenQuote, deltaAsset, deltaQuote, deltaLiquidity);
    }

    /** @dev Reduces virtual reserves and liquidity. Credits `msg.sender`. */
    function _unallocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity
    ) internal returns (uint deltaAsset, uint deltaQuote) {
        if (useMax) deltaLiquidity = positions[msg.sender][poolId].freeLiquidity;
        if (deltaLiquidity == 0) revert ZeroLiquidity();

        HyperPool memory pool = pools[poolId];
        if (!pool.exists()) revert NonExistentPool(poolId);

        (deltaAsset, deltaQuote) = pool.getLiquidityDeltas(-toInt128(deltaLiquidity)); // rounds down

        ChangeLiquidityParams memory args = ChangeLiquidityParams({
            owner: msg.sender,
            poolId: poolId,
            timestamp: _blockTimestamp(),
            deltaAsset: deltaAsset,
            deltaQuote: deltaQuote,
            tokenAsset: pool.pair.tokenAsset,
            tokenQuote: pool.pair.tokenQuote,
            deltaLiquidity: -toInt128(deltaLiquidity)
        });

        _changeLiquidity(args);
        emit Unallocate(poolId, pool.pair.tokenAsset, pool.pair.tokenQuote, deltaAsset, deltaQuote, deltaLiquidity);
    }

    function _changeLiquidity(ChangeLiquidityParams memory args) internal returns (uint feeAsset, uint feeQuote) {
        (HyperPool storage pool, HyperPosition storage pos) = (pools[args.poolId], positions[args.owner][args.poolId]);

        // Positions are broken up into "free" and "staked" liquidity buckets.
        // The pool accrues fees to the sum of these buckets, so the same fees are earned
        // for a position with 2 free and 0 staked as a position with 1 free and 1 staked.
        // The purpose for staking is to access a new fee bucket, the "reward", in addition
        // to the standard bucket.
        uint256 positionLiquidity = pos.freeLiquidity + pos.stakedLiquidity;
        (feeAsset, feeQuote) = pos.syncPositionFees(
            positionLiquidity,
            pool.feeGrowthGlobalAsset,
            pool.feeGrowthGlobalQuote
        );

        _changePosition(args);
    }

    /** @dev Changes position liquidity and timestamp. */
    function _changePosition(ChangeLiquidityParams memory args) internal {
        HyperPosition storage position = positions[args.owner][args.poolId];

        if (args.deltaLiquidity < 0) {
            uint distance = position.getTimeSinceChanged(_blockTimestamp());
            if (pools[args.poolId].params.jit > distance) revert JitLiquidity(distance);
        }

        position.changePositionLiquidity(args.timestamp, args.deltaLiquidity);

        _changePool(args);
    }

    /** @dev Changes virtual reserves and pool liquidity. Does not update timestamp of pool. */
    function _changePool(ChangeLiquidityParams memory args) internal {
        (address asset, address quote) = (args.tokenAsset, args.tokenQuote);

        pools[args.poolId].changePoolLiquidity(args.deltaLiquidity);

        if (args.deltaLiquidity < 0) {
            _decreaseReserves(asset, args.deltaAsset);
            _decreaseReserves(quote, args.deltaQuote);
        } else {
            // note: Reserves are used at the end of instruction processing to interactions transactions.
            _increaseReserves(asset, args.deltaAsset);
            _increaseReserves(quote, args.deltaQuote);
        }
    }

    function _stake(uint64 poolId, uint128 deltaLiquidity) internal {
        HyperPool storage pool = pools[poolId];
        if (!pool.exists()) revert NonExistentPool(poolId);

        HyperPosition memory pos = positions[msg.sender][poolId];
        if (deltaLiquidity == 0) revert ZeroLiquidity();
        if (pos.freeLiquidity < deltaLiquidity) revert InsufficientPosition(poolId);

        uint feeEarned = _changeStake(poolId, toInt128(deltaLiquidity));
        pool.stakedLiquidityDelta += toInt128(deltaLiquidity);
        emit Stake(poolId, msg.sender, deltaLiquidity);
    }

    function _unstake(uint64 poolId, uint128 deltaLiquidity) internal returns (uint feeEarned) {
        HyperPool storage pool = pools[poolId];
        if (!pool.exists()) revert NonExistentPool(poolId);

        uint timestamp = _blockTimestamp();
        HyperPosition memory pos = positions[msg.sender][poolId];
        if (pos.stakeTimestamp == 0) revert PositionNotStaked(poolId);
        if (pos.unstakeTimestamp > timestamp) revert StakeNotMature(poolId); // todo: Investigate if its okay to unstake whenever.

        feeEarned = _changeStake(poolId, -toInt128(deltaLiquidity));
        pool.stakedLiquidityDelta -= toInt128(deltaLiquidity);
        emit Unstake(poolId, msg.sender, deltaLiquidity);
    }

    function _changeStake(uint64 poolId, int128 deltaLiquidity) internal returns (uint feeEarned) {
        uint timestamp = _blockTimestamp();
        HyperPool memory pool = pools[poolId];
        HyperPosition storage pos = positions[msg.sender][poolId];
        if (pos.stakeTimestamp == 0) pos.stakeTimestamp = timestamp.safeCastTo32();
        if (pos.unstakeTimestamp == 0) pos.unstakeTimestamp = pool.params.maturity();

        feeEarned = pos.syncPositionStakedFees(pool.stakedLiquidity, pool.feeGrowthGlobalReward); // must apply before liquidity changes.
        pos.changePositionLiquidity(timestamp, -deltaLiquidity);
        pos.stakedLiquidity = Assembly.addSignedDelta(pos.stakedLiquidity, deltaLiquidity);
    }

    // ===== Swaps ===== //

    function _swapExactIn(
        Order memory args
    ) internal returns (uint64 poolId, uint256 remainder, uint256 input, uint256 output) {
        if (args.input == 0) revert ZeroInput();

        uint limitPrice = args.output;
        bool sellAsset = args.direction == 0;

        HyperPool memory pool = pools[args.poolId];
        if (args.useMax == 0) {
            input = args.input;
        } else {
            address tokenInput = sellAsset ? pool.pair.tokenAsset : pool.pair.tokenQuote;
            input = getBalance(msg.sender, tokenInput);
        }

        uint256 passed = getTimePassed(args.poolId);
        (output, ) = pool.getAmountOut(sellAsset, input, passed);

        args.input = input.safeCastTo128();
        args.output = output.safeCastTo128();

        (poolId, remainder, input, output) = _swap(args);

        uint nextPrice = pools[args.poolId].lastPrice;
        if (!sellAsset && nextPrice > limitPrice) revert SwapLimitReached();
        if (sellAsset && limitPrice > nextPrice) revert SwapLimitReached();
    }

    /** @dev Swaps in direction (0 or 1) input of tokens (0 = asset, 1 = quote) for output of tokens (0 = quote, 1 = asset). */
    function _swap(
        Order memory args
    ) internal returns (uint64 poolId, uint256 remainder, uint256 input, uint256 output) {
        if (args.input == 0) revert ZeroInput();

        HyperPool storage pool = pools[args.poolId];
        if (!pool.exists()) revert NonExistentPool(args.poolId);

        _state.sell = args.direction == 0; // 0: asset -> quote, 1: quote -> asset
        _state.fee = msg.sender == pool.controller ? pool.params.priorityFee : uint(pool.params.fee);
        _state.feeGrowthGlobal = _state.sell ? pool.feeGrowthGlobalAsset : pool.feeGrowthGlobalQuote;
        _state.tokenInput = _state.sell ? pool.pair.tokenAsset : pool.pair.tokenQuote;
        _state.tokenOutput = _state.sell ? pool.pair.tokenQuote : pool.pair.tokenAsset;

        Price.RMM memory rmm = Price.RMM({strike: pool.params.strike(), sigma: pool.params.volatility, tau: 0});
        Iteration memory _swap;
        {
            (uint256 price, int24 tick, uint updatedTau) = _computeSyncedPrice(args.poolId);
            rmm.tau = updatedTau;

            uint internalBalance = getBalance(msg.sender, _state.sell ? pool.pair.tokenAsset : pool.pair.tokenQuote);
            remainder = args.useMax == 1 ? internalBalance : args.input;
            remainder = remainder.scaleToWad(_state.sell ? pool.pair.decimalsAsset : pool.pair.decimalsQuote);
            output = args.output;
            output = output.scaleToWad(_state.sell ? pool.pair.decimalsQuote : pool.pair.decimalsAsset);

            // Keeps WAD values
            _swap = Iteration({
                price: price,
                tick: tick,
                feeAmount: 0,
                remainder: remainder,
                liquidity: pool.liquidity,
                input: 0,
                output: output
            });
        }

        if (rmm.tau == 0) revert PoolExpired();
        if (_swap.output == 0) revert ZeroOutput();
        if (_swap.remainder == 0) revert ZeroInput();
        if (_swap.liquidity == 0) revert ZeroLiquidity();

        // =---= Effects =---= //

        // These are WAD values.
        uint256 liveIndependent;
        uint256 nextIndependent;
        uint256 liveDependent;
        uint256 nextDependent;
        uint256 priorityFeeAmount;

        {
            uint256 maxInput;
            uint256 deltaInput;
            uint256 deltaInputLessFee;
            uint256 deltaOutput = _swap.output;

            // Virtual reserves
            if (_state.sell) {
                (liveDependent, liveIndependent) = rmm.computeReserves(_swap.price);
                maxInput = (FixedPointMathLib.WAD - liveIndependent).mulWadDown(_swap.liquidity); // There can be maximum 1:1 ratio between assets and liqudiity.
            } else {
                (liveIndependent, liveDependent) = rmm.computeReserves(_swap.price);
                maxInput = (rmm.strike - liveIndependent).mulWadDown(_swap.liquidity); // There can be maximum strike:1 liquidity ratio between quote and liquidity.
            }

            priorityFeeAmount = msg.sender == pool.controller ? (pool.liquidity * _state.fee) / 10_000 : 0;
            _swap.feeAmount = priorityFeeAmount != 0
                ? 0
                : ((_swap.remainder > maxInput ? maxInput : _swap.remainder) * _state.fee) / 10_000;
            _state.feeGrowthGlobal = FixedPointMathLib.divWadDown(_swap.feeAmount, _swap.liquidity);
            if (priorityFeeAmount != 0) _state.priorityFeeGrowthGlobal = priorityFeeAmount.divWadDown(_swap.liquidity); // todo: change to staked liquidity

            deltaInput = _swap.remainder > maxInput ? maxInput : _swap.remainder; // swaps up to the maximum input
            deltaInputLessFee = deltaInput - _swap.feeAmount;

            nextIndependent = liveIndependent + deltaInputLessFee.divWadDown(_swap.liquidity);
            nextDependent = liveDependent - deltaOutput.divWadDown(_swap.liquidity);

            _swap.remainder -= deltaInput;
            _swap.input += deltaInput;
        }

        {
            uint256 nextPrice;
            int256 liveInvariantWad;
            int256 nextInvariantWad;

            if (_state.sell) {
                liveInvariantWad = rmm.invariantOf(liveDependent, liveIndependent);
                nextInvariantWad = rmm.invariantOf(nextDependent, nextIndependent);
                nextPrice = rmm.getPriceWithX(nextIndependent);
            } else {
                liveInvariantWad = rmm.invariantOf(liveIndependent, liveDependent);
                nextInvariantWad = rmm.invariantOf(nextIndependent, nextDependent);
                nextPrice = rmm.getPriceWithX(nextDependent);
            }

            liveInvariantWad = liveInvariantWad.scaleFromWadDownSigned(pool.pair.decimalsQuote); // invariant is denominated in quote token.
            nextInvariantWad = nextInvariantWad.scaleFromWadDownSigned(pool.pair.decimalsQuote);
            if (nextInvariantWad < liveInvariantWad) revert InvalidInvariant(liveInvariantWad, nextInvariantWad);

            _swap.price = (nextPrice * (0.001 ether + 1)) / 0.001 ether;
        }

        {
            uint inputDec;
            uint outputDec;
            if (_state.sell) {
                inputDec = pool.pair.decimalsAsset;
                outputDec = pool.pair.decimalsQuote;
            } else {
                inputDec = pool.pair.decimalsQuote;
                outputDec = pool.pair.decimalsAsset;
            }

            _swap.input = _swap.input.scaleFromWadDown(inputDec);
            _swap.output = _swap.output.scaleFromWadDown(outputDec);
        }

        // Apply pool effects.
        _syncPool(
            args.poolId,
            Price.computeTickWithPrice(_swap.price),
            _swap.price,
            _swap.liquidity,
            _state.sell ? _state.feeGrowthGlobal : 0,
            _state.sell ? 0 : _state.feeGrowthGlobal,
            _state.priorityFeeGrowthGlobal
        );

        _increaseReserves(_state.tokenInput, _swap.input);
        _decreaseReserves(_state.tokenOutput, _swap.output);

        // Apply reserve effects.
        if (priorityFeeAmount != 0) {
            // Uses hyper's internal balance as a fee bucket for priority swaps.
            // todo: investigate two different pools accruing priority rewards in the same bucket,
            // and if it's possible to "steal" another pool's accrued priority rewards.
            _increaseReserves(WETH, priorityFeeAmount);
            emit IncreaseUserBalance(address(this), WETH, priorityFeeAmount);
            __account__.credit(address(this), WETH, priorityFeeAmount);
        }

        emit Swap(args.poolId, _swap.price, _state.tokenInput, _swap.input, _state.tokenOutput, _swap.output);

        delete _state;
        return (args.poolId, _swap.remainder, _swap.input, _swap.output);
    }

    /**
     * @dev Computes the price of the pool, which changes over time.
     *
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _computeSyncedPrice(uint64 poolId) internal view returns (uint256 price, int24 tick, uint updatedTau) {
        HyperPool memory pool = pools[poolId];
        if (!pool.exists()) revert NonExistentPool(poolId);

        (price, tick, updatedTau) = (pool.lastPrice, pool.lastTick, pool.tau(_blockTimestamp()));

        uint passed = getTimePassed(poolId);
        if (passed > 0) {
            uint256 lastTau = pool.lastTau(); // pool.params.maturity() - pool.lastTimestamp.
            (price, tick) = pool.computePriceChangeWithTime(lastTau, passed);
        }
    }

    /**
     * @dev Effects on a Pool after a successful swap order condition has been met.
     */
    function _syncPool(
        uint64 poolId,
        int24 tick,
        uint256 price,
        uint256 liquidity,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote,
        uint256 feeGrowthGlobalReward
    ) internal returns (uint256 timeDelta) {
        HyperPool storage pool = pools[poolId];

        uint256 timestamp = _blockTimestamp();
        timeDelta = getTimePassed(poolId);

        // todo: better configuration of this value?
        uint requiredTimePassedForStake = 1;
        if (timeDelta >= requiredTimePassedForStake) {
            pool.stakedLiquidity = Assembly.addSignedDelta(pool.stakedLiquidity, pool.stakedLiquidityDelta);
            pool.stakedLiquidityDelta = 0;
        }

        if (pool.lastTick != tick) pool.lastTick = tick;
        if (pool.lastPrice != price) pool.lastPrice = price.safeCastTo128();
        if (pool.liquidity != liquidity) pool.liquidity = liquidity.safeCastTo128();
        if (pool.lastTimestamp != timestamp) pool.syncPoolTimestamp(timestamp);

        pool.feeGrowthGlobalAsset = Assembly.computeCheckpoint(pool.feeGrowthGlobalAsset, feeGrowthGlobalAsset);
        pool.feeGrowthGlobalQuote = Assembly.computeCheckpoint(pool.feeGrowthGlobalQuote, feeGrowthGlobalQuote);
        pool.feeGrowthGlobalReward = Assembly.computeCheckpoint(pool.feeGrowthGlobalReward, feeGrowthGlobalReward);
    }

    // ===== Initializing Pools ===== //

    function _createPair(address asset, address quote) internal returns (uint24 pairId) {
        if (asset == quote) revert SameTokenError();

        pairId = getPairId[asset][quote];
        if (pairId != 0) revert PairExists(pairId);

        (uint8 decimalsAsset, uint8 decimalsQuote) = (IERC20(asset).decimals(), IERC20(quote).decimals());
        if (!decimalsAsset.isBetween(Assembly.MIN_DECIMALS, Assembly.MAX_DECIMALS))
            revert InvalidDecimals(decimalsAsset);
        if (!decimalsQuote.isBetween(Assembly.MIN_DECIMALS, Assembly.MAX_DECIMALS))
            revert InvalidDecimals(decimalsQuote);

        pairId = ++getPairNonce;

        getPairId[asset][quote] = pairId; // note: order of tokens matters!
        pairs[pairId] = HyperPair({
            tokenAsset: asset,
            decimalsAsset: decimalsAsset,
            tokenQuote: quote,
            decimalsQuote: decimalsQuote
        });

        emit CreatePair(pairId, asset, quote, decimalsAsset, decimalsQuote);
    }

    /** @dev If pairId == 0, its a magic variable that uses current pair nonce. */
    function _createPool(
        uint24 pairId,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 vol,
        uint16 dur,
        uint16 jit,
        int24 max,
        uint128 price
    ) internal returns (uint64 poolId) {
        if (price == 0) revert ZeroPrice();

        uint32 timestamp = uint(_blockTimestamp()).safeCastTo32();
        HyperPool memory pool;
        pool.controller = controller;
        pool.lastTimestamp = timestamp;
        pool.lastPrice = price;
        pool.lastTick = Price.computeTickWithPrice(pool.lastPrice);
        bool hasController = pool.controller != address(0);
        if (hasController && priorityFee == 0) revert InvalidFee(priorityFee); // Cannot set priority to 0.

        uint24 pairNonce = pairId == 0 ? getPairNonce : pairId; // magic variable todo: fix, possible to set 0 pairId if getPairNonce is 0
        pool.pair = pairs[pairNonce];

        HyperCurve memory params = HyperCurve({
            maxTick: max,
            jit: hasController ? jit : uint8(_liquidityPolicy()),
            fee: fee,
            duration: dur,
            volatility: vol,
            priorityFee: hasController ? priorityFee : 0, // min fee
            createdAt: timestamp
        });
        params.validateParameters();
        pool.params = params;

        uint32 poolNonce = ++getPoolNonce;

        poolId = Enigma.encodePoolId(pairNonce, hasController, poolNonce);
        if (pools[poolId].exists()) revert PoolExists(); // todo: poolNonce always increments, so this never gets hit, remove

        pools[poolId] = pool; // effect

        emit CreatePool(poolId, hasController, pool.pair.tokenAsset, pool.pair.tokenQuote, price);
    }

    function changeParameters(
        uint64 poolId,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        int24 maxTick
    ) external lock interactions {
        HyperPool storage pool = pools[poolId];
        if (pool.controller != msg.sender) revert NotController();

        HyperCurve memory modified = pool.params;
        if (jit != 0) modified.jit = jit;
        if (maxTick != 0) modified.maxTick = maxTick;
        if (fee != 0) modified.fee = fee;
        if (volatility != 0) modified.volatility = volatility;
        if (duration != 0) modified.duration = duration;
        if (priorityFee != 0) modified.priorityFee = priorityFee;

        pool.changePoolParameters(modified);

        emit ChangeParameters(poolId, priorityFee, fee, volatility, duration, jit, maxTick);
    }

    /** @dev Overridable in tests.  */
    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }

    /** @dev Overridable in tests.  */
    function _liquidityPolicy() internal view virtual returns (uint256) {
        return JUST_IN_TIME_LIQUIDITY_POLICY;
    }

    // ===== Accounting System ===== //
    /**
     * @dev Reserves are an internally tracked amount of tokens that should match the return value of `balanceOf`.
     *
     * @custom:security Directly manipulates reserves.
     */
    function _increaseReserves(address token, uint256 amount) internal {
        __account__.increase(token, amount);
        emit IncreaseReserveBalance(token, amount);
    }

    /**
     * @dev Reserves are an internally tracked amount of tokens that should match the return value of `balanceOf`.
     *
     * @custom:security Directly manipulates reserves.
     * @custom:reverts With `InsufficientReserve` if current reserve balance for `token` iss less than `amount`.
     */
    function _decreaseReserves(address token, uint256 amount) internal {
        __account__.decrease(token, amount);
        emit DecreaseReserveBalance(token, amount);
    }

    /**
     * @dev A positive credit is a receivable paid to the `msg.sender` internal balance.
     *      Positive credits are only applied to the internal balance of the account.
     *      Therefore, it does not require a state change for the global reserves.
     *
     * @custom:security Directly manipulates intrernal balances.
     */
    function _applyCredit(address token, uint256 amount) internal {
        __account__.credit(msg.sender, token, amount);
        emit IncreaseUserBalance(msg.sender, token, amount);
    }

    /**
     * @dev A positive debit is a cost that must be paid for a transaction to be processed.
     *      If a balance exists for the token for the internal balance of `msg.sender`,
     *      it will be used to pay the debit. Else, the contract expects tokens to be transferred in.
     *
     * @custom:security Directly manipulates intrernal balances.
     */
    function _applyDebit(address token, uint256 amount) internal {
        __account__.debit(msg.sender, token, amount);
        emit DecreaseUserBalance(msg.sender, token, amount);
    }

    /**
     * @dev Alternative entrypoint to execute functions.
     * @param data Encoded Enigma data. First byte must be an Enigma instruction.
     */
    function _process(bytes calldata data) internal {
        (, bytes1 instruction) = Assembly.separate(data[0]); // Upper byte is useMax, lower byte is instruction.

        if (instruction == Enigma.ALLOCATE) {
            (uint8 useMax, uint64 poolId, uint128 deltaLiquidity) = Enigma.decodeAllocate(data);
            _allocate(useMax == 1, poolId, deltaLiquidity);
        } else if (instruction == Enigma.UNALLOCATE) {
            (uint8 useMax, uint64 poolId, uint128 deltaLiquidity) = Enigma.decodeUnallocate(data);
            _unallocate(useMax == 1, poolId, deltaLiquidity);
        } else if (instruction == Enigma.SWAP) {
            Order memory args;
            (args.useMax, args.poolId, args.input, args.output, args.direction) = Enigma.decodeSwap(data);
            _swap(args);
        } else if (instruction == Enigma.STAKE_POSITION) {
            (uint64 poolId, uint128 deltaLiquidity) = Enigma.decodeStakePosition(data);
            _stake(poolId, deltaLiquidity);
        } else if (instruction == Enigma.UNSTAKE_POSITION) {
            (uint64 poolId, uint128 deltaLiquidity) = Enigma.decodeUnstakePosition(data);
            _unstake(poolId, deltaLiquidity);
        } else if (instruction == Enigma.CREATE_POOL) {
            (
                uint24 pairId,
                address controller,
                uint16 priorityFee,
                uint16 fee,
                uint16 vol,
                uint16 dur,
                uint16 jit,
                int24 max,
                uint128 price
            ) = Enigma.decodeCreatePool(data);
            _createPool(pairId, controller, priorityFee, fee, vol, dur, jit, max, price);
        } else if (instruction == Enigma.CREATE_PAIR) {
            (address asset, address quote) = Enigma.decodeCreatePair(data);
            _createPair(asset, quote);
        } else {
            revert InvalidInstruction();
        }
    }

    /**

        Be aware of these settlement invariants:

        Invariant 1. Every token that is interacted with is cached and exists.
        Invariant 2. Tokens are removed from cache, and cache is empty by end of settlement.
        Invariant 3. Cached tokens cannot be carried over from previous transactions.
        Invariant 4. Execution does not exit during the loops prematurely.
        Invariant 5. Account `settled` bool is set to true at end of `settlement`.
        Invariant 6. Debits reduce `reserves` of `token`.

     */
    function _settlement() internal {
        if (!__account__.prepared) revert OS.NotPreparedToSettle();

        address[] memory tokens = __account__.warm;
        uint256 loops = tokens.length;
        if (loops == 0) return __account__.reset(); // exit early.

        uint x;
        uint i = loops;
        do {
            // Loop backwards to pop tokens off.
            address token = tokens[i - 1];
            // Apply credits or debits to net balance.
            (uint credited, uint debited, uint remainder) = __account__.settle(token, address(this));
            // Reserves were increased, we paid a debit, therefore need to decrease reserves by `debited` amount.
            if (debited > 0) {
                emit DecreaseUserBalance(msg.sender, token, debited);
                emit DecreaseReserveBalance(token, debited);
            }
            // Reserves were not tracking some tokens, increase the reserves to account for them.
            if (credited > 0) {
                emit IncreaseUserBalance(msg.sender, token, credited);
                emit IncreaseReserveBalance(token, credited);
            }
            // Outstanding amount must be transferred in.
            if (remainder > 0) _payments.push(Payment({token: token, amount: remainder}));
            // Token accounted for.
            __account__.warm.pop();
            unchecked {
                --i;
                ++x;
            }
        } while (i != 0);

        Payment[] memory payments = _payments;

        uint px = payments.length;
        while (px != 0) {
            uint index = px - 1;
            OS.__dangerousTransferFrom__(payments[index].token, address(this), payments[index].amount);
            unchecked {
                --px;
            }
        }

        __account__.reset();
        delete _payments;
    }

    // ===== View ===== //

    /** @dev Can be manipulated. */
    function getLatestPrice(uint64 poolId) public view returns (uint price) {
        (price, , ) = _computeSyncedPrice(poolId);
    }

    function getTimePassed(uint64 poolId) public view returns (uint) {
        return _blockTimestamp() - pools[poolId].lastTimestamp;
    }

    function getVirtualReserves(uint64 poolId) public view override returns (uint128 deltaAsset, uint128 deltaQuote) {
        return pools[poolId].getVirtualReserves();
    }

    function getMaxLiquidity(
        uint64 poolId,
        uint deltaAsset,
        uint deltaQuote
    ) public view override returns (uint128 deltaLiquidity) {
        return pools[poolId].getMaxLiquidity(deltaAsset, deltaQuote);
    }

    function getLiquidityDeltas(
        uint64 poolId,
        int128 deltaLiquidity
    ) public view override returns (uint128 deltaAsset, uint128 deltaQuote) {
        return pools[poolId].getLiquidityDeltas(deltaLiquidity);
    }

    function getAmounts(uint64 poolId) public view override returns (uint256 deltaAsset, uint256 deltaQuote) {
        return pools[poolId].getAmounts();
    }

    function getAmountOut(uint64 poolId, bool sellAsset, uint amountIn) public view returns (uint output) {
        HyperPool memory pool = pools[poolId];
        (output, ) = pool.getAmountOut({
            sellAsset: sellAsset,
            amountIn: amountIn,
            timeSinceUpdate: _blockTimestamp() - pool.lastTimestamp // invariant: should not underflow.
        });
    }
}
