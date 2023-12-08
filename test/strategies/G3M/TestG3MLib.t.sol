// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../../Setup.sol";

contract TestG3MLib is Setup {
    using FixedPointMathLib for *;

    function test_SF_computeISF() public view {
        uint256 x = 0.05 ether;
        uint256 y = G3MStrategyLib.computeISFunction(x);
        console.log(y);
    }

    function test_SF_computeSF() public view {
        uint256 w0 = 0.05 ether;
        uint256 w1 = 0.9 ether;
        uint256 t = 0.5 ether;
        uint256 fw0 = G3MStrategyLib.computeISFunction(w0);
        console.log(fw0);
        uint256 fw1 = G3MStrategyLib.computeISFunction(w1);
        console.log(fw1);
        uint256 weightX = G3MStrategyLib.computeSFunction(t, fw1 - fw0, fw0);
        console.log(weightX);
    }
}
