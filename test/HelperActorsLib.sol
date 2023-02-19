// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

using Actors for ActorsState global;

struct ActorsState {
    address last;
    address[] active;
    mapping(address => bool) exists;
}

library Actors {
    function rand(ActorsState storage self, uint seed) internal view returns (address) {
        if (self.active.length == 0) return address(0xc0ffee); // thanks horsefacts
        return self.active[seed % self.active.length];
    }
}
