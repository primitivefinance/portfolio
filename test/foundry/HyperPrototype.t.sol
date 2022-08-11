pragma solidity 0.8.13;

import "../shared/BaseTest.sol";

import "../../contracts/prototype/HyperPrototype.sol";

contract TestHyperPrototype is HyperPrototype, BaseTest {
    function testSlick() public {
        bool perpetual = (0 | 1 | 0) == 0;
        console.log("is perpetual?", perpetual);
        assembly {
            perpetual := iszero(or(0, or(1, 0))) // ((strike == 0 && sigma == 0) && maturity == 0)
        }

        console.log("is perpetual?", perpetual);
    }
}
