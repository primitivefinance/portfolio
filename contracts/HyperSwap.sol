// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@primitivefi/rmm-core/contracts/libraries/ReplicationMath.sol";

import "./EnigmaVirtualMachine.sol";

/// @title Hyper Swap
/// @notice Must have higher level contracts implement critical safety checks.
/// @dev Processes the swap instructions and logic for all pools.
abstract contract HyperSwap is EnigmaVirtualMachine {
    using SafeCast for uint256;

    // --- View --- //

    /// @dev Expects the latest timestamp of a pool as an argument to compute the elapsed time since maturity.
    function checkSwapMaturityCondition(uint128 lastTimestamp) public view returns (uint256 elapsed) {
        uint128 current = _blockTimestamp();
        if (current > lastTimestamp) elapsed = current - lastTimestamp; // note: Zero if not passed maturity.
    }

    /// @inheritdoc IEnigmaView
    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        public
        view
        override
        returns (uint256 deltaBase, uint256 deltaQuote)
    {
        Pool memory pool = pools[poolId];
        uint256 total = uint256(pool.internalLiquidity);
        deltaBase = (uint256(pool.internalBase) * deltaLiquidity) / total;
        deltaQuote = (uint256(pool.internalQuote) * deltaLiquidity) / total;
    }

    /// @inheritdoc IEnigmaView
    function getInvariant(uint48 poolId) public view override returns (int128 invariant) {
        Curve memory curve = curves[uint32(poolId)]; // note: Purposefully removes first two bytes through explicit conversion.
        uint32 tau = curve.maturity - uint32(pools[poolId].blockTimestamp); // note: Curve maturity can never be less than lastTimestamp.
        (uint256 basePerLiquidity, uint256 quotePerLiquidity) = getPhysicalReserves(poolId, PRECISION); // One liquidity unit.

        Pair memory pair = pairs[uint16(poolId >> 32)];
        uint256 scaleFactorBase = 10**(18 - pair.decimalsBase);
        uint256 scaleFactorQuote = 10**(18 - pair.decimalsQuote);
        invariant = ReplicationMath.calcInvariant(
            scaleFactorBase,
            scaleFactorQuote,
            basePerLiquidity,
            quotePerLiquidity,
            curve.strike,
            curve.sigma,
            tau
        );
    }

    // --- Internal --- //

    /// @dev Replaces the desired `deltaIn` amount with the `balanceOf` the `msg.sender` if the `useMax` flag is 1.
    function _swapExactForExact(bytes calldata data) internal returns (uint48 poolId, uint256 deltaOut) {
        (uint8 useMax, uint48 poolId_, uint128 deltaIn, uint128 deltaOut_, uint8 dir) = Instructions.decodeSwap(data);
        poolId = poolId_;
        deltaOut = deltaOut_;

        if (useMax == 1) {
            Pair memory pair = pairs[uint16(poolId >> 32)];
            if (dir == 0) deltaIn = _balanceOf(pair.tokenBase, msg.sender).toUint128();
            else deltaIn = _balanceOf(pair.tokenQuote, msg.sender).toUint128();
        }

        _swap(poolId, dir, deltaIn, deltaOut);
    }

    /// @notice Updates the reserves and latest timestamp of the pool at `poolId`.
    /// @dev Updates the virtual reserves and checks the pre and post invariants.
    /// @param direction Simple way to express the desired swap path. 0 = base -> quote, 1 = quote -> base.
    /// @custom:security Critical. Directly handles token amounts by altering the reserves of pools.
    /// @custom:mev Higher level peripheral contract should implement checks that desired tokens are received.
    function _swap(
        uint48 poolId,
        uint8 direction,
        uint256 input,
        uint256 output
    ) internal {
        Pool storage pool = pools[poolId];

        uint128 lastTimestamp = _updateLastTimestamp(poolId);
        uint256 secondsPastMaturity = checkSwapMaturityCondition(lastTimestamp);
        if (secondsPastMaturity > BUFFER) revert PoolExpiredError();

        int128 invariantX64 = getInvariant(poolId);
        Pair memory pair = pairs[uint16(poolId >> 32)];
        {
            Curve memory curve = curves[uint32(poolId)]; // note: Explicit conversion removes first two bytes.
            uint32 tau = curve.maturity - uint32(pool.blockTimestamp); // note: Cannot underflow.
            uint256 amountInFee = (input * curve.gamma) / PERCENTAGE;
            uint256 adjustedBase;
            uint256 adjustedQuote;

            if (direction == 0) {
                adjustedBase = uint256(pool.internalBase) + amountInFee;
                adjustedQuote = uint256(pool.internalQuote) - output;
            } else {
                adjustedBase = uint256(pool.internalBase) - output;
                adjustedQuote = uint256(pool.internalQuote) + amountInFee;
            }

            adjustedBase = (adjustedBase * PRECISION) / pool.internalLiquidity;
            adjustedQuote = (adjustedQuote * PRECISION) / pool.internalLiquidity;

            int128 invariantAfter = ReplicationMath.calcInvariant(
                10**(18 - pair.decimalsBase),
                10**(18 - pair.decimalsQuote),
                adjustedBase,
                adjustedQuote,
                curve.strike,
                curve.sigma,
                tau
            );

            if (invariantX64 > invariantAfter) revert InvariantError(invariantX64, invariantAfter);

            if (direction == 0) {
                pool.internalBase += uint128(input);
                pool.internalQuote -= uint128(output);
                globalReserves[pair.tokenBase] += uint128(input);
                globalReserves[pair.tokenQuote] -= uint128(output);
            } else {
                pool.internalBase -= uint128(output);
                pool.internalQuote += uint128(input);
                globalReserves[pair.tokenBase] -= uint128(output);
                globalReserves[pair.tokenQuote] += uint128(input);
            }

            pool.blockTimestamp = lastTimestamp;
        }

        emit Swap(
            poolId,
            input,
            output,
            direction == 0 ? pair.tokenBase : pair.tokenQuote,
            direction == 0 ? pair.tokenQuote : pair.tokenBase
        );
    }

    /// @dev First step in a swap is to sync the pool to the block timestamp, which is used to compute the time until maturity.
    function _updateLastTimestamp(uint48 poolId) internal virtual returns (uint128 blockTimestamp) {
        Pool storage pool = pools[poolId];
        if (pool.blockTimestamp == 0) revert NonExistentPool(poolId);

        uint32 curveId = uint32(poolId); // note: Purposefully uses explicit conversion to get last 4 bytes.
        Curve storage curve = curves[curveId];
        uint32 maturity = curve.maturity;
        blockTimestamp = _blockTimestamp();
        if (blockTimestamp > maturity) blockTimestamp = maturity; // If expired, set to the maturity.

        pool.blockTimestamp = blockTimestamp; // Updates the state of the pool.
        emit UpdateLastTimestamp(poolId);
    }

    // --- External --- //

    /// @inheritdoc IEnigmaActions
    function updateLastTimestamp(uint48 poolId) external override lock returns (uint128 blockTimestamp) {
        blockTimestamp = _updateLastTimestamp(poolId);
    }
}
