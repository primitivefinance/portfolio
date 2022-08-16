// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./EnigmaVirtualMachinePrototype.sol";
import "../libraries/HyperSwapLib.sol";
import "solstat/Invariant.sol";

import "forge-std/Test.sol";

abstract contract HyperPrototype is EnigmaVirtualMachinePrototype {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    /**
     * @notice Temporary variables used in the order filling loop.
     * @param tick Current tick being swapped at this step.
     * @param price Current price this swap is at.
     * @param remainder Order amount to be filled.
     * @param liquidity Pool total liquidity.
     * @param input Total input amount.
     * @param output Total output amount.
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
     * @notice Specific pool info used to reference for swaps.
     */
    struct Transient {
        uint48 poolId;
        uint256 tau;
        uint256 sigma;
        uint256 gamma;
        uint256 strike;
        uint256 maturity;
    }

    Transient internal transient;

    struct Order {
        uint8 useMax;
        uint48 poolId;
        uint128 input;
        uint128 limit;
        uint8 direction;
    }

    function _swapExactForExact(bytes calldata data) internal returns (uint48 poolId, uint256 remainder) {
        Order memory args;
        (args.useMax, args.poolId, args.input, args.limit, args.direction) = Instructions.decodeSwap(data[1:]);

        if (!_doesPoolExist(args.poolId)) revert NonExistentPool(args.poolId);

        // Store the pool transiently, then delete after the swap.
        Curve memory curve = _curves[uint32(args.poolId)];
        transient = Transient({
            poolId: args.poolId,
            gamma: curve.gamma,
            strike: curve.strike,
            sigma: curve.sigma,
            maturity: curve.maturity,
            tau: curve.maturity - _blockTimestamp()
        });

        // Pool is used to fetch information and eventually have its state updated.
        HyperPool storage pool = _pools[args.poolId];

        // Get the variables for first iteration of the swap.
        Iteration memory swap;
        {
            uint256 tau = curve.maturity - pool.blockTimestamp;
            uint256 deltaTau = _blockTimestamp() - pool.blockTimestamp;

            // Price is changing over time, so this is the actual price which swaps begin at.
            uint256 livePrice = HyperSwapLib.computePriceWithChangeInTau(
                curve.strike,
                curve.sigma,
                pool.lastPrice,
                tau,
                deltaTau
            );
            int24 liveTick = _computeTickIndexGivenPrice(livePrice);

            swap = Iteration({
                price: livePrice,
                tick: liveTick,
                remainder: args.input,
                liquidity: pool.liquidity,
                input: 0,
                output: 0
            });
        }

        // ----- Effects ----- //

        // --- Warning: loop --- //
        // Loops until a condition is met:
        // 1. Order is filled.
        // 2. Limit price is met.
        do {
            // Get the current and next tick info, along with current real reserves.
            uint256 liveReserve = computeR2WithPriceTransient(swap.price);

            // Use the next price to compute the max input of tokens to get to the next price.
            int24 nextTick = swap.tick + TICK_SIZE;
            uint256 nextPrice = _computePriceGivenTickIndex(nextTick);
            uint256 nextReserve = computeR2WithPriceTransient(nextPrice);

            // Get the max amount that can be filled for a max distance swap.
            uint256 maxInput = (nextReserve - liveReserve).mulWadDown(swap.liquidity);

            uint256 delta;
            uint256 nextOtherReserve;
            uint256 otherReserve = computeR1WithPriceTransient(swap.price);

            // If we can't fill it, set the next price to swap at and reduce the remainder to fill.
            if (swap.remainder >= maxInput) {
                // Compute the amount in with respect to liquidity of this slot.
                delta = maxInput; // Swap the most in. todo: making sure using liquidity as a multiplier works.
                // Update the liquidity.
                int256 liquidityDelta = transitionSlot(args.poolId, swap.tick);
                if (liquidityDelta > 0) swap.liquidity += uint256(liquidityDelta);
                else swap.liquidity -= uint256(liquidityDelta);
                swap.tick = nextTick; // Set the next tick.
                swap.price = nextPrice; // Set the next price according to the next tick.
                swap.remainder -= delta; // Reduce the remainder of the order to fill.
                swap.input += delta; // Add to the total input of the swap.
                nextOtherReserve = computeR1WithR2Transient(liveReserve); // Compute other reserve to compute output amount.
                swap.output += otherReserve - nextOtherReserve;
            } else {
                swap.price = computePriceWithInput(transient.poolId, swap.price, swap.remainder); // Compute new price given the input.
                swap.input += swap.remainder; // Add the full amount remaining to the toal.
                nextOtherReserve = computeR1WithR2Transient(liveReserve + swap.remainder); // Compute the other reserve to compute output amount.
                swap.output += otherReserve - nextOtherReserve;
                swap.remainder = 0; // Reduce the remainder to zero, as the order has been filled.
            }
        } while (swap.remainder != 0 || args.limit > swap.price);

        // Update Pool State Effects
        transitionPool(pool, swap.tick, swap.price, swap.liquidity);

        // Update Global Balance Effects
        Pair memory pair = _pairs[uint16(transient.poolId >> 32)];
        _increaseGlobal(pair.tokenBase, swap.input);
        _decreaseGlobal(pair.tokenQuote, swap.output);

        // Reset transient state.
        delete transient;

        emit Swap(args.poolId, swap.input, swap.output, pair.tokenBase, pair.tokenQuote);
    }

    /**
     * @notice Effects on a Pool after a successful swap order has been filled.
     */
    function transitionPool(
        HyperPool storage pool,
        int24 tick,
        uint256 price,
        uint256 liquidity
    ) internal returns (uint256 timeDelta) {
        if (pool.lastPrice != price) pool.lastPrice = price;
        if (pool.lastTick != tick) pool.lastTick = tick;
        if (pool.liquidity != liquidity) pool.liquidity = liquidity;

        uint256 timestamp = _blockTimestamp();
        timeDelta = timestamp - pool.blockTimestamp;
        pool.blockTimestamp = timestamp;
    }

    /**
     * @notice Effects on a slot after its been transitioned to another slot.
     */
    function transitionSlot(uint48 poolId, int24 tick) internal returns (int256) {
        HyperSlot storage slot = _slots[poolId][tick];
        slot.timestamp = _blockTimestamp();
        return slot.liquidityDelta;
    }

    function computeR1WithPriceTransient(uint256 price) internal view returns (uint256 R1) {
        R1 = HyperSwapLib.computeR1WithPrice(price, transient.strike, transient.sigma, transient.tau);
    }

    function computeR2WithPriceTransient(uint256 price) internal view returns (uint256 R2) {
        R2 = HyperSwapLib.computeR2WithPrice(price, transient.strike, transient.sigma, transient.tau);
    }

    function computeR1WithR2Transient(uint256 R1) internal view returns (uint256 R2) {
        R2 = computeR1GivenR2(R1, transient.strike, transient.sigma, transient.maturity, 0);
    }

    int24 public constant TICK_SIZE = 2;

    /**
     * @notice Computes a price given a change in the respective reserve.
     * custom:math Maybe? P_b = P_a e^{Φ^-1(amount)}
     */
    function computePriceWithInput(
        uint48 poolId,
        uint256 lastPrice,
        uint256 swapAmount
    ) public view returns (uint256 price) {
        Curve memory curve = _curves[uint32(poolId)];
        uint256 tau = curve.maturity - _blockTimestamp();
        uint256 lastReserve = HyperSwapLib.computeR2WithPrice(lastPrice, curve.strike, curve.sigma, tau);
        uint256 nextReserve = lastReserve + swapAmount;
        price = HyperSwapLib.computePriceWithR2(nextReserve, curve.strike, curve.sigma, tau);
    }

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
        uint256 price = _computePriceGivenTickIndex(loTick);
        // Compute the current virtual reserves given the pool's lastPrice.
        uint256 currentR2 = HyperSwapLib.computeR2WithPrice(
            pool.lastPrice,
            curve.strike,
            curve.sigma,
            curve.maturity - timestamp
        );
        // Compute the real reserves given the lower price bound.
        uint256 deltaR2 = HyperSwapLib.computeR2WithPrice(price, curve.strike, curve.sigma, curve.maturity - timestamp); // todo: I don't think this is right since its (1 - (x / x(P_a)))
        // If the real reserves are zero, then the tick is at the bounds and so we should use virtual reserves.
        if (deltaR2 == 0) deltaR2 = currentR2;
        else deltaR2 = currentR2.divWadDown(deltaR2);
        uint256 deltaR1 = computeR1GivenR2(deltaR2, curve.strike, curve.sigma, curve.maturity, price); // todo: fix with using the hiTick.
        deltaR1 = deltaR1.mulWadDown(delLiquidity);
        deltaR2 = deltaR2.mulWadDown(delLiquidity);

        _increaseLiquidity(poolId_, loTick, hiTick, deltaR1, deltaR2, delLiquidity);
    }

    /**
        e^(ln(1.0001) * tickIndex) = price

        ln(price) = ln(1.0001) * tickIndex

        tickIndex = ln(price) / ln(1.0001)
     */
    function _computePriceGivenTickIndex(int24 tickIndex) internal pure returns (uint256 price) {
        int256 tickWad = int256(tickIndex) * int256(FixedPointMathLib.WAD);
        price = uint256(FixedPointMathLib.powWad(1_0001e14, tickWad));
    }

    function _computeTickIndexGivenPrice(uint256 priceWad) internal pure returns (int24 tick) {
        uint256 numerator = uint256(int256(priceWad).lnWad());
        uint256 denominator = uint256(int256(1_0001e14).lnWad());
        uint256 val = numerator / denominator + 1; // Values are in Fixed Point Q.96 format. Rounds up.
        tick = int24(int256((numerator)) / int256(denominator) + 1);
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
        HyperSlot memory slot = _slots[poolId_][loTick];
        HyperPool memory pool = _pools[poolId_];
        uint256 timestamp = _blockTimestamp();
        uint256 price = _computePriceGivenTickIndex(loTick);
        uint256 currentR2 = HyperSwapLib.computeR2WithPrice(
            pool.lastPrice,
            curve.strike,
            curve.sigma,
            curve.maturity - timestamp
        );

        uint256 deltaR2 = HyperSwapLib.computeR2WithPrice(price, curve.strike, curve.sigma, curve.maturity - timestamp); // todo: I don't think this is right since its (1 - (x / x(P_a)))
        if (deltaR2 == 0) deltaR2 = currentR2;
        else deltaR2 = currentR2.divWadDown(deltaR2);

        uint256 deltaR1 = computeR1GivenR2(deltaR2, curve.strike, curve.sigma, curve.maturity, price); // todo: fix with using the hiTick.
        deltaR1 = deltaR1.mulWadDown(deltaLiquidity);
        deltaR2 = deltaR2.mulWadDown(deltaLiquidity);

        // Decrease amount of liquidity in each tick.
        _decreaseSlotLiquidity(poolId_, loTick, deltaLiquidity, false);
        _decreaseSlotLiquidity(poolId_, hiTick, deltaLiquidity, true);

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
     * @notice Computes the R1 reserve given the R2 reserve and a price.
     *
     * @custom:math R1 / price(hiTickIndex) = tradingFunction(...)
     */
    function computeR1GivenR2(
        uint256 R2,
        uint256 strike,
        uint256 sigma,
        uint256 maturity,
        uint256 price
    ) internal view returns (uint256 R1) {
        uint256 tau = maturity - _blockTimestamp();
        R1 = Invariant.getY(R2, strike, sigma, tau, 0); // todo: add non-zero invariant
        // todo: add hiTick range
        //R1 = R1.mulWadDown(price); // Multiplies price to calibrate to the price specified.
    }

    /**
     * @notice Updates the liquidity of a slot, and returns a bool to reflect whether its instantiation state was changed.
     */
    function _increaseSlotLiquidity(
        uint48 poolId,
        int24 tickIndex,
        uint256 deltaLiquidity,
        bool hi
    ) internal returns (bool alterState) {
        HyperSlot storage slot = _slots[poolId][tickIndex];

        uint256 prevLiquidity = slot.totalLiquidity;
        uint256 nextLiquidity = slot.totalLiquidity + deltaLiquidity;

        alterState = (prevLiquidity == 0 && nextLiquidity != 0); // If the liquidity started at zero but was altered.

        slot.totalLiquidity = nextLiquidity;
        if (alterState) slot.instantiated = !slot.instantiated;
        // todo: apply the liquidity delta depending on tick positioning in range.
    }

    /**
     * @notice Updates the liquidity of a slot, and returns a bool to reflect whether its instantiation state was changed.
     */
    function _decreaseSlotLiquidity(
        uint48 poolId,
        int24 tickIndex,
        uint256 deltaLiquidity,
        bool hi
    ) internal returns (bool alterState) {
        HyperSlot storage slot = _slots[poolId][tickIndex];

        uint256 prevLiquidity = slot.totalLiquidity;
        uint256 nextLiquidity = slot.totalLiquidity - deltaLiquidity;

        alterState = (prevLiquidity == 0 && nextLiquidity != 0) || (prevLiquidity != 0 && nextLiquidity == 0); // If there was liquidity previously and all of it was removed.

        slot.totalLiquidity = nextLiquidity;
        if (alterState) slot.instantiated = !slot.instantiated;
        // todo: apply the liquidity delta depending on tick positioning in range.
    }

    error ZeroPairId();
    error ZeroCurveId();

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
            lastTick: _computeTickIndexGivenPrice(price), // todo: implement tick and price grid.
            blockTimestamp: timestamp,
            liquidity: 0
        });

        emit CreatePool(poolId_, pairId, curveId, price);
    }

    function _doesPoolExist(uint48 poolId) internal view returns (bool exists) {
        exists = _pools[poolId].blockTimestamp != 0;
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
}
