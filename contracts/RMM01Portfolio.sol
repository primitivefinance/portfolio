// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/**

  ------------------------------------

  Hyper is a replicating market maker.

  ------------------------------------

  Primitive™

 */

import "./Hyper.sol";

contract RMM01Portfolio is HyperVirtual {
    using RMM01Lib for RMM01Lib.RMM;
    using RMM01Lib for HyperPool;
    using SafeCastLib for uint256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;
    using {Assembly.isBetween} for uint8;
    using {Assembly.scaleFromWadDownSigned} for int256;
    using {Assembly.scaleFromWadDown, Assembly.scaleFromWadUp, Assembly.scaleToWad} for uint256;

    /**
     * @dev
     * Failing to pass a valid WETH contract that implements the `deposit()` function,
     * will cause all transactions with Hyper to fail once address(this).balance > 0.
     *
     * @notice
     * Tokens sent to this contract are lost.
     */
    constructor(address weth) HyperVirtual(weth) {}

    // Implemented

    function afterSwapEffects(uint64 poolId, Iteration memory iteration) internal override returns (bool) {
        HyperPool storage pool = pools[poolId];

        int256 liveInvariantWad = 0; // todo: add prev invariant to iteration?
        // Apply priority invariant growth.
        if (msg.sender == pool.controller) {
            int256 delta = iteration.invariant - liveInvariantWad;
            uint256 deltaAbs = uint256(delta < 0 ? -delta : delta);
            if (deltaAbs != 0) _state.invariantGrowthGlobal = deltaAbs.divWadDown(iteration.liquidity); // todo: don't like this setting internal _state...
        }

        return true;
    }

    function beforeSwap(uint64 poolId) internal override returns (bool, int256) {
        (, int256 invariant, uint256 updatedTau) = _computeSyncedPrice(poolId);
        pools[poolId].syncPoolTimestamp(block.timestamp);

        RMM01Lib.RMM memory rmm = pools[poolId].getRMM();

        if (rmm.tau == 0) return (false, invariant);

        return (true, invariant);
    }

    function canUpdatePosition(
        HyperPool memory pool,
        HyperPosition memory position,
        int delta
    ) public view override returns (bool) {
        if (delta < 0) {
            uint256 distance = position.getTimeSinceChanged(block.timestamp);
            return (pool.params.jit <= distance);
        }

        return true;
    }

    function checkPool(HyperPool memory pool) public view override returns (bool) {
        return pool.exists();
    }

    function checkInvariant(
        HyperPool memory pool,
        int invariant,
        uint reserve0,
        uint reserve1
    ) public view override returns (bool, int256 nextInvariant) {
        int256 nextInvariant = pool.getRMM().invariantOf({R_y: reserve1, R_x: reserve0}); // fix this is inverted?

        int256 liveInvariantWad = invariant.scaleFromWadDownSigned(pool.pair.decimalsQuote); // invariant is denominated in quote token.
        int256 nextInvariantWad = nextInvariant.scaleFromWadDownSigned(pool.pair.decimalsQuote);
        return (nextInvariantWad >= liveInvariantWad, nextInvariant);
    }

    function computeMaxInput(
        HyperPool memory pool,
        bool direction,
        uint reserveIn,
        uint liquidity
    ) public view override returns (uint) {
        uint maxInput;
        if (direction) {
            maxInput = (FixedPointMathLib.WAD - reserveIn).mulWadDown(liquidity); // There can be maximum 1:1 ratio between assets and liqudiity.
        } else {
            maxInput = (pool.getRMM().strike - reserveIn).mulWadDown(liquidity); // There can be maximum strike:1 liquidity ratio between quote and liquidity.
        }

        return maxInput;
    }

    function computeReservesFromPrice(
        HyperPool memory pool,
        uint price
    ) public view override returns (uint reserve0, uint reserve1) {
        (reserve1, reserve0) = pool.getRMM().computeReserves(price, 0);
    }

    function estimatePrice(uint64 poolId) public view override returns (uint price) {
        price = getLatestPrice(poolId);
    }

    function getReserves(HyperPool memory pool) public view override returns (uint reserve0, uint reserve1) {
        (reserve0, reserve1) = pool.getAmountsWad();
    }

    /**
     * @dev Computes the price of the pool, which changes over time.
     *
     * @custom:reverts Underflows if the reserve of the input token is lower than the next one, after the next price movement.
     * @custom:reverts Underflows if current reserves of output token is less then next reserves.
     */
    function _computeSyncedPrice(
        uint64 poolId
    ) internal view returns (uint256 price, int256 invariant, uint256 updatedTau) {
        HyperPool memory pool = pools[poolId];
        if (!pool.exists()) revert NonExistentPool(poolId);
        RMM01Lib.RMM memory curve = pool.getRMM();

        updatedTau = pool.computeTau(block.timestamp);
        curve.tau = updatedTau;

        (uint256 x, uint256 y) = pool.getAmountsWad();
        invariant = curve.invariantOf({R_y: y, R_x: x});
        price = curve.getPriceWithX({R_x: x});
    }

    // ===== View ===== //

    function _estimateAmountOut(
        HyperPool memory pool,
        bool sellAsset,
        uint amountIn
    ) internal view override returns (uint output) {
        uint256 passed = getTimePassed(pool);
        (output, ) = pool.getPoolAmountOut(sellAsset, amountIn, passed);
    }

    /** @dev Can be manipulated. */
    function getLatestPrice(uint64 poolId) public view returns (uint256 price) {
        (price, , ) = _computeSyncedPrice(poolId);
    }

    /** @dev Immediately next invariant value. */
    function getInvariant(uint64 poolId) public view returns (int256 invariant) {
        HyperPool memory pool = pools[poolId];
        uint elapsed = block.timestamp - pool.lastTimestamp;
        (invariant, ) = pool.getNextInvariant(elapsed);
    }

    function getAmountOut(
        uint64 poolId,
        bool sellAsset,
        uint256 amountIn
    ) public view override(Objective) returns (uint256 output) {
        HyperPool memory pool = pools[poolId];
        (output, ) = pool.getPoolAmountOut({
            sellAsset: sellAsset,
            amountIn: amountIn,
            timeSinceUpdate: block.timestamp - pool.lastTimestamp // invariant: should not underflow.
        });
    }
}
