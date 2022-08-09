pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../../contracts/Decompiler.sol";

contract TestDecompiler is Decompiler, Test {
    function testFallback() public {
        vm.prank(address(0));
        vm.deal(address(0), 1 ether);
        address(this).call{value: 1 ether}("");
    }
}
