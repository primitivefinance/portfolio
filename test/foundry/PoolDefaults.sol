// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UD60x18} from "@prb/math/UD60x18.sol";

uint256 constant EPOCH_LENGTH = 3600; // in seconds
uint256 constant AUCTION_LENGTH = 60; // in seconds

UD60x18 constant PUBLIC_SWAP_FEE = UD60x18.wrap(6000000000000000); // in bips? 0.6%
UD60x18 constant AUCTION_FEE = UD60x18.wrap(6000000000000000); // in bips? 0.6%

uint8 constant SLOT_SPACING = 1;
