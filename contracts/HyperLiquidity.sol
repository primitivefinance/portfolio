pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "hardhat/console.sol";

interface HyperLiquidityErrors {
    error ZilchError();
    error ZeroLiquidityError();
}

interface HyperLiquidityEvents {
    event Debit(address token, uint256 amount);
    event Credit(address token, uint256 amount);
}

interface HyperLiquidityDataStructures {
    struct Tokens {
        address tokenBase;
        address tokenQuote;
    }

    struct Pool {
        uint128 internalBase;
        uint128 internalQuote;
        uint128 internalLiquidity;
        uint128 blockTimestamp;
    }

    struct Position {
        uint256 liquidity;
        uint128 blockTimestamp;
    }
}

/// @notice Designed to maintain collateral for the sum of virtual liquidity across all pools.
contract HyperLiquidity is HyperLiquidityErrors, HyperLiquidityEvents, HyperLiquidityDataStructures {
    // --- View --- //

    /// Gets base and quote tokens entitled to argument `liquidity`.
    function getPhysicalReserves(uint256 liquidity) public view returns (uint256, uint256) {
        Pool memory pool = pools[0];
        uint256 total = uint256(pool.internalLiquidity);
        uint256 amount0 = (pool.internalBase * liquidity) / total;
        uint256 amount1 = (pool.internalQuote * liquidity) / total;
        return (amount0, amount1);
    }

    // --- Internal Functions (Can Override in Tests) --- //
    function _blockTimestamp() internal view returns (uint128) {
        return uint128(block.timestamp);
    }

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

    /// @notice Changes internal "fake" reserves of a pool with `id`.
    /// @dev    Liquidity must be credited to an address, and token amounts must be _applyDebited.
    function _addLiquidity(
        uint8 id,
        uint256 deltaBase,
        uint256 deltaQuote
    ) internal returns (uint256 deltaLiquidity) {
        Pool storage pool = pools[id];
        if (pool.blockTimestamp == 0) revert ZilchError();

        uint256 liquidity0 = (deltaBase * pool.internalLiquidity) / uint256(pool.internalBase);
        uint256 liquidity1 = (deltaQuote * pool.internalLiquidity) / uint256(pool.internalQuote);
        deltaLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;

        if (deltaLiquidity == 0) revert ZeroLiquidityError();

        pool.internalBase += uint128(deltaBase);
        pool.internalQuote += uint128(deltaQuote);
        pool.internalLiquidity += uint128(deltaLiquidity);
        pool.blockTimestamp = _blockTimestamp();

        Tokens storage token = tokens[id];
        globalReserves[token.tokenBase] += deltaBase;
        globalReserves[token.tokenQuote] += deltaQuote;

        Position storage pos = positions[msg.sender][id];
        pos.liquidity += deltaLiquidity;
        pos.blockTimestamp = _blockTimestamp();
    }

    function _removeLiquidity(uint8 id, uint256 deltaLiquidity)
        internal
        returns (uint256 deltaBase, uint256 deltaQuote)
    {
        Pool storage pool = pools[id];
        if (pool.blockTimestamp == 0) revert ZilchError();

        deltaBase = (pool.internalBase * deltaLiquidity) / pool.internalLiquidity;
        deltaQuote = (pool.internalQuote * deltaLiquidity) / pool.internalLiquidity;

        if (deltaLiquidity == 0) revert ZeroLiquidityError();

        pool.internalBase -= uint128(deltaBase);
        pool.internalQuote -= uint128(deltaQuote);
        pool.internalLiquidity -= uint128(deltaLiquidity);
        pool.blockTimestamp = _blockTimestamp();

        Tokens storage token = tokens[id];
        globalReserves[token.tokenBase] -= deltaBase;
        globalReserves[token.tokenQuote] -= deltaQuote;

        Position storage pos = positions[msg.sender][id];
        pos.liquidity -= deltaLiquidity;
        pos.blockTimestamp = _blockTimestamp();
    }

    // --- External --- //

    function fund(address token, uint256 amount) external {
        _applyCredit(token, amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function draw(address token, uint256 amount) external {
        _applyDebit(token, amount);
        IERC20(token).transfer(msg.sender, amount);
    }

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
            else _removeLiquidity(id, deltaLiquidity);
        }

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

    // --- Storage --- //

    // Token -> Physical Reserves.
    mapping(address => uint256) public globalReserves;
    // Pool id -> Pool Data Structure.
    mapping(uint8 => Pool) public pools;
    // Pool id -> Tokens of a Pool.
    mapping(uint8 => Tokens) public tokens;
    // User -> Pool id -> Liquidity Positions.
    mapping(address => mapping(uint8 => Position)) public positions;
    // User -> Token -> Interal Balance.
    mapping(address => mapping(address => uint256)) public balances;
    // Token -> Touched Flag. Stored temporary to signal which token reserves were tapped.
    mapping(address => bool) public addressCache;
}
