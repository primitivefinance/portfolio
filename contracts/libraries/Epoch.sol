// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

using {getStartTime, getEpochsPassed, getLastUpdatedId, getTimeToTransition, getTimePassedInCurrentEpoch} for Epoch global;

struct Epoch {
    uint256 id;
    uint256 endTime;
    uint256 length;
}

function getStartTime(Epoch memory epoch) pure returns (uint256 startTime) {
    startTime = epoch.endTime - epoch.length;
}

function getEpochsPassed(Epoch memory epoch, uint256 lastUpdatedTimestamp) pure returns (uint256 epochsPassed) {
    epochsPassed = (epoch.endTime - (lastUpdatedTimestamp + 1)) / epoch.length;
}

function getLastUpdatedId(Epoch memory epoch, uint256 epochsPassed) pure returns (uint256 lastUpdateId) {
    lastUpdateId = epoch.id - epochsPassed;
}

function getTimeToTransition(Epoch memory epoch, uint256 epochsPassed, uint256 lastUpdatedTimestamp) pure returns (uint256 timeToTransition) {
    timeToTransition = epoch.endTime - (epochsPassed * epoch.length) - lastUpdatedTimestamp;
}

function getTimePassedInCurrentEpoch(Epoch memory epoch, uint256 lastUpdatedTimestamp) view returns (uint256 timePassed) {
    uint256 startTime = epoch.getStartTime();
    uint256 lastUpdateInCurrentEpoch = lastUpdatedTimestamp > startTime ? lastUpdatedTimestamp : startTime;
    timePassed = block.timestamp - lastUpdateInCurrentEpoch;
}