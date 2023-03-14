// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

using InvariantGhost for InvariantGhostState global;

struct InvariantGhostState {
    uint64 last;
    uint64[] poolIds;
    mapping(uint64 => bool) exists;
}

/**
 * @dev Manages the pools that are being acted upon.
 */
library InvariantGhost {
    function add(InvariantGhostState storage self, uint64 poolId) internal {
        if (!self.exists[poolId]) {
            self.exists[poolId] = true;
            self.poolIds.push(poolId);
            self.last = poolId;
        }
    }

    function pop(InvariantGhostState storage self) internal returns (uint64) {
        uint64 last = self.poolIds[self.poolIds.length - 1];
        self.poolIds.pop();
        return last;
    }

    function rand(
        InvariantGhostState storage self,
        uint256 seed
    ) internal view returns (uint64) {
        if (self.poolIds.length == 0) return uint64(0xc0ffee); // thanks horsefacts
        return self.poolIds[seed % self.poolIds.length];
    }
}
