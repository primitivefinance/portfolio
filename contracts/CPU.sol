// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import {JumpError} from "./EnigmaTypes.sol";

// --- Instructions --- //
bytes1 constant UNKNOWN = 0x00;
bytes1 constant ALLOCATE = 0x01;
bytes1 constant UNSET00 = 0x02;
bytes1 constant UNALLOCATE = 0x03;
bytes1 constant UNSET01 = 0x04;
bytes1 constant SWAP = 0x05;
bytes1 constant STAKE_POSITION = 0x06;
bytes1 constant UNSTAKE_POSITION = 0x07;
bytes1 constant UNSET02 = 0x08;
bytes1 constant UNSET03 = 0x09;
bytes1 constant CREATE_POOL = 0x0B;
bytes1 constant CREATE_PAIR = 0x0C;
bytes1 constant CREATE_CURVE = 0x0D;
bytes1 constant INSTRUCTION_JUMP = 0xAA;

/// @dev Used as the first pointer for the jump process.
uint8 constant JUMP_PROCESS_START_POINTER = 2;

/** @dev Be careful. Main entry point to start processing instructions. */
function __startProcess__(function(bytes calldata data) _process) {
    if (msg.data[0] != INSTRUCTION_JUMP) _process(msg.data);
    else _jumpProcess(msg.data, _process);
}

/// @notice First byte should always be the INSTRUCTION_JUMP Enigma code.
/// @dev Expects a special encoding method for multiple instructions.
/// @param data Includes opcode as byte at index 0. First byte should point to next instruction.
/// @custom:security Critical. Processes multiple instructions. Data must be encoded perfectly.
function _jumpProcess(bytes calldata data, function(bytes calldata data) _process) {
    uint8 length = uint8(data[1]);
    uint8 pointer = JUMP_PROCESS_START_POINTER; // note: [opcode, length, pointer, ...instruction, pointer, ...etc]
    uint256 start;
    // For each instruction set...
    for (uint256 i; i != length; ++i) {
        // Start at the index of the first byte of the next instruction.
        start = pointer;
        // Set the new pointer to the next instruction, located at the pointer.
        pointer = uint8(data[pointer]);
        // The `start:` includes the pointer byte, while the `:end` `pointer` is excluded.
        if (pointer > data.length) revert JumpError(pointer);
        bytes calldata instruction = data[start:pointer];
        // Process the instruction.
        _process(instruction[1:]); // note: Removes the pointer to the next instruction.
    }
}
