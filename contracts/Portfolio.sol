// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./Objective.sol";

/**
 * @title   Portfolio
 * @author  Primitive™
 * @custom:contributor TomAFrench
 */
abstract contract PortfolioVirtual is Objective {
    using SafeCastLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    using AssemblyLib for uint8;
    using AssemblyLib for int256;
    using AssemblyLib for uint256;

    function VERSION() public pure returns (string memory) {
        assembly ("memory-safe") {
            // Load 0x20 (32) in memory at slot 0x00, this corresponds to the
            // offset location of the next data.
            mstore(0x00, 0x20)

            // Then we load both the length of our string (11 bytes, 0x0b in hex) and its
            // actual hex value (0x626574612d76302e312e30) using the offset 0x2b. Using this
            // particular offset value will right pad the length at the end of the slot
            // and left pad the string at the beginning of the next slot, assuring the
            // right ABI format to return a string.
            mstore(0x2b, 0x0b76312e302e302d62657461) // "v1.0.0-beta"

            // Return all the 96 bytes (0x60) of data that was loaded into the memory.
            return(0x00, 0x60)
        }
    }

    Account.AccountSystem public __account__;

    /// @inheritdoc IPortfolioGetters
    address public immutable WETH;
    /// @inheritdoc IPortfolioGetters
    address public immutable REGISTRY;
    /// @inheritdoc IPortfolioGetters
    uint24 public getPairNonce;

    mapping(address => uint256) public protocolFees;
    mapping(uint24 => uint32) public getPoolNonce;
    mapping(uint24 => PortfolioPair) public pairs;
    mapping(uint64 => PortfolioPool) public pools;
    mapping(address => mapping(address => uint24)) public getPairId;
    mapping(address => mapping(uint64 => PortfolioPosition)) public positions;

    uint256 internal _locked = 1;
    uint256 internal _liquidityPolicy = JUST_IN_TIME_LIQUIDITY_POLICY;
    uint256 private _protocolFee;

    /**
     * @dev Manipulated in `_settlement` only.
     * @custom:invariant MUST be deleted after every transaction that uses it.
     */
    Payment[] private _payments;

    /**
     * @dev
     * Manipulated in `_swap` to avoid stack too deep.
     * Utilized in virtual function implementations to handle fee growth, if any.
     *
     * @custom:invariant MUST be deleted after every transaction that uses it.
     */
    SwapState private _state;

    /**
     * @dev
     * Protects against re-entrancy and getting to invalid settlement states.
     * Used on all external non-view functions.
     *
     * @custom:guide
     * Step 1. Enter `_locked` re-entrancy guard.
     * Step 3. Wrap the entire ether balance of this contract and credit the wrapped ether to the msg.sender account.
     * Step 5. Execute the function logic.
     * Step 7. Enter the settlement function, requesting token payments or sending them out to msg.sender.
     * Step 8. Validate Portfolio's account system was settled.
     * Step 10. Exit `_locked` re-entrancy guard.
     */
    modifier lock() {
        if (_locked != 1) revert InvalidReentrancy();

        _locked = 2;
        _;
        _locked = 1;

        if (!__account__.settled) revert InvalidSettlement();
    }

    /**
     * @dev
     * Failing to pass a valid WETH contract that implements the `deposit()` function,
     * will cause all transactions with Portfolio to fail once address(this).balance > 0.
     *
     * @notice
     * Tokens sent to this contract are lost.
     */
    constructor(address weth, address registry) {
        WETH = weth;
        REGISTRY = registry;
        __account__.settled = true;
    }

    receive() external payable {
        if (msg.sender != WETH) revert();
    }

    // ===== Account Getters ===== //

    /// @inheritdoc IPortfolioGetters
    function getNetBalance(address token) public view returns (int256) {
        return __account__.getNetBalance(token, address(this));
    }

    /// @inheritdoc IPortfolioGetters
    function getReserve(address token) public view returns (uint256) {
        return __account__.reserves[token];
    }

    // ===== External Actions ===== //

    /// @inheritdoc IPortfolioActions
    function multiprocess(bytes calldata data) external payable lock {
        // Wraps msg.value.
        _deposit();

        // Effects
        if (data[0] != FVM.INSTRUCTION_JUMP) _process(data);
        else FVM._jumpProcess(data, _process);

        // Interactions
        _settlement();
    }

    /// @inheritdoc IPortfolioActions
    function changeParameters(
        uint64 poolId,
        uint16 priorityFee,
        uint16 fee,
        uint16 jit
    ) external lock {
        PortfolioPool storage pool = pools[poolId];
        if (pool.controller != msg.sender) revert NotController();

        PortfolioCurve memory modified;
        modified = pool.params;
        if (jit != 0) modified.jit = jit;
        if (fee != 0) modified.fee = fee;
        if (priorityFee != 0) modified.priorityFee = priorityFee;

        pool.changePoolParameters(modified);

        emit ChangeParameters(poolId, priorityFee, fee, jit);
    }

    // ===== Internal ===== //

    /**
     * @dev Increases virtual reserves and liquidity. Debits `msg.sender`.
     * @param deltaLiquidity Quantity of liquidity to mint in WAD units.
     * @param maxDeltaAsset Maximum quantity of asset tokens paid in WAD units.
     * @param maxDeltaQuote Maximum quantity of quote tokens paid in WAD units.
     * @return deltaAsset Real quantity of `asset` tokens paid to pool, in native token decimals.
     * @return deltaQuote Real quantity of `quote` tokens paid to pool, in native token decimals.
     */
    function _allocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 maxDeltaAsset,
        uint128 maxDeltaQuote
    ) internal returns (uint256 deltaAsset, uint256 deltaQuote) {
        if (!checkPool(poolId)) revert NonExistentPool(poolId);

        PortfolioPair memory pair = pools[poolId].pair;

        if (useMax) {
            // A positive net balance is a surplus of tokens in the accounting state that can be used to mint liquidity.
            int256 surplusAsset = getNetBalance(pair.tokenAsset);
            int256 surplusQuote = getNetBalance(pair.tokenQuote);
            if (surplusAsset < 0) surplusAsset = 0;
            if (surplusQuote < 0) surplusQuote = 0;
            deltaLiquidity = pools[poolId].getPoolMaxLiquidity({
                deltaAsset: uint256(surplusAsset),
                deltaQuote: uint256(surplusQuote)
            });
        }

        if (deltaLiquidity == 0) revert ZeroLiquidity();
        (deltaAsset, deltaQuote) = pools[poolId].getPoolLiquidityDeltas(
            AssemblyLib.toInt128(deltaLiquidity)
        ); // note: Rounds up.
        if (deltaAsset == 0 || deltaQuote == 0) revert ZeroAmounts();
        if (deltaAsset > maxDeltaAsset || deltaQuote > maxDeltaQuote) {
            revert MaxDeltaReached();
        }

        ChangeLiquidityParams memory args = ChangeLiquidityParams({
            owner: msg.sender,
            poolId: poolId,
            timestamp: block.timestamp,
            deltaAsset: deltaAsset,
            deltaQuote: deltaQuote,
            tokenAsset: pair.tokenAsset,
            tokenQuote: pair.tokenQuote,
            deltaLiquidity: AssemblyLib.toInt128(deltaLiquidity)
        });

        _changeLiquidity(args);

        // Scale WAD -> Decimals.
        (deltaAsset, deltaQuote) = (
            deltaAsset.scaleFromWadDown(pair.decimalsAsset),
            deltaQuote.scaleFromWadDown(pair.decimalsQuote)
        );

        emit Allocate(
            poolId,
            pair.tokenAsset,
            pair.tokenQuote,
            deltaAsset,
            deltaQuote,
            deltaLiquidity
            );
    }

    /**
     * @dev Reduces virtual reserves and liquidity. Credits `msg.sender`.
     */
    function _deallocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 minDeltaAsset,
        uint128 minDeltaQuote
    ) internal returns (uint256 deltaAsset, uint256 deltaQuote) {
        if (!checkPool(poolId)) revert NonExistentPool(poolId);

        PortfolioPair memory pair = pools[poolId].pair;
        (address asset, address quote) = (pair.tokenAsset, pair.tokenQuote);

        if (useMax) {
            deltaLiquidity = positions[msg.sender][poolId].freeLiquidity;
        }

        if (deltaLiquidity == 0) revert ZeroLiquidity();
        (deltaAsset, deltaQuote) = pools[poolId].getPoolLiquidityDeltas(
            -AssemblyLib.toInt128(deltaLiquidity)
        ); // note: Rounds down.

        if (deltaAsset < minDeltaAsset || deltaQuote < minDeltaQuote) {
            revert MinDeltaUnmatched();
        }
        ChangeLiquidityParams memory args = ChangeLiquidityParams({
            owner: msg.sender,
            poolId: poolId,
            timestamp: block.timestamp,
            deltaAsset: deltaAsset,
            deltaQuote: deltaQuote,
            tokenAsset: asset,
            tokenQuote: quote,
            deltaLiquidity: -AssemblyLib.toInt128(deltaLiquidity)
        });

        _changeLiquidity(args);

        // Scale WAD -> Decimals.
        (deltaAsset, deltaQuote) = (
            deltaAsset.scaleFromWadDown(pair.decimalsAsset),
            deltaQuote.scaleFromWadDown(pair.decimalsQuote)
        );

        emit Deallocate(
            poolId, asset, quote, deltaAsset, deltaQuote, deltaLiquidity
            );
    }

    /**
     * @dev Manipulates reserves depending on if liquidity is being allocated or deallocated.
     */
    function _changeLiquidity(ChangeLiquidityParams memory args) internal {
        (PortfolioPool storage pool, PortfolioPosition storage position) =
            (pools[args.poolId], positions[args.owner][args.poolId]);

        bool canUpdate =
            checkPosition(args.poolId, args.owner, args.deltaLiquidity);
        if (!canUpdate) revert JitLiquidity(pool.params.jit);

        (uint128 deltaAssetWad, uint128 deltaQuoteWad) =
            (args.deltaAsset.safeCastTo128(), args.deltaQuote.safeCastTo128());

        // Can only be in the case of an allocation,
        // because pool.liquidity cannot be 0 on deallocation.
        if (pool.liquidity == 0) {
            // On create, virtualX and virtualY are set to initial
            // liquidity of 1E18 and its corresponding reserves.
            // Therefore, reset the virtual reserves since they are being allocated to
            // for the first time in this transaction.
            pool.virtualX = 0;
            pool.virtualY = 0;
        }

        position.changePositionLiquidity(args.timestamp, args.deltaLiquidity);
        pools[args.poolId].changePoolLiquidity(args.deltaLiquidity);

        (address asset, address quote) = (args.tokenAsset, args.tokenQuote);
        if (args.deltaLiquidity < 0) {
            _decreaseReserves(asset, deltaAssetWad);
            _decreaseReserves(quote, deltaQuoteWad);
            pool.virtualX -= deltaAssetWad;
            pool.virtualY -= deltaQuoteWad;
        } else {
            _increaseReserves(asset, deltaAssetWad);
            _increaseReserves(quote, deltaQuoteWad);
            pool.virtualX += deltaAssetWad;
            pool.virtualY += deltaQuoteWad;
        }
    }

    /**
     * @dev
     * Swaps in input of tokens (sellAsset == 1 = asset, sellAsset == 0 = quote)
     * for output of tokens (sellAsset == 1 = quote, sellAsset == 0 = asset).
     *
     * Fees can be saved into two buckets:
     * 1. Re-invested into the pool, increasing the value of liquidity.
     * 2. Pro-rata distribution to all liquidity position's `owed` tokens, via fee growth accumulator.
     *
     * These different fee buckets are applied using this logic:
     * 1. Add the input swap amount, fee included, to the per liquidity reserves in `syncPool`.
     * 2. Add the input swap amount less the fee, to the per liquidity reserves in `syncPool`
     *    and increase the `feeGrowthGlobal` value by the `feeAmount` divided by `pool.liquidity`.
     *
     * @custom:invariant MUST not change liquidity of a pool.
     */
    function _swap(Order memory args)
        internal
        returns (uint64 poolId, uint256 input, uint256 output)
    {
        PortfolioPool storage pool = pools[args.poolId];
        if (!checkPool(args.poolId)) revert NonExistentPool(args.poolId);

        // -=- Load Fee & Token Info -=- //
        _state.sell = args.sellAsset == 1;
        _state.fee = msg.sender == pool.controller
            ? pool.params.priorityFee
            : pool.params.fee;

        if (_state.sell) {
            _state.tokenInput = pool.pair.tokenAsset;
            _state.tokenOutput = pool.pair.tokenQuote;
        } else {
            _state.tokenInput = pool.pair.tokenQuote;
            _state.tokenOutput = pool.pair.tokenAsset;
        }

        // -=- Load Swap Info -=- //
        Iteration memory iteration;
        {
            (bool success, int256 invariant) = _beforeSwapEffects(args.poolId);
            if (!success) revert PoolExpired();

            if (args.useMax == 1) {
                // Net balance is the surplus of tokens in the accounting state that can be spent.
                int256 netBalance = getNetBalance(
                    _state.sell ? pool.pair.tokenAsset : pool.pair.tokenQuote
                );
                if (netBalance < 0) netBalance = 0;
                input = uint256(netBalance);
            } else {
                input = args.input;
            }

            output = args.output;
            iteration.prevInvariant = invariant;
            iteration.input = input;
            iteration.liquidity = pool.liquidity;
            iteration.output = output;
            (iteration.virtualX, iteration.virtualY) =
                pool.getVirtualReservesWad();
        }

        if (iteration.output == 0) revert ZeroOutput();
        if (iteration.input == 0) revert ZeroInput();
        if (iteration.liquidity == 0) revert ZeroLiquidity();

        uint256 liveIndependentWad; // total reserve of input token in WAD
        uint256 nextIndependentWad;
        uint256 nextIndependentWadLessFee;
        uint256 liveDependentWad; // total reserve of output token in WAD
        uint256 nextDependentWad;

        //  -=- Compute New Reserves -=- //
        {
            uint256 deltaInput;
            uint256 deltaInputLessFee;
            uint256 deltaOutput = iteration.output;

            // Virtual reserves
            if (_state.sell) {
                (liveIndependentWad, liveDependentWad) =
                    (iteration.virtualX, iteration.virtualY);
            } else {
                (liveDependentWad, liveIndependentWad) =
                    (iteration.virtualX, iteration.virtualY);
            }

            deltaInput = iteration.input;

            iteration.feeAmount = (deltaInput * _state.fee) / PERCENTAGE;
            if (_protocolFee != 0) {
                uint256 protocolFeeAmountWad =
                    iteration.feeAmount / _protocolFee;

                // Reduce both the input amount and fee amount by the protocol fee.
                // The protocol fee is not applied to the reserve, so it is not included in deltaInput.
                // The feeAmount pays for the protocolFeeAmount, so it is not included in feeAmount.
                deltaInput -= protocolFeeAmountWad;
                iteration.feeAmount -= protocolFeeAmountWad;
                iteration.protocolFeeAmount = protocolFeeAmountWad;
            }

            deltaInputLessFee = deltaInput - iteration.feeAmount;
            nextIndependentWad = liveIndependentWad + deltaInput;

            // This is a very critical piece of code!
            // nextIndependentWadLessFee:
            // This value should be used in `syncPool`.
            // The next independent amount is computed with the fee amount applied.
            // This means the lesser next independent reserve and dependent reserve
            // will pass the invariant.
            //
            // nextIndependent:
            // The fee amount has to be added to the reserve to re-invest it in the pool.
            // So the next reserve should include the fee amount, since it was added to the reserves.
            // This will mean the independent reserve has more tokens than expected,
            // leading to a larger invariant.
            nextIndependentWadLessFee = liveIndependentWad + deltaInputLessFee;
            nextDependentWad = liveDependentWad - deltaOutput;
        }

        // -=- Assert Invariant Passes -=- //
        {
            bool validInvariant;
            int256 nextInvariantWad;

            if (_state.sell) {
                (iteration.virtualX, iteration.virtualY) =
                    (nextIndependentWadLessFee, nextDependentWad);
            } else {
                (iteration.virtualX, iteration.virtualY) =
                    (nextDependentWad, nextIndependentWadLessFee);
            }

            (validInvariant, nextInvariantWad) = checkInvariant(
                args.poolId,
                iteration.prevInvariant,
                iteration.virtualX.divWadDown(iteration.liquidity), // Expects X per liquidity.
                iteration.virtualY.divWadDown(iteration.liquidity), // Expects Y per liquidity.
                block.timestamp
            );

            if (!validInvariant) {
                revert InvalidInvariant(
                    iteration.prevInvariant, nextInvariantWad
                );
            }
            iteration.nextInvariant = int128(nextInvariantWad);
        }

        if (_state.sell) {
            iteration.virtualX = nextIndependentWad;
        } else {
            iteration.virtualY = nextIndependentWad;
        }

        // =---= Effects =---= //

        _syncPool(args.poolId, iteration.virtualX, iteration.virtualY);

        _increaseReserves(_state.tokenInput, iteration.input); // Increasing reserves creates a debit that must be paid from `msg.sender`.
        _decreaseReserves(_state.tokenOutput, iteration.output); // Decreasing reserves creates a surplus that can be used in following instructions.

        // -=- Scale Amounts to Native Token Decimals -=- //
        {
            uint256 inputDec;
            uint256 outputDec;
            if (_state.sell) {
                inputDec = pool.pair.decimalsAsset;
                outputDec = pool.pair.decimalsQuote;
            } else {
                inputDec = pool.pair.decimalsQuote;
                outputDec = pool.pair.decimalsAsset;
            }

            // Scaling the input here is important. ALl the math was done using WAD units.
            // But all the token related amounts must be in their native token decimals.
            iteration.input = iteration.input.scaleFromWadDown(inputDec);
            iteration.output = iteration.output.scaleFromWadDown(outputDec);

            if (iteration.protocolFeeAmount != 0) {
                protocolFees[_state.tokenInput] += iteration.protocolFeeAmount;
            }
        }

        emit Swap(
            args.poolId,
            getVirtualPrice(args.poolId),
            _state.tokenInput,
            iteration.input,
            _state.tokenOutput,
            iteration.output,
            iteration.feeAmount,
            iteration.nextInvariant
            );

        delete _state;
        return (args.poolId, iteration.input, iteration.output);
    }

    /**
     * @dev Effects on a `pool` after a successful swap.
     */
    function _syncPool(
        uint64 poolId,
        uint256 nextVirtualX,
        uint256 nextVirtualY
    ) internal {
        PortfolioPool storage pool = pools[poolId];

        pool.virtualX = nextVirtualX.safeCastTo128();
        pool.virtualY = nextVirtualY.safeCastTo128();

        // If not updated in the other swap hooks, update the timestamp.
        if (pool.lastTimestamp != block.timestamp) {
            pool.syncPoolTimestamp(block.timestamp);
        }
    }

    function _createPair(
        address asset,
        address quote
    ) internal returns (uint24 pairId) {
        if (asset == quote) revert SameTokenError();

        pairId = getPairId[asset][quote];
        if (pairId != 0) revert PairExists(pairId);

        (uint8 decimalsAsset, uint8 decimalsQuote) =
            (IERC20(asset).decimals(), IERC20(quote).decimals());
        if (!decimalsAsset.isBetween(MIN_DECIMALS, MAX_DECIMALS)) {
            revert InvalidDecimals(decimalsAsset);
        }
        if (!decimalsQuote.isBetween(MIN_DECIMALS, MAX_DECIMALS)) {
            revert InvalidDecimals(decimalsQuote);
        }

        pairId = ++getPairNonce;

        getPairId[asset][quote] = pairId; // note: Order of tokens matters!
        pairs[pairId] = PortfolioPair({
            tokenAsset: asset,
            decimalsAsset: decimalsAsset,
            tokenQuote: quote,
            decimalsQuote: decimalsQuote
        });

        emit CreatePair(pairId, asset, quote, decimalsAsset, decimalsQuote);
    }

    /**
     * @param pairId Nonce of the target pair. A `0` is a magic variable to use the state variable `getPairNonce` instead.
     * @param controller An address that can change the `fee`, `priorityFee`, and `jit` parameters of the created pool.
     * @param priorityFee Priority fee for the pool (10,000 being 100%). This is a percentage of fees paid by the controller when swapping.
     * @param fee Fee for the pool (10,000 being 100%). This is a percentage of fees paid by the users when swapping.
     * @param volatility Expected volatility of the pool.
     * @param duration Quantity of days (in units of days) until the pool "expires". Uses `type(uint16).max` as a magic variable to set `perpetual = true`.
     * @param jit Just In Time policy (expressed in seconds).
     * @param maxPrice Terminal price of the pool once maturity is reached (expressed in the quote token).
     * @param price Initial price of the pool (expressed in the quote token).
     */
    function _createPool(
        uint24 pairId,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 maxPrice,
        uint128 price
    ) internal returns (uint64 poolId) {
        if (price == 0) revert ZeroPrice();
        uint24 pairNonce = pairId == 0 ? getPairNonce : pairId; // magic variable
        if (pairNonce == 0) revert InvalidPair();

        bool hasController = controller != address(0);
        {
            uint32 poolNonce = ++getPoolNonce[pairNonce];
            poolId = FVM.encodePoolId(pairNonce, hasController, poolNonce);
        }

        PortfolioPool storage pool = pools[poolId];
        pool.controller = controller;
        if (hasController && priorityFee == 0) revert InvalidFee(priorityFee); // Cannot set priority to 0.

        uint32 timestamp = block.timestamp.safeCastTo32();
        pool.lastTimestamp = timestamp;
        pool.pair = pairs[pairNonce];

        bool isPerpetual = duration == type(uint16).max ? true : false; // type(uint16).max is a magic variable
        PortfolioCurve memory params = PortfolioCurve({
            maxPrice: maxPrice,
            jit: hasController ? jit : uint16(_liquidityPolicy),
            fee: fee,
            duration: isPerpetual ? uint16(MAX_DURATION) : duration, // Set duration to the max if perpetual.
            volatility: volatility,
            priorityFee: hasController ? priorityFee : 0,
            createdAt: timestamp,
            perpetual: isPerpetual
        });
        pool.changePoolParameters(params);

        (uint256 x, uint256 y) = computeReservesFromPrice(poolId, price);
        (pool.virtualY, pool.virtualX) = (y.safeCastTo128(), x.safeCastTo128());

        emit CreatePool(
            poolId,
            pool.pair.tokenAsset,
            pool.pair.tokenQuote,
            pool.controller,
            pool.params.maxPrice,
            pool.params.jit,
            pool.params.fee,
            pool.params.duration,
            pool.params.volatility,
            pool.params.priorityFee
            );
    }

    // ===== Accounting System ===== //

    /**
     * @dev Wraps address(this).balance of ether but does not credit to `msg.sender`.
     * Received WETH will remain in the contract as a surplus, i.e. `getNetBalance(WETH)` will be positive.
     * The `settlement` function handles how to apply the surplus,
     * by either using it to pay a debit or by gifting the `msg.sender`.
     */
    function _deposit() internal {
        if (msg.value > 0) {
            __account__.__wrapEther__(WETH);
            emit Deposit(msg.sender, msg.value);
        }
    }

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
     * @dev Used on every entry point to scale user-provided arguments from decimals to WAD.
     */
    function _scaleAmountsToWad(
        uint64 poolId,
        uint256 amountAssetDec,
        uint256 amountQuoteDec
    ) internal view returns (uint128 amountAssetWad, uint128 amountQuoteWad) {
        PortfolioPair memory pair = pools[poolId].pair;

        amountAssetWad = amountAssetDec.safeCastTo128();
        if (amountAssetDec != type(uint128).max) {
            amountAssetWad =
                amountAssetDec.scaleToWad(pair.decimalsAsset).safeCastTo128();
        }

        amountQuoteWad = amountQuoteDec.safeCastTo128();
        if (amountQuoteDec != type(uint128).max) {
            amountQuoteWad =
                amountQuoteDec.scaleToWad(pair.decimalsQuote).safeCastTo128();
        }
    }

    /**
     * @dev Use `multiprocess` to enter this function to process instructions.
     * @param data Custom encoded FVM data. First byte must be an FVM instruction.
     */
    function _process(bytes calldata data) internal {
        (, bytes1 instruction) = AssemblyLib.separate(data[0]); // Upper byte is useMax, lower byte is instruction.

        if (instruction == FVM.SWAP_ASSET || instruction == FVM.SWAP_QUOTE) {
            Order memory args;
            (args.useMax, args.poolId, args.input, args.output, args.sellAsset)
            = FVM.decodeSwap(data);

            if (args.sellAsset == 1) {
                (args.input, args.output) = _scaleAmountsToWad({
                    poolId: args.poolId,
                    amountAssetDec: args.input,
                    amountQuoteDec: args.output
                });
            } else {
                (args.output, args.input) = _scaleAmountsToWad({
                    poolId: args.poolId,
                    amountAssetDec: args.output,
                    amountQuoteDec: args.input
                });
            }

            _swap(args);
        } else if (instruction == FVM.ALLOCATE) {
            (
                uint8 useMax,
                uint64 poolId,
                uint128 deltaLiquidity,
                uint128 maxDeltaAsset,
                uint128 maxDeltaQuote
            ) = FVM.decodeAllocateOrDeallocate(data);

            (maxDeltaAsset, maxDeltaQuote) = _scaleAmountsToWad({
                poolId: poolId,
                amountAssetDec: maxDeltaAsset,
                amountQuoteDec: maxDeltaQuote
            });

            _allocate(
                useMax == 1,
                poolId,
                deltaLiquidity,
                maxDeltaAsset,
                maxDeltaQuote
            );
        } else if (instruction == FVM.DEALLOCATE) {
            (
                uint8 useMax,
                uint64 poolId,
                uint128 deltaLiquidity,
                uint128 minDeltaAsset,
                uint128 minDeltaQuote
            ) = FVM.decodeAllocateOrDeallocate(data);

            (minDeltaAsset, minDeltaQuote) = _scaleAmountsToWad({
                poolId: poolId,
                amountAssetDec: minDeltaAsset,
                amountQuoteDec: minDeltaQuote
            });
            _deallocate(
                useMax == 1,
                poolId,
                deltaLiquidity,
                minDeltaAsset,
                minDeltaQuote
            );
        } else if (instruction == FVM.CREATE_POOL) {
            (
                uint24 pairId,
                address controller,
                uint16 priorityFee,
                uint16 fee,
                uint16 vol,
                uint16 dur,
                uint16 jit,
                uint128 maxPrice,
                uint128 price
            ) = FVM.decodeCreatePool(data);
            _createPool(
                pairId,
                controller,
                priorityFee,
                fee,
                vol,
                dur,
                jit,
                maxPrice,
                price
            );
        } else if (instruction == FVM.CREATE_PAIR) {
            (address asset, address quote) = FVM.decodeCreatePair(data);
            _createPair(asset, quote);
        } else {
            revert InvalidInstruction();
        }
    }

    /**
     * Be aware of these settlement invariants:
     * =
     *     Invariant 1. Every token that is interacted with is cached and exists.
     *     Invariant 2. Tokens are removed from cache and cache is empty by end of settlement.
     *     Invariant 3. Cached tokens cannot be carried over from previous transactions.
     *     Invariant 4. Execution does not exit during the loops prematurely.
     *     Invariant 5. Account `settled` bool is set to true at end of `settlement`.
     *     Invariant 6. Debits reduce `reserves` of `token`.
     */
    function _settlement() internal {
        address[] memory tokens = __account__.warm;
        uint256 loops = tokens.length;

        if (loops == 0) return __account__.reset(); // Exit early.

        // Compute all the payments that must be paid to this contract.
        uint256 i = loops;
        do {
            // Loop backwards to pop tokens off.
            address token = tokens[i - 1];

            // Apply credits or debits to net balance.
            // If credited, these are extra tokens that will be transferred to `msg.sender`.
            // If debited, some tokens were paid via `msg.sender`'s internal balance.
            // If remainder, not enough tokens were paid. Must be transferred in from `msg.sender`.
            (uint256 credited, uint256 remainder) =
                __account__.settle(token, address(this));

            // Only `credited` or `remainder` can be non-zero.
            // Outstanding amount must be transferred in to `address(this)`.
            // Untracked credits must be transferred out to `msg.sender`.
            _payments.push(
                Payment({
                    token: token,
                    amountTransferTo: credited, // Reserves are not tracking some tokens.
                    amountTransferFrom: remainder, // Reserves need more tokens.
                    balance: Account.__balanceOf__(token, address(this))
                })
            );

            // Token considered fully accounted for.
            __account__.warm.pop();
            unchecked {
                --i; // Cannot underflow because loop exits at 0!
            }
        } while (i != 0);

        // Uses `token.transferFrom(msg.sender, address(this), amount)` to pay for the outstanding debits.
        // Uses `token.transfer(msg.sender, amount)` to pay out the untracked credits.
        Payment[] memory payments = _payments;
        uint256 px = payments.length;
        while (px != 0) {
            uint256 index = px - 1;
            address token = payments[index].token;
            uint8 decimals = IERC20(token).decimals();

            (uint256 amountTransferTo, uint256 amountTransferFrom) = (
                payments[index].amountTransferTo,
                payments[index].amountTransferFrom
            );

            // Scale WAD -> Decimals.
            amountTransferTo = amountTransferTo.scaleFromWadDown(decimals);
            amountTransferFrom = amountTransferFrom.scaleFromWadDown(decimals);

            if (amountTransferTo > 0) {
                uint256 prev = payments[index].balance;

                // Interaction
                if (token == WETH) {
                    Account.__dangerousUnwrapEther__(
                        WETH, msg.sender, amountTransferTo
                    );
                } else {
                    Account.SafeTransferLib.safeTransfer(
                        Account.ERC20(token), msg.sender, amountTransferTo
                    );
                }

                uint256 post = Account.__balanceOf__(token, address(this));
                uint256 expected = prev - amountTransferTo;
                if (post < expected) {
                    revert NegativeBalance(
                        token, int256(post) - int256(expected)
                    );
                }
            }

            if (amountTransferFrom > 0) {
                uint256 prev = payments[index].balance;

                // Interaction
                Account.__dangerousTransferFrom__(
                    token, address(this), amountTransferFrom
                );

                uint256 post = Account.__balanceOf__(token, address(this));
                uint256 expected = prev + amountTransferFrom;
                if (post < expected) {
                    revert NegativeBalance(
                        token, int256(post) - int256(expected)
                    );
                }
            }

            unchecked {
                --px; // Cannot underflow because loop exits at 0!
            }
        }

        __account__.reset(); // Clears token cache and sets `settled` to `true`.
        delete _payments;
    }

    function claimFee(address token, uint256 amount) external override lock {
        if (msg.sender != IPortfolioRegistry(REGISTRY).controller()) {
            revert NotController();
        }

        uint256 amountWad;
        uint8 decimals = IERC20(token).decimals();
        if (amount == type(uint256).max) {
            amountWad = protocolFees[token];
            amount = amountWad.scaleFromWadDown(decimals);
        } else {
            amountWad = amount.scaleToWad(decimals);
        }

        protocolFees[token] -= amountWad;
        _decreaseReserves(token, amountWad);

        _settlement();

        emit ClaimFees(token, amount);
    }

    function setProtocolFee(uint256 fee) external override lock {
        if (msg.sender != IPortfolioRegistry(REGISTRY).controller()) {
            revert NotController();
        }
        if (fee > 20 || fee < 4) revert InvalidFee(uint16(fee));

        uint256 prevFee = _protocolFee;
        _protocolFee = fee;

        emit UpdateProtocolFee(prevFee, fee);
    }

    // ===== Public View ===== //

    /// @inheritdoc IPortfolioGetters
    function getLiquidityDeltas(
        uint64 poolId,
        int128 deltaLiquidity
    ) public view returns (uint128 deltaAsset, uint128 deltaQuote) {
        (uint256 deltaAssetWad, uint256 deltaQuoteWad) =
            pools[poolId].getPoolLiquidityDeltas(deltaLiquidity);

        PortfolioPair memory pair = pools[poolId].pair;
        deltaAsset =
            deltaAssetWad.scaleFromWadDown(pair.decimalsAsset).safeCastTo128();
        deltaQuote =
            deltaQuoteWad.scaleFromWadDown(pair.decimalsQuote).safeCastTo128();
    }

    /// @inheritdoc IPortfolioGetters
    function getMaxLiquidity(
        uint64 poolId,
        uint256 amount0,
        uint256 amount1
    ) public view returns (uint128 deltaLiquidity) {
        PortfolioPair memory pair = pools[poolId].pair;

        (amount0, amount1) = (
            amount0.scaleToWad(pair.decimalsAsset),
            amount1.scaleToWad(pair.decimalsQuote)
        );

        return pools[poolId].getPoolMaxLiquidity(amount0, amount1);
    }

    /// @inheritdoc IPortfolioGetters
    function getPoolReserves(uint64 poolId)
        public
        view
        override
        returns (uint256 deltaAsset, uint256 deltaQuote)
    {
        (uint256 deltaAssetWad, uint256 deltaQuoteWad) =
            pools[poolId].getPoolReserves();

        deltaAsset =
            deltaAssetWad.scaleFromWadDown(pools[poolId].pair.decimalsAsset);
        deltaQuote =
            deltaQuoteWad.scaleFromWadDown(pools[poolId].pair.decimalsQuote);
    }

    /// @inheritdoc IPortfolioGetters
    function getVirtualReservesDec(uint64 poolId)
        public
        view
        override
        returns (uint128 deltaAsset, uint128 deltaQuote)
    {
        return pools[poolId].getVirtualReservesDec();
    }
}
