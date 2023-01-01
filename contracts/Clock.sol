// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

using {
    syncEpoch,
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

function syncEpoch(Epoch storage epoch, uint timestamp) returns (uint passed) {
    passed = epoch.getEpochsPassed(timestamp);
    epoch.id += passed;
    epoch.endTime += (epoch.interval + (passed * epoch.interval));
}

function getStartTime(Epoch memory epoch) pure returns (uint256 startTime) {
    if (epoch.endTime < epoch.interval)
        startTime = 0; // todo: fix, avoids underflow
    else startTime = epoch.endTime - epoch.interval;
}

function getEpochsPassed(Epoch memory epoch, uint256 lastUpdatedTimestamp) pure returns (uint256 epochsPassed) {
    // If timestamp is not greater than end time, no epochs have passed.
    if (lastUpdatedTimestamp < epoch.endTime) return 0;
    if (epoch.interval == 0) return 0;

    epochsPassed = (lastUpdatedTimestamp - epoch.endTime) / epoch.interval + 1;
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
    if (epoch.endTime < (epochsPassed * epoch.interval) || epoch.endTime < lastUpdatedTimestamp)
        timeToTransition = 1; // todo: fix this, avoids the arthimetic undeflow
    else timeToTransition = epoch.endTime - (epochsPassed * epoch.interval) - lastUpdatedTimestamp;
}

function getTimePassedInCurrentEpoch(
    Epoch memory epoch,
    uint timestamp,
    uint256 lastUpdatedTimestamp
) pure returns (uint256 timePassed) {
    uint256 startTime = epoch.getStartTime();
    uint256 lastUpdateInCurrentEpoch = lastUpdatedTimestamp > startTime ? lastUpdatedTimestamp : startTime;
    timePassed = timestamp - lastUpdateInCurrentEpoch;
}
