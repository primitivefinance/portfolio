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

function dangerousTransferETH(address to, uint256 value) {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH transfer error");
}

/// @title Enigma Virtual Machine.
/// @notice Stores the state of the Enigma with functions to change state.
/// @dev Implements low-level internal virtual functions, re-entrancy guard and state.
contract Hyper is IHyper {
    using SafeCast for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    using HyperSwapLib for HyperSwapLib.Expiring;

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                                      CONSTANTS                                                       |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

    /// @notice Current version of this contract.
    /// @dev Optimized function returning the version of this contract
    ///      while saving some bytes of storage (inspired by Seaport).
    /// @return "prototype-v1.0.0" encoded as a string
    function VERSION() public view returns (string memory) {
        // 33,089 bytes
        assembly {
            // Load 0x20 (32) in memory at slot 0x00, this corresponds to the
            // offset location of the next data.
            mstore(0x00, 0x20)

            // Then we load both the length of our string (0x10) and its actual value
            // (0x70726f746f747970652d76312e302e30) using the offset 0x30. Using this
            // particular offset value will right pad the length at the end of the slot
            // and left pad the string at the beginning of the next slot, assuring the
            // right ABI format to return a string.
            mstore(0x30, 0x1070726f746f747970652d76312e302e30)

            // Return all the 96 bytes (0x60) of data that was loaded into the memory.
            return(0x00, 0x60)
        }
    }

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

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                                      STORAGE                                                         |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

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

    /// @dev Pool id -> Auction Param Data Structure.
    mapping(uint48 => AuctionParams) auctionParams;

    /// @dev Pool id -> Auction Fees
    mapping(uint48 => uint128) auctionFees;

    /// @dev Pool id -> Curve Data Structure stores parameters.
    mapping(uint32 => Curve) public curves;

    /// @dev Pool id -> HyperPool Data Structure.
    mapping(uint48 => HyperPool) public pools;

    /// @dev Raw curve parameters packed into bytes32 mapped onto a Curve id when it was deployed.
    mapping(bytes32 => uint32) public getCurveId;

    /// @dev Token -> Physical Reserves.
    mapping(address => uint256) public globalReserves;

    /// @dev Pool id -> Tick -> Slot has liquidity at a price.
    mapping(uint48 => mapping(int24 => HyperSlot)) public slots;

    /// @dev Base Token -> Quote Token -> Pair id
    mapping(address => mapping(address => uint16)) public getPairId;

    /// @dev User -> Token -> Internal Balance.
    mapping(address => mapping(address => uint256)) public balances;

    /// @dev User -> Position Id -> Liquidity Position.
    mapping(address => mapping(uint96 => HyperPosition)) public positions;

    /// @dev Pool id -> Epoch Id -> Priority Payment Growth Global
    mapping(uint48 => mapping(uint256 => uint256)) internal priorityGrowthPoolSnapshot;

    /// @dev Pool id -> Tick -> Epoch Id -> Priority Payment Growth Outside
    mapping(uint48 => mapping(int24 => mapping(uint256 => uint256))) internal priorityGrowthSlotSnapshot;

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                                     MODIFIERS                                                        |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

    /// @dev Protection against reentracy
    modifier lock() {
        if (locked != 1) revert LockedError();

        locked = 2;
        _;
        locked = 1;
    }

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                                  SPECIAL FUNCTIONS                                                   |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

    /// @param weth_ Address of the WETH9 contract
    constructor(address weth_) {
        WETH = weth_;
    }

    // Note: Not sure if we should always revert when receiving ETH
    receive() external payable {
        revert();
    }

    // --- External functions directly callable (no instructions)  --- //

    // FIXME: Remove this as part of the auction reimplementation
    function setAuctionParams(
        uint48 poolId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 fee,
        uint256 length
    ) external {
        // todo: access control, add param checks
        AuctionParams storage params = auctionParams[poolId];
        if (startPrice != 0) params.startPrice = startPrice;
        if (endPrice != 0) params.endPrice = endPrice;
        if (fee != 0) params.fee = fee;
        if (length != 0) params.length = length;

        emit SetAuctionParams(poolId, params.startPrice, params.endPrice, params.fee, params.length);
    }

    // FIXME: Remove this as part of the auction reimplementation
    function collectAuctionFees(uint48 poolId) external {
        // todo: access control
        uint128 fees = auctionFees[poolId];
        if (fees > 0) {
            auctionFees[poolId] = 0;
            uint16 pairId = uint16(poolId >> 32);
            Pair memory pair = pairs[pairId];
            SafeTransferLib.safeTransfer(ERC20(pair.tokenQuote), msg.sender, fees);
        }
    }

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                                     ENTRY POINT                                                      |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

    /// @notice Main touchpoint for receiving calls.
    /// @dev Critical: data must be encoded properly to be processed.
    /// @custom:security Critical. Guarded against re-entrancy. This is like the bank vault door.
    /// @custom:mev Higher level security checks must be implemented by calling contract.
    fallback() external payable lock {
        if (msg.data[0] != Instructions.INSTRUCTION_JUMP) _process(msg.data);
        else _jumpProcess(msg.data);
        _settleBalances();
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
        } else if (instruction == Instructions.FILL_PRIORITY_AUCTION) {
            (poolId) = _fillPriorityAuction(data);
        } else if (instruction == Instructions.CREATE_POOL) {
            (poolId) = _createPool(data);
        } else if (instruction == Instructions.CREATE_CURVE) {
            _createCurve(data);
        } else if (instruction == Instructions.CREATE_PAIR) {
            _createPair(data);
        } else if (instruction == Instructions.COLLECT_FEES) {
            _collectFees(data);
        } else if (instruction == Instructions.DRAW) {
            // _draw(data);
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

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                                    INSTRUCTIONS                                                      |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

    //  +----------------------------------------------------------------------------------+
    //  |                                      FUNDS                                       |
    //  +----------------------------------------------------------------------------------+

    // FIXME: Remove this external function and add an instruction instead
    function draw(
        address token,
        uint256 amount,
        address to
    ) external lock {
        // note: Would pull tokens without this conditional check.
        if (balances[msg.sender][token] < amount) revert DrawBalance();
        _applyDebit(token, amount);

        if (token == WETH) _dangerousUnwrap(to, amount);
        else SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    // FIXME: Remove this external function and add an instruction instead
    function fund(address token, uint256 amount) external payable override lock {
        _adjustUserBalance(msg.sender, token, int256(amount));
        if (token == WETH) _safeWrap();
        else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
    }

    //  +----------------------------------------------------------------------------------+
    //  |                                     LIQUIDITY                                    |
    //  +----------------------------------------------------------------------------------+

    /**
     * @notice Enigma method to add liquidity to a range of prices in a pool.
     *
     * @custom:reverts If attempting to add liquidity to a pool that has not been created.
     * @custom:reverts If attempting to add zero liquidity.
     */
    function _addLiquidity(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint8 useMax, uint48 poolId_, int24 loTick, int24 hiTick, uint128 delLiquidity) = Decoder.decodeAddLiquidity(
            data
        ); // Packs the use max flag in the Enigma instruction code byte.
        poolId = poolId_;

        if (delLiquidity == 0) revert ZeroLiquidityError();
        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        // update pool, relevant slots with time
        _syncPool(poolId);

        _syncSlot(poolId, loTick);
        _syncSlot(poolId, hiTick);

        // Compute amounts of tokens for the real reserves.
        Curve memory curve = curves[uint32(poolId_)];
        HyperPool storage pool = pools[poolId_];
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
        (uint8 useMax, uint48 poolId_, uint16 pairId, int24 loTick, int24 hiTick, uint128 deltaLiquidity) = Decoder
            .decodeRemoveLiquidity(data); // Packs useMax flag into Enigma instruction code byte.

        if (deltaLiquidity == 0) revert ZeroLiquidityError();
        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        // update pool, relevant slots with time
        _syncPool(poolId_);

        _syncSlot(poolId, loTick);
        _syncSlot(poolId, hiTick);

        // Compute amounts of tokens for the real reserves.
        Curve memory curve = curves[uint32(poolId_)];
        HyperPool storage pool = pools[poolId_];
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
        if (loTick <= pool.lastTick && hiTick > pool.lastTick) {
            pool.liquidity -= deltaLiquidity;
        }

        // Todo: delete any slots if uninstantiated.

        // Todo: update bitmap of instantiated/uninstantiated slots.

        _decreasePosition(poolId_, loTick, hiTick, deltaLiquidity);

        // note: Global reserves are referenced at end of processing to determine amounts of token to transfer.
        Pair memory pair = pairs[pairId];
        _adjustGlobalBalance(pair.tokenBase, -int256(deltaR2));
        _adjustGlobalBalance(pair.tokenQuote, -int256(deltaR1));

        emit RemoveLiquidity(poolId_, pair.tokenBase, pair.tokenQuote, deltaR1, deltaR2, deltaLiquidity);
    }

    function _collectFees(bytes calldata data) internal {
        (uint96 positionId, uint128 amountAssetRequested, uint128 amountQuoteRequested) = Decoder.decodeCollectFees(
            data
        );

        // No need to check if the requested amounts are higher than the owed ones
        // because this would cause the next lines to revert.
        positions[msg.sender][positionId].tokensOwedAsset -= amountAssetRequested;
        positions[msg.sender][positionId].tokensOwedQuote -= amountQuoteRequested;

        // Right shift the positionId to keep only the pairId part (first 2 bytes).
        uint16 pairId = uint16(positionId >> 80);

        // Should save some gas
        Pair memory pair = pairs[pairId];

        if (amountAssetRequested > 0)
            _adjustUserBalance(msg.sender, pair.tokenBase, int256(int128(amountAssetRequested)));
        if (amountQuoteRequested > 0)
            _adjustUserBalance(msg.sender, pair.tokenQuote, int256(int128(amountAssetRequested)));

        emit Collect(
            positionId,
            msg.sender,
            amountAssetRequested,
            pair.tokenBase,
            amountQuoteRequested,
            pair.tokenQuote
        );
    }

    //  +----------------------------------------------------------------------------------+
    //  |                                     SWAPPING                                     |
    //  +----------------------------------------------------------------------------------+

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
        (args.useMax, args.poolId, args.input, args.limit, args.direction) = Decoder.decodeSwap(data); // Packs useMax flag into Enigma instruction code byte.

        if (args.input == 0) revert ZeroInput();
        if (!_doesPoolExist(args.poolId)) revert NonExistentPool(args.poolId);

        state.sell = args.direction == 0; // args.direction == 0 ? Swap asset for quote : Swap quote for asset.

        // Pair is used to update global reserves and check msg.sender balance.
        Pair memory pair = pairs[uint16(args.poolId >> 32)];
        // Pool is used to fetch information and eventually have its state updated.
        HyperPool storage pool = pools[args.poolId];

        state.feeGrowthGlobal = state.sell ? pool.feeGrowthGlobalAsset : pool.feeGrowthGlobalQuote;

        // Get the variables for first iteration of the swap.
        SwapIteration memory swap;
        {
            // Writes the pool after computing its updated price with respect to time elapsed since last update.
            (uint256 price, int24 tick) = _syncPool(args.poolId);
            // Expect the caller to exhaust their entire balance of the input token.
            remainder = args.useMax == 1 ? _balanceOf(pair.tokenBase, msg.sender) : args.input;
            // Begin the iteration at the live price & tick, using the total swap input amount as the remainder to fill.
            swap = SwapIteration({
                price: price,
                tick: tick,
                feeAmount: 0,
                remainder: remainder,
                liquidity: pool.liquidity,
                stakedLiquidity: pool.stakedLiquidity,
                pendingStakedLiquidityDelta: pool.pendingStakedLiquidityDelta,
                input: 0,
                output: 0
            });
        }

        // Store the pool transiently, then delete after the swap.
        HyperSwapLib.Expiring memory expiring;
        {
            // Curve stores the parameters of the trading function.
            Curve memory curve = curves[uint32(args.poolId)];

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

            // todo: get the next tick with active liquidity.

            // Get the max amount that can be filled for a max distance swap.
            uint256 maxInput = (nextIndependent - liveIndependent).mulWadDown(swap.liquidity); // Active liquidity acts as a multiplier.
            // Calculate the amount of fees paid at this tick.
            swap.feeAmount = ((swap.remainder >= maxInput ? maxInput : swap.remainder) * (1e4 - state.gamma)) / 10_000;
            state.feeGrowthGlobal = FixedPointMathLib.divWadDown(swap.feeAmount, swap.liquidity);
            // Compute amount to swap in this step.
            // If the full tick is crossed, reduce the remainder of the trade by the max amount filled by the tick.
            if (swap.remainder >= maxInput) {
                delta = maxInput - swap.feeAmount;

                Order memory _args = args;
                SwapState memory _state = state;
                SwapIteration memory _swap = swap;
                HyperPool storage _pool = pool;

                {
                    // Entering or exiting the tick will transition the pool's active range.
                    (
                        int256 liquidityDelta,
                        int256 stakedLiquidityDelta,
                        int256 pendingStakedLiquidityDelta
                    ) = _transitionSlot(
                            _args.poolId,
                            _swap.tick,
                            (_state.sell ? _state.feeGrowthGlobal : _pool.feeGrowthGlobalAsset),
                            (_state.sell ? _pool.feeGrowthGlobalQuote : _state.feeGrowthGlobal),
                            _pool.priorityGrowthGlobal
                        );

                    _swap.liquidity = signedAdd(_swap.liquidity, liquidityDelta);
                    _swap.stakedLiquidity = signedAdd(_swap.stakedLiquidity, stakedLiquidityDelta);
                    _swap.pendingStakedLiquidityDelta += pendingStakedLiquidityDelta;
                }

                // Update variables for next iteration.
                swap.tick = nextTick; // Set the next slot.
                swap.price = nextPrice; // Set the next price according to the next slot.
                swap.remainder -= delta + swap.feeAmount; // Reduce the remainder of the order to fill.

                // Save liquidity values changed by slot transition
                swap.liquidity = _swap.liquidity;
                swap.stakedLiquidity = _swap.stakedLiquidity;
                swap.pendingStakedLiquidityDelta = _swap.pendingStakedLiquidityDelta;
            } else {
                // Reaching this block will fill the order. Set the swap input
                delta = swap.remainder - swap.feeAmount;
                nextIndependent = liveIndependent + delta.divWadDown(swap.liquidity);

                delta = swap.remainder; // the swap input should increment the non-fee applied amount
                swap.remainder = 0; // Reduce the remainder to zero, as the order has been filled.
            }

            // Compute the output of the swap by computing the difference between the dependent reserves.
            if (state.sell) nextDependent = expiring.computeR1WithR2(nextIndependent, 0, 0);
            else nextDependent = expiring.computeR2WithR1(nextIndependent, 0, 0);
            swap.input += delta; // Add to the total input of the swap.
            swap.output += liveDependent - nextDependent;
        } while (swap.remainder != 0 && args.limit > swap.price);

        // Update Pool State Effects
        if (pool.lastPrice != swap.price) pool.lastPrice = swap.price;
        if (pool.lastTick != swap.tick) pool.lastTick = swap.tick;
        if (pool.liquidity != swap.liquidity) pool.liquidity = swap.liquidity;
        if (pool.stakedLiquidity != swap.stakedLiquidity) pool.stakedLiquidity = swap.stakedLiquidity;
        if (pool.pendingStakedLiquidityDelta != swap.pendingStakedLiquidityDelta)
            pool.pendingStakedLiquidityDelta = swap.pendingStakedLiquidityDelta;

        uint256 feeGrowthGlobalAsset = state.sell ? state.feeGrowthGlobal : 0;
        uint256 feeGrowthGlobalQuote = state.sell ? 0 : state.feeGrowthGlobal;
        if (feeGrowthGlobalAsset > 0) pool.feeGrowthGlobalAsset += feeGrowthGlobalAsset;
        if (feeGrowthGlobalQuote > 0) pool.feeGrowthGlobalQuote += feeGrowthGlobalQuote;

        // Update Global Balance Effects
        // Return variables and swap event.
        (poolId, remainder, input, output) = (args.poolId, swap.remainder, swap.input, swap.output);
        emit Swap(args.poolId, swap.input, swap.output, pair.tokenBase, pair.tokenQuote);

        _adjustGlobalBalance(pair.tokenBase, int256(swap.input));
        _adjustGlobalBalance(pair.tokenQuote, -int256(swap.output));
    }

    //  +----------------------------------------------------------------------------------+
    //  |                                      STAKING                                     |
    //  +----------------------------------------------------------------------------------+

    function _stakePosition(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint48 poolId_, uint96 positionId) = Decoder.decodeStakePosition(data);
        poolId = poolId_;

        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        _syncPool(poolId);

        HyperPosition storage pos = positions[msg.sender][positionId];

        // update slots
        _syncSlot(poolId, pos.loTick);
        _syncSlot(poolId, pos.hiTick);

        // update staked position
        _syncPosition(pos, poolId);

        if (pos.pendingStakedLiquidityDelta != 0 || pos.stakedLiquidity != 0) revert PositionStakedError(positionId);
        if (pos.totalLiquidity == 0) revert PositionZeroLiquidityError(positionId);

        // update position
        pos.pendingStakedLiquidityDelta = int256(pos.totalLiquidity);
        pos.pendingStakedEpoch = epochs[poolId].id;

        // update slots
        _increaseSlotPendingStake(poolId, pos.loTick, pos.totalLiquidity, false);
        _increaseSlotPendingStake(poolId, pos.hiTick, pos.totalLiquidity, true);

        // update pool
        HyperPool storage pool = pools[poolId_];
        if (pos.loTick <= pool.lastTick && pos.hiTick > pool.lastTick) {
            // if position's liquidity is in range, add to next epoch's delta
            pool.pendingStakedLiquidityDelta += int256(pos.totalLiquidity);
        }

        // emit Stake Position
    }

    function _unstakePosition(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint48 poolId_, uint96 positionId) = Decoder.decodeUnstakePosition(data);
        poolId = poolId_;

        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        _syncPool(poolId);

        HyperPosition storage pos = positions[msg.sender][positionId];

        // update slots
        _syncSlot(poolId, pos.loTick);
        _syncSlot(poolId, pos.hiTick);

        // update staked position
        _syncPosition(pos, poolId);

        if (pos.pendingStakedLiquidityDelta == 0 && pos.stakedLiquidity == 0) revert PositionNotStakedError(positionId);

        pos.pendingStakedLiquidityDelta = -int256(pos.totalLiquidity);
        pos.unstakedEpoch = epochs[poolId].id;

        _decreaseSlotPendingStake(poolId, pos.loTick, pos.totalLiquidity, false);
        _decreaseSlotPendingStake(poolId, pos.hiTick, pos.totalLiquidity, true);

        HyperPool storage pool = pools[poolId_];
        if (pos.loTick <= pool.lastTick && pos.hiTick > pool.lastTick) {
            // if position's liquidity is in range, add to next epoch's delta
            pool.pendingStakedLiquidityDelta -= int256(pos.totalLiquidity);
        }

        // emit Unstake Position
    }

    //  +----------------------------------------------------------------------------------+
    //  |                                      CREATION                                    |
    //  +----------------------------------------------------------------------------------+

    /**
     * @notice Uses a pair and curve to instantiate a pool at a price.
     *
     * @custom:reverts If price is 0.
     * @custom:reverts If pool with pair and curve has already been created.
     * @custom:reverts If an expiring pool and the current timestamp is beyond the pool's maturity parameter.
     */
    function _createPool(bytes calldata data) internal returns (uint48 poolId) {
        (uint48 poolId_, uint16 pairId, uint32 curveId, uint128 price) = Decoder.decodeCreatePool(data);

        if (price == 0) revert ZeroPrice();

        // Zero id values are magic variables, since no curve or pair can have an id of zero.
        if (pairId == 0) pairId = uint16(getPairNonce);
        if (curveId == 0) curveId = uint32(getCurveNonce);
        poolId = uint48(bytes6(abi.encodePacked(pairId, curveId)));
        if (_doesPoolExist(poolId)) revert PoolExists();

        Curve memory curve = curves[curveId];
        (uint128 strike, uint48 maturity, uint24 sigma) = (curve.strike, curve.maturity, curve.sigma);

        bool perpetual;
        assembly {
            perpetual := iszero(or(strike, or(maturity, sigma))) // Equal to (strike | maturity | sigma) == 0, which returns true if all three values are zero.
        }

        uint128 timestamp = _blockTimestamp();
        if (!perpetual && timestamp > curve.maturity) revert PoolExpiredError();

        // Write the epoch data
        epochs[poolId] = Epoch({id: 0, endTime: timestamp + EPOCH_INTERVAL, interval: EPOCH_INTERVAL});

        // Write the pool to state with the desired price.
        pools[poolId].lastPrice = price;
        pools[poolId].lastTick = HyperSwapLib.computeTickWithPrice(price); // todo: implement slot and price grid.
        pools[poolId].blockTimestamp = timestamp;

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
        (uint24 sigma, uint32 maturity, uint16 fee, uint16 priorityFee, uint128 strike) = Decoder.decodeCreateCurve(
            data
        ); // Expects Enigma encoded data.

        bytes32 rawCurveId = toBytes32(data[1:]); // note: Trims the single byte Enigma instruction code.

        curveId = getCurveId[rawCurveId]; // Gets the nonce of this raw curve, if it was created already.
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
        (address asset, address quote) = Decoder.decodeCreatePair(data); // Expects Engima encoded data.
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

    //  +----------------------------------------------------------------------------------+
    //  |                                 PRIORITY AUCTION                                 |
    //  +----------------------------------------------------------------------------------+

    // FIXME: This part needs to be refactored due to the change of the auction mechanism (no more Dutch auction)

    function _fillPriorityAuction(bytes calldata data) internal returns (uint48 poolId) {
        (uint48 poolId_, address priorityOwner, uint128 limitAmount) = Decoder.decodeFillPriorityAuction(data);

        if (!_doesPoolExist(poolId_)) revert();
        if (priorityOwner == address(0)) revert();

        _syncPool(poolId);

        HyperPool storage pool = pools[poolId_];
        if (pool.prioritySwapper != address(0)) revert();

        Epoch memory epoch = epochs[poolId_];
        if (epoch.endTime <= _blockTimestamp()) revert();

        AuctionParams memory poolAuctionParams = auctionParams[poolId];
        uint128 auctionPayment = _calculateAuctionPayment(
            poolAuctionParams.startPrice,
            poolAuctionParams.endPrice,
            0,
            _blockTimestamp()
        );
        require(auctionPayment <= limitAmount);

        uint128 auctionFee = _calculateAuctionFee(auctionPayment, poolAuctionParams.fee);
        uint128 auctionNet = auctionPayment - auctionFee;
        uint256 epochTimeRemaining = epoch.endTime - _blockTimestamp();

        // save pool's priority payment per second
        pool.priorityPaymentPerSecond = FixedPointMathLib.divWadDown(auctionNet, epochTimeRemaining);

        // set new priority swapper
        pool.prioritySwapper = priorityOwner;

        // save auction fees
        auctionFees[poolId_] += auctionFee;

        // add debit payable by auction filler
        uint16 pairId = uint16(poolId >> 32);
        Pair memory pair = pairs[pairId];
        _adjustGlobalBalance(pair.tokenQuote, int128(auctionPayment));
    }

    function _calculateAuctionPayment(
        uint256 startPrice,
        uint256 endPrice,
        uint256 startTime,
        uint256 fillTime
    ) internal returns (uint128 auctionPayment) {
        return 0;
    }

    function _calculateAuctionFee(uint128 auctionPayment, uint256 fee) internal returns (uint128 auctionFee) {
        return 0;
    }

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                             STATE ALTERING FUNCTIONS                                                 |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

    /// @dev A positive credit is a receivable paid to the `msg.sender` internal balance.
    ///      Positive credits are only applied to the internal balance of the account.
    ///      Therefore, it does not require a state change for the global reserves.
    ///
    ///      Dangerous! Calls to external contract with an inline assembly `safeTransferFrom`.
    ///      A positive debit is a cost that must be paid for a transaction to be processed.
    ///      If a balance exists for the token for the internal balance of `msg.sender`,
    ///      it will be used to pay the debit.
    ///      Else, tokens are expected to be transferred into this contract using `transferFrom`.
    ///      Externally paid debits increase the balance of the contract, so the global
    ///      reserves must be increased.
    /// @custom:security Critical. Only method which credits / debits accounts with tokens.
    function _adjustUserBalance(
        address user,
        address token,
        int256 amount
    ) internal {
        if (amount > 0) {
            unchecked {
                balances[msg.sender][token] += uint256(amount);
            }
        } else {
            uint256 _amount = uint256(~amount + 1); // Funky bits manipulation turning negative amounts positive
            if (balances[msg.sender][token] >= _amount) balances[msg.sender][token] -= _amount;
            else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), _amount);
        }

        emit AdjustUserBalance(user, token, amount);
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

    /// @dev Most important function because it manages the solvency of the Engima.
    /// @custom:security Critical. Global balances of tokens are compared with the actual `balanceOf`.
    function _adjustGlobalBalance(address token, int256 amount) internal {
        if (amount > 0) {
            unchecked {
                globalReserves[token] += uint256(amount);
            }
        } else {
            globalReserves[token] -= uint256(~amount + 1);
        }

        emit AdjustGlobalBalance(token, amount);
    }

    // --- Positions --- //

    /// @dev Assumes the position is properly allocated to an account by the end of the transaction.
    /// @custom:security High. Only method of increasing the liquidity held by accounts.
    function _increasePosition(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint256 deltaLiquidity
    ) internal {
        uint96 positionId = uint96(bytes12(abi.encodePacked(poolId, loTick, hiTick)));

        HyperPosition storage pos = positions[msg.sender][positionId];

        _syncPosition(pos, poolId);

        // initialize the position's ticks if not previously set
        if (pos.loTick == 0 && pos.hiTick == 0) {
            pos.loTick = loTick;
            pos.hiTick = hiTick;
        }

        (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) = _getFeeGrowthInside(
            poolId,
            hiTick,
            loTick,
            pools[poolId].lastTick,
            pools[poolId].feeGrowthGlobalAsset,
            pools[poolId].feeGrowthGlobalQuote
        );

        if (pos.totalLiquidity == 0) {
            // initialize fee growth inside
            pos.feeGrowthInsideAssetLast = feeGrowthInsideAsset;
            pos.feeGrowthInsideQuoteLast = feeGrowthInsideQuote;
        } else {
            _updatePositionFees(pos, poolId, feeGrowthInsideAsset, feeGrowthInsideQuote);
        }

        if (pos.pendingStakedLiquidityDelta != 0 || pos.stakedLiquidity != 0) {
            // position is already staked, add to pending stake amount
            pos.pendingStakedLiquidityDelta += int256(deltaLiquidity);
            pos.pendingStakedEpoch = epochs[poolId].id;

            HyperPool storage pool = pools[poolId];
            if (loTick <= pool.lastTick && hiTick > pool.lastTick) {
                pool.pendingStakedLiquidityDelta += int256(deltaLiquidity);
            }

            // update slots
            _increaseSlotPendingStake(poolId, pos.loTick, pos.totalLiquidity, false);
            _increaseSlotPendingStake(poolId, pos.hiTick, pos.totalLiquidity, true);

            // emit IncreasePendingStake
        }

        pos.totalLiquidity += deltaLiquidity.toUint128();
        emit IncreasePosition(msg.sender, positionId, deltaLiquidity);
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

        HyperPosition storage pos = positions[msg.sender][positionId];

        _syncPosition(pos, poolId);

        if (pos.pendingStakedLiquidityDelta != 0 || pos.stakedLiquidity != 0) revert PositionStakedError(positionId);

        (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) = _getFeeGrowthInside(
            poolId,
            hiTick,
            loTick,
            pools[poolId].lastTick,
            pools[poolId].feeGrowthGlobalAsset,
            pools[poolId].feeGrowthGlobalQuote
        );

        _updatePositionFees(pos, poolId, feeGrowthInsideAsset, feeGrowthInsideQuote);

        pos.totalLiquidity -= deltaLiquidity.toUint128();

        emit DecreasePosition(msg.sender, positionId, deltaLiquidity);
    }

    // TODO: Is this still needed?
    /// @dev Reverts if liquidity was allocated within time elapsed in seconds returned by `_liquidityPolicy`.
    /// @custom:security High. Must be used in place of `_decreasePosition` in most scenarios.
    function _decreasePositionCheckJit(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint256 deltaLiquidity
    ) internal {
        (uint256 distance, uint256 timestamp) = checkJitLiquidity(msg.sender, poolId, loTick, hiTick);
        if (_liquidityPolicy() > distance) revert JitLiquidity(distance);

        _decreasePosition(poolId, loTick, hiTick, deltaLiquidity);
    }

    function _syncPosition(HyperPosition storage pos, uint48 poolId) internal {
        if (pos.pendingStakedLiquidityDelta != 0 || pos.stakedLiquidity != 0) {
            Epoch memory epoch = epochs[poolId];

            uint256 initialStakedLiquidity = pos.stakedLiquidity;
            uint256 transitionEpochId;
            if (epoch.endTime - epoch.interval >= pos.blockTimestamp) {
                if (pos.pendingStakedLiquidityDelta != 0) {
                    transitionEpochId = pos.pendingStakedEpoch;
                    pos.stakedLiquidity = signedAdd(pos.stakedLiquidity, pos.pendingStakedLiquidityDelta);
                    if (initialStakedLiquidity == 0) {
                        pos.stakedEpoch = pos.pendingStakedEpoch;
                    }
                }
                pos.pendingStakedLiquidityDelta = 0;
                pos.pendingStakedEpoch = 0;
            }

            uint256 priorityGrowthInside = _getPriorityGrowthInsideEpochs(
                poolId,
                pos.hiTick,
                pos.loTick,
                pools[poolId].lastTick,
                pos.stakedEpoch,
                (pos.unstakedEpoch == 0) ? epoch.id : pos.unstakedEpoch
            );

            if (pos.stakedEpoch != transitionEpochId && transitionEpochId != 0) {
                // calculate up to transition, then the rest
                uint256 priorityGrowthInsideTransition = _getPriorityGrowthInsideEpochs(
                    poolId,
                    pos.hiTick,
                    pos.loTick,
                    pools[poolId].lastTick,
                    pos.stakedEpoch,
                    transitionEpochId
                );
                pos.tokensOwedQuote += FixedPointMathLib.mulWadDown(
                    priorityGrowthInsideTransition - pos.priorityGrowthInsideLast,
                    initialStakedLiquidity
                );
                pos.tokensOwedQuote += FixedPointMathLib.mulWadDown(
                    priorityGrowthInside - priorityGrowthInsideTransition - pos.priorityGrowthInsideLast,
                    pos.stakedLiquidity
                );
            } else {
                pos.tokensOwedQuote += FixedPointMathLib.mulWadDown(
                    priorityGrowthInside - pos.priorityGrowthInsideLast,
                    pos.stakedLiquidity
                );
            }
            pos.priorityGrowthInsideLast = priorityGrowthInside;

            if (epoch.id > pos.unstakedEpoch && epoch.endTime - epoch.interval >= pos.blockTimestamp) {
                // note: stakedLiquidity, pendingStakedLiquidityDelta, pendingStakedEpoch should already be 0
                pos.stakedEpoch = 0;
                pos.priorityGrowthInsideLast = 0;
            }
        }
        pos.blockTimestamp = _blockTimestamp();
    }

    function _getPriorityGrowthInsideEpochs(
        uint48 poolId,
        int24 hi,
        int24 lo,
        int24 current,
        uint256 startEpoch,
        uint256 endEpoch
    ) internal view returns (uint256 priorityGrowthInsideEpochs) {
        uint256 priorityGrowthInsideStart = _getPriorityGrowthInside(poolId, hi, lo, current, startEpoch);
        uint256 priorityGrowthInsideEnd = _getPriorityGrowthInside(poolId, hi, lo, current, endEpoch);
        priorityGrowthInsideEpochs = priorityGrowthInsideEnd - priorityGrowthInsideStart;
    }

    function _getPriorityGrowthInside(
        uint48 poolId,
        int24 hi,
        int24 lo,
        int24 current,
        uint256 epoch
    ) internal view returns (uint256 priorityGrowthInside) {
        uint256 priorityGrowthGlobal = priorityGrowthPoolSnapshot[poolId][epoch];

        uint256 hiPriorityGrowthOutside = priorityGrowthSlotSnapshot[poolId][hi][epoch];
        uint256 loPriorityGrowthOutside = priorityGrowthSlotSnapshot[poolId][lo][epoch];

        uint256 priorityGrowthBelow;
        if (current >= lo) {
            priorityGrowthBelow = loPriorityGrowthOutside;
        } else {
            priorityGrowthBelow = priorityGrowthGlobal - loPriorityGrowthOutside;
        }

        uint256 priorityGrowthAbove;
        if (current < hi) {
            priorityGrowthAbove = hiPriorityGrowthOutside;
        } else {
            priorityGrowthAbove = priorityGrowthGlobal - hiPriorityGrowthOutside;
        }

        priorityGrowthInside = priorityGrowthGlobal - priorityGrowthBelow - priorityGrowthAbove;
    }

    function _updatePositionFees(
        HyperPosition storage pos,
        uint48 poolId,
        uint256 feeGrowthInsideAsset,
        uint256 feeGrowthInsideQuote
    ) internal {
        uint256 tokensOwedAsset = FixedPointMathLib.mulWadDown(
            feeGrowthInsideAsset - pos.feeGrowthInsideAssetLast,
            pos.totalLiquidity
        );

        uint256 tokensOwedQuote = FixedPointMathLib.mulWadDown(
            feeGrowthInsideQuote - pos.feeGrowthInsideQuoteLast,
            pos.totalLiquidity
        );

        pos.feeGrowthInsideAssetLast = feeGrowthInsideAsset;
        pos.feeGrowthInsideQuoteLast = feeGrowthInsideQuote;

        pos.tokensOwedAsset += tokensOwedAsset;
        pos.tokensOwedQuote += tokensOwedQuote;
    }

    function _getFeeGrowthInside(
        uint48 poolId,
        int24 hi,
        int24 lo,
        int24 current,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote
    ) internal view returns (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) {
        HyperSlot storage hiTick = slots[poolId][hi];
        HyperSlot storage loTick = slots[poolId][lo];

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

    /**
     * @notice Updates the state of the pool (and it's epoch) with respect to time.
     *
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _syncPool(uint48 poolId) internal returns (uint256 price, int24 tick) {
        HyperPool storage pool = pools[poolId];

        uint256 timestamp = _blockTimestamp();

        if (timestamp == pool.blockTimestamp) {
            return (pool.lastPrice, pool.lastTick);
        }

        Epoch storage epoch = epochs[poolId];

        // calculate accrued staking rewards per unit of staked liquidity
        if (pool.stakedLiquidity > 0 && pool.priorityPaymentPerSecond > 0) {
            uint256 epochTimestamp = timestamp < epoch.endTime ? timestamp : epoch.endTime;
            // note: could epochTimestamp ever be < pool.blockTimestamp?
            uint256 priorityPaymentChange = pool.priorityPaymentPerSecond * (epochTimestamp - pool.blockTimestamp);
            pool.priorityGrowthGlobal += FixedPointMathLib.divWadDown(priorityPaymentChange, pool.stakedLiquidity);
            // save priority payment snapshot
            priorityGrowthPoolSnapshot[poolId][epoch.id] = pool.priorityGrowthGlobal;
        }

        // epoch transition logic
        if (pool.blockTimestamp < epoch.endTime && timestamp >= epoch.endTime) {
            // transition epoch
            epoch.id += 1;
            epoch.endTime += epoch.interval;
            // initialize new epoch's priority payment snapshot
            priorityGrowthPoolSnapshot[poolId][epoch.id] = pool.priorityGrowthGlobal;
            // update staked liquidity kicked in / out due to epoch transition
            if (pool.pendingStakedLiquidityDelta > 0) {
                pool.stakedLiquidity += uint256(pool.pendingStakedLiquidityDelta);
            } else {
                pool.stakedLiquidity -= abs(pool.pendingStakedLiquidityDelta);
            }
            // reset pending stake delta, priority swapper, priority payment rate
            pool.pendingStakedLiquidityDelta = 0;
            pool.prioritySwapper = address(0);
            pool.priorityPaymentPerSecond = uint128(0);
        }

        // fetch pool's curve, calculate updated price and tick
        Curve memory curve = curves[uint32(poolId)];
        uint256 tau = curve.maturity - pool.blockTimestamp;
        HyperSwapLib.Expiring memory expiring = HyperSwapLib.Expiring(curve.strike, curve.sigma, tau);
        // apply time change to price, tick
        price = expiring.computePriceWithChangeInTau(pool.lastPrice, timestamp - pool.blockTimestamp);
        tick = HyperSwapLib.computeTickWithPrice(price); // todo: check computeTickWithPrice returns tick % TICK_SIZE == 0
        // if updated tick, then apply slot transitions
        if (tick != pool.lastTick) {
            int24 tickJump = price > pool.lastPrice ? TICK_SIZE : -TICK_SIZE;
            SyncIteration memory syncIteration = SyncIteration({
                tick: pool.lastTick + tickJump,
                liquidity: pool.liquidity,
                stakedLiquidity: pool.stakedLiquidity,
                pendingStakedLiquidityDelta: pool.pendingStakedLiquidityDelta
            });
            do {
                (
                    int256 liquidityDelta,
                    int256 stakedLiquidityDelta,
                    int256 slotPendingStakedLiquidityDelta
                ) = _transitionSlot(
                        poolId,
                        syncIteration.tick,
                        pool.feeGrowthGlobalAsset,
                        pool.feeGrowthGlobalQuote,
                        pool.priorityGrowthGlobal
                    );
                // update sync iteration for change in slot
                syncIteration.liquidity = signedAdd(syncIteration.liquidity, liquidityDelta);
                syncIteration.stakedLiquidity = signedAdd(syncIteration.stakedLiquidity, stakedLiquidityDelta);
                syncIteration.pendingStakedLiquidityDelta += slotPendingStakedLiquidityDelta;
                syncIteration.tick += tickJump;
            } while (tick != syncIteration.tick);
            // update pool fields effected by change in tick
            pool.lastTick = tick;
            pool.liquidity = syncIteration.liquidity;
            pool.stakedLiquidity = syncIteration.stakedLiquidity;
            pool.pendingStakedLiquidityDelta = syncIteration.pendingStakedLiquidityDelta;
        }
        pool.lastPrice = price;
        pool.blockTimestamp = timestamp;
    }

    /**
     * @notice Syncs a slot to a new timestamp and returns its deltas to update the pool's liquidity values.
     * @dev Effects on a slot after its been transitioned to another slot.
     * @dev Assumes epoch transition applied before calling.
     * @param poolId Identifier of the pool.
     * @param tick Key of the slot specified to be transitioned.
     * @return liquidityDelta Difference in amount of liquidity available before or after this slot.
     * @return stakedLiquidityDelta Difference in amount of staked liquidity available before or after this slot.
     * @return pendingStakedLiquidityDelta Difference in amount the staked liquidity should change at next epoch transition.
     */
    function _transitionSlot(
        uint48 poolId,
        int24 tick,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote,
        uint256 priorityGrowthGlobal
    )
        internal
        returns (
            int256 liquidityDelta,
            int256 stakedLiquidityDelta,
            int256 pendingStakedLiquidityDelta
        )
    {
        HyperSlot storage slot = slots[poolId][tick];

        slot.feeGrowthOutsideAsset = feeGrowthGlobalAsset - slot.feeGrowthOutsideAsset;
        slot.feeGrowthOutsideQuote = feeGrowthGlobalQuote - slot.feeGrowthOutsideQuote;

        slot.priorityGrowthOutside = priorityGrowthGlobal - slot.priorityGrowthOutside;

        _syncSlot(poolId, tick); // updates staking deltas, saves snapshots of priorityGrowthOutside

        liquidityDelta = slot.liquidityDelta;
        stakedLiquidityDelta = slot.stakedLiquidityDelta;
        pendingStakedLiquidityDelta = slot.pendingStakedLiquidityDelta;

        // todo: update transition event

        emit SlotTransition(poolId, tick, slot.liquidityDelta);
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
        HyperPool storage pool = pools[poolId];
        if (loTick <= pool.lastTick && hiTick > pool.lastTick) {
            pool.liquidity += deltaLiquidity;
        }

        // Todo: update bitmap of instantiated slots.

        _increasePosition(poolId, loTick, hiTick, deltaLiquidity);

        // note: Global reserves are used at the end of instruction processing to settle transactions.
        uint16 pairId = uint16(poolId >> 32);
        Pair memory pair = pairs[pairId];
        _adjustGlobalBalance(pair.tokenBase, int256(deltaR2));
        _adjustGlobalBalance(pair.tokenQuote, int256(deltaR1));

        emit AddLiquidity(poolId, pair.tokenBase, pair.tokenQuote, deltaR2, deltaR1, deltaLiquidity);
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
        HyperSlot storage slot = slots[poolId][tick];

        uint256 prevLiquidity = slot.totalLiquidity;
        uint256 nextLiquidity = slot.totalLiquidity + deltaLiquidity;

        alterState = (prevLiquidity == 0 && nextLiquidity != 0); // If the liquidity started at zero but was altered.

        slot.totalLiquidity = nextLiquidity;
        if (alterState) slot.instantiated = !slot.instantiated;

        // If a slot is exited and is on the upper bound of the range, there is a "loss" of liquidity to the next slot.
        if (hi) slot.liquidityDelta -= int256(deltaLiquidity);
        else slot.liquidityDelta += int256(deltaLiquidity);
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
        HyperSlot storage slot = slots[poolId][tick];

        uint256 prevLiquidity = slot.totalLiquidity;
        uint256 nextLiquidity = slot.totalLiquidity - deltaLiquidity;

        alterState = (prevLiquidity == 0 && nextLiquidity != 0) || (prevLiquidity != 0 && nextLiquidity == 0); // If there was liquidity previously and all of it was removed.

        slot.totalLiquidity = nextLiquidity;
        if (alterState) slot.instantiated = !slot.instantiated;

        // Update liquidity deltas depending on the changed amount.
        if (hi) slot.liquidityDelta += int256(deltaLiquidity);
        else slot.liquidityDelta -= int256(deltaLiquidity);
    }

    function _syncSlot(uint48 poolId, int24 tick) internal {
        HyperSlot storage slot = slots[poolId][tick];

        Epoch memory epoch = epochs[poolId];

        if (epoch.endTime - epoch.interval >= slot.timestamp) {
            // note: check case where loSlot.timestamp = epoch.endTime - epoch.interval
            slot.stakedLiquidityDelta += slot.pendingStakedLiquidityDelta;
            slot.pendingStakedLiquidityDelta = 0;
        }

        slot.timestamp = _blockTimestamp();

        // save priority payment snapshot
        priorityGrowthSlotSnapshot[poolId][tick][epoch.id] = slot.priorityGrowthOutside;
    }

    function _increaseSlotPendingStake(
        uint48 poolId,
        int24 tick,
        uint256 pendingStakedLiquidity,
        bool hi
    ) internal {
        HyperSlot storage slot = slots[poolId][tick];

        if (hi) {
            slot.pendingStakedLiquidityDelta -= int256(pendingStakedLiquidity);
        } else {
            slot.pendingStakedLiquidityDelta += int256(pendingStakedLiquidity);
        }
    }

    function _decreaseSlotPendingStake(
        uint48 poolId,
        int24 tick,
        uint256 pendingStakedLiquidity,
        bool hi
    ) internal {
        HyperSlot storage slot = slots[poolId][tick];

        if (hi) {
            slot.pendingStakedLiquidityDelta += int256(pendingStakedLiquidity);
        } else {
            slot.pendingStakedLiquidityDelta -= int256(pendingStakedLiquidity);
        }
    }

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                               INTERNAL FUNCTIONS                                                     |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

    /// @dev Overridable in tests.
    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }

    /// @dev Overridable in tests.
    function _liquidityPolicy() internal view virtual returns (uint256) {
        return JUST_IN_TIME_LIQUIDITY_POLICY;
    }

    /// @dev Gas optimized `balanceOf` method.
    function _balanceOf(address token, address account) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, account)
        );
        if (!success || data.length != 32) revert BalanceError();
        return abi.decode(data, (uint256));
    }

    function _safeWrap() internal {
        IWETH(WETH).deposit{value: msg.value}();
    }

    function _dangerousUnwrap(address to, uint256 amount) internal {
        IWETH(WETH).withdraw(amount);

        // Marked as dangerous because it makes an external call to the `to` address.
        dangerousTransferETH(to, amount);
    }

    // --- General Utils --- //

    function _doesPoolExist(uint48 poolId) internal view returns (bool exists) {
        exists = pools[poolId].blockTimestamp != 0;
    }

    function _isValidDecimals(uint8 decimals) internal pure returns (bool valid) {
        valid = isBetween(decimals, MIN_DECIMALS, MAX_DECIMALS);
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
        if (token == WETH && msg.value > 0) _safeWrap();

        uint256 global = globalReserves[token];
        uint256 actual = _balanceOf(token, address(this));
        if (global > actual) {
            uint256 deficit = global - actual;
            _applyDebit(token, deficit);
        } else {
            uint256 surplus = actual - global;
            _adjustUserBalance(msg.sender, token, int256(surplus));
        }

        _cacheAddress(token, false); // note: Effectively saying "any pool with this token was paid for in full".
    }

    // --- View --- //

    // todo: check for hash collisions with instruction calldata and fix.

    function checkJitLiquidity(
        address account,
        uint48 poolId,
        int24 loTick,
        int24 hiTick
    ) public view returns (uint256 distance, uint256 timestamp) {
        uint96 positionId = uint96(bytes12(abi.encodePacked(poolId, loTick, hiTick)));
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

    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        external
        view
        returns (uint256 deltaBase, uint256 deltaQuote)
    {}

    function updateLastTimestamp(uint48) external override returns (uint128 blockTimestamp) {}
}
