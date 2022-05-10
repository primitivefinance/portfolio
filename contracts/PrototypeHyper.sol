//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./libraries/Decoder.sol";

contract PrototypeHyper {
    string private greeting;
    // --- Order Types --- //
    bytes1 public constant UNKNOWN = bytes1(0x00);
    bytes1 public constant ADD_LIQUIDITY = bytes1(0x01);
    bytes1 public constant ADD_LIQUIDITY_ETH = bytes1(0x02);
    bytes1 public constant REMOVE_LIQUIDITY = bytes1(0x03);
    bytes1 public constant REMOVE_LIQUIDITY_ETH = bytes1(0x04);
    bytes1 public constant SWAP_EXACT_TOKENS_FOR_TOKENS = bytes1(0x05);
    bytes1 public constant SWAP_TOKENS_FOR_EXACT_TOKENS = bytes1(0x06);
    bytes1 public constant SWAP_EXACT_ETH_FOR_TOKENS = bytes1(0x07);
    bytes1 public constant SWAP_TOKENS_FOR_EXACT_ETH = bytes1(0x08);
    bytes1 public constant SWAP_EXACT_TOKENS_FOR_ETH = bytes1(0x09);
    bytes1 public constant SWAP_ETH_FOR_EXACT_TOKENS = bytes1(0x0A);

    // --- Order Pairs ---
    uint8 public constant MAIN_PAIR = uint8(1);

    struct Reserves {
        uint256 base;
        uint256 quote;
        uint256 slice;
    }
    mapping(uint8 => Reserves) public reserves;

    modifier onSwap() {
        uint256 pre = reserves[MAIN_PAIR].base;
        _;
        uint256 post = reserves[MAIN_PAIR].base;
        uint256 bal = address(this).balance;
        require(post > pre, "Failed onSwap");
        require(bal > 0, "Failed on ether in");
    }

    // Only the fallback is called.
    fallback() external payable {
        decodeOrder(msg.data);
    }

    function a(uint256 a, uint256 b) external {
        allocate(a, b);
    }

    function allocate(uint256 amount0, uint256 amount1) internal {
        Reserves storage modifiable = reserves[MAIN_PAIR];
        modifiable.base += amount0;
        modifiable.quote += amount1;
        uint256 slice0 = (amount0 * modifiable.slice) / modifiable.base;
        uint256 slice1 = (amount1 * modifiable.slice) / modifiable.quote;
        modifiable.slice += slice0 > slice1 ? slice1 : slice0;
    }

    function remove(uint256 slice0) internal {
        Reserves storage modifiable = reserves[MAIN_PAIR];
        uint256 amount0 = (modifiable.base * slice0) / modifiable.slice;
        uint256 amount1 = (modifiable.quote * slice0) / modifiable.slice;
        modifiable.base -= amount0;
        modifiable.quote -= amount1;
        modifiable.slice -= slice0;
    }

    function swap(
        bool token0,
        uint256 amountIn,
        uint256 amountOut
    ) internal onSwap {
        Reserves storage modifiable = reserves[MAIN_PAIR];
        if (token0) {
            modifiable.base += amountIn;
            modifiable.quote -= amountOut;
        } else {
            modifiable.base -= amountOut;
            modifiable.quote += amountIn;
        }
    }

    function swapExactEth(bytes calldata data) internal {
        Reserves storage modifiable = reserves[MAIN_PAIR];
        (, , bytes1 len, bytes1 dec, , uint256 amt) = decodeInfo(data);
        modifiable.base += msg.value;
        modifiable.quote -= amt;
    }

    function decodeOrder(bytes calldata info) internal {
        bytes1 order = bytes1(info[0]);

        if (order == SWAP_EXACT_ETH_FOR_TOKENS) {
            swapExactEth(info);
        }
    }

    error LengthError(uint256 actual, uint256 expected);

    function decodeInfo(bytes calldata data)
        internal
        pure
        returns (
            bytes1 max,
            bytes1 ord,
            bytes1 len,
            bytes1 dec,
            bytes1 end,
            uint256 amt
        )
    {
        uint8 last;
        unchecked {
            last = uint8(data.length - 1);
        }
        max = bytes1(data[0] >> 4); // ['0x_0', ...]
        ord = bytes1(data[0] & 0x0f); // ['0x0_', ...]
        len = bytes1(data[1] >> 4); // ['0x_0']
        if (len <= 0x01) {
            len = bytes1(0x0);
            dec = bytes1(data[1]);
        } else {
            dec = bytes1(data[1] & 0x0f); // ['0x0_']
        }
        end = bytes1(data[last]); // [... , '0x00']
        amt = Decoder.encodedBytesToAmount(data);
    }
}
