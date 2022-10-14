pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/libraries/Encoder.sol";

contract TestEncoder is Test {
    function testEncodeCreatePool() public {
        bytes memory amount = hex"0101";
        bytes
            memory expected = hex"0B9bc0dC30f3522bA29A37Cf9098EabCDEa86dD93532c18e72DD64531B1C43Eec684B1E3Ee9d7EB6160101";
        bytes memory data = Encoder.encodeCreatePool(
            0x9bc0dC30f3522bA29A37Cf9098EabCDEa86dD935,
            0x32c18e72DD64531B1C43Eec684B1E3Ee9d7EB616,
            amount
        );

        assertEq(data, expected);
    }
}
