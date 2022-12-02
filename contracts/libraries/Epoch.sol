// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {EPOCH_LENGTH} from "./GlobalDefaults.sol";

using {sync} for Epoch global;

struct Epoch {
    uint256 id;
    uint256 endTime;
}

function sync(Epoch storage epoch) returns (bool newEpoch) {
    if (block.timestamp >= epoch.endTime) {
        // TODO: definitely double check this
        uint256 epochsPassed = (block.timestamp - epoch.endTime) / EPOCH_LENGTH;
        epoch.id += (1 + epochsPassed);
        epoch.endTime += (EPOCH_LENGTH + (epochsPassed * EPOCH_LENGTH));
        newEpoch = true;
    }
}