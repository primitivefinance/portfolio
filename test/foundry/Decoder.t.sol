pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/libraries/Decoder.sol";

/// @dev This contract looks a bit pointless but is necessary to pass
/// the data as calldata bytes into the Decoder library...
contract DecoderWrapper {
    function decodeCreatePool(bytes calldata data)
        public
        pure
        returns (
            address token0,
            address token1,
            uint256 price
        )
    {
        (token0, token1, price) = Decoder.decodeCreatePool(data);
    }

    function decodeSwap(bytes calldata data)
        public
        returns (
            uint8 useMax,
            uint48 poolId,
            uint128 input,
            uint128 limit,
            uint8 direction
        )
    {
        (useMax, poolId, input, limit, direction) = Decoder.decodeSwap(data);
    }
}

contract TestDecoder is Test {
    DecoderWrapper public decoder;

    function setUp() public {
        decoder = new DecoderWrapper();
    }

    function testDecodeCreatePool() public {
        bytes memory data = hex"0B9bc0dC30f3522bA29A37Cf9098EabCDEa86dD93532c18e72DD64531B1C43Eec684B1E3Ee9d7EB6160101";

        (address token0, address token1, uint256 price) = decoder.decodeCreatePool(data);

        assertEq(token0, 0x32c18e72DD64531B1C43Eec684B1E3Ee9d7EB616);
        assertEq(token1, 0x9bc0dC30f3522bA29A37Cf9098EabCDEa86dD935);
        assertEq(price, 10);
    }

    function testDecoderSwap() public {
        bytes memory data = hex"05000002071201060100";

        (uint8 useMax, uint48 poolId, uint128 input, uint128 limit, uint8 direction) = decoder.decodeSwap(data);

        assertEq(useMax, 0);
        assertEq(poolId, 2);
        assertEq(input, 1 ether);
        assertEq(limit, 1 * 10**6);
        assertEq(direction, 0);
    }
}
