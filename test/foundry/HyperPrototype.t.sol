pragma solidity 0.8.13;

import "../shared/BaseTest.sol";

import "../../contracts/prototype/HyperPrototype.sol";

contract TestHyperPrototype is HyperPrototype, BaseTest {
    function testPairs() public {
        _pairs;
    }
}
