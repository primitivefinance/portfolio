// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title Hyper Instructions
/// @dev Contains all the instructions of Hyper
/// @author Primitive
library Instructions {
    // TODO: Maybe change the order of the instructions?
    bytes1 public constant UNKNOWN = 0x00;
    bytes1 public constant DRAW = 0x02;
    bytes1 public constant FUND = 0x09;
    bytes1 public constant ADD_LIQUIDITY = 0x01;
    bytes1 public constant REMOVE_LIQUIDITY = 0x03;
    bytes1 public constant COLLECT_FEES = 0x04;
    bytes1 public constant SWAP = 0x05;
    bytes1 public constant STAKE_POSITION = 0x06;
    bytes1 public constant UNSTAKE_POSITION = 0x07;
    bytes1 public constant FILL_PRIORITY_AUCTION = 0x08;
    bytes1 public constant CREATE_POOL = 0x0B;
    bytes1 public constant CREATE_PAIR = 0x0C;
    bytes1 public constant CREATE_CURVE = 0x0D;
    bytes1 public constant INSTRUCTION_JUMP = 0xAA;
}
