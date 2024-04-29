// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "solmate/tokens/ERC1155.sol";
import "./libraries/PortfolioLib.sol";
import "./libraries/PositionLib.sol";
import "./libraries/PoolLib.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPortfolio.sol";
import "./interfaces/IPortfolioRegistry.sol";
import "./interfaces/IStrategy.sol";
import "./PositionRenderer.sol";

/**
 * @title
 * Portfolio
 *
 * @author
 * Primitive™
 *
 * @dev
 * All directly transferred tokens to this contract are lost.
 *
 * @custom:contributor TomAFrench
 */
contract Portfolio is ERC1155, IPortfolio {
    using AssemblyLib for *;
    using FixedPointMathLib for *;
    using SafeCastLib for *;

    /// @inheritdoc IPortfolioState
    function VERSION() public pure returns (string memory) {
        assembly ("memory-safe") {
            // Load 0x20 (32) in memory at slot 0x00, this corresponds to the
            // offset location of the next data.
            mstore(0x00, 0x20)

            // We load the length of our string (11 bytes, 0x0b in hex) and its
            // actual hex value (0x76312e352e302d62657461) using the offset 0x2b.
            // Using this particular offset value will right pad the length at
            // the end of the slot and left pad the string at the beginning of
            // the next slot, assuring the right ABI format to return a string.
            mstore(0x2b, 0x0b76312e352e302d62657461) // "v1.5.0-beta"

            // Return all the 96 bytes (0x60) of data that was loaded into
            // the memory.
            return(0x00, 0x60)
        }
    }

    /// @dev Stores the accounting state of Portfolio.
    AccountLib.AccountSystem internal __account__;

    /// @inheritdoc IPortfolioState
    address public immutable WETH;

    /// @inheritdoc IPortfolioState
    address public immutable REGISTRY;

    /// @inheritdoc IPortfolioState
    address public immutable POSITION_RENDERER;

    /// @inheritdoc IPortfolioState
    uint24 public getPairNonce;

    /// @inheritdoc IPortfolioState
    mapping(address => uint256) public protocolFees;

    /// @inheritdoc IPortfolioState
    mapping(uint24 => uint32) public getPoolNonce;

    /// @inheritdoc IPortfolioState
    mapping(uint24 => PortfolioPair) public pairs;

    /// @inheritdoc IPortfolioState
    mapping(uint64 => PortfolioPool) public pools;

    mapping(address => mapping(uint64 => PortfolioPosition)) public positions;

    /// @inheritdoc IPortfolioState
    mapping(address => mapping(address => uint24)) public getPairId;

    /// @dev Part of the reentrancy guard, 1 = unlocked, 2 = locked.
    uint256 internal _locked = 1;

    /// @inheritdoc IPortfolioState
    uint256 public protocolFee;

    /**
     * @notice
     * Credit and debits that are cleared during settlement.
     *
     * @dev
     * Manipulated in `_settlement` only.
     *
     * @custom:invariant
     * MUST be deleted after every transaction that uses it.
     */
    Payment[] private _payments;

    /// @dev True if the current call is a multicall.
    bool private _currentMulticall;

    /**
     * @notice
     * Used in `allocate` to prevent pool creation frontrunning.
     *
     * @dev
     * Tracks the id of the last pool that was created, quite useful during
     * a multicall to avoid being tricked into allocating into the wrong pool.
     */
    uint64 private _getLastPoolId;

    /**
     * @notice
     * Custom mutex designed to prevent injected single-call re-entrancy
     * during multi-calls.
     *
     * @dev
     * Protects against re-entrancy and getting to invalid settlement states.
     * This lock works in pair with `_postLock` and both should be used on all
     * external non-view functions (except the restricted ones).
     *
     * Upon entering the mutex, there can be two conditions:
     * 1. `_locked != 1`. If not in a multicall, i.e. `&& !_currentMulticall`,
     *                    revert (singleCall -> singleCall re-entrancy).
     * 2. `_locked > 2`.  Reached here from starting in multicall.
     *                    This was called from another singleCall that did not have postLock() fire,
     *                    i.e. `_locked > 2`, revert because its injected re-entrancy:
     *                    (multiCall -> singleCall -> injected singleCall re-entrancy).
     *
     * This enforces that only the originally defined multicall actions are run,
     * and injected single calls are successfully caught and reverted by the mutex.
     * These injected re-entrancy guards are caught because the `postLock()` never gets called,
     * which decrements the `_locked` variable.
     * Multicalls go through because they don't fire the `postLock()` until after the calls ran.
     *
     * @custom:example Scenarios:
     * 1. reenter during multicall's action execution
     * multicall -> _currentMulticall = true
     *   preLock() -> _locked++ = 2
     *     singleCall()
     *       preLock() -> _locked++ = 3
     *       reenter during current execution (injected) -> postLock() does not decrement _locked.
     *         singeCall()
     *           preLock(): (_locked != 1 && (false || true)) == true, revert
     *   _currentMulticall = false;
     *   settlement()
     *   postLock()
     *
     * 2. reenter during multicall's settlement
     * multicall -> _currentMulticall = true
     *   preLock() -> _locked++ = 2
     *     singleCall
     *       preLock(): -> _locked++ == 3
     *       postLock(): -> _locked-- == 2
     *   _currentMulticall = false;
     *   settlement() -> _locked == 2
     *     reenter
     *       singeCall()
     *         preLock(): (_locked != 1 && (true || false)) == true, revert
     *   ...if continued (somehow gets passed the revert)
     *       mutliCall()
     *         passes multicall re-entrancy guard because not in multicall
     *         preLock(): (_locked != 1 && (true || false)) == true, revert
     *   ... settlement finishes
     *   postLock(): -> _locked-- == 1
     *
     * note
     * Private functions are used instead of modifiers to reduce the size
     * of the bytecode.
     */
    function _preLock() private {
        if (_locked != 1 && (!_currentMulticall || _locked > 2)) {
            revert Portfolio_InvalidReentrancy();
        }

        _locked++;
    }

    /// @dev Second part of the reentracy guard (see `_preLock`).
    function _postLock() private {
        _locked--;

        // Reverts if the account system was not settled after a normal call.
        if (!__account__.settled && !_currentMulticall) {
            revert Portfolio_InvalidSettlement();
        }
    }

    /**
     * @dev
     * Portfolio relies on the security of the NormalStrategy implementation,
     * since all pools created without a strategy default to this one.
     *
     * @param weth Address of the WETH contract. Failing to pass a valid WETH
     * contract that implements the `deposit()` function will cause all
     * transactions with Portfolio to fail once `address(this).balance > 0`.
     * @param registry Address of a contract that implements the `IRegistry` interface.
     * @param positionRenderer Address of the contract rendering the NFT positions.
     */
    constructor(
        address weth,
        address registry,
        address positionRenderer
    ) ERC1155() {
        WETH = weth;
        REGISTRY = registry;
        POSITION_RENDERER = positionRenderer;
        __account__.settled = true;
    }

    receive() external payable {
        if (msg.sender != WETH) revert();
    }

    /**
     * @notice Returns the metadata associated with a pool token.
     * @param id Id of the pool (type can be casted from `uint64`).
     * @return A Base64 encoded JSON string containing the pool metadata.
     */
    function uri(uint256 id) public view override returns (string memory) {
        return PositionRenderer(POSITION_RENDERER).uri(id);
    }

    // ===== Account Getters ===== //

    /// @inheritdoc IPortfolioAccounting
    function getNetBalance(address token) public view returns (int256) {
        return __account__.getNetBalance(token, address(this));
    }

    /// @inheritdoc IPortfolioAccounting
    function getReserve(address token) public view returns (uint256) {
        return __account__.reserves[token];
    }

    // ===== External Actions ===== //

    /// @inheritdoc IPortfolioActions
    function multicall(bytes[] calldata data)
        public
        payable
        returns (bytes[] memory results)
    {
        // Prevents multicall reentrancy.
        if (_currentMulticall) revert Portfolio_InvalidMulticall();

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
        if (pool.controller != msg.sender) revert Portfolio_NotController();

        if (fee != 0) {
            if (!fee.isBetween(MIN_FEE, MAX_FEE)) {
                revert PoolLib_InvalidFee(fee);
            }
            pool.feeBasisPoints = fee;
        }

        if (priorityFee != 0) {
            if (!priorityFee.isBetween(MIN_FEE, pool.feeBasisPoints)) {
                revert PoolLib_InvalidPriorityFee(priorityFee);
            }
            pool.priorityFeeBasisPoints = priorityFee;
        }

        emit ChangeParameters(poolId, priorityFee, fee);
        _postLock();
    }


    /// @inheritdoc IPortfolioActions
    function allocate(
        bool useMax,
        address recipient,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 maxDeltaAsset,
        uint128 maxDeltaQuote
    ) external payable returns (uint256 deltaAsset, uint256 deltaQuote) {
        _preLock();
        if (_currentMulticall == false) _deposit();

        if (poolId == 0) poolId = _getLastPoolId;
        if (getStrategy(poolId) == address(0)) {
            revert Portfolio_NonExistentPool(poolId);
        }
        if (!IStrategy(getStrategy(poolId)).validatePool(poolId)) {
            revert Portfolio_InvalidPool(poolId);
        }

        (maxDeltaAsset, maxDeltaQuote) = _scaleAmountsToWad({
            poolId: poolId,
            amountAssetDec: maxDeltaAsset,
            amountQuoteDec: maxDeltaQuote
        });

        PortfolioPair memory pair = pairs[PoolId.wrap(poolId).pairId()];

        if (useMax) {
            // A positive net balance is a surplus of tokens in the accounting state that can be used to mint liquidity.
            int256 surplusAsset = getNetBalance(pair.tokenAsset);
            int256 surplusQuote = getNetBalance(pair.tokenQuote);

            if (surplusAsset < 0) surplusAsset = 0;
            if (surplusQuote < 0) surplusQuote = 0;

            (uint128 surplusAssetWad, uint128 surplusQuoteWad) =
            _scaleAmountsToWad({
                poolId: poolId,
                amountAssetDec: uint256(surplusAsset),
                amountQuoteDec: uint256(surplusQuote)
            });

            deltaLiquidity = pools[poolId].getPoolMaxLiquidity({
                deltaAsset: surplusAssetWad,
                deltaQuote: surplusQuoteWad
            });
        }

        if (deltaLiquidity == 0) revert Portfolio_ZeroLiquidityAllocate();
        (deltaAsset, deltaQuote) = pools[poolId].getPoolLiquidityDeltas(
            AssemblyLib.toInt128(deltaLiquidity)
        ); // note: Rounds up.

        if (deltaAsset > maxDeltaAsset) revert Portfolio_MaxAssetExceeded();
        if (deltaQuote > maxDeltaQuote) revert Portfolio_MaxQuoteExceeded();

        ChangeLiquidityParams memory args = ChangeLiquidityParams({
            owner: recipient,
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

        if (deltaAsset == 0 && deltaQuote == 0) {
            revert Portfolio_ZeroAmountsAllocate();
        }

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

    /// @inheritdoc IPortfolioActions
    function deallocate(
        bool useMax,
        uint64 poolId,
        uint128 deltaLiquidity,
        uint128 minDeltaAsset,
        uint128 minDeltaQuote
    ) external payable returns (uint256 deltaAsset, uint256 deltaQuote) {
        _preLock();

        if (_currentMulticall == false) _deposit();

        if (!IStrategy(getStrategy(poolId)).validatePool(poolId)) {
            revert Portfolio_NonExistentPool(poolId);
        }

        (minDeltaAsset, minDeltaQuote) = _scaleAmountsToWad({
            poolId: poolId,
            amountAssetDec: minDeltaAsset,
            amountQuoteDec: minDeltaQuote
        });

        PortfolioPair memory pair = pairs[PoolId.wrap(poolId).pairId()];
        (address asset, address quote) = (pair.tokenAsset, pair.tokenQuote);

        if (useMax) {
            deltaLiquidity = balanceOf[msg.sender][poolId].safeCastTo128();
        }

        if (deltaLiquidity == 0) revert Portfolio_ZeroLiquidityDeallocate();
        (deltaAsset, deltaQuote) = pools[poolId].getPoolLiquidityDeltas(
            -AssemblyLib.toInt128(deltaLiquidity)
        ); // note: Rounds down.

        if (deltaAsset < minDeltaAsset) revert Portfolio_MinAssetExceeded();
        if (deltaQuote < minDeltaQuote) revert Portfolio_MinQuoteExceeded();

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
     * @dev
     * Manipulates reserves depending on if liquidity is being allocated or deallocated.
     * If allocating to an instantiated pool, a minimum amount of liquidity is permanently
     * burned to prevent the pool from reaching 0 liquidity.
     */
    function _changeLiquidity(ChangeLiquidityParams memory args) internal returns (uint256 feeAsset, uint256 feeQuote, uint256 invariantGrowth) {
        (PortfolioPool storage pool, PortfolioPosition storage position) = (pools[args.poolId], positions[args.owner][args.poolId]);

        (feeAsset, feeQuote, invariantGrowth) = position.syncPositionFees(
            pool.feeGrowthGlobalAsset, pool.feeGrowthGlobalQuote, pool.invariantGrowthGlobal
        );

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
                revert Portfolio_InsufficientLiquidity();
            }
            positionLiquidity -= int128(uint128(BURNED_LIQUIDITY));
        }

        if (positionLiquidity > 0) {
            _mint(
                args.owner, args.poolId, uint256(int256(positionLiquidity)), ""
            );
        } else {
            _burn(args.owner, args.poolId, uint256(-int256(positionLiquidity)));
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

    /// @inheritdoc IPortfolioActions
    function swap(Order calldata args)
        external
        payable
        returns (uint64 poolId, uint256 input, uint256 output)
    {
        _preLock();
        if (_currentMulticall == false) _deposit();

        // Return and event variables are kept in native token decimals.
        (poolId, input, output) = (args.poolId, args.input, args.output);

        PortfolioPool storage pool = pools[args.poolId];
        if (!pool.exists()) revert Portfolio_NonExistentPool(poolId);
        if (pool.isEmpty()) revert Portfolio_ZeroSwapLiquidity();

        IStrategy strategy = IStrategy(getStrategy(poolId));
        if (!strategy.validatePool(poolId)) revert Portfolio_InvalidPool(poolId);// forgefmt: disable-line

        // Sets the pool's lastTimestamp to the current block timestamp, in storage.
        pool.syncPoolTimestamp(block.timestamp);

        // Call the beforeSwap hook to get the pre-swap invariant.
        (bool success, int256 invariant) =
            strategy.beforeSwap(poolId, args.sellAsset, msg.sender);
        if (!success) revert Portfolio_BeforeSwapFail();

        // Load input and output token information with respective pair tokens.
        PortfolioPair memory pair = pairs[PoolId.wrap(poolId).pairId()];

        // Swap requires an intermediary state where all units are in WAD.
        SwapState memory inter;
        if (args.sellAsset) {
            inter.decimalsInput = pair.decimalsAsset;
            inter.decimalsOutput = pair.decimalsQuote;
            inter.tokenInput = pair.tokenAsset;
            inter.tokenOutput = pair.tokenQuote;
            inter.feeGrowthGlobal = pool.feeGrowthGlobalAsset;
        } else {
            inter.decimalsInput = pair.decimalsQuote;
            inter.decimalsOutput = pair.decimalsAsset;
            inter.tokenInput = pair.tokenQuote;
            inter.tokenOutput = pair.tokenAsset;
            inter.feeGrowthGlobal = pool.feeGrowthGlobalQuote;
        }

        // Overwrites the input argument with the token surplus, if available.
        if (args.useMax) {
            // Net balance is the surplus of tokens in the accounting state that can be spent.
            int256 netBalance = getNetBalance(inter.tokenInput);
            if (netBalance > 0) {
                input = uint256(netBalance).safeCastTo128();
            }
        }

        inter.prevInvariant = invariant;
        inter.amountInputUnit = input;
        inter.amountOutputUnit = output;
        inter.liquidity = pool.liquidity;

        // Converts input and output amounts to WAD units for the swap math.
        inter = inter.toWad();

        // ====== Enter Intermediary State ====== //

        if (inter.amountOutputUnit == 0) revert Portfolio_ZeroSwapOutput();
        if (inter.amountInputUnit == 0) revert Portfolio_ZeroSwapInput();

        // Copy the swap amount args and edit them with the WAD scaled ones.
        Order memory orderInWad = args;

        (orderInWad.input, orderInWad.output) = (
            inter.amountInputUnit.safeCastTo128(),
            inter.amountOutputUnit.safeCastTo128()
        );

        {
            // Compute the respective fee and protocol fee amounts.
            // Compute the reserves after applying the desired swap amounts and fees.
            bool sellAsset = args.sellAsset;
            uint256 adjustedVirtualX;
            uint256 adjustedVirtualY;
            (
                inter.feeAmountUnit,
                inter.protocolFeeAmountUnit,
                adjustedVirtualX,
                adjustedVirtualY
            ) = orderInWad.computeSwapResult(
                pool.virtualX, pool.virtualY, pool.feeBasisPoints, protocolFee
            );

            // ====== Invariant Check ====== //

            bool validInvariant;
            (validInvariant, inter.nextInvariant) = strategy.validateSwap(
                poolId, inter.prevInvariant, adjustedVirtualX, adjustedVirtualY 
            );

            if (!validInvariant) {
                revert Portfolio_InvalidInvariant(
                    inter.prevInvariant, inter.nextInvariant
                );
            }
        }

        // In the case of a non-zero protocol fee, a small portion of the input amount (protocol fee) is not re-invested to the pool.
        // Therefore, to properly sync the pool's reserve, the protocol fee must be subtracted from the input.
        // Take the protocol fee from the input amount, so that protocol fee is not re-invested into pool.
        // Increases the independent pool reserve by the input amount, including fee and excluding protocol fee.
        // Decrease the dependent pool reserve by the output amount.
        pool.adjustReserves(
            args.sellAsset,
            inter.amountInputUnit - inter.protocolFeeAmountUnit,
            inter.amountOutputUnit
        );
        // returns false if the invariant is > 0
        bool valid = strategy.checkInvariant(poolId, pool);
        if (!valid) {
            // If the invariant is > 0, the pool is segmented and the fees are not reinvested.
            pool.adjustReserves(
                !args.sellAsset,
                0,
                inter.feeAmountUnit
            );
            inter.feeGrowthGlobal += inter.feeAmountUnit;
        }

        // Increasing reserves requires Portfolio's balance of tokens to also increases by the end of `settlement`.
        _increaseReserves(inter.tokenInput, inter.amountInputUnit);
        // Decreasing reserves creates a surplus in Portfolio's balance, which is transferred out in `settlement`.
        _decreaseReserves(inter.tokenOutput, inter.amountOutputUnit);

        if (inter.protocolFeeAmountUnit != 0) {
            // protocolFees are stored in WAD units, which requires Unit = WAD on protocolFeeAmount.
            protocolFees[inter.tokenInput] += inter.protocolFeeAmountUnit;
        }

        // ====== Exit Intermediary State ====== //

        // Amounts are scaled back to their original decimals for the swap event and return variables.
        inter = inter.fromWad();

        // Swap event emits amounts in native token decimals.
        emit Swap(
            poolId,
            args.sellAsset,
            inter.tokenInput,
            input,
            inter.tokenOutput,
            output,
            inter.feeAmountUnit,
            inter.nextInvariant
        );

        if (_currentMulticall == false) _settlement();
        _postLock();
    }

    /// @inheritdoc IPortfolioActions
    function createPair(
        address asset,
        address quote
    ) external payable returns (uint24 pairId) {
        _preLock();

        if (asset == quote) revert Portfolio_DuplicateToken();

        pairId = getPairId[asset][quote];
        if (pairId != 0) revert Portfolio_PairExists(pairId);

        (uint8 decimalsAsset, uint8 decimalsQuote) =
            (IERC20(asset).decimals(), IERC20(quote).decimals());
        if (
            !decimalsAsset.isBetween(
                ConstantsLib.MIN_DECIMALS, ConstantsLib.MAX_DECIMALS
            )
        ) {
            revert Portfolio_InvalidDecimals(decimalsAsset);
        }
        if (
            !decimalsQuote.isBetween(
                ConstantsLib.MIN_DECIMALS, ConstantsLib.MAX_DECIMALS
            )
        ) {
            revert Portfolio_InvalidDecimals(decimalsQuote);
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

    /// @inheritdoc IPortfolioActions
    function createPool(
        uint24 pairId,
        uint256 reserveXPerWad,
        uint256 reserveYPerWad,
        uint16 feeBasisPoints,
        uint16 priorityFeeBasisPoints,
        address controller,
        address strategy,
        bytes calldata strategyArgs
    ) public payable virtual returns (uint64 poolId) {
        _preLock();

        // Use a 0 `pairId` to create a pool with the last created pair.
        uint24 pairNonce = pairId == 0 ? getPairNonce : pairId;
        if (pairNonce == 0) revert Portfolio_InvalidPairNonce();

        // Increment the pool nonce.
        uint32 poolNonce = ++getPoolNonce[pairNonce];

        // Compute the poolId, which is a packed 64-bit integer.
        poolId = PoolIdLib.encode(
            false, // Flips the "altered" flag in the upper 4 bits: "0x10..."
            controller != address(0), // Flips the "controlled" flag in the lower 4 bits:  "0x01..."
            pairNonce,
            poolNonce
        );

        // Instantiate the pool.
        pools[poolId].createPool({
            reserveX: reserveXPerWad,
            reserveY: reserveYPerWad,
            feeBasisPoints: feeBasisPoints,
            strategy: strategy
        });

        // Store the last created poolId for the multicall, to make sure the user is not frontrun.
        _getLastPoolId = poolId;

        // This call also prevents accidently creating a pool with an invalid strategy target address.
        bool success =
            IStrategy(getStrategy(poolId)).afterCreate(poolId, strategyArgs);
        if (!success) revert Portfolio_AfterCreateFail();

        emit CreatePool(
            poolId,
            pairs[pairNonce].tokenAsset,
            pairs[pairNonce].tokenQuote,
            reserveXPerWad,
            reserveYPerWad,
            feeBasisPoints,
            priorityFeeBasisPoints,
            controller,
            strategy
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
        PortfolioPair memory pair = pairs[PoolId.wrap(poolId).pairId()];

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
     * @dev Be aware of these settlement invariants:
     *      Invariant 1. Every token that is interacted with is cached and exists.
     *      Invariant 2. Tokens are removed from cache and cache is empty by end of settlement.
     *      Invariant 3. Cached tokens cannot be carried over from previous transactions.
     *      Invariant 4. Execution does not exit during the loops prematurely.
     *      Invariant 5. Account `settled` bool is set to true at end of `settlement`.
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
                        balance: AccountLib.__balanceOf__(token, address(this))
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
                    AccountLib.__dangerousUnwrapEther__(
                        WETH, msg.sender, amountTransferTo
                    );
                } else {
                    AccountLib.SafeTransferLib.safeTransfer(
                        token, msg.sender, amountTransferTo
                    );
                }

                uint256 post = AccountLib.__balanceOf__(token, address(this));
                uint256 expected = prev - amountTransferTo;
                if (post < expected) {
                    revert Portfolio_Insolvent(
                        token, int256(post) - int256(expected)
                    );
                }
            } else if (amountTransferFrom > 0) {
                uint256 prev = payments[index].balance;

                // Interaction
                AccountLib.SafeTransferLib.safeTransferFrom(
                    token, msg.sender, address(this), amountTransferFrom
                );

                uint256 post = AccountLib.__balanceOf__(token, address(this));
                uint256 expected = prev + amountTransferFrom;
                if (post < expected) {
                    revert Portfolio_Insolvent(
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

    /// @inheritdoc IPortfolioRegistryActions
    function claimFee(address token, uint256 amount) external override {
        _preLock();

        if (msg.sender != IPortfolioRegistry(REGISTRY).controller()) {
            revert Portfolio_NotController();
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

        emit ClaimFees(token, amount);

        if (_currentMulticall == false) _settlement();
        _postLock();
    }

    /// @inheritdoc IPortfolioRegistryActions
    function setProtocolFee(uint256 fee) external override {
        _preLock();

        if (msg.sender != IPortfolioRegistry(REGISTRY).controller()) {
            revert Portfolio_NotController();
        }
        if (fee > 20 || fee < 4) {
            revert Portfolio_InvalidProtocolFee(fee);
        }

        uint256 prevFee = protocolFee;
        protocolFee = fee;

        emit UpdateProtocolFee(prevFee, fee);

        _postLock();
    }

    // ===== Public View ===== //

    /// @inheritdoc IPortfolioView
    function getLiquidityDeltas(
        uint64 poolId,
        int128 deltaLiquidity
    ) public view returns (uint128 deltaAsset, uint128 deltaQuote) {
        (uint256 deltaAssetWad, uint256 deltaQuoteWad) =
            pools[poolId].getPoolLiquidityDeltas(deltaLiquidity);

        PortfolioPair memory pair = pairs[PoolId.wrap(poolId).pairId()];

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

    /// @inheritdoc IPortfolioView
    function getMaxLiquidity(
        uint64 poolId,
        uint256 amount0,
        uint256 amount1
    ) public view returns (uint128 deltaLiquidity) {
        PortfolioPair memory pair = pairs[PoolId.wrap(poolId).pairId()];

        (amount0, amount1) = (
            amount0.scaleToWad(pair.decimalsAsset),
            amount1.scaleToWad(pair.decimalsQuote)
        );

        return pools[poolId].getPoolMaxLiquidity(amount0, amount1);
    }

    /// @inheritdoc IPortfolioView
    function getPoolReserves(uint64 poolId)
        public
        view
        override
        returns (uint256 deltaAsset, uint256 deltaQuote)
    {
        (uint256 deltaAssetWad, uint256 deltaQuoteWad) =
            pools[poolId].getPoolReserves();

        PortfolioPair memory pair = pairs[PoolId.wrap(poolId).pairId()];

        deltaAsset = deltaAssetWad.scaleFromWadDown(pair.decimalsAsset);
        deltaQuote = deltaQuoteWad.scaleFromWadDown(pair.decimalsQuote);
    }

    /// @inheritdoc IPortfolioStrategy
    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn,
        address swapper
    ) public view virtual returns (uint256 output) {
        return IStrategy(getStrategy(poolId)).getAmountOut(
            poolId, sellAsset, amountIn, swapper
        );
    }

    /// @inheritdoc IPortfolioStrategy
    function getSpotPrice(uint64 poolId)
        public
        view
        virtual
        returns (uint256 price)
    {
        return IStrategy(getStrategy(poolId)).getSpotPrice(poolId);
    }

    /// @inheritdoc IPortfolioStrategy
    function getMaxOrder(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external view virtual returns (Order memory) {
        return IStrategy(getStrategy(poolId)).getMaxOrder(
            poolId, sellAsset, swapper
        );
    }

    /// @inheritdoc IPortfolioView
    function getStrategy(uint64 poolId) public view returns (address) {
        return pools[poolId].strategy;
    }

    /// @inheritdoc IPortfolioStrategy
    function simulateSwap(
        Order memory order,
        uint256 timestamp,
        address swapper
    )
        external
        view
        virtual
        override
        returns (bool success, int256 prevInvariant, int256 postInvariant)
    {
        return IStrategy(getStrategy(order.poolId)).simulateSwap(
            order, timestamp, swapper
        );
    }

    /// @inheritdoc IPortfolioStrategy
    function getInvariant(uint64 poolId) external view returns (int256) {
        return IStrategy(getStrategy(poolId)).getInvariant(poolId);
    }
}
