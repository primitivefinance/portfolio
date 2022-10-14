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
    function VERSION() public pure returns (string memory) {
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

    /// @dev Policy for the "wait" time in seconds between adding and removing liquidity.
    uint256 public constant JUST_IN_TIME_LIQUIDITY_POLICY = 4;

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                                      STORAGE                                                         |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

    /// @dev Reentrancy guard initialized to state
    uint256 private locked = 1;

    /// @dev Maps the pair of tokens with their pool id
    /// token0 -> token1 -> poolId
    /// Note than token0 < token1, duplicate pairs are not possible
    mapping(address => mapping(address => uint24)) public getPoolId;

    /// @dev Pool id -> Pair of a Pool.
    mapping(uint24 => Pool) public pools;

    /// @dev A value incremented by one on pool creation. Reduces calldata.
    /// Actually a uint24 but we don't cast it down because the storage slot is 32 bytes anyway
    uint256 public getPoolNonce;

    /// @dev Token -> Physical Reserves.
    mapping(address => uint256) public globalReserves;

    /// @dev Pool id -> Tick -> Slot has liquidity at a price.
    mapping(uint24 => mapping(int24 => HyperSlot)) public slots;

    /// @dev User -> Token -> Internal Balance.
    mapping(address => mapping(address => uint256)) public balances;

    /// @dev User -> Position Id -> Liquidity Position.
    mapping(address => mapping(uint96 => HyperPosition)) public positions;

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
            (poolId) = _addOrRemoveLiquidity(data);
        } else if (instruction == Instructions.REMOVE_LIQUIDITY) {
            (poolId) = _addOrRemoveLiquidity(data);
        } else if (instruction == Instructions.SWAP) {
            // (poolId, , , ) = _swapExactForExact(data);
        } else if (instruction == Instructions.CREATE_POOL) {
            (poolId) = _createPool(data);
        } else if (instruction == Instructions.CREATE_PAIR) {
            _createPair(data);
        } else if (instruction == Instructions.COLLECT_FEES) {
            _collectFees(data);
        } else if (instruction == Instructions.DRAW) {
            _draw(data);
        } else if (instruction == Instructions.FUND) {
            _fund(data);
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
        // TODO: Gas optimize this loop
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
    //  |                                   USER BALANCE                                   |
    //  +----------------------------------------------------------------------------------+

    /// @notice Transfers `amount` of `token` to the `to` account.
    /// @dev Decreases the `msg.sender` account's internal balance of `token`.
    /// @custom:security High. Calls the `token` external contract.
    function _draw(bytes calldata data) internal {
        (address to, address token, uint256 amount) = Decoder.decodeDraw(data);

        // note: Would pull tokens without this conditional check.
        if (balances[msg.sender][token] < amount) revert DrawBalance();
        _adjustUserBalance(msg.sender, token, int256(amount));

        if (token == WETH) _dangerousUnwrap(to, amount);
        else SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    // TODO: Add NatSpec
    function _fund(bytes calldata data) internal {
        (address token, uint256 amount) = Decoder.decodeFund(data);
        _adjustUserBalance(msg.sender, token, int256(amount));
        if (token == WETH) _safeWrap();
        else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
    }

    //  +----------------------------------------------------------------------------------+
    //  |                                     LIQUIDITY                                    |
    //  +----------------------------------------------------------------------------------+

    function _calculateDeltaAmounts(
        uint24 poolId,
        int24 loTick,
        int24 hiTick,
        uint128 deltaLiquidity
    ) internal returns (uint256 amount0, uint256 amount1) {}

    // TODO: This function is almost done, we just need to calculate amount0 and amount1
    function _addOrRemoveLiquidity(bytes calldata data) internal returns (uint48 poolId) {
        (
            bytes1 instruction,
            uint8 useMax,
            uint48 poolId,
            uint16 pairId,
            int24 loTick,
            int24 hiTick,
            uint128 deltaLiquidity
        ) = Decoder.decodeAddOrRemoveLiquidity(data);

        // TODO: Should we add a check for the min / max ticks?

        if (deltaLiquidity == 0) revert ZeroLiquidityError();
        if (!_doesPoolExist(poolId)) revert NonExistentPool(poolId);

        _adjustSlot(
            poolId,
            hiTick,
            // TODO: Not a huge fan of the ternary operator in this case
            instruction == 0x01 ? int256(uint256(deltaLiquidity)) : -int256(uint256(deltaLiquidity)),
            true
        );

        _adjustSlot(
            poolId,
            loTick,
            // TODO: Not a huge fan of the ternary operator in this case
            instruction == 0x01 ? int256(uint256(deltaLiquidity)) : -int256(uint256(deltaLiquidity)),
            false
        );

        // TODO: Calculate these two bad boys using fancy Math
        (uint256 amount0, uint256 amount1) = _calculateDeltaAmounts(poolId, loTick, hiTick, deltaLiquidity);

        if (loTick <= pool.lastTick && hiTick > pool.lastTick) {
            pool.liquidity = instruction == 0x01 ? pool.liquidity + deltaLiquidity : pool.liquidity - deltaLiquidity;
        }

        // Todo: update bitmap of instantiated slots.

        _adjustPosition(
            poolId,
            loTick,
            hiTick,
            instruction == 0x01 ? int256(uint256(deltaLiquidity)) : -int256(uint256(deltaLiquidity))
        );

        // note: Global reserves are used at the end of instruction processing to settle transactions.
        Pair memory pair = pairs[pairId];

        // TODO: I think this is wrong because we are adding / subtracting in the _adjustGlobalBalance function
        _adjustGlobalBalance(pair.token0, instruction == 0x01 ? int256(amount0) : -int256(amount0));
        _adjustGlobalBalance(pair.token1, instruction == 0x01 ? int256(amount1) : -int256(amount1));

        if (instruction == 0x01) emit AddLiquidity(poolId, pair.token0, pair.token1, amount0, amount1, deltaLiquidity);
        else emit RemoveLiquidity(poolId, pair.token0, pair.token1, amount0, amount1, deltaLiquidity);
    }

    // TODO: This function DOES NOT update the owed tokens, bug or feature?
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

    function _getAmountOut(
        uint24 poolId,
        uint256 input,
        bool direction
    ) internal returns (uint256 output) {}

    /*
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
    /*
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
            (uint256 price, int24 tick) = _adjustPoolStaking(args.poolId);
            // Expect the caller to exhaust their entire balance of the input token.
            remainder = args.useMax == 1 ? _balanceOf(pair.tokenBase, msg.sender) : args.input;
            // Begin the iteration at the live price & tick, using the total swap input amount as the remainder to fill.
            swap = SwapIteration({
                price: price,
                tick: tick,
                feeAmount: 0,
                remainder: remainder,
                liquidity: pool.liquidity,
                input: 0,
                output: 0
            });
        }

        state.gamma = pool.gamma;

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
                    int256 liquidityDelta = _transitionSlot(
                        _args.poolId,
                        _swap.tick,
                        (_state.sell ? _state.feeGrowthGlobal : _pool.feeGrowthGlobalAsset),
                        (_state.sell ? _pool.feeGrowthGlobalQuote : _state.feeGrowthGlobal)
                    );

                    _swap.liquidity = signedAdd(_swap.liquidity, liquidityDelta);
                }

                // Update variables for next iteration.
                swap.tick = nextTick; // Set the next slot.
                swap.price = nextPrice; // Set the next price according to the next slot.
                swap.remainder -= delta + swap.feeAmount; // Reduce the remainder of the order to fill.

                // Save liquidity values changed by slot transition
                swap.liquidity = _swap.liquidity;
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
*/

    //  +----------------------------------------------------------------------------------+
    //  |                                      CREATION                                    |
    //  +----------------------------------------------------------------------------------+

    /**
     * @notice Uses a pair to instantiate a pool at a price.
     *
     * @custom:reverts If price is 0.
     * @custom:reverts If pool with pair and curve has already been created.
     * @custom:reverts If an expiring pool and the current timestamp is beyond the pool's maturity parameter.
     */
    function _createPool(bytes calldata data) internal returns (uint48 poolId) {
        (address token0, address token1, uint256 amount0, uint256 amount1) = Decoder.decodeCreatePool(data);

        poolId = pools[token0][token1];

        if (poolId != 0) revert PoolExists();
        if (token0 == token1) revert SameTokenError();

        poolId = uint24(++getPoolNonce);
        pools[token0][token1] = poolId;

        (uint8 token0Decimals, uint8 token1Decimals) = (IERC20(token0).decimals(), IERC20(token1).decimals());

        if (!_isValidDecimals(token0Decimals)) revert DecimalsError(token0Decimals);
        if (!_isValidDecimals(token1Decimals)) revert DecimalsError(token1Decimals);

        // TODO: Do we need to add liquidity right away or can we just put a price?
        pools[poolId] = Pool({
            token0: token0,
            token0Decimals: token0Decimals,
            token1: token1,
            token1Decimals: token1Decimals,
            lastPrice: 0,
            lastTick: 0,
            liquidity: 0,
            feeGrowthGlobalAsset: 0,
            feeGrowthGlobalQuote: 0
        });

        emit CreatePool(poolId, token0, token1);
    }

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                             STATE ALTERING FUNCTIONS                                                 |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

    /**
     * @dev Updates the liquidity of a slot
     */
    function _adjustSlot(
        uint48 poolId,
        int24 tick,
        int256 deltaLiquidity,
        bool hi
    ) internal returns (bool alterState) {
        HyperSlot storage slot = slots[poolId][tick];

        uint256 prevLiquidity = slot.totalLiquidity;
        uint256 nextLiquidity = deltaLiquidity > 0
            ? slot.totalLiquidity + uint256(deltaLiquidity)
            : slot.totalLiquidity - abs(deltaLiquidity);

        // If there was liquidity previously and all of it was removed OR vice-versa
        alterState = (prevLiquidity == 0 && nextLiquidity != 0) || (prevLiquidity != 0 && nextLiquidity == 0);

        slot.totalLiquidity = nextLiquidity;
        if (alterState) slot.instantiated = !slot.instantiated;

        // If a slot is exited and is on the upper bound of the range, there is a "loss" of liquidity to the next slot.
        if (hi) slot.liquidityDelta -= deltaLiquidity;
        else slot.liquidityDelta += deltaLiquidity;
    }

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
            if (balances[msg.sender][token] >= abs(amount)) balances[msg.sender][token] -= abs(amount);
            else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), abs(amount));
        }

        emit AdjustUserBalance(user, token, amount);
    }

    /// @dev Most important function because it manages the solvency of the Engima.
    /// @custom:security Critical. Global balances of tokens are compared with the actual `balanceOf`.
    function _adjustGlobalBalance(address token, int256 amount) internal {
        if (amount > 0) {
            unchecked {
                globalReserves[token] += uint256(amount);
            }
        } else {
            globalReserves[token] -= abs(amount);
        }

        emit AdjustGlobalBalance(token, amount);
    }

    // --- Positions --- //
    function _adjustPosition(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        int256 deltaLiquidity
    ) internal {
        uint96 positionId = uint96(bytes12(abi.encodePacked(poolId, loTick, hiTick)));
        HyperPosition storage pos = positions[msg.sender][positionId];

        (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) = _getFeeGrowthInside(
            poolId,
            hiTick,
            loTick,
            pools[poolId].lastTick,
            pools[poolId].feeGrowthGlobalAsset,
            pools[poolId].feeGrowthGlobalQuote
        );

        uint256 tokensOwedAsset = FixedPointMathLib.mulWadDown(
            feeGrowthInsideAsset - pos.feeGrowthInsideAssetLast,
            pos.totalLiquidity
        );

        uint256 tokensOwedQuote = FixedPointMathLib.mulWadDown(
            feeGrowthInsideQuote - pos.feeGrowthInsideQuoteLast,
            pos.totalLiquidity
        );

        pos.tokensOwedAsset += tokensOwedAsset;
        pos.tokensOwedQuote += tokensOwedQuote;

        pos.feeGrowthInsideAssetLast = feeGrowthInsideAsset;
        pos.feeGrowthInsideQuoteLast = feeGrowthInsideQuote;

        // TODO: Do we really need this? We already get it from the position id
        if (pos.loTick == 0 && pos.hiTick == 0) {
            pos.loTick = loTick;
            pos.hiTick = hiTick;
        }

        if (deltaLiquidity > 0) pos.totalLiquidity += uint128(int128(deltaLiquidity));
        else pos.totalLiquidity -= abs(deltaLiquidity);
    }

    // TODO: Is this still needed?
    /// @dev Reverts if liquidity was allocated within time elapsed in seconds returned by `_liquidityPolicy`.
    /// @custom:security High. Must be used in place of `_decreasePosition` in most scenarios.
    function _decreasePositionCheckJit(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        int256 deltaLiquidity
    ) internal {
        (uint256 distance, ) = checkJitLiquidity(msg.sender, poolId, loTick, hiTick);
        if (_liquidityPolicy() > distance) revert JitLiquidity(distance);

        _adjustPosition(poolId, loTick, hiTick, deltaLiquidity);
    }

    /**
     * @notice Syncs a slot to a new timestamp and returns its deltas to update the pool's liquidity values.
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
    ) internal returns (int256 liquidityDelta) {
        HyperSlot storage slot = slots[poolId][tick];

        slot.feeGrowthOutsideAsset = feeGrowthGlobalAsset - slot.feeGrowthOutsideAsset;
        slot.feeGrowthOutsideQuote = feeGrowthGlobalQuote - slot.feeGrowthOutsideQuote;

        _adjustSlot(poolId, tick);

        liquidityDelta = slot.liquidityDelta;

        // todo: update transition event

        emit SlotTransition(poolId, tick, slot.liquidityDelta);
    }

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                             STATE READING FUNCTIONS                                                  |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

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

    //  +----------------------------------------------------------------------------------------------------------------------+
    //  |                                                                                                                      |
    //  |                                               INTERNAL FUNCTIONS                                                     |
    //  |                                                                                                                      |
    //  +----------------------------------------------------------------------------------------------------------------------+

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
            _adjustUserBalance(msg.sender, token, -int256(deficit));
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

    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        external
        view
        returns (uint256 deltaBase, uint256 deltaQuote)
    {}
}
