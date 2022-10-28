pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/Smol.sol";

contract TestSmol is Test {
    Smol public smol;

    function setUp() public {
        smol = new Smol();
    }
}
