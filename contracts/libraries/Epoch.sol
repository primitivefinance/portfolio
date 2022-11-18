// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./GlobalDefaults.sol";

/// @title   Epoch Library
/// @author  Primitive
/// @dev     Data structure library for Epochs
library Epoch {
    /// @notice                Stores global state of an epoch
    /// @param id              Identifier starting at 0, monotonically increasing
    /// @param endTime         End time of the current epoch id in seconds
    struct Data {
        uint256 id;
        uint256 endTime;
    }

    /// @notice                Updates the epoch data w.r.t. time passing
    function sync(Data storage epoch) internal {
        if (block.timestamp >= epoch.endTime) {
            // TODO: definitely double check this
            uint256 epochsPassed = (block.timestamp - epoch.endTime) / EPOCH_LENGTH;
            epoch.id += (1 + epochsPassed);
            epoch.endTime += (EPOCH_LENGTH + (epochsPassed * EPOCH_LENGTH));
        }
    }
}
