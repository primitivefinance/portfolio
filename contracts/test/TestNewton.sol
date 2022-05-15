pragma solidity ^0.8.0;

import "../libraries/Newton.sol";

contract TestNewton {
    using ABDKMath64x64 for int128;
    int128 public result;

    function testComputeOutput(int128 x) public returns (int128) {
        int128 epsilon = ABDKMath64x64.fromUInt(1).div(ABDKMath64x64.fromUInt(1e2));
        uint256 maxRuns = 15;
        int128 y = Newton.compute(x, epsilon, maxRuns, _tradingFunction, _derivativeTradingFunction);
        result = y;
        return y;
    }

    function testCompute(int128 x) public returns (int128) {
        int128 epsilon = ABDKMath64x64.fromUInt(1).div(ABDKMath64x64.fromUInt(1e2));
        uint256 maxRuns = 15;
        return Newton.compute(x, epsilon, maxRuns, _tradingFunction, _derivativeTradingFunction);
    }

    function testComputeTen(int128 x) public returns (int128) {
        int128 epsilon = ABDKMath64x64.fromUInt(1).div(ABDKMath64x64.fromUInt(1e2));
        return Newton.computeTen(x, epsilon, _tradingFunction, _derivativeTradingFunction);
    }

    function tradingFunction(int128 x) public pure returns (int128) {
        return _tradingFunction(x);
    }

    function derivativeTradingFunction(int128 x) public pure returns (int128) {
        return _derivativeTradingFunction(x);
    }

    function _tradingFunction(int128 x) internal pure returns (int128) {
        return x.pow(3).sub(x.pow(2)).add(ABDKMath64x64.fromUInt(2));
    }

    function _derivativeTradingFunction(int128 x) internal pure returns (int128) {
        return ABDKMath64x64.fromUInt(3).mul(x.pow(2)).sub(ABDKMath64x64.fromUInt(2).mul(x));
    }
}
