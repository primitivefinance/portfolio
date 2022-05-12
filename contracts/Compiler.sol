pragma solidity ^0.8.0;

import "./HyperSwap.sol";

interface CompilerEvents {
    event Debit(address token, uint256 amount);
    event Credit(address token, uint256 amount);
}

/// @notice Final Boss
/// @dev HyperSwap -> SingleOrder & MultiOrder -> { HyperSwap: _swap -> { HyperLiquidity: _addLiquidity & _removeLiquidity } }
contract Compiler is HyperSwap, CompilerEvents {
    // --- Internal --- //

    function _getBal(address token) internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
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

    function _settle(uint8[] memory ids) internal {
        uint256 len = ids.length;
        for (uint256 i; i != len; i++) {
            uint8 id = ids[i];
            Tokens memory tks = tokens[id];
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
        uint8 id,
        uint8 kind,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    ) external {
        Tokens memory tkns = tokens[id];
        _cacheAddress(tkns.tokenBase, true);
        _cacheAddress(tkns.tokenQuote, true);

        if (kind == 1) _addLiquidity(id, deltaBase, deltaQuote);
        else if (kind == 5) _swap(id, 0, deltaBase, deltaQuote);
        else _removeLiquidity(id, deltaLiquidity);

        uint8[] memory ids = new uint8[](1);
        ids[0] = id;
        _settle(ids);
    }

    /// ToDo: Handle amounts better, order types and cleanup code, etc.
    function multiOrder(
        uint8[] memory ids,
        uint8[] memory kinds,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    ) public {
        uint256 len = ids.length;
        for (uint256 i; i != len; i++) {
            uint8 id = ids[i];
            uint8 kind = kinds[i];
            Tokens memory tks = tokens[id];
            _cacheAddress(tks.tokenBase, true);
            _cacheAddress(tks.tokenQuote, true);
            if (kind == 1) _addLiquidity(id, deltaBase, deltaQuote);
            else if (kind == 5) _swap(id, 0, deltaBase, deltaQuote);
            else _removeLiquidity(id, deltaLiquidity);
        }

        _settle(ids);
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
