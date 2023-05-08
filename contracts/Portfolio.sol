// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

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
            // actual hex value (0x76312e322e302d62657461) using the offset 0x2b. Using this
            // particular offset value will right pad the length at the end of the slot
            // and left pad the string at the beginning of the next slot, assuring the
            // right ABI format to return a string.
            mstore(0x2b, 0x0b76312e322e302d62657461) // "v1.2.0-beta"

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

    // Tracks the id of the last pool that was created, quite useful during a
    // multicall to avoid being tricked into allocating into the wrong pool.
    uint64 public getLastPoolId;

    mapping(address => uint256) public protocolFees;
    mapping(uint24 => uint32) public getPoolNonce;
    mapping(uint24 => PortfolioPair) public pairs;
    mapping(uint64 => PortfolioPool) public pools;
    mapping(address => mapping(address => uint24)) public getPairId;
    mapping(address => mapping(uint64 => uint128)) public positions;

    uint256 internal _locked = 1;
    uint256 internal _liquidityPolicy = JUST_IN_TIME_LIQUIDITY_POLICY;
    uint256 private _protocolFee;

    /**
     * @dev Manipulated in `_settlement` only.
     * @custom:invariant MUST be deleted after every transaction that uses it.
     */
    Payment[] private _payments;

    /// @dev True if the current call is a multicall.
    bool private _currentMulticall;

    /**
     * @dev Protects against reentrancy and getting to invalid settlement states.
     * This lock works in pair with `_postLock` and both should be used on all
     * external non-view functions (except the restricted ones).
     *
     * Note: Private functions are used instead of modifiers to reduce the size
     * of the bytecode.
     */
    function _preLock() private {
        // Reverts if the lock was already set and the current call is not a multicall.
        if (_locked != 1 && !_currentMulticall) {
            revert InvalidReentrancy();
        }

        _locked = 2;
    }

    /**
     * @dev Second part of the reentracy guard (see `_preLock`).
     */
    function _postLock() private {
        _locked = 1;

        // Reverts if the account system was not settled after a normal call.
        if (!__account__.settled && !_currentMulticall) {
            revert InvalidSettlement();
        }
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

    function multicall(bytes[] calldata data)
        public
        payable
        returns (bytes[] memory results)
    {
        // Prevents multicall reentrancy.
        if (_currentMulticall) revert InvalidMulticall();

        _preLock();
        _currentMulticall = true;

        // Wraps msg.value.
        _deposit();

        results = new bytes[](data.length);

        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) =
                address(this).delegatecall(data[i]);

            if (!success) {
                assembly {
                    revert(add(32, result), mload(result))
                }
            }

            results[i] = result;
        }

        _currentMulticall = false;

        // Interactions
        _settlement();
        _postLock();
    }

    /// @inheritdoc IPortfolioActions
    function changeParameters(
        uint64 poolId,
        uint16 priorityFee,
        uint16 fee
    ) external {
        _preLock();
        PortfolioPool storage pool = pools[poolId];
        if (pool.controller != msg.sender) revert NotController();

        PortfolioCurve memory modified;
        modified = pool.params;
        if (fee != 0) modified.fee = fee;
        if (priorityFee != 0) modified.priorityFee = priorityFee;

        pool.changePoolParameters(modified);

        emit ChangeParameters(poolId, priorityFee, fee);
        _postLock();
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
    function allocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 maxDeltaAsset,
        uint128 maxDeltaQuote
    ) external payable returns (uint256 deltaAsset, uint256 deltaQuote) {
        _preLock();
        if (_currentMulticall == false) _deposit();

        if (poolId == 0) poolId = getLastPoolId;
        if (!checkPool(poolId)) revert NonExistentPool(poolId);

        (maxDeltaAsset, maxDeltaQuote) = _scaleAmountsToWad({
            poolId: poolId,
            amountAssetDec: maxDeltaAsset,
            amountQuoteDec: maxDeltaQuote
        });

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

        if (deltaAsset == 0 || deltaQuote == 0) revert ZeroAmounts(); // Make sure to prevent allocates which provide fractional token amounts.
        emit Allocate(
            poolId,
            pair.tokenAsset,
            pair.tokenQuote,
            deltaAsset,
            deltaQuote,
            deltaLiquidity
        );

        if (_currentMulticall == false) _settlement();
        _postLock();
    }

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
    ) external payable returns (uint256 deltaAsset, uint256 deltaQuote) {
        _preLock();

        if (_currentMulticall == false) _deposit();

        if (!checkPool(poolId)) revert NonExistentPool(poolId);

        (minDeltaAsset, minDeltaQuote) = _scaleAmountsToWad({
            poolId: poolId,
            amountAssetDec: minDeltaAsset,
            amountQuoteDec: minDeltaQuote
        });

        PortfolioPair memory pair = pools[poolId].pair;
        (address asset, address quote) = (pair.tokenAsset, pair.tokenQuote);

        if (useMax) {
            deltaLiquidity = positions[msg.sender][poolId];
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

        if (_currentMulticall == false) _settlement();
        _postLock();
    }

    /**
     * @dev Manipulates reserves depending on if liquidity is being allocated or deallocated.
     */
    function _changeLiquidity(ChangeLiquidityParams memory args) internal {
        PortfolioPool storage pool = pools[args.poolId];

        (uint128 deltaAssetWad, uint128 deltaQuoteWad) =
            (args.deltaAsset.safeCastTo128(), args.deltaQuote.safeCastTo128());

        // Can only be in the case of the first allocation,
        // because pool.liquidity cannot be 0 on deallocation.
        // And there is no way for the pool to get to zero liquidity
        // since a small amount of liquidity is burned.
        int128 positionLiquidity = args.deltaLiquidity;
        if (pool.liquidity == 0) {
            // When a pool is created, the virtual reserves are
            // initialized to match the reported price as specified by the pool creator.
            // These resereves are initialized based on 1E18 units of liquidity.
            // Since no liquidity was actually provided yet, the first
            // allocate will need to reset the virtual reserves before incrementing them.
            pool.virtualX = 0;
            pool.virtualY = 0;
            // Small amount of liquidity is removed from initial position to permanently burn it.
            // This prevents the pool from reaching 0 in both virtual reserves if all liquidity is removed.
            if (positionLiquidity < int128(uint128(BURNED_LIQUIDITY))) {
                revert InsufficientLiquidity();
            }
            positionLiquidity -= int128(uint128(BURNED_LIQUIDITY));
        }

        positions[args.owner][args.poolId] = AssemblyLib.addSignedDelta(
            positions[args.owner][args.poolId], positionLiquidity
        );
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
        returns (uint64 poolId, uint256 input, uint256 output)
    {
        _preLock();
        if (_currentMulticall == false) _deposit();

        PortfolioPool storage pool = pools[args.poolId];

        // Scale amounts from native token decimals to WAD.
        // Load input and output token information with respective pair tokens.
        SwapState memory info;
        if (args.sellAsset) {
            (args.input, args.output) = _scaleAmountsToWad({
                poolId: args.poolId,
                amountAssetDec: args.input,
                amountQuoteDec: args.output
            });

            info.decimalsInput = pool.pair.decimalsAsset;
            info.decimalsOutput = pool.pair.decimalsQuote;
            info.tokenInput = pool.pair.tokenAsset;
            info.tokenOutput = pool.pair.tokenQuote;
        } else {
            (args.output, args.input) = _scaleAmountsToWad({
                poolId: args.poolId,
                amountAssetDec: args.output,
                amountQuoteDec: args.input
            });

            info.decimalsInput = pool.pair.decimalsQuote;
            info.decimalsOutput = pool.pair.decimalsAsset;
            info.tokenInput = pool.pair.tokenQuote;
            info.tokenOutput = pool.pair.tokenAsset;
        }

        // --- Checks --- //
        if (!checkPool(args.poolId)) revert NonExistentPool(args.poolId);

        (bool success, int256 invariant) =
            _beforeSwapEffects(args.poolId, args.sellAsset);
        if (!success) revert PoolExpired();

        Iteration memory iteration;
        iteration.input = args.input;
        iteration.output = args.output;
        iteration.prevInvariant = invariant;
        iteration.liquidity = pool.liquidity;
        (iteration.virtualX, iteration.virtualY) = pool.getVirtualReservesWad();

        if (args.useMax) {
            // Net balance is the surplus of tokens in the accounting state that can be spent.
            int256 netBalance = getNetBalance(info.tokenInput);
            if (netBalance > 0) iteration.input = uint256(netBalance);
        }

        if (iteration.output == 0) revert ZeroOutput();
        if (iteration.input == 0) revert ZeroInput();
        if (iteration.liquidity == 0) revert ZeroLiquidity();

        // --- Effects --- //

        // In the case of a non-zero protocol fee, a small portion of the input amount (protocol fee) is not re-invested to the pool.
        // Therefore, this input amount will properly sync the pool's reserves by subtracting the protocol fee amount from this value.
        uint256 deltaIndependentReserveWad = iteration.input;

        {
            // Use the priority fee if the pool controller is the caller.
            uint256 feePercentage = pool.controller == msg.sender
                ? pool.params.priorityFee
                : pool.params.fee;

            // Compute the respective fee and protocol fee amounts.
            iteration.feeAmount =
                (deltaIndependentReserveWad * feePercentage) / PERCENTAGE;
            if (iteration.feeAmount == 0) iteration.feeAmount = 1; // Fee should never be zero.

            if (_protocolFee != 0) {
                // Protocol fee is a proportion of the fee amount.
                iteration.protocolFeeAmount = iteration.feeAmount / _protocolFee;
                // Reduce the increase in the independent reserve, so that protocol fee is not re-invested into pool.
                deltaIndependentReserveWad -= iteration.protocolFeeAmount;
                // Take the protocol fee from the fee amount.
                iteration.feeAmount -= iteration.protocolFeeAmount;
            }

            (uint256 adjustedVirtualX, uint256 adjustedVirtualY) =
                (iteration.virtualX, iteration.virtualY);

            // 1. Compute the new independent reserve without the fee amount included,
            //      so that the invariant check passes even without the additional fees.
            // 2. Compute the new dependent reserve by subtracting the full output swap amount.
            // 3. Adjust the reserves to be the pool reserves per 1E18 liquidity.
            //      Independent reserve is rounded down and dependent reserve is rounded up.
            //      This ensures the invariant check is done using reserves that are rounded to the benefit of Portfolio.
            if (args.sellAsset) {
                adjustedVirtualX +=
                    (deltaIndependentReserveWad - iteration.feeAmount);
                adjustedVirtualX =
                    adjustedVirtualX.divWadDown(iteration.liquidity);

                adjustedVirtualY -= iteration.output;
                adjustedVirtualY =
                    adjustedVirtualY.divWadUp(iteration.liquidity);
            } else {
                adjustedVirtualX -= iteration.output;
                adjustedVirtualX =
                    adjustedVirtualX.divWadUp(iteration.liquidity);

                adjustedVirtualY +=
                    (deltaIndependentReserveWad - iteration.feeAmount);
                adjustedVirtualY =
                    adjustedVirtualY.divWadDown(iteration.liquidity);
            }

            // --- Invariant Check --- //

            bool validInvariant;
            (validInvariant, iteration.nextInvariant) = checkInvariant(
                args.poolId,
                iteration.prevInvariant,
                adjustedVirtualX,
                adjustedVirtualY,
                block.timestamp
            );

            if (!validInvariant) {
                revert InvalidInvariant(
                    iteration.prevInvariant, iteration.nextInvariant
                );
            }
        }

        // Increases the independent pool reserve by the input amount, including fee and excluding protocol fee.
        // Decrease the dependent pool reserve by the output amount.
        _syncPool(
            args.poolId,
            args.sellAsset,
            deltaIndependentReserveWad,
            iteration.output
        );

        _increaseReserves(info.tokenInput, iteration.input); // Increasing global reserves creates a debit that must be paid from `msg.sender`.
        _decreaseReserves(info.tokenOutput, iteration.output); // Decreasing global reserves creates a surplus that can be used in following instructions.

        // --- Post-conditions --- //

        // Protocol fees are applied to a mapping that can be claimed by Registry controller.
        // Protocol fees are in WAD units and are downscaled to their original decimals when being claimed.
        if (iteration.protocolFeeAmount != 0) {
            protocolFees[info.tokenInput] += iteration.protocolFeeAmount;
        }

        // Amounts are scaled back to their original decimals for the swap event and return variables.
        iteration.input = iteration.input.scaleFromWadDown(info.decimalsInput);
        iteration.output =
            iteration.output.scaleFromWadDown(info.decimalsOutput);
        iteration.feeAmount =
            iteration.feeAmount.scaleFromWadDown(info.decimalsInput);

        emit Swap(
            args.poolId,
            getSpotPrice(args.poolId),
            info.tokenInput,
            iteration.input,
            info.tokenOutput,
            iteration.output,
            iteration.feeAmount,
            iteration.nextInvariant
        );

        if (_currentMulticall == false) _settlement();
        _postLock();

        return (args.poolId, iteration.input, iteration.output);
    }

    /**
     * @dev Effects on a `pool` after a successful swap.
     * @param deltaInWad Amount of input tokens in WAD units to increase the independent reserve by.
     * @param deltaOutWad Amount of output tokens in WAD units to decrease the dependent reserve by.
     */
    function _syncPool(
        uint64 poolId,
        bool sellAsset,
        uint256 deltaInWad,
        uint256 deltaOutWad
    ) internal {
        PortfolioPool storage pool = pools[poolId];

        if (sellAsset) {
            pool.virtualX += deltaInWad.safeCastTo128();
            pool.virtualY -= deltaOutWad.safeCastTo128();
        } else {
            pool.virtualX -= deltaOutWad.safeCastTo128();
            pool.virtualY += deltaInWad.safeCastTo128();
        }

        // If not updated in the other swap hooks, update the timestamp.
        if (pool.lastTimestamp != block.timestamp) {
            pool.syncPoolTimestamp(block.timestamp);
        }
    }

    function createPair(
        address asset,
        address quote
    ) external payable returns (uint24 pairId) {
        _preLock();

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

        _postLock();
    }

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
    ) external payable returns (uint64 poolId) {
        _preLock();

        if (price == 0) revert ZeroPrice();
        uint24 pairNonce = pairId == 0 ? getPairNonce : pairId; // magic variable
        if (pairNonce == 0) revert InvalidPairNonce();

        bool hasController = controller != address(0);
        {
            uint32 poolNonce = ++getPoolNonce[pairNonce];
            poolId =
                AssemblyLib.encodePoolId(pairNonce, hasController, poolNonce);

            // TODO: Checks if it's cheaper to assign the storage variable this
            // way or get rid of the returned variable `poolId` instead.
            getLastPoolId = poolId;
        }

        PortfolioPool storage pool = pools[poolId];
        pool.controller = controller;
        if (hasController && priorityFee == 0) revert InvalidFee(priorityFee); // Cannot set priority to 0.

        uint32 timestamp = block.timestamp.safeCastTo32();
        pool.lastTimestamp = timestamp;
        pool.pair = pairs[pairNonce];

        // `type(uint16).max` is a magic variable for perpetual pools.
        if (duration > uint16(MAX_DURATION) && duration != type(uint16).max) {
            revert InvalidDuration(duration);
        }

        PortfolioCurve memory params = PortfolioCurve({
            strikePrice: strikePrice,
            fee: fee,
            duration: duration,
            volatility: volatility,
            priorityFee: hasController ? priorityFee : 0,
            createdAt: timestamp
        });
        pool.changePoolParameters(params);

        (uint256 x, uint256 y) = computeReservesFromPrice(poolId, price);
        (pool.virtualY, pool.virtualX) = (y.safeCastTo128(), x.safeCastTo128());

        emit CreatePool(
            poolId,
            pool.pair.tokenAsset,
            pool.pair.tokenQuote,
            pool.controller,
            pool.params.strikePrice,
            pool.params.fee,
            pool.params.duration,
            pool.params.volatility,
            pool.params.priorityFee
        );

        _postLock();
    }

    // ===== Accounting System ===== //

    /**
     * @dev Wraps address(this).balance of ether but does not credit to `msg.sender`.
     * Received WETH will remain in the contract as a surplus, i.e. `getNetBalance(WETH)` will be positive.
     * The `settlement` function handles how to apply the surplus,
     * by either using it to pay a debit or transferring it to `msg.sender`.
     */
    function _deposit() internal {
        if (msg.value > 0) {
            __account__.__wrapEther__(WETH);
            emit Deposit(msg.sender, msg.value);
        }
    }

    /**
     * @dev Reserves are an internally tracked amount of tokens that should match the return value of `balanceOf`.
     * @param token Address of the token to increment the reserves of.
     * @param amount Quantity of tokens to add to the reserves in WAD units.
     *
     * @custom:security Directly manipulates reserves.
     */
    function _increaseReserves(address token, uint256 amount) internal {
        __account__.increase(token, amount);
        emit IncreaseReserveBalance(token, amount);
    }

    /**
     * @dev Reserves are an internally tracked amount of tokens that should match the return value of `balanceOf`.
     * @param token Address of the token to decrement the reserves of.
     * @param amount Quantity of tokens to subtract from the reserves in WAD units.
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
     * @param amountAssetDec Quantity of asset tokens in native token decimals.
     * @param amountQuoteDec Quantity of quote tokens in native token decimals.
     * @return amountAssetWad Quantity of asset tokens in WAD units.
     * @return amountQuoteWad Quantity of quote tokens in WAD units.
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
     * Be aware of these settlement invariants:
     *
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
            // If remainder, not enough tokens were paid. Must be transferred in from `msg.sender`.
            // The `credited` amount is in native token decimals of `token`.
            // The `remainder` amount is in native token decimals of `token`.
            (uint256 credited, uint256 remainder) =
                __account__.settle(token, address(this));

            // Only `credited` or `remainder` can be non-zero.
            // Outstanding amount must be transferred in to `address(this)`.
            // Untracked credits must be transferred out to `msg.sender`.
            if (credited != 0 || remainder != 0) {
                _payments.push(
                    Payment({
                        token: token,
                        amountTransferTo: credited, // Reserves are not tracking some tokens.
                        amountTransferFrom: remainder, // Reserves need more tokens.
                        balance: Account.__balanceOf__(token, address(this))
                    })
                );
            }

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

            (uint256 amountTransferTo, uint256 amountTransferFrom) = (
                payments[index].amountTransferTo,
                payments[index].amountTransferFrom
            );

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
            } else if (amountTransferFrom > 0) {
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

    /// @inheritdoc IPortfolioActions
    function claimFee(address token, uint256 amount) external override {
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

    /// @inheritdoc IPortfolioActions
    function setProtocolFee(uint256 fee) external override {
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

        if (deltaLiquidity < 0) {
            // If deallocating, round amounts down to ensure credits are not overestimated.
            deltaAsset = deltaAssetWad.scaleFromWadDown(pair.decimalsAsset)
                .safeCastTo128();
            deltaQuote = deltaQuoteWad.scaleFromWadDown(pair.decimalsQuote)
                .safeCastTo128();
        } else {
            // If allocating, round amounts up to ensure payments are not underestimated.
            deltaAsset =
                deltaAssetWad.scaleFromWadUp(pair.decimalsAsset).safeCastTo128();
            deltaQuote =
                deltaQuoteWad.scaleFromWadUp(pair.decimalsQuote).safeCastTo128();
        }
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
