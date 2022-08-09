/// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "@primitivefi/rmm-core/contracts/libraries/Units.sol";

import "../EnigmaVirtualMachine.sol";

library StandardPoolHelpers {
    uint128 public constant STRIKE = 1e19;
    uint24 public constant SIGMA = 1e4;
    uint32 public constant MATURITY = 31556953; // adds 1
    uint16 public constant FEE = 100;
    uint32 public constant GAMMA = 9900;

    uint128 public constant INTERNAL_BASE = 308537538726000000;
    uint128 public constant INTERNAL_QUOTE = 3085375387260000000;
    uint128 public constant INTERNAL_LIQUIDITY = 1e18;
}

abstract contract Helpers is EnigmaVirtualMachine {
    address public base;
    address public quote;

    function helperSetTokens(address base_, address quote_) public {
        base = base_;
        quote = quote_;
    }

    /// @dev Creates a hardcoded pool with parameters plugged into: https://www.desmos.com/calculator/hv9kg9d16x
    function helperCreateStandardPool(uint48 poolId) public {
        require(base != address(0x0), "no-base-token");
        require(quote != address(0x0), "no-quote-token");

        Curve storage curve = curves[uint32(poolId)];
        curve.strike = StandardPoolHelpers.STRIKE; // 10
        curve.sigma = StandardPoolHelpers.SIGMA; // 100%
        curve.maturity = StandardPoolHelpers.MATURITY; // adds one second because block timestamp is at least 1
        curve.gamma = StandardPoolHelpers.GAMMA; // 99%

        Pair storage pair = pairs[uint16(poolId >> 32)];
        pair.decimalsBase = IERC20(base).decimals();
        pair.tokenBase = base;
        pair.decimalsQuote = IERC20(quote).decimals();
        pair.tokenQuote = quote;

        Pool storage pool = pools[poolId];
        pool.internalBase = StandardPoolHelpers.INTERNAL_BASE; // 0.308
        pool.internalQuote = StandardPoolHelpers.INTERNAL_QUOTE; // 3.08
        pool.internalLiquidity = StandardPoolHelpers.INTERNAL_LIQUIDITY; // 1
        pool.blockTimestamp = 1; // arbitrary, but cannot be zero!

        Position storage pos = positions[msg.sender][poolId];
        pos.liquidity = 1e18;
        pos.blockTimestamp = _blockTimestamp();

        globalReserves[pair.tokenBase] += pool.internalBase;
        globalReserves[pair.tokenQuote] += pool.internalQuote;
    }
}
