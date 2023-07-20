// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "contracts/libraries/BisectionLib.sol" as BisectionLib;

contract TestBisectionLib is Test {
    function simplePolynomial(
        bytes memory args,
        uint256 x
    ) internal pure returns (int256) {
        (int256 a, int256 b, int256 c) =
            abi.decode(args, (int256, int256, int256));

        int256 input = int256(x);

        return int256(a * input * input + b * input + c); // f(x) = ax^2 + bx + c
    }

    function test_bisection_basic_polynomial() public {
        uint256 root = BisectionLib.bisection(
            abi.encode(1, 0, -1), 0, 2, 1, 100, simplePolynomial
        );
        assertEq(root, 1);
    }
}
