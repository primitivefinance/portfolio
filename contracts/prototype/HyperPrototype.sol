// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {isBetween} from "../libraries/Utils.sol";

import "../libraries/HyperSwapLib.sol";
import "./EnigmaVirtualMachinePrototype.sol";

abstract contract HyperPrototype is EnigmaVirtualMachinePrototype {
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
        HyperPool memory pool = _pools[poolId];
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
        _updatePool(poolId, tick, price, pool.liquidity, false, 0);
    }

    // FIXME: Temporary variables to avoid the hideous stack too deep errors
    uint256 _gamma;
    uint256 _fees;
    uint256 _growthFeesToAdd;

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
        _growthFeesToAdd = 0;

        Order memory args;
        (args.useMax, args.poolId, args.input, args.limit, args.direction) = Instructions.decodeSwap(data); // Packs useMax flag into Enigma instruction code byte.

        if (args.input == 0) revert ZeroInput();
        if (!_doesPoolExist(args.poolId)) revert NonExistentPool(args.poolId);

        bool sell = args.direction == 0; // args.direction == 0 ? Swap asset for quote : Swap quote for asset.

        // Pair is used to update global reserves and check msg.sender balance.
        Pair memory pair = _pairs[uint16(args.poolId >> 32)];
        // Pool is used to fetch information and eventually have its state updated.
        HyperPool memory pool = _pools[args.poolId];

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

            // Fetch the correct gamma to calculate the fees.
            _gamma = msg.sender == pool.prioritySwapper ? curve.priorityGamma : curve.gamma;
        }

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
                remainder: remainder,
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
            if (sell) {
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

            // Calculate the amount of fees to deduct from the amount in
            _fees = (swap.remainder * _gamma) / 10_000;
            _growthFeesToAdd += _fees;
            swap.remainder -= _fees;

            // Compute amount to swap in this step.
            // If the full tick is crossed, reduce the remainder of the trade by the max amount filled by the tick.
            if (swap.remainder >= maxInput) {
                delta = maxInput;

                {
                    // Entering or exiting the tick will transition the pool's active range.
                    int256 liquidityDelta = _transitionSlot(args.poolId, swap.tick);
                    if (liquidityDelta > 0) swap.liquidity += uint256(liquidityDelta);
                    else swap.liquidity -= uint256(liquidityDelta);
                }

                // Update variables for next iteration.
                swap.tick = nextTick; // Set the next slot.
                swap.price = nextPrice; // Set the next price according to the next slot.
                swap.remainder -= delta; // Reduce the remainder of the order to fill.
                swap.input += delta; // Add to the total input of the swap.
            } else {
                // Reaching this block will fill the order. Set the swap input
                delta = swap.remainder;
                nextIndependent = liveIndependent + delta.divWadDown(swap.liquidity);

                swap.remainder = 0; // Reduce the remainder to zero, as the order has been filled.
                swap.input += delta; // Add the full amount remaining to the toal.
            }

            // Compute the output of the swap by computing the difference between the dependent reserves.
            if (sell) nextDependent = expiring.computeR1WithR2(nextIndependent, 0, 0);
            else nextDependent = expiring.computeR2WithR1(nextIndependent, 0, 0);
            swap.output += liveDependent - nextDependent;
        } while (swap.remainder != 0 && args.limit > swap.price);

        // Update Pool State Effects
        _updatePool(args.poolId, swap.tick, swap.price, swap.liquidity, sell, _growthFeesToAdd);
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
        bool sell,
        uint256 feesGrowth
    ) internal returns (uint256 timeDelta) {
        HyperPool storage pool = _pools[poolId];
        if (pool.lastPrice != price) pool.lastPrice = price;
        if (pool.lastTick != tick) pool.lastTick = tick;
        if (pool.liquidity != liquidity) pool.liquidity = liquidity;

        uint256 timestamp = _blockTimestamp();
        timeDelta = timestamp - pool.blockTimestamp;
        pool.blockTimestamp = timestamp;

        if (feesGrowth > 0) {
            if (sell) {
                pool.feeGrowthGlobalAsset += feesGrowth;
            } else {
                pool.feeGrowthGlobalQuote += feesGrowth;
            }
        }

        emit PoolUpdate(
            poolId,
            pool.lastPrice,
            pool.lastTick,
            pool.liquidity,
            sell ? feesGrowth : 0,
            sell ? 0 : feesGrowth
        );
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
        (uint8 useMax, uint48 poolId_, int24 loTick, int24 hiTick, uint128 delLiquidity) = Instructions
            .decodeAddLiquidity(data); // Packs the use max flag in the Enigma instruction code byte.
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
        if (pos.staked) revert PositionStakedError(positionId);
        if (pos.totalLiquidity == 0) revert PositionZeroLiquidityError(positionId);

        HyperSlot storage loSlot = _slots[poolId_][pos.loTick];
        HyperSlot storage hiSlot = _slots[poolId_][pos.hiTick];

        // add staked delta to lo tick, remove from hi tick
        loSlot.stakedLiquidityDelta += int256(pos.totalLiquidity);
        hiSlot.stakedLiquidityDelta -= int256(pos.totalLiquidity);
        // note: we don't need to account for totalStakedLiquidity at a tick
        // since the "normal" liquidity ensures the tick remains instantiated

        HyperPool storage pool = _pools[poolId_];
        if (pos.loTick <= pool.lastTick && pos.hiTick > pool.lastTick) {
            // if position's liquidity is in range, add to pool's current
            // staked liquidity amount
            pool.stakedLiquidity += pos.totalLiquidity;
        }

        pos.staked = true;

        // emit Stake Position
    }

    function _unstakePosition(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint48 poolId_, uint96 positionId) = Instructions.decodeUnstakePosition(data);
        poolId = poolId_;

        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId_);

        HyperPosition storage pos = _positions[msg.sender][positionId];
        if (!pos.staked) revert PositionNotStakedError(positionId);

        HyperSlot storage loSlot = _slots[poolId_][pos.loTick];
        HyperSlot storage hiSlot = _slots[poolId_][pos.hiTick];

        // note: is it okay to remove staked liquidity now? will immediately stop earning rewards
        loSlot.stakedLiquidityDelta -= int256(pos.totalLiquidity);
        hiSlot.stakedLiquidityDelta += int256(pos.totalLiquidity);

        HyperPool storage pool = _pools[poolId_];
        if (pos.loTick <= pool.lastTick && pos.hiTick > pool.lastTick) {
            // if position's liquidity is in range, remove staked liquidity amount
            // from pool's state
            pool.stakedLiquidity -= pos.totalLiquidity;
        }

        Epoch storage epoch = _epochs[poolId_];
        pos.unstakeEpochId = epoch.id;
        pos.staked = false;

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

        // Write the pool to state with the desired price.
        _pools[poolId] = HyperPool({
            lastPrice: price,
            lastTick: HyperSwapLib.computeTickWithPrice(price), // todo: implement slot and price grid.
            blockTimestamp: timestamp,
            liquidity: 0,
            stakedLiquidity: 0,
            prioritySwapper: address(0),
            feeGrowthGlobalAsset: 0,
            feeGrowthGlobalQuote: 0
        });

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
}
