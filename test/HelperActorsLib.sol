// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

using Actors for ActorsState global;

struct ActorsState {
    address last;
    address[] active;
    mapping(address => bool) exists;
}

/**
 * @dev Manages the actors that act upon subjects in the test suite.
 *
 * User Manual:
 * - Use `rand` to get a random actor available in the list of actors.
 * - Use `exists()` to check if the actor is already added to the list.
 * - Use `add` to add an actor the list.
 */
library Actors {
    function rand(ActorsState storage self, uint seed) internal view returns (address) {
        if (self.active.length == 0) return address(0xc0ffee); // thanks horsefacts
        return self.active[seed % self.active.length];
    }

    function add(ActorsState storage self, address actor) internal {
        if (!self.exists[actor]) {
            self.active.push(actor);
            self.last = actor;
        }
    }

    function pop(ActorsState storage self) internal returns (address) {
        address last = self.active[self.active.length - 1];
        self.active.pop();
        return last;
    }
}
