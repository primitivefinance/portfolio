pragma solidity ^0.8.0;

contract Basic {
    function test_add(uint a) public returns (bool) {
        require(a + 1 > 1);
    }
}
