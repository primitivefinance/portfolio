pragma solidity ^0.8.0;

import "../EnigmaVirtualMachine.sol";
import "../libraries/Units.sol";

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
        curve.strike = 1e19; // 10
        curve.sigma = 1e4; // 100%
        curve.maturity = uint32(Units.YEAR) + 1; // adds one second because block timestamp is at least 1
        curve.gamma = 1e4 - 100; // 99%

        Pair storage pair = pairs[uint16(poolId >> 32)];
        pair.decimalsBase = IERC20(base).decimals();
        pair.tokenBase = base;
        pair.decimalsQuote = IERC20(quote).decimals();
        pair.tokenQuote = quote;

        Pool storage pool = pools[poolId];
        pool.internalBase = 308537538726000000; // 0.308
        pool.internalQuote = 3085375387260000000; // 3.08
        pool.internalLiquidity = 1e18; // 1
        pool.blockTimestamp = 1; // arbitrary, but cannot be zero!

        Position storage pos = positions[msg.sender][poolId];
        pos.liquidity = 1e18;
        pos.blockTimestamp = _blockTimestamp();

        globalReserves[pair.tokenBase] += pool.internalBase;
        globalReserves[pair.tokenQuote] += pool.internalQuote;
    }
}
