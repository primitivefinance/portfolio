// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./EnigmaVirtualMachinePrototype.sol";
import "../libraries/HyperSwapLib.sol";
import "solstat/Invariant.sol";

abstract contract HyperPrototype is EnigmaVirtualMachinePrototype {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    function _swapExactForExact(bytes calldata data) internal returns (uint48 poolId, uint256 a) {}

    /**
     * @notice Enigma method to add liquidity to a range of prices in a pool.
     */
    function _addLiquidity(bytes calldata data) internal returns (uint48 poolId, uint256 a) {
        (uint8 useMax, uint48 poolId_, int24 loTick, int24 hiTick, uint128 random0, uint128 random1) = Instructions
            .decodeAddLiquidity(data);

        uint256 delLiquidity = random0;

        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId);

        // Compute amounts of tokens for the real reserves.
        Curve memory curve = _curves[uint32(poolId)];
        HyperSlot memory slot = _slots[loTick];
        uint256 timestamp = _blockTimestamp();
        uint256 price = _computePriceGivenTickIndex(loTick);
        uint256 deltaR2 = HyperSwapLib.computeR2WithPrice(price, curve.strike, curve.sigma, curve.maturity - timestamp); // todo: I don't think this is right since its (1 - (x / x(P_a)))
        uint256 deltaR1 = computeR1GivenR2(deltaR2, curve.strike, curve.sigma, curve.maturity, price); // todo: fix with using the hiTick.
        deltaR1 = deltaR1.mulWadDown(delLiquidity);
        deltaR2 = deltaR2.mulWadDown(delLiquidity);

        _increaseLiquidity(poolId_, loTick, hiTick, deltaR1, deltaR2, delLiquidity);
    }

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
            .decodeRemoveLiquidity(data);

        if (deltaLiquidity == 0) revert ZeroLiquidityError();
        if (!_doesPoolExist(poolId_)) revert NonExistentPool(poolId);

        // Compute amounts of tokens for the real reserves.
        Curve memory curve = _curves[uint32(poolId)];
        HyperSlot memory slot = _slots[loTick];
        uint256 timestamp = _blockTimestamp();
        uint256 price = _computePriceGivenTickIndex(loTick);
        uint256 deltaR2 = HyperSwapLib.computeR2WithPrice(price, curve.strike, curve.sigma, curve.maturity - timestamp); // todo: I don't think this is right since its (1 - (x / x(P_a)))
        uint256 deltaR1 = computeR1GivenR2(deltaR2, curve.strike, curve.sigma, curve.maturity, price); // todo: fix with using the hiTick.
        deltaR1 = deltaR1.mulWadDown(deltaLiquidity);
        deltaR2 = deltaR2.mulWadDown(deltaLiquidity);

        // Decrease amount of liquidity in each tick.
        _decreaseSlotLiquidity(loTick, deltaLiquidity, false);
        _decreaseSlotLiquidity(hiTick, deltaLiquidity, true);

        // Todo: delete any slots if uninstantiated.

        // Todo: update bitmap of instantiated/uninstantiated slots.

        // Todo: update postition of caller.

        // note: Global reserves are referenced at end of processing to determine amounts of token to transfer.
        Pair memory pair = _pairs[pairId];
        _decreaseGlobal(pair.tokenBase, deltaR1);
        _decreaseGlobal(pair.tokenQuote, deltaR2);

        emit RemoveLiquidity(poolId, pairId, deltaR1, deltaR2, deltaLiquidity);
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
        _increaseSlotLiquidity(loTick, deltaLiquidity, false);
        _increaseSlotLiquidity(hiTick, deltaLiquidity, true);

        // Todo: update bitmap of instantiated slots.

        // Todo: update postition of caller.

        // note: Global reserves are used at the end of instruction processing to settle transactions.
        uint16 pairId = uint16(poolId >> 32);
        Pair memory pair = _pairs[pairId];
        _increaseGlobal(pair.tokenBase, deltaR1);
        _increaseGlobal(pair.tokenQuote, deltaR2);

        emit AddLiquidity(poolId, pairId, deltaR1, deltaR2, deltaLiquidity);
    }

    /**
     * @notice Computes the R1 reserve given the R2 reserve and a price.
     *
     * @custom:math R1 / price = tradingFunction(...)
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
        R1 = R1.mulWadDown(price); // Multiplies price to calibrate to the price specified.
    }

    /**
     * @notice Updates the liquidity of a slot, and returns a bool to reflect whether its instantiation state was changed.
     */
    function _increaseSlotLiquidity(
        int24 tickIndex,
        uint256 deltaLiquidity,
        bool hi
    ) internal returns (bool alterState) {
        HyperSlot storage slot = _slots[tickIndex];

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
        int24 tickIndex,
        uint256 deltaLiquidity,
        bool hi
    ) internal returns (bool alterState) {
        HyperSlot storage slot = _slots[tickIndex];

        uint256 prevLiquidity = slot.totalLiquidity;
        uint256 nextLiquidity = slot.totalLiquidity + deltaLiquidity;

        alterState = !((prevLiquidity != 0) && (nextLiquidity == 0)); // If there was liquidity previously and all of it was removed.

        slot.totalLiquidity = nextLiquidity;
        if (alterState) slot.instantiated = !slot.instantiated;
        // todo: apply the liquidity delta depending on tick positioning in range.
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

        if (price == 0) revert ZeroPrice();
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
        _pools[poolId] = HyperPool({
            lastPrice: price,
            lastTick: 0, // todo: implement tick and price grid.
            blockTimestamp: timestamp,
            liquidity: 0
        });

        emit CreatePool(poolId, pairId, curveId, price);
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
