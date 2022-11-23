// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

import "./libraries/BrainMath.sol";
import "./libraries/Epoch.sol";
import "./libraries/GlobalDefaults.sol";
import "./libraries/Pool.sol";
import "./libraries/Position.sol";
import "./libraries/Slot.sol";

import "./interfaces/IERC20.sol";

// TODO:
// - Add WETH wrapping / unwrapping
// - Add the internal balances, fund and withdraw
// - Add Multicall?
// - Fixed point library
// - Slippage checks
// - Extra function parameters
// - Events
// - Custom errors
// - Interface
// - slots bitmap

contract Smol {
    using Epoch for Epoch.Data;
    using Pool for Pool.Data;
    using Pool for mapping(bytes32 => Pool.Data);
    using Position for Position.Data;
    using Position for mapping(bytes32 => Position.Data);
    using Slot for Slot.Data;
    using Slot for mapping(bytes32 => Slot.Data);

    Epoch.Data public epoch;

    mapping(bytes32 => Pool.Data) public pools;
    mapping(bytes32 => Position.Data) public positions;
    mapping(bytes32 => Slot.Data) public slots;

    /// @notice Internal token balances
    mapping(address => mapping(address => uint256)) public internalBalances;

    address public auctionFeeCollector;

    constructor(uint256 startTime, address _auctionFeeCollector) {
        require(startTime > block.timestamp);
        epoch = Epoch.Data({id: 0, endTime: startTime});
        auctionFeeCollector = _auctionFeeCollector;
    }

    modifier started() {
        require(epoch.id > 0, "Hyper not started yet.");
        _;
    }

    function start() public {
        epoch.sync();
        require(epoch.id > 0, "Hyper not started yet.");
        // TODO: emit ActivateHyper
    }

    function fund(
        address to,
        address token,
        uint256 amount
    ) public {
        SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
        internalBalances[to][token] += amount;
    }

    function withdraw(
        address to,
        address token,
        uint256 amount
    ) public {
        require(internalBalances[msg.sender][token] >= amount);
        internalBalances[msg.sender][token] -= amount;
        SafeTransferLib.safeTransferFrom(ERC20(token), address(this), to, amount);
    }

    function activatePool(
        address tokenA,
        address tokenB,
        uint256 sqrtPriceFixedPoint
    ) public started {
        epoch.sync();
        pools.activate(tokenA, tokenB, sqrtPriceFixedPoint);

        // TODO: emit ActivatePool event
    }

    function updateLiquidity(
        bytes32 poolId,
        int128 lowerSlotIndex,
        int128 upperSlotIndex,
        int256 amount
    ) public started {
        if (lowerSlotIndex > upperSlotIndex) revert();
        if (amount == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

        epoch.sync();
        pool.sync(epoch);

        bytes32 lowerSlotId = Slot.getId(poolId, lowerSlotIndex);
        Slot.Data storage lowerSlot = slots[lowerSlotId];
        lowerSlot.sync(epoch);

        bytes32 upperSlotId = Slot.getId(poolId, upperSlotIndex);
        Slot.Data storage upperSlot = slots[upperSlotId];
        upperSlot.sync(epoch);

        bytes32 positionId = Position.getId(msg.sender, poolId, lowerSlotIndex, upperSlotIndex);
        Position.Data storage position = positions[positionId];

        if (position.lastUpdatedTimestamp == 0) {
            if (amount < 0) revert();
            position.lowerSlotIndex = lowerSlotIndex;
            position.upperSlotIndex = upperSlotIndex;
            position.lastUpdatedTimestamp = block.timestamp;
        } else {
            position.sync(pool, lowerSlot, upperSlot, epoch);
        }

        if (amount > 0) {
            _addLiquidity(pool, lowerSlot, upperSlot, position, uint256(amount));
        } else {
            _removeLiquidity(pool, lowerSlot, upperSlot, position, uint256(amount));
        }
    }

    function _addLiquidity(
        Pool.Data storage pool,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot,
        Position.Data storage position,
        uint256 amount
    ) internal {
        uint256 addAmountLeft = amount;

        // use negative pending liquidity first
        if (position.pendingLiquidity < int256(0)) {
            uint256 addedPending = uint256(position.pendingLiquidity) >= amount
                ? amount
                : uint256(position.pendingLiquidity);

            position.pendingLiquidity += int256(addedPending);

            lowerSlot.pendingLiquidityDelta += int256(addedPending);
            upperSlot.pendingLiquidityDelta -= int256(addedPending);

            lowerSlot.pendingLiquidityGross += int256(addedPending);
            upperSlot.pendingLiquidityGross += int256(addedPending);

            if (position.lowerSlotIndex <= pool.slotIndex && pool.slotIndex < position.upperSlotIndex) {
                pool.pendingLiquidity += int256(addedPending);
            }

            addAmountLeft -= addedPending;
        }

        if (addAmountLeft > 0) {
            position.swapLiquidity += addAmountLeft;
            position.pendingLiquidity += int256(addAmountLeft);

            lowerSlot.swapLiquidityDelta += int256(addAmountLeft);
            lowerSlot.pendingLiquidityDelta += int256(addAmountLeft);
            if (lowerSlot.liquidityGross == uint256(0)) {
                // TODO: add to / initialize slot in bitmap
                // TODO: initialize per liquidity outside values
                lowerSlot.liquidityGross += uint256(addAmountLeft);
            }

            upperSlot.swapLiquidityDelta -= int256(addAmountLeft);
            upperSlot.pendingLiquidityDelta -= int256(addAmountLeft);
            if (upperSlot.liquidityGross == uint256(0)) {
                // TODO: add to / initialize slot in bitmap
                // TODO: initialize per liquidity outside values
                upperSlot.liquidityGross += uint256(addAmountLeft);
            }

            (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
                PRICE_GRID_FIXED_POINT,
                addAmountLeft,
                pool.sqrtPriceFixedPoint,
                pool.slotIndex,
                position.lowerSlotIndex,
                position.upperSlotIndex
            );
            if (amountA != 0 && amountB != 0) {
                pool.swapLiquidity += addAmountLeft;
                pool.pendingLiquidity += int256(addAmountLeft);
            }

            // TODO: Remove amountA & amountB from internal balance
        }

        // TODO: Emit add liquidity event
    }

    function _removeLiquidity(
        Pool.Data storage pool,
        Slot.Data storage lowerSlot,
        Slot.Data storage upperSlot,
        Position.Data storage position,
        uint256 amount
    ) internal {
        uint256 removeAmountLeft = amount;

        // remove positive pending liquidity immediately
        if (position.pendingLiquidity > int256(0)) {
            if (position.swapLiquidity < amount) revert();

            uint256 removedPending = uint256(position.pendingLiquidity) >= amount
                ? amount
                : uint256(position.pendingLiquidity);

            position.swapLiquidity -= removedPending;
            position.pendingLiquidity -= int256(removedPending);

            lowerSlot.swapLiquidityDelta -= int256(removedPending);
            lowerSlot.pendingLiquidityDelta -= int256(removedPending);
            lowerSlot.liquidityGross -= removedPending;
            // TODO: check liquidity gross value for bitmap

            upperSlot.swapLiquidityDelta += int256(removedPending);
            upperSlot.pendingLiquidityDelta += int256(removedPending);
            upperSlot.liquidityGross -= removedPending;
            // TODO: check liquidity gross value for bitmap

            // credit tokens owed to the position immediately
            (uint256 amountA, uint256 amountB) = _calculateLiquidityDeltas(
                PRICE_GRID_FIXED_POINT,
                removedPending,
                pool.sqrtPriceFixedPoint,
                pool.slotIndex,
                position.lowerSlotIndex,
                position.upperSlotIndex
            );

            // TODO: add amountA & b to internal balance

            if (amountA != 0 && amountB != 0) {
                pool.swapLiquidity -= removedPending;
                pool.pendingLiquidity -= int256(removedPending);
            }

            removeAmountLeft -= removedPending;
        } else {
            if (position.swapLiquidity - uint256(position.pendingLiquidity) < amount) revert();
        }

        // schedule removeAmountLeft to be removed from remaining liquidity
        if (removeAmountLeft > 0) {
            position.pendingLiquidity -= int256(removeAmountLeft);

            lowerSlot.pendingLiquidityDelta -= int256(removeAmountLeft);
            upperSlot.pendingLiquidityDelta += int256(removeAmountLeft);

            lowerSlot.pendingLiquidityGross -= int256(removeAmountLeft);
            upperSlot.pendingLiquidityGross -= int256(removeAmountLeft);

            if (position.lowerSlotIndex <= pool.slotIndex && pool.slotIndex < position.upperSlotIndex) {
                pool.pendingLiquidity -= int256(removeAmountLeft);
            }
        }

        // save slot snapshots
        lowerSlot.snapshots[epoch.id] = Slot.Snapshot({
            proceedsPerLiquidityOutsideFixedPoint: lowerSlot.proceedsPerLiquidityOutsideFixedPoint,
            feesAPerLiquidityOutsideFixedPoint: lowerSlot.feesAPerLiquidityOutsideFixedPoint,
            feesBPerLiquidityOutsideFixedPoint: lowerSlot.feesBPerLiquidityOutsideFixedPoint
        });
        upperSlot.snapshots[epoch.id] = Slot.Snapshot({
            proceedsPerLiquidityOutsideFixedPoint: upperSlot.proceedsPerLiquidityOutsideFixedPoint,
            feesAPerLiquidityOutsideFixedPoint: upperSlot.feesAPerLiquidityOutsideFixedPoint,
            feesBPerLiquidityOutsideFixedPoint: upperSlot.feesBPerLiquidityOutsideFixedPoint
        });

        // TODO: emit RemoveLiquidity event
    }

    struct SwapCache {
        int128 activeSlotIndex;
        uint256 slotProportionF;
        uint256 activeLiquidity;
        uint256 activePrice;
        int128 slotIndexOfNextDelta;
        int128 nextDelta;
    }

    function swap(
        address tokenA,
        address tokenB,
        uint256 tendered,
        bool direction
    ) public started {
        uint256 tenderedRemaining = tendered;
        uint256 received;

        uint256 cumulativeFees;
        SwapCache memory swapCache;

        if (!direction) {} else {}
    }

    function bid(
        bytes32 poolId,
        uint256 epochId,
        address refunder,
        address swapper,
        uint256 amount
    ) public started {
        if (amount == 0) revert();

        Pool.Data storage pool = pools[poolId];
        if (pool.lastUpdatedTimestamp == 0) revert();

        epoch.sync();
        if (epochId != epoch.id + 1) revert();
        if (block.timestamp < epoch.endTime - AUCTION_LENGTH) revert();

        pool.sync(epoch); // @dev: pool needs to sync here, assumes no bids otherwise

        uint256 fee = (amount * AUCTION_FEE) / 10000;
        amount -= fee;

        if (amount > pool.bids[epoch.id + 1].amount) {
            // TO-DO: balance changes for msg.sender, auctionFeeCollector, previous bid refunder
            pool.bids[epoch.id + 1] = Pool.Bid({
                refunder: refunder,
                swapper: swapper,
                amount: amount,
                proceedsPerSecondFixedPoint: PRBMathUD60x18.div(amount, EPOCH_LENGTH)
            });
        }

        // TODO: emit event
    }
}
