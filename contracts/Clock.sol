// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

using {
    getStartTime,
    getEpochsPassed,
    getLastUpdatedId,
    getTimeToTransition,
    getTimePassedInCurrentEpoch
} for Epoch global;

/// @dev Time interval information for liquidity staking.
struct Epoch {
    uint256 id;
    uint256 endTime;
    uint256 interval;
}

function getStartTime(Epoch memory epoch) pure returns (uint256 startTime) {
    if (epoch.endTime < epoch.interval)
        startTime = 0; // todo: fix, avoids underflow
    else startTime = epoch.endTime - epoch.interval;
}

function getEpochsPassed(Epoch memory epoch, uint256 lastUpdatedTimestamp) pure returns (uint256 epochsPassed) {
    if (epoch.endTime < (lastUpdatedTimestamp + 1))
        epochsPassed = 1; // todo: fix this, avoids the arthimetic undeflow
    else epochsPassed = (epoch.endTime - (lastUpdatedTimestamp + 1)) / epoch.interval;
}

function getLastUpdatedId(Epoch memory epoch, uint256 epochsPassed) pure returns (uint256 lastUpdateId) {
    if (epoch.id < epochsPassed)
        lastUpdateId = 0; // todo: fix, avoids underflow
    else lastUpdateId = epoch.id - epochsPassed;
}

function getTimeToTransition(
    Epoch memory epoch,
    uint256 epochsPassed,
    uint256 lastUpdatedTimestamp
) pure returns (uint256 timeToTransition) {
    timeToTransition = epoch.endTime - (epochsPassed * epoch.interval) - lastUpdatedTimestamp;
}

function getTimePassedInCurrentEpoch(
    Epoch memory epoch,
    uint timestamp,
    uint256 lastUpdatedTimestamp
) view returns (uint256 timePassed) {
    uint256 startTime = epoch.getStartTime();
    uint256 lastUpdateInCurrentEpoch = lastUpdatedTimestamp > startTime ? lastUpdatedTimestamp : startTime;
    timePassed = timestamp - lastUpdateInCurrentEpoch;
}
