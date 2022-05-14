pragma solidity ^0.8.0;

import "./HyperSwap.sol";
import "./HyperLiquidity.sol";

import "hardhat/console.sol";

/// @notice Final Boss
/// @dev Inherits the pool creator, swapper, and liquidity modules.
contract Compiler is HyperLiquidity, HyperSwap {
    // --- Fallback --- //

    fallback() external payable {
        uint16[] memory pairIds;
        if (msg.data[0] != INSTRUCTION_JUMP) {
            pairIds = new uint16[](1);
            uint16 pairId = _process(msg.data);
            if (pairId != 0) _tempPairIds.push(pairId);
            //pairIds[0] = pairId;
        } else {
            pairIds = _jumpProcess(msg.data);
        }

        _settleBalances(pairIds);
    }

    // --- View --- //

    // --- Internal --- //

    function _process(bytes calldata data) internal returns (uint16 pairId) {
        bytes1 instruction = bytes1(data[0] & 0x0f);
        uint48 poolId;

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

        // Caching the addresses to settle the pools interacted with in the fallback function.
        pairId = uint16(poolId >> 32);
        Pair memory pair = pairs[pairId];
        if (!addressCache[pair.tokenBase]) _cacheAddress(pair.tokenBase, true);
        if (!addressCache[pair.tokenQuote]) _cacheAddress(pair.tokenQuote, true);
    }

    function _cacheAddress(address token, bool flag) internal {
        addressCache[token] = flag;
    }

    error JumpError(uint256 pointer);

    uint16[] private _tempPairIds; // note: critical, used in jump process and cleared at end.

    /// @dev Expects a special encoding method for multiple instructions.
    /// @param data Includes opcode as byte at index 0. First byte should point to next instruction.
    function _jumpProcess(bytes calldata data) internal returns (uint16[] memory) {
        uint8 length = uint8(data[1]);
        uint8 pointer = 2; // note: [opcode, length, instructionPointer, ...instruction, pointer, ...etc]
        uint256 start;

        uint16[] memory pairIds = new uint16[](length); // note: need to return all the pairs interacted with.

        // For each instruction set...
        for (uint256 i; i != length; ++i) {
            // Start at the first byte of the next instruction
            start = pointer;

            // Set the new pointer to the next instruction
            pointer = uint8(data[pointer]);

            // Get the bytes of the instruction
            if (pointer > data.length) revert JumpError(pointer);
            bytes calldata instruction = data[start:pointer];

            // Process the instruction
            uint16 pairId = _process(instruction[1:]); // Removes the pointer to the next instruction.

            // Add the pair to the array
            console.log("adding pairId:", pairId);
            //if (pairId != 0) pairIds[i] = pairId; // note: pairIds start at 1 because nonce is incremented first.
            if (pairId != 0) _tempPairIds.push(pairId);
        }

        return pairIds;
    }

    /// @dev Critical level function that is responsible for handling tokens, debits and credits.
    function _settleBalances(uint16[] memory pairIds) internal {
        uint256 len = _tempPairIds.length; //pairIds.length;
        uint16[] memory ids = new uint16[](len);
        console.log("len");
        console.log(len);
        if (len == 0) return; // note: Dangerous! If pools were interacted with, this return being trigerred would be a failure.
        for (uint256 i; i != len; ++i) {
            uint16 pairId = ids[i];
            Pair memory pair = pairs[pairId];
            console.log(pairId);
            console.log(pair.tokenBase, pair.tokenQuote);
            _settleToken(pair.tokenBase);
            _settleToken(pair.tokenQuote);
        }

        delete _tempPairIds;
    }

    function _settleToken(address token) private {
        if (!addressCache[token]) return; // note: early short circuit, since attempting to settle twice is common for big orders.

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

    /// @dev Critical level function that is responsible for handling tokens, debits and credits.
    function _settle(uint32[] memory poolIds) private {
        uint256 len = poolIds.length;
        for (uint256 i; i != len; i++) {
            uint48 poolId = poolIds[i];
            Pair memory tks = pairs[uint16(poolId)];
            uint256 globalBase = globalReserves[tks.tokenBase];
            uint256 globalQuote = globalReserves[tks.tokenQuote];
            uint256 actualBase = _balanceOf(tks.tokenBase);
            uint256 actualQuote = _balanceOf(tks.tokenQuote);
            if (addressCache[tks.tokenBase]) {
                if (globalBase > actualBase) {
                    uint256 deficit = globalBase - actualBase;
                    // _applyDebit
                    _applyDebit(tks.tokenBase, deficit);
                } else {
                    // _applyCredit if non zero
                    uint256 surplus = actualBase - globalBase;
                    _applyCredit(tks.tokenBase, surplus);
                }

                _cacheAddress(tks.tokenBase, false);
            }

            if (addressCache[tks.tokenQuote]) {
                if (globalQuote > actualQuote) {
                    uint256 deficit = globalQuote - actualQuote;
                    // _applyDebit
                    _applyDebit(tks.tokenQuote, deficit);
                } else {
                    // _applyCredit if non zero
                    uint256 surplus = actualQuote - globalQuote;
                    _applyCredit(tks.tokenQuote, surplus);
                }

                _cacheAddress(tks.tokenQuote, false);
            }
        }
    }

    /// @dev A non-zero debit is a cost that must be paid for a transaction to go through.
    ///      If a balance exists for the token for the respective account `msg.sender`,
    ///      it will be used to pay the debit.
    ///      Else, tokens are expected to be transferred into this contract.
    ///      Externally paid debits increase the balance of the contract, so the global
    ///      reserves must be increased.
    function _applyDebit(address token, uint256 amount) private {
        if (balances[msg.sender][token] >= amount) balances[msg.sender][token] -= amount;
        else {
            _increaseGlobal(token, amount);
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
        emit Debit(token, amount);
    }

    /// @dev A non-zero credit is a receivalble paid to the `msg.sender` account.
    ///      Positive credits are only applied to the internal balance of the account.
    ///      Therefore, it does not require a state change for the global reserves.
    function _applyCredit(address token, uint256 amount) private {
        balances[msg.sender][token] += amount;
        emit Credit(token, amount);
    }

    // --- External --- //

    /// ToDo: Implement all order types.
    function singleOrder(
        uint48 poolId,
        uint8 kind,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    ) external lock {
        Pair memory pair = pairs[uint16(poolId)];
        _cacheAddress(pair.tokenBase, true);
        _cacheAddress(pair.tokenQuote, true);

        if (kind == 5) _swap(poolId, 0, deltaBase, deltaQuote);

        uint32[] memory poolIds = new uint32[](1);
        poolIds[0] = uint32(poolId);
        _settle(poolIds);
    }

    /// ToDo: Handle amounts better, order types and cleanup code, etc.
    function multiOrder(
        uint32[] memory poolIds,
        uint8[] memory kinds,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    ) public lock {
        uint256 len = poolIds.length;
        for (uint256 i; i != len; i++) {
            uint48 poolId = poolIds[i];
            uint8 kind = kinds[i];
            Pair memory tks = pairs[uint16(poolId)];
            _cacheAddress(tks.tokenBase, true);
            _cacheAddress(tks.tokenQuote, true);
            if (kind == 5) _swap(poolId, 0, deltaBase, deltaQuote);
        }

        _settle(poolIds);
    }

    // --- External --- //
    // ToDo: Move to be internal
    function fund(address token, uint256 amount) external lock {
        _applyCredit(token, amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function draw(address token, uint256 amount) external lock {
        _applyDebit(token, amount);
        IERC20(token).transfer(msg.sender, amount);
    }
}
