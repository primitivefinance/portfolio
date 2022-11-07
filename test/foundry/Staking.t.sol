// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";

struct Position {
    uint256 liquidity; // Liquidity owned
    uint256 lockedUntil; // Epoch index
}

contract StakingPrototype {
    uint256 public start; // Start of the first epoch (epoch)
    uint256 public epochDuration = 1 days;
    uint256 public lastEpochTouched; // Index of the latest updated epoch

    // epoch index => liquidity delta
    mapping(uint256 => int256) public stakedLiquidityDelta;

    // Address could be changed later a hash of
    // user address + lower tick + upper tick
    mapping(address => Position) public positionOf;

    // Liquidity available during the current epoch
    uint256 public currentLiquidity;

    constructor() {
        // Tracks when the first epoch starts
        start = block.timestamp;
    }

    /// @notice Stakes liquidity for a specific period of epochs
    /// @param liquidity Amount of liquidity to stake
    /// @param from Start of the staking (epoch index)
    /// @param to End of the staking (epoch index)
    function stake(
        uint256 liquidity,
        uint256 from,
        uint256 to
    ) public {
        uint256 currentEpochIndex = getEpochIndex(block.timestamp);

        // `from` epoch index must always be greater than `currentEpochIndex`
        if (from < currentEpochIndex) revert();

        Position storage position = positionOf[msg.sender];

        // Once staked, liquidity cannot be updated
        // We might change that later though, the only requirement would
        // be to lock the liquidity when the auction starts
        if (position.liquidity > 0) revert();

        // Updates the position liquidity
        position.liquidity += liquidity;

        // Adds liquidity when the staking period will start
        stakedLiquidityDelta[from] += int256(liquidity);

        // Removes liquidity when the staking period will end
        stakedLiquidityDelta[to] -= int256(liquidity);
    }

    /// @notice Updates the current epoch
    function updateCurrentEpoch() public {
        // Gets the index of the current epoch (time based)
        uint256 currentEpochIndex = getEpochIndex(block.timestamp);

        // If the current epoch was the latest updated we're good,
        // otherwise we need to update the current liquidity
        if (lastEpochTouched != currentEpochIndex) {
            // Keeps track of the amount of liquidity to add
            // or remove to the current liquidity
            int256 delta;

            // We might have missed more than one epoch (it's unlikely
            // but possible), so we have to update the liquidity starting
            // from the `lastEpochTouched` index
            for (uint256 i = lastEpochTouched; i < currentEpochIndex; ) {
                unchecked {
                    ++i;
                }
                delta += stakedLiquidityDelta[i];
            }

            // Updates the current liquidity
            if (delta > 0) {
                currentLiquidity += uint256(delta);
            } else {
                currentLiquidity -= uint256(~delta + 1);
            }

            // Stores the index of the last epoch updated
            lastEpochTouched = currentEpochIndex;
        }
    }

    /// @notice Returns the epoch index corresponding to a specific timestamp
    function getEpochIndex(uint256 timestamp) public view returns (uint256) {
        return timestamp / epochDuration;
    }
}

contract TestStakingPrototype is Test {
    StakingPrototype public stakingPrototype;

    function setUp() public {
        stakingPrototype = new StakingPrototype();
    }

    function test_check_epoch_duration() public {
        assertEq(stakingPrototype.epochDuration(), 1 days);
    }

    function test_get_epoch_index() public {
        assertEq(stakingPrototype.getEpochIndex(block.timestamp), 0);
    }

    function test_get_epoch_index_next_day() public {
        vm.warp(block.timestamp + 1 days);

        assertEq(stakingPrototype.getEpochIndex(block.timestamp), 1);
    }

    function test_stake_liquidity_and_update_deltas() public {
        stakingPrototype.stake(10, 1, 10);
        assertEq(stakingPrototype.stakedLiquidityDelta(1), 10);
        assertEq(stakingPrototype.stakedLiquidityDelta(10), -10);
        assertEq(stakingPrototype.currentLiquidity(), 0);
    }

    function test_update_current_epoch() public {
        stakingPrototype.stake(10, 1, 10);
        vm.warp(block.timestamp + 1 days);
        assertEq(stakingPrototype.lastEpochTouched(), 0);
        stakingPrototype.updateCurrentEpoch();
        assertEq(stakingPrototype.lastEpochTouched(), 1);
        assertEq(stakingPrototype.currentLiquidity(), 10);
    }
}
