// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                           __----~~~~~~~~~~~------___             //
//       It's a dragon!                           .  .   ~~//====......          __--~ ~~           //
//                                -.            \_|//     |||\\  ~~~~~~::::... /~                   //
//                             ___-==_       _-~o~  \/    |||  \\            _/~~-                  //
//                     __---~~~.==~||\=_    -_--~/_-~|-   |\\   \\        _/~                       //
//                 _-~~     .=~    |  \\-_    '-~7  /-   /  ||    \      /                          //
//               .~       .~       |   \\ -_    /  /-   /   ||      \   /                           //
//              /  ____  /         |     \\ ~-_/  /|- _/   .||       \ /                            //
//              |~~    ~~|--~~~~--_ \     ~==-/   | \~--===~~        .\                             //
//                       '         ~-|      /|    |-~\~~       __--~~                               //
//                                   |-~~-_/ |    |   ~\_   _-~            /\                       //
//                                        /  \     \__   \/~                \__                     //
//                                    _--~ _/ | .-~~____--~-/                  ~~==.                //
//                                   ((->/~   '.|||' -_|    ~~-/ ,              . _||               //
//                                              -_     ~\      ~~---l__i__i__i--~~_/                //
//                                              _-~-__   ~)  \--______________--~~                  //
//                                            //.-~~~-~_--~- |-------~~~~~~~~                       //
//                                                   //.-~~~--\                                     //
//////////////////////////////////////////////////////////////////////////////////////////////////////

import "./EnigmaTypes.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IHyper.sol";
import "./interfaces/IERC20.sol";

import {console} from "forge-std/Test.sol";

/**
 * @title Primitive Hyper.
 */
contract Hyper is IHyper {
    using SafeCastLib for uint;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    using Price for Price.RMM;

    OS.AccountSystem public __account__;

    string public constant VERSION = "beta-v0.0.1";
    address public immutable WETH;

    uint256 private locked = 1;
    uint256 public getPairNonce;
    uint256 public getPoolNonce;

    mapping(uint24 => Pair) public pairs;
    mapping(uint64 => HyperPool) public pools;
    mapping(address => mapping(address => uint24)) public getPairId;
    mapping(address => mapping(uint64 => HyperPosition)) public positions;

    /** @dev Used on every external function and external entrypoint. */
    modifier lock() {
        if (locked != 1) revert InvalidReentrancy();

        locked = 2;
        _;
        locked = 1;
    }

    /** @dev Used on every external operation that touches tokens. */
    modifier interactions() {
        __account__.__wrapEther__(WETH); // Deposits msg.value ether, this contract receives WETH.

        __account__.prepared = false;
        _;
        __account__.prepared = true;

        __account__.settlement(OS.__dangerousTransferFrom__, address(this));

        if (!__account__.settled) revert InvalidSettlement();
    }

    constructor(address weth) {
        WETH = weth;
        __account__.settled = true;
    }

    receive() external payable {
        if (msg.sender != WETH) revert();
    }

    /**  @dev Alternative entrypoint to process operations using encoded calldata transferred directly as `msg.data`. */
    fallback() external payable lock interactions {
        CPU.__startProcess__(_process);
    }

    /** @dev balanceOf(token) - getReserve(token). If negative, you win. */
    function getNetBalance(address token) public view returns (int256) {
        return __account__.getNetBalance(token, address(this));
    }

    /** @dev Internal balance sum of `token`. */
    function getReserve(address token) public view returns (uint) {
        return __account__.reserves[token];
    }

    /** @dev Internal balance of `owner` of `token`. */
    function getBalance(address owner, address token) public view returns (uint) {
        return __account__.balances[owner][token];
    }

    // ===== Actions ===== //

    /// @inheritdoc IHyperActions
    function syncPool(uint64 poolId) external override lock interactions returns (uint128 lastTimestamp) {
        _syncPoolPrice(poolId);
        return _blockTimestamp();
    }

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
    function stake(uint64 poolId) external lock interactions {
        _stake(poolId);
    }

    /// @inheritdoc IHyperActions
    function unstake(uint64 poolId) external lock interactions {
        _unstake(poolId);
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
        Order memory args = Order({
            useMax: useMax ? 1 : 0,
            poolId: poolId,
            input: input,
            limit: limit.safeCastTo128(),
            direction: sellAsset ? 0 : 1
        });
        (, remainder, , output) = _swapExactIn(args);
    }

    /// @inheritdoc IHyperActions
    function draw(address token, uint256 amount, address to) external lock interactions {
        if (amount > getBalance(msg.sender, token)) revert DrawBalance();

        _applyDebit(token, amount);
        _decreaseReserves(token, amount);

        if (token == WETH) OS.__dangerousUnwrapEther__(WETH, to, amount);
        else OS.SafeTransferLib.safeTransfer(OS.ERC20(token), to, amount);
    }

    /// @inheritdoc IHyperActions
    function fund(address token, uint256 amount) external override lock interactions {
        _applyCredit(token, amount);
        __account__.dangerousFund(token, address(this), amount); // Pulls tokens, settlement credits msg.sender.
    }

    /// @inheritdoc IHyperActions
    function deposit() external payable override lock interactions {
        _applyCredit(WETH, msg.value);
        _increaseReserves(WETH, msg.value);
        emit Deposit(msg.sender, msg.value);
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

        Pair memory pair = pairs[CPU.decodePairIdFromPoolId(poolId)];
        if (useMax) {
            deltaLiquidity = pool.getMaxLiquidity(
                getBalance(msg.sender, pair.tokenAsset),
                getBalance(msg.sender, pair.tokenQuote)
            );
        }

        if (deltaLiquidity == 0) revert ZeroLiquidity();
        (deltaAsset, deltaQuote) = pool.getLiquidityDeltas(int128(deltaLiquidity)); // note: rounds up.

        ChangeLiquidityParams memory args = ChangeLiquidityParams(
            msg.sender,
            poolId,
            _blockTimestamp(),
            deltaAsset,
            deltaQuote,
            pair.tokenAsset,
            pair.tokenQuote,
            int128(deltaLiquidity) // TODO: add better type safety for these conversions, or tests to make sure its not an issue.
        );

        _changeLiquidity(args);
        emit Allocate(poolId, pair.tokenAsset, pair.tokenQuote, deltaAsset, deltaQuote, deltaLiquidity);
    }

    function _changeLiquidity(ChangeLiquidityParams memory args) internal returns (uint feeAsset, uint feeQuote) {
        (HyperPool storage pool, HyperPosition storage pos) = (pools[args.poolId], positions[args.owner][args.poolId]);

        (feeAsset, feeQuote) = pos.syncPositionFees(
            pool.liquidity,
            pool.feeGrowthGlobalAsset,
            pool.feeGrowthGlobalQuote
        );

        _changePosition(args);
        if (feeAsset > 0 || feeQuote > 0)
            emit EarnFees(args.owner, args.poolId, feeAsset, args.tokenAsset, feeQuote, args.tokenQuote);
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
        emit ChangePosition(args.owner, args.poolId, args.deltaLiquidity);
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

    /** @dev Reduces virtual reserves and liquidity. Credits `msg.sender`. */
    function _unallocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity
    ) internal returns (uint deltaAsset, uint deltaQuote) {
        if (useMax) deltaLiquidity = positions[msg.sender][poolId].totalLiquidity;
        if (deltaLiquidity == 0) revert ZeroLiquidity();

        HyperPool memory pool = pools[poolId];
        if (!pool.exists()) revert NonExistentPool(poolId);

        (deltaAsset, deltaQuote) = pool.getLiquidityDeltas(-int128(deltaLiquidity)); // rounds down

        Pair memory pair = pairs[CPU.decodePairIdFromPoolId(poolId)];
        ChangeLiquidityParams memory args = ChangeLiquidityParams(
            msg.sender,
            poolId,
            _blockTimestamp(),
            deltaAsset,
            deltaQuote,
            pair.tokenAsset,
            pair.tokenQuote,
            -int128(deltaLiquidity)
        );

        _changeLiquidity(args);
        emit Unallocate(poolId, pair.tokenAsset, pair.tokenQuote, deltaAsset, deltaQuote, deltaLiquidity);
    }

    function _stake(uint64 poolId) internal {
        if (!pools[poolId].exists()) revert NonExistentPool(poolId);

        HyperPosition storage pos = positions[msg.sender][poolId];
        if (pos.stakeTimestamp != 0) revert PositionStaked(poolId);
        if (pos.totalLiquidity == 0) revert PositionZeroLiquidity(poolId);

        HyperPool storage pool = pools[poolId];
        pool.stakedLiquidityDelta += int128(pos.totalLiquidity);

        pos.stakeTimestamp = _blockTimestamp(); // todo: fix

        // note: do we need to update position lastTimestamp?

        // emit Stake Position
    }

    function _unstake(uint64 poolId) internal {
        if (!pools[poolId].exists()) revert NonExistentPool(poolId);

        HyperPosition storage pos = positions[msg.sender][poolId];
        if (pos.stakeTimestamp == 0 || pos.unstakeTimestamp != 0) revert PositionNotStaked(poolId);

        HyperPool storage pool = pools[poolId];
        pool.stakedLiquidityDelta -= int128(pos.totalLiquidity);

        pos.unstakeTimestamp = _blockTimestamp(); // todo: fix

        // note: do we need to update position lastTimestamp?

        // emit Unstake Position
    }

    // ===== Swaps ===== //

    SwapState state;

    /** * @dev Swaps in direction (0 or 1) exact input of tokens (0 = asset, 1 = quote) for output of tokens (0 = quote, 1 = asset) up to limit price. */
    function _swapExactIn(
        Order memory args
    ) internal returns (uint64 poolId, uint256 remainder, uint256 input, uint256 output) {
        if (args.input == 0) revert ZeroInput();

        HyperPool storage pool = pools[args.poolId];
        if (!pool.exists()) revert NonExistentPool(args.poolId);

        state.sell = args.direction == 0; // 0: asset -> quote, 1: quote -> asset
        state.fee = uint(pool.params.fee);
        state.feeGrowthGlobal = state.sell ? pool.feeGrowthGlobalAsset : pool.feeGrowthGlobalQuote;

        Pair memory pair = pairs[CPU.decodePairIdFromPoolId(args.poolId)];
        Iteration memory _swap;
        {
            (uint256 price, int24 tick) = _syncPoolPrice(args.poolId);
            uint internalBalance = getBalance(msg.sender, state.sell ? pair.tokenAsset : pair.tokenQuote);
            remainder = args.useMax == 1 ? internalBalance : args.input;
            remainder = remainder * 10 ** (MAX_DECIMALS - (state.sell ? pair.decimalsAsset : pair.decimalsQuote)); // WAD
            _swap = Iteration({
                price: price,
                tick: tick,
                feeAmount: 0,
                remainder: remainder,
                liquidity: pool.liquidity,
                input: 0,
                output: 0
            });
        }

        Price.RMM memory rmm = Price.RMM({strike: pool.strike(), sigma: pool.params.volatility, tau: pool.lastTau()});
        if (rmm.tau == 0) revert PoolExpired();

        // =---= Effects =---= //

        // These are WAD values.
        uint256 liveIndependent;
        uint256 nextIndependent;
        uint256 liveDependent;
        uint256 nextDependent;

        {
            uint256 maxInput;
            uint256 deltaInput;

            // Virtual reserves
            if (state.sell) {
                (liveDependent, liveIndependent) = rmm.computeReserves(_swap.price);
                maxInput = (FixedPointMathLib.WAD - liveIndependent).mulWadDown(_swap.liquidity); // There can be maximum 1:1 ratio between assets and liqudiity.
            } else {
                (liveIndependent, liveDependent) = rmm.computeReserves(_swap.price);
                maxInput = (rmm.strike - liveIndependent).mulWadDown(_swap.liquidity); // There can be maximum strike:1 liquidity ratio between quote and liquidity.
            }

            _swap.feeAmount = ((_swap.remainder > maxInput ? maxInput : _swap.remainder) * state.fee) / 10_000;
            state.feeGrowthGlobal = FixedPointMathLib.divWadDown(_swap.feeAmount, _swap.liquidity);

            if (_swap.remainder > maxInput) {
                deltaInput = maxInput - _swap.feeAmount;
                nextIndependent = liveIndependent + deltaInput.divWadDown(_swap.liquidity);
                _swap.remainder -= (deltaInput + _swap.feeAmount);
            } else {
                deltaInput = _swap.remainder - _swap.feeAmount;
                nextIndependent = liveIndependent + deltaInput.divWadDown(_swap.liquidity);
                deltaInput = _swap.remainder; // Swap input amount including the fee payment.
                _swap.remainder = 0; // Clear the remainder to zero, as the order has been filled.
            }

            // Compute the output of the swap by computing the difference between the dependent reserves.
            if (state.sell) nextDependent = rmm.computeR1WithR2(nextIndependent);
            else nextDependent = rmm.computeR2WithR1(nextIndependent);

            // Apply swap amounts to swap state.
            _swap.input += deltaInput;
            _swap.output += (liveDependent - nextDependent);
        }

        {
            uint256 nextPrice;
            uint256 limitPrice = args.limit;
            int256 liveInvariant;
            int256 nextInvariant;

            if (state.sell) {
                liveInvariant = rmm.invariant(liveDependent, liveIndependent);
                nextInvariant = rmm.invariant(nextDependent, nextIndependent);
                nextPrice = rmm.computePriceWithR2(nextIndependent);
            } else {
                liveInvariant = rmm.invariant(liveIndependent, liveDependent);
                nextInvariant = rmm.invariant(nextIndependent, nextDependent);
                nextPrice = rmm.computePriceWithR2(nextDependent);
            }

            if (!state.sell && nextPrice > limitPrice) revert SwapLimitReached();
            if (state.sell && limitPrice > nextPrice) revert SwapLimitReached();

            // TODO: figure out invariant stuff, reverse swaps have 1e3 error (invariant goes negative by 1e3 precision)?
            if (nextInvariant < liveInvariant) revert InvalidInvariant(liveInvariant, nextInvariant);

            _swap.price = nextPrice;
        }

        {
            // Scale down amounts from WAD.
            uint inputScale;
            uint outputScale;
            if (state.sell) {
                inputScale = MAX_DECIMALS - pair.decimalsAsset;
                outputScale = MAX_DECIMALS - pair.decimalsQuote;
            } else {
                inputScale = MAX_DECIMALS - pair.decimalsQuote;
                outputScale = MAX_DECIMALS - pair.decimalsAsset;
            }

            _swap.input = _swap.input / (10 ** inputScale);
            _swap.output = _swap.output / (10 ** outputScale);
        }

        // Apply pool effects.
        _syncPool(
            args.poolId,
            Price.computeTickWithPrice(_swap.price),
            _swap.price,
            _swap.liquidity,
            state.sell ? state.feeGrowthGlobal : 0,
            state.sell ? 0 : state.feeGrowthGlobal
        );

        // Apply reserve effects.
        _increaseReserves(pair.tokenAsset, _swap.input);
        _decreaseReserves(pair.tokenQuote, _swap.output);

        (poolId, remainder, input, output) = (args.poolId, _swap.remainder, _swap.input, _swap.output);
        emit Swap(args.poolId, _swap.input, _swap.output, pair.tokenAsset, pair.tokenQuote);
    }

    /**
     * @dev Computes the price of the pool, which changes over time. Syncs pool to new price if enough time has passed.
     *
     * @custom:reverts If pool does not exist.
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _syncPoolPrice(uint64 poolId) internal returns (uint256 price, int24 tick) {
        if (!pools[poolId].exists()) revert NonExistentPool(poolId);

        HyperPool memory pool = pools[poolId];
        (price, tick) = (pool.lastPrice, pool.lastTick);

        uint passed = getTimePassed(poolId);
        if (passed > 0) {
            uint256 tau = pool.lastTau(); // uses pool's last update timestamp.
            (price, tick) = pool.computePriceChangeWithTime(tau, passed);
            _syncPool(poolId, tick, price, pool.liquidity, pool.feeGrowthGlobalAsset, pool.feeGrowthGlobalQuote);
        }
    }

    /**
     * @dev Effects on a Pool after a successful swap order condition has been met.
     *
     * @return timeDelta Amount of time passed since the last update to the pool.
     */
    function _syncPool(
        uint64 poolId,
        int24 tick,
        uint256 price,
        uint256 liquidity,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote
    ) internal returns (uint256 timeDelta) {
        HyperPool storage pool = pools[poolId];

        uint256 timestamp = _blockTimestamp();
        timeDelta = getTimePassed(poolId);
        if (timeDelta > 0) {
            pool.stakedLiquidity = Assembly.addSignedDelta(pool.stakedLiquidity, pool.stakedLiquidityDelta);
            pool.stakedLiquidityDelta = int128(0);
        }

        if (pool.lastTick != tick) pool.lastTick = tick;
        if (pool.lastPrice != price) pool.lastPrice = price.safeCastTo128();
        if (pool.liquidity != liquidity) pool.liquidity = liquidity.safeCastTo128();
        if (pool.lastTimestamp != timestamp) pool.lastTimestamp = uint32(timestamp);

        pool.feeGrowthGlobalAsset = Assembly.computeCheckpoint(pool.feeGrowthGlobalAsset, feeGrowthGlobalAsset);
        pool.feeGrowthGlobalQuote = Assembly.computeCheckpoint(pool.feeGrowthGlobalQuote, feeGrowthGlobalQuote);

        Pair memory pair = pairs[CPU.decodePairIdFromPoolId(poolId)];
        emit PoolUpdate(
            poolId,
            pool.lastPrice,
            pool.lastTick,
            pool.liquidity,
            pair.tokenAsset,
            pair.tokenQuote,
            feeGrowthGlobalAsset,
            feeGrowthGlobalQuote
        );
    }

    // ===== Initializing Pools ===== //

    /**
     * @dev Pairs are used in pool creation to determine the pool's underlying tokens.
     *
     * @custom:reverts If decoded addresses are the same.
     * @custom:reverts If __ordered__ pair of addresses has already been created and has a non-zero pairId.
     * @custom:reverts If decimals of either token are not between 6 and 18, inclusive.
     */
    function _createPair(address asset, address quote) internal returns (uint24 pairId) {
        if (asset == quote) revert SameTokenError();

        pairId = getPairId[asset][quote];
        if (pairId != 0) revert PairExists(pairId);

        (uint8 decimalsAsset, uint8 decimalsQuote) = (IERC20(asset).decimals(), IERC20(quote).decimals());
        if (!Assembly.isBetween(decimalsAsset, MIN_DECIMALS, MAX_DECIMALS)) revert InvalidDecimals(decimalsAsset);
        if (!Assembly.isBetween(decimalsQuote, MIN_DECIMALS, MAX_DECIMALS)) revert InvalidDecimals(decimalsQuote);

        unchecked {
            pairId = uint24(++getPairNonce);
        }

        getPairId[asset][quote] = pairId; // note: order of tokens matters!
        pairs[pairId] = Pair({
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
        if (vol == 0) revert InvalidVolatility(vol);
        if (dur == 0) revert InvalidDuration(dur);
        if (max >= MAX_TICK) revert InvalidTick(max);
        if (jit > JUST_IN_TIME_MAX) revert InvalidJit(jit);
        if (!Assembly.isBetween(fee, MIN_POOL_FEE, MAX_POOL_FEE)) revert InvalidFee(fee);
        if (!Assembly.isBetween(priorityFee, MIN_POOL_FEE, fee)) revert InvalidFee(priorityFee);

        if (pairId == 0) pairId = uint24(getPairNonce); // magic variable

        uint32 poolNonce;
        unchecked {
            poolNonce = uint32(++getPoolNonce);
        }

        bool isMutable = controller != address(0);
        HyperPool memory params;
        {
            uint32 timestamp = uint(_blockTimestamp()).safeCastTo32();
            params = HyperPool({
                lastTick: Price.computeTickWithPrice(price),
                lastTimestamp: timestamp, // fix type
                controller: controller,
                feeGrowthGlobalAsset: 0,
                feeGrowthGlobalQuote: 0,
                lastPrice: price,
                liquidity: 0,
                stakedLiquidity: 0,
                stakedLiquidityDelta: 0,
                params: HyperCurve({
                    maxTick: max,
                    jit: isMutable ? jit : uint8(_liquidityPolicy()),
                    fee: fee,
                    duration: dur,
                    volatility: vol,
                    priorityFee: isMutable ? priorityFee : 0,
                    createdAt: timestamp
                })
            });

            poolId = CPU.encodePoolId(pairId, isMutable, poolNonce);
        }

        if (pools[poolId].exists()) revert PoolExists();
        pools[poolId] = params;

        Pair memory pair = pairs[pairId];
        emit CreatePool(poolId, isMutable, pair.tokenAsset, pair.tokenQuote, price);
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
        pool.changePoolParameters(
            HyperCurve({
                maxTick: maxTick,
                jit: jit,
                fee: fee,
                duration: duration,
                volatility: volatility,
                priorityFee: priorityFee,
                createdAt: 0
            })
        );

        // TODO: emit an event
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
        emit IncreaseUserBalance(token, amount);
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
        emit DecreaseUserBalance(token, amount);
    }

    /**
     * @dev Alternative entrypoint to execute functions.
     * @param data Encoded Enigma data. First byte must be an Enigma instruction.
     */
    function _process(bytes calldata data) internal {
        (, bytes1 instruction) = Assembly.separate(data[0]); // Upper byte is useMax, lower byte is instruction.

        if (instruction == CPU.ALLOCATE) {
            (uint8 useMax, uint64 poolId, uint128 deltaLiquidity) = CPU.decodeAllocate(data);
            _allocate(useMax == 1, poolId, deltaLiquidity);
        } else if (instruction == CPU.UNALLOCATE) {
            (uint8 useMax, uint64 poolId, uint128 deltaLiquidity) = CPU.decodeUnallocate(data);
            _unallocate(useMax == 1, poolId, deltaLiquidity);
        } else if (instruction == CPU.SWAP) {
            Order memory args;
            (args.useMax, args.poolId, args.input, args.limit, args.direction) = CPU.decodeSwap(data);
            _swapExactIn(args);
        } else if (instruction == CPU.STAKE_POSITION) {
            uint64 poolId = CPU.decodeStakePosition(data);
            _stake(poolId);
        } else if (instruction == CPU.UNSTAKE_POSITION) {
            uint64 poolId = CPU.decodeUnstakePosition(data);
            _unstake(poolId);
        } else if (instruction == CPU.CREATE_POOL) {
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
            ) = CPU.decodeCreatePool(data);
            _createPool(pairId, controller, priorityFee, fee, vol, dur, jit, max, price);
        } else if (instruction == CPU.CREATE_PAIR) {
            (address asset, address quote) = CPU.decodeCreatePair(data);
            _createPair(asset, quote);
        } else {
            revert InvalidInstruction();
        }
    }

    // ===== View ===== //

    function getTimePassed(uint64 poolId) public view returns (uint) {
        return _blockTimestamp() - pools[poolId].lastTimestamp;
    }

    function getMaxLiquidity(
        uint64 poolId,
        uint deltaAsset,
        uint deltaQuote
    ) public view override returns (uint128 deltaLiquidity) {
        return pools[poolId].getMaxLiquidity(deltaAsset, deltaQuote);
    }

    function getVirtualReserves(uint64 poolId) public view override returns (uint128 deltaAsset, uint128 deltaQuote) {
        return pools[poolId].getVirtualReserves();
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

    function getAssetAmountOut(uint64 poolId, uint amountIn) public view returns (uint) {
        return _getAmountOut(poolId, false, amountIn);
    }

    function getQuoteAmountOut(uint64 poolId, uint amountIn) public view returns (uint) {
        return _getAmountOut(poolId, true, amountIn);
    }

    function _getAmountOut(uint64 poolId, bool sellAsset, uint amountIn) internal view returns (uint output) {
        uint24 pairId = CPU.decodePairIdFromPoolId(poolId);
        HyperPool memory pool = pools[poolId];
        (output, ) = pool.getAmountOut({
            pair: pairs[pairId],
            sellAsset: sellAsset,
            amountIn: amountIn,
            timeSinceUpdate: _blockTimestamp() - pool.lastTimestamp
        });
    }
}
