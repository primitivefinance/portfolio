// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

uint128 constant DEFAULT_STRIKE = 10e18;
uint24 constant DEFAULT_SIGMA = 1e4;
uint32 constant DEFAULT_MATURITY = 31556953; // adds 1
uint16 constant DEFAULT_FEE = 100;
uint32 constant DEFAULT_GAMMA = 9900;
uint32 constant DEFAULT_PRIORITY_GAMMA = 9950;
uint128 constant DEFAULT_QUOTE_RESERVE = 3085375116376210650;
uint128 constant DEFAULT_ASSET_RESERVE = 308537516918601823;
uint128 constant DEFAULT_LIQUIDITY = 1e18;
uint128 constant DEFAULT_PRICE = 10e18;
int24 constant DEFAULT_TICK = int24(23027); // 10e18, rounded up! pay attention

contract HelperHyperProfiles {}
