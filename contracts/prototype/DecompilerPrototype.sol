// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";

import "./HyperPrototype.sol";

/// @title Enigma Decompiler
/// @notice Main contract of the Enigma that implements instruction processing.
/// @dev Eliminates the use of function signatures. Expects encoded bytes as msg.data in the fallback.
contract DecompilerPrototype is HyperPrototype {
    // --- Constructor --- //

    constructor(address weth) EnigmaVirtualMachinePrototype(weth) {}

    // --- Receive ETH fallback --- //

    // Note: Not sure if we should always revert when receiving ETH
    receive() external payable {
        revert();
    }

    // --- Fallback --- //

    /// @notice Main touchpoint for receiving calls.
    /// @dev Critical: data must be encoded properly to be processed.
    /// @custom:security Critical. Guarded against re-entrancy. This is like the bank vault door.
    /// @custom:mev Higher level security checks must be implemented by calling contract.
    fallback() external payable lock {
        if (msg.data[0] != Instructions.INSTRUCTION_JUMP) _process(msg.data);
        else _jumpProcess(msg.data);
        _settleBalances();
    }

    // --- Private --- //

    /// @dev Critical array, used in jump process to track the pairs that were interacted with.
    /// @notice Cleared at end and never permanently set.
    /// @custom:security High. Without pairIds to loop through, no token amounts are settled.
    uint16[] internal _tempPairIds;

    /// @dev Token -> Touched Flag. Stored temporary to signal which token reserves were tapped.
    mapping(address => bool) internal _addressCache;

    /// @dev Flag set to `true` during `_process`. Set to `false` during `_settleToken`.
    /// @custom:security High. Referenced in settlement to pay for tokens due.
    function _cacheAddress(address token, bool flag) internal {
        _addressCache[token] = flag;
    }

    // --- Internal --- //

    /// @dev A positive credit is a receivable paid to the `msg.sender` internal balance.
    ///      Positive credits are only applied to the internal balance of the account.
    ///      Therefore, it does not require a state change for the global reserves.
    /// @custom:security Critical. Only method which credits accounts with tokens.
    function _applyCredit(address token, uint256 amount) internal {
        _balances[msg.sender][token] += amount;
        emit Credit(token, amount);
    }

    /// @dev Dangerous! Calls to external contract with an inline assembly `safeTransferFrom`.
    ///      A positive debit is a cost that must be paid for a transaction to be processed.
    ///      If a balance exists for the token for the internal balance of `msg.sender`,
    ///      it will be used to pay the debit.
    ///      Else, tokens are expected to be transferred into this contract using `transferFrom`.
    ///      Externally paid debits increase the balance of the contract, so the global
    ///      reserves must be increased.
    /// @custom:security Critical. Handles the payment of tokens for all pool actions.
    function _applyDebit(address token, uint256 amount) internal {
        if (_balances[msg.sender][token] >= amount) _balances[msg.sender][token] -= amount;
        else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
        emit Debit(token, amount);
    }

    /// @notice Single instruction processor that will forward instruction to appropriate function.
    /// @dev Critical: Every token of every pair interacted with is cached to be settled later.
    /// @param data Encoded Enigma data. First byte must be an Enigma instruction.
    /// @custom:security Critical. Directly sends instructions to be executed.
    function _process(bytes calldata data) internal override {
        uint48 poolId;
        bytes1 instruction = bytes1(data[0] & 0x0f);
        if (instruction == Instructions.UNKNOWN) revert UnknownInstruction();

        if (instruction == Instructions.ADD_LIQUIDITY) {
            (poolId, ) = _addLiquidity(data);
        } else if (instruction == Instructions.REMOVE_LIQUIDITY) {
            (poolId, , ) = _removeLiquidity(data);
        } else if (instruction == Instructions.SWAP) {
            (poolId, , , ) = _swapExactForExact(data);
        } else if (instruction == Instructions.STAKE_POSITION) {
            (poolId, ) = _stakePosition(data);
        } else if (instruction == Instructions.UNSTAKE_POSITION) {
            (poolId, ) = _unstakePosition(data);
        } else if (instruction == Instructions.CREATE_POOL) {
            (poolId) = _createPool(data);
        } else if (instruction == Instructions.CREATE_CURVE) {
            _createCurve(data);
        } else if (instruction == Instructions.CREATE_PAIR) {
            _createPair(data);
        } else {
            revert UnknownInstruction();
        }

        // note: Only pool interactions have a non-zero poolId.
        if (poolId != 0) {
            uint16 pairId = uint16(poolId >> 32);
            // Add the pair to the array to track all the pairs that have been interacted with.
            _tempPairIds.push(pairId); // note: critical to push the tokens interacted with.
            // Caching the addresses to settle the pools interacted with in the fallback function.
            Pair memory pair = _pairs[pairId]; // note: pairIds start at 1 because nonce is incremented first.
            if (!_addressCache[pair.tokenBase]) _cacheAddress(pair.tokenBase, true);
            if (!_addressCache[pair.tokenQuote]) _cacheAddress(pair.tokenQuote, true);
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
            Pair memory pair = _pairs[pairId];
            _settleToken(pair.tokenBase);
            _settleToken(pair.tokenQuote);
        }

        delete _tempPairIds;
    }

    /// @dev Increases the `msg.sender` internal balance of a token, or requests payment from them.
    /// @param token Target token to pay or credit.
    /// @custom:security Critical. Handles crediting accounts or requesting payment for debits.
    function _settleToken(address token) internal {
        if (!_addressCache[token]) return; // note: Early short circuit, since attempting to settle twice is common for big orders.

        // If the token is WETH, make sure to wrap any ETH sent to the contract.
        if (token == WETH && msg.value > 0) _wrap();

        uint256 global = _globalReserves[token];
        uint256 actual = _balanceOf(token, address(this));
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
        if (_balances[msg.sender][token] < amount) revert DrawBalance();
        _applyDebit(token, amount);

        if (token == WETH) _dangerousUnwrap(to, amount);
        else SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    /// @inheritdoc IEnigmaActions
    function fund(address token, uint256 amount) external payable override lock {
        _applyCredit(token, amount);
        if (token == WETH) _wrap();
        else SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, address(this), amount);
    }

    // --- View --- //

    // todo: check for hash collisions with instruction calldata and fix.

    function slots(uint48 poolId, int24 slot) external view returns (IEnigmaDataStructures.HyperSlot memory) {
        return _slots[poolId][slot];
    }

    function pairs(uint16 pairId) external view override returns (Pair memory p) {
        p = _pairs[pairId];
    }

    function curves(uint32 curveId) external view override returns (Curve memory c) {
        c = _curves[curveId];
    }

    function pools(uint48 poolId) external view override returns (HyperPool memory) {
        p = _pools[poolId];
    }

    function reserves(address asset) external view override returns (uint256) {
        return _globalReserves[asset];
    }

    function getCurveId(bytes32 packedCurve) external view override returns (uint32) {
        return _getCurveIds[packedCurve];
    }

    function getCurveNonce() external view override returns (uint256) {
        return _curveNonce;
    }

    function getPairNonce() external view override returns (uint256) {
        return _pairNonce;
    }

    function getPairId(address asset, address quote) external view returns (uint256) {
        return _getPairId[asset][quote];
    }

    function checkJitLiquidity(
        address,
        uint48,
        int24,
        int24
    ) external view override returns (uint256 distance, uint256 timestamp) {}

    function getLiquidityMinted(
        uint48 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) external view returns (uint256 deltaLiquidity) {}

    function getInvariant(uint48 poolId) external view returns (int128 invariant) {}

    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        external
        view
        returns (uint256 deltaBase, uint256 deltaQuote)
    {}

    function updateLastTimestamp(uint48) external override returns (uint128 blockTimestamp) {}
}
