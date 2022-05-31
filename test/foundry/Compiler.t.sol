pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../../contracts/Compiler.sol";

contract TestCompiler is Compiler, Test {
    function testFallback() public {
        vm.prank(address(0));
        vm.deal(address(0), 1 ether);
        address(this).call{value: 1 ether}("");
    }
}
