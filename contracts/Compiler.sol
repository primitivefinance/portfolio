pragma solidity ^0.8.0;

import "./HyperSwap.sol";
import "./HyperLiquidity.sol";

interface CompilerEvents {
    event Debit(address token, uint256 amount);
    event Credit(address token, uint256 amount);
}

/// @notice Final Boss
/// @dev Inherits the pool creator, swapper, and liquidity modules.
contract Compiler is HyperLiquidity, HyperSwap, CompilerEvents {
    // --- Fallback --- //

    fallback() external payable {
        _process(msg.data);
    }

    // --- View --- //

    function _getBal(address token) internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    // --- Internal --- //

    function _process(bytes calldata data) internal {
        bytes1 instruction = bytes1(data[0] & 0x0f);

        if (instruction == CREATE_POOL) {}
    }

    function _cacheAddress(address token, bool flag) internal {
        addressCache[token] = flag;
    }

    function _applyDebit(address token, uint256 amount) internal {
        if (balances[msg.sender][token] >= amount) balances[msg.sender][token] -= amount;
        else IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Debit(token, amount);
    }

    function _applyCredit(address token, uint256 amount) internal {
        balances[msg.sender][token] += amount;
        emit Credit(token, amount);
    }

    function _settle(uint32[] memory poolIds) internal {
        uint256 len = poolIds.length;
        for (uint256 i; i != len; i++) {
            uint48 poolId = poolIds[i];
            Pair memory tks = pairs[uint16(poolId)];
            uint256 globalBase = globalReserves[tks.tokenBase];
            uint256 globalQuote = globalReserves[tks.tokenQuote];
            uint256 actualBase = _getBal(tks.tokenBase);
            uint256 actualQuote = _getBal(tks.tokenQuote);
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

    // --- External --- //

    /// ToDo: Implement all order types.
    function singleOrder(
        uint48 poolId,
        uint8 kind,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    ) external {
        Pair memory pair = pairs[uint16(poolId)];
        _cacheAddress(pair.tokenBase, true);
        _cacheAddress(pair.tokenQuote, true);

        if (kind == 1) _addLiquidity(poolId, deltaBase, deltaQuote);
        else if (kind == 5) _swap(poolId, 0, deltaBase, deltaQuote);

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
    ) public {
        uint256 len = poolIds.length;
        for (uint256 i; i != len; i++) {
            uint48 poolId = poolIds[i];
            uint8 kind = kinds[i];
            Pair memory tks = pairs[uint16(poolId)];
            _cacheAddress(tks.tokenBase, true);
            _cacheAddress(tks.tokenQuote, true);
            if (kind == 1) _addLiquidity(poolId, deltaBase, deltaQuote);
            else if (kind == 5) _swap(poolId, 0, deltaBase, deltaQuote);
        }

        _settle(poolIds);
    }

    // --- External --- //
    // ToDo: Move to be internal
    function fund(address token, uint256 amount) external {
        _applyCredit(token, amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function draw(address token, uint256 amount) external {
        _applyDebit(token, amount);
        IERC20(token).transfer(msg.sender, amount);
    }
}
