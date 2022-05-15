pragma solidity ^0.8.0;

import "./HyperSwap.sol";
import "./HyperLiquidity.sol";

/// @title Enigma Compiler
/// @notice Main contract of the Enigma that implements instruction processing.
/// @dev Eliminates the majority use of function signatures. Expects encoded bytes as msg.data in the fallback.
contract Compiler is HyperLiquidity, HyperSwap {
    // --- Fallback --- //

    /// @notice Main touchpoint for receiving calls.
    /// @dev Critical: data must be encoded properly to be processed.
    /// @custom:security Critical. Guarded against re-entrancy. This is like the bank vault door.
    fallback() external payable lock {
        if (msg.data[0] != INSTRUCTION_JUMP) {
            _process(msg.data);
        } else {
            _jumpProcess(msg.data);
        }

        _settleBalances();
    }

    // --- Private --- //

    /// @dev Critical array, used in jump process to track the pairs that were interacted with.
    /// @notice Cleared at end, never permanently set.
    uint16[] internal _tempPairIds;

    /// @dev Flag set to true during `_process`. Set to false during `_settleToken`.
    /// @custom:security High. Referenced in settlement to pay for tokens due.
    function _cacheAddress(address token, bool flag) internal {
        addressCache[token] = flag;
    }

    // --- Internal --- //

    /// @dev A non-zero credit is a receivalble paid to the `msg.sender` account.
    ///      Positive credits are only applied to the internal balance of the account.
    ///      Therefore, it does not require a state change for the global reserves.
    /// @custom:security Critical. The only method that accounts are credited for tokens.
    function _applyCredit(address token, uint256 amount) internal {
        balances[msg.sender][token] += amount;
        emit Credit(token, amount);
    }

    /// @dev A non-zero debit is a cost that must be paid for a transaction to go through.
    ///      If a balance exists for the token for the respective account `msg.sender`,
    ///      it will be used to pay the debit.
    ///      Else, tokens are expected to be transferred into this contract.
    ///      Externally paid debits increase the balance of the contract, so the global
    ///      reserves must be increased.
    /// @custom:security Critical. Handles the payment of tokens for all pool actions.
    function _applyDebit(address token, uint256 amount) internal {
        if (balances[msg.sender][token] >= amount) balances[msg.sender][token] -= amount;
        else IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Debit(token, amount);
    }

    /// @notice First byte should always be the INSTRUCTION_JUMP Enigma code.
    /// @dev Expects a special encoding method for multiple instructions.
    /// @param data Includes opcode as byte at index 0. First byte should point to next instruction.
    /// @custom:security Critical. Processes multiple instructions. Data must be encoded perfectly.
    function _jumpProcess(bytes calldata data) internal {
        uint8 length = uint8(data[1]);
        uint8 pointer = 2; // note: [opcode, length, pointer, ...instruction, pointer, ...etc]
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

    /// @notice Single instruction processor that will forward instruction to appropriate function.
    /// @dev Critical: Every token of every pair interacted with is cached to be settled later.
    /// @param data Encoded Enigma data. First byte must be an Enigma instruction.
    /// @custom:security Critical. Directly sends instructions to be executed.
    function _process(bytes calldata data) internal returns (uint16 pairId) {
        uint48 poolId;
        bytes1 instruction = bytes1(data[0] & 0x0f);

        if (instruction == ADD_LIQUIDITY) {
            (poolId, ) = _addLiquidity(data);
        } else if (instruction == REMOVE_LIQUIDITY) {
            (poolId, , ) = _removeLiquidity(data);
        } else if (instruction == SWAP_EXACT_TOKENS_FOR_TOKENS) {
            (poolId, ) = _swapExactTokens(data);
        } else if (instruction == CREATE_POOL) {
            _createPool(data);
        } else if (instruction == CREATE_CURVE) {
            _createCurve(data);
        } else if (instruction == CREATE_PAIR) {
            _createPair(data);
        }

        // note: Only pool interactions have a non-zero poolId.
        if (poolId != 0) {
            pairId = uint16(poolId >> 32);
            // Add the pair to the array to track all the pairs that have been interacted with.
            _tempPairIds.push(pairId); // note: critical to push the tokens interacted with.
            // Caching the addresses to settle the pools interacted with in the fallback function.
            Pair memory pair = pairs[pairId]; // note: pairIds start at 1 because nonce is incremented first.
            if (!addressCache[pair.tokenBase]) _cacheAddress(pair.tokenBase, true);
            if (!addressCache[pair.tokenQuote]) _cacheAddress(pair.tokenQuote, true);
        }
    }

    /// @dev Critical level function that is responsible for handling tokens, debits and credits.
    /// @custom:security Critical. Handles token payments with `_settleToken`.
    function _settleBalances() internal {
        uint256 len = _tempPairIds.length;
        uint16[] memory ids = _tempPairIds;
        if (len == 0) return; // note: Dangerous! If pools were interacted with, this return being trigerred would be a failure.
        for (uint256 i; i != len; ++i) {
            uint16 pairId = ids[i];
            Pair memory pair = pairs[pairId];
            _settleToken(pair.tokenBase);
            _settleToken(pair.tokenQuote);
        }

        delete _tempPairIds;
    }

    /// @dev Increases the `msg.sender` internal balance of a token, or requests payment from them.
    /// @param token Target token to pay or credit.
    /// @custom:security Critical. Handles crediting accounts or requesting payment for debits.
    function _settleToken(address token) internal {
        if (!addressCache[token]) return; // note: Early short circuit, since attempting to settle twice is common for big orders.

        uint256 global = globalReserves[token];
        uint256 actual = _balanceOf(token);

        if (global > actual) {
            uint256 deficit = global - actual;
            _applyDebit(token, deficit);
        } else {
            uint256 surplus = actual - global;
            _applyCredit(token, surplus);
        }

        _cacheAddress(token, false); // note: Effectively saying "any pool with this token was paid for in full".
    }

    // --- External --- //

    /// @inheritdoc IEnigmaActions
    function draw(
        address token,
        uint256 amount,
        address to
    ) external lock {
        // note: Would pull tokens without this conditional check.
        if (balances[msg.sender][token] < amount) revert DrawBalance();
        _applyDebit(token, amount);
        IERC20(token).transfer(to, amount);
    }

    /// @inheritdoc IEnigmaActions
    function fund(address token, uint256 amount) external override lock {
        _applyCredit(token, amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
}
