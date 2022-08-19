// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../libraries/HyperSwapLib.sol";
import "./EnigmaVirtualMachinePrototype.sol";

// temp
import "forge-std/Test.sol";

abstract contract HyperPrototype is EnigmaVirtualMachinePrototype {
    using HyperSwapLib for HyperSwapLib.Expiring;
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    // --- Swap --- //

    error Underflow(uint256, uint256, string); // todo: remove, this is temp

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
        uint256 liquidity;
        uint256 input;
        uint256 output;
    }

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
        Order memory args;
        (args.useMax, args.poolId, args.input, args.limit, args.direction) = Instructions.decodeSwap(data[1:]);

        if (args.input == 0) revert ZeroInput();
        if (!_doesPoolExist(args.poolId)) revert NonExistentPool(args.poolId);

        // Pool is used to fetch information and eventually have its state updated.
        HyperPool memory pool = _pools[args.poolId];

        // Store the pool transiently, then delete after the swap.
        Curve memory curve = _curves[uint32(args.poolId)];
        HyperSwapLib.Expiring memory expiring = HyperSwapLib.Expiring({
            strike: curve.strike,
            sigma: curve.sigma,
            tau: curve.maturity - _blockTimestamp()
        });

        // Get the variables for first iteration of the swap.
        Iteration memory swap;
        {
            uint256 tau = curve.maturity - pool.blockTimestamp;
            uint256 deltaTau = _blockTimestamp() - pool.blockTimestamp;

            // Price is changing over time, so this is the actual price which swaps begin at.
            uint256 livePrice = HyperSwapLib.computePriceWithChangeInTau(
                expiring.strike,
                expiring.sigma,
                pool.lastPrice,
                tau,
                deltaTau
            );
            int24 liveTick = HyperSwapLib.computeTickWithPrice(livePrice);
            int24 tick = _isBetween(
                (int256(liveTick)),
                (int256(pool.lastTick - TICK_SIZE)),
                (int256(pool.lastTick + TICK_SIZE))
            )
                ? liveTick
                : pool.lastTick;

            // Begin the iteration at the live price & tick, using the total swap input amount as the remainder to fill.
            swap = Iteration({
                price: livePrice,
                tick: tick,
                remainder: args.input,
                liquidity: pool.liquidity,
                input: 0,
                output: 0
            });
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
            // Get the current and next slot info, along with current real reserves.
            uint256 liveR2 = expiring.computeR2WithPrice(swap.price);

            // Use the next price to compute the max input of tokens to get to the next price.
            // Next price is lower, because we are increasing reserves of the asset.
            int24 nextTick = swap.tick - TICK_SIZE;
            uint256 nextPrice = HyperSwapLib.computePriceWithTick(nextTick);
            uint256 nextR2 = expiring.computeR2WithPrice(nextPrice);

            // Get the max amount that can be filled for a max distance swap.
            if (liveR2 > nextR2) revert Underflow(nextR2, liveR2, "reserve max input");
            uint256 maxInput = (nextR2 - liveR2).mulWadDown(swap.liquidity); // Active liquidity acts as a multiplier.

            uint256 delta;
            uint256 nextR1;
            uint256 liveR1 = expiring.computeR1WithPrice(swap.price);

            // If the full tick is crossed, reduce the remainder of the trade by the max amount filled by the tick.
            if (swap.remainder >= maxInput) {
                delta = maxInput;

                // Entering or exiting the tick will transition the pool's active range.
                int256 liquidityDelta = _transitionSlot(args.poolId, swap.tick);
                if (liquidityDelta > 0) swap.liquidity += uint256(liquidityDelta);
                else swap.liquidity -= uint256(liquidityDelta);

                // Update variables for next iteration.
                swap.tick = nextTick; // Set the next slot.
                swap.price = nextPrice; // Set the next price according to the next slot.
                swap.remainder -= delta; // Reduce the remainder of the order to fill.
                swap.input += delta; // Add to the total input of the swap.

                // Compute output amount and add to the cumulative sum.
                nextR1 = expiring.computeR1WithR2(liveR2, 0, 0);
                if (nextR1 > liveR1) revert Underflow(liveR1, nextR1, "other reserve 0");
                swap.output += liveR1 - nextR1;
            } else {
                // Reaching this block will fill the order. Set the swap input
                delta = swap.remainder;
                swap.remainder = 0; // Reduce the remainder to zero, as the order has been filled.

                // Update variables that will be used to update state of the pool.
                {
                    // avoids stack too deep errors.
                    uint256 reserve = expiring.computeR2WithPrice(swap.price);
                    uint256 nextReserve = reserve + delta;

                    // Compute new price given the input.
                    swap.price = expiring.computePriceWithR2(nextReserve);
                }

                swap.input += delta; // Add the full amount remaining to the toal.

                // Compute the output amount and add to the cumulative output.
                nextR1 = expiring.computeR1WithR2(liveR2 + delta, 0, 0); // Compute the other reserve to compute output amount.
                if (nextR1 > liveR1) revert Underflow(liveR1, nextR1, "other reserve 1");
                swap.output += liveR1 - nextR1;
            }
        } while (swap.remainder != 0 && args.limit > swap.price);

        console.log("Doing swap with input/output", swap.input, swap.output);

        // Update Pool State Effects
        _updatePool(args.poolId, swap.tick, swap.price, swap.liquidity);

        // Update Global Balance Effects
        Pair memory pair = _pairs[uint16(args.poolId >> 32)];
        _increaseGlobal(pair.tokenBase, swap.input);
        if (_globalReserves[pair.tokenQuote] < swap.output) revert Underflow(0, 0, "quote bal");
        _decreaseGlobal(pair.tokenQuote, swap.output);

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
        uint256 liquidity
    ) internal returns (uint256 timeDelta) {
        HyperPool storage pool = _pools[poolId];
        if (pool.lastPrice != price) pool.lastPrice = price;
        if (pool.lastTick != tick) pool.lastTick = tick;
        if (pool.liquidity != liquidity) pool.liquidity = liquidity;

        uint256 timestamp = _blockTimestamp();
        timeDelta = timestamp - pool.blockTimestamp;
        pool.blockTimestamp = timestamp;

        emit PoolUpdate(poolId, pool.lastPrice, pool.lastTick, pool.liquidity);
    }

    /**
     * @notice Syncs a slot to a new timestamp and returns its liqudityDelta to update the pool's liquidity.
     * @dev Effects on a slot after its been transitioned to another slot.
     * @param poolId Identifier of the pool.
     * @param tick Key of the slot specified to be transitioned.
     * @return liquidityDelta Difference in amount of liquidity available before or after this slot.
     */
    function _transitionSlot(uint48 poolId, int24 tick) internal returns (int256 liquidityDelta) {
        HyperSlot storage slot = _slots[poolId][tick];
        slot.timestamp = _blockTimestamp();
        liquidityDelta = slot.liquidityDelta;

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
        (uint8 useMax, uint48 poolId_, int24 loTick, int24 hiTick, uint128 delLiquidity, ) = Instructions
            .decodeAddLiquidity(data[1:]);
        poolId = poolId_;

        if (delLiquidity == 0) revert ZeroLiquidityError();
        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        // Compute amounts of tokens for the real reserves.
        Curve memory curve = _curves[uint32(poolId_)];
        HyperSlot memory slot = _slots[poolId_][loTick];
        HyperPool memory pool = _pools[poolId_];
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
            .decodeRemoveLiquidity(data[1:]); // Trims Enigma Instruction Code.

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
            pool.liquidity -= deltaLiquidity;
            pool.blockTimestamp = _blockTimestamp();
        }

        // Todo: delete any slots if uninstantiated.

        // Todo: update bitmap of instantiated/uninstantiated slots.

        // Todo: update postition of caller.

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
            pool.liquidity += deltaLiquidity;
            pool.blockTimestamp = _blockTimestamp();
        }

        // Todo: update bitmap of instantiated slots.

        // Todo: update postition of caller.

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
    function _createPool(bytes calldata data)
        internal
        returns (
            uint48 poolId,
            uint256 a,
            uint256 b
        )
    {
        (uint48 poolId_, uint16 pairId, uint32 curveId, uint128 price) = Instructions.decodeCreatePool(data);
        poolId = poolId_;

        if (price == 0) revert ZeroPrice();
        if (uint16(poolId >> 32) == 0) revert ZeroPairId();
        if (uint32(poolId) == 0) revert ZeroCurveId();
        if (_doesPoolExist(poolId_)) revert PoolExists();

        Curve memory curve = _curves[curveId];
        (uint128 strike, uint48 maturity, uint24 sigma) = (curve.strike, curve.maturity, curve.sigma);
        bool perpetual;
        assembly {
            perpetual := iszero(or(strike, or(maturity, sigma))) // Equal to (strike | maturity | sigma) == 0, which returns true if all three values are zero.
        }

        uint128 timestamp = _blockTimestamp();
        if (!perpetual && timestamp > curve.maturity) revert PoolExpiredError();

        // Write the pool to state with the desired price.
        _pools[poolId_] = HyperPool({
            lastPrice: price,
            lastTick: HyperSwapLib.computeTickWithPrice(price), // todo: implement slot and price grid.
            blockTimestamp: timestamp,
            liquidity: 0
        });

        emit CreatePool(poolId_, pairId, curveId, price);
    }

    /**
     * @notice Maps a nonce to a set of curve parameters, strike, sigma, fee, and maturity.
     * @dev Curves are used to create pools.
     * It's possible to make a perpetual pool, by only specifying the fee parameter.
     *
     * @custom:reverts If set parameters have already been used to create a curve.
     * @custom:reverts If fee parameter is outside the bounds of 0.01% to 10.00%, inclusive.
     * @custom:reverts If one of the non-fee parameters is zero, but the others are not zero.
     */
    function _createCurve(bytes calldata data) internal returns (uint32 curveId) {
        (uint24 sigma, uint32 maturity, uint16 fee, uint128 strike) = Instructions.decodeCreateCurve(data); // Expects Enigma encoded data.

        bytes32 rawCurveId = Decoder.toBytes32(data[1:]); // note: Trims the single byte Enigma instruction code.

        curveId = _getCurveIds[rawCurveId]; // Gets the nonce of this raw curve, if it was created already.
        if (curveId != 0) revert CurveExists(curveId);

        if (!_isBetween(fee, MIN_POOL_FEE, MAX_POOL_FEE)) revert FeeOOB(fee);

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

        // Writes the curve to state with a reverse lookup.
        _curves[curveId] = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});
        _getCurveIds[rawCurveId] = curveId;

        emit CreateCurve(curveId, strike, sigma, maturity, gamma);
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
        valid = _isBetween(decimals, 6, 18);
    }

    function _isBetween(
        uint256 value,
        uint256 lower,
        uint256 upper
    ) internal pure returns (bool valid) {
        assembly {
            // Is `val` between lo and hi?
            function isValid(val, lo, hi) -> between {
                between := iszero(sgt(mul(sub(val, lo), sub(val, hi)), 0)) // iszero(x > amount ? 1 : 0) ? true : false, (n - a) * (n - b) <= 0, n = amount, a = lower, b = upper
            }

            valid := isValid(value, lower, upper)
        }
    }

    function _isBetween(
        int256 value,
        int256 lower,
        int256 upper
    ) internal pure returns (bool valid) {
        assembly {
            // Is `val` between lo and hi?
            function isValid(val, lo, hi) -> between {
                between := iszero(sgt(mul(sub(val, lo), sub(val, hi)), 0)) // iszero(x > amount ? 1 : 0) ? true : false, (n - a) * (n - b) <= 0, n = amount, a = lower, b = upper
            }

            valid := isValid(value, lower, upper)
        }
    }
}
