//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

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

    function swapExactEth(bytes memory data) internal {
        Reserves storage modifiable = reserves[MAIN_PAIR];
        (, , bytes1 len, bytes1 dec, , bytes32 amt) = decodeAmountInfo(data);
        modifiable.base += msg.value;
        modifiable.quote -= uint256(amt);
    }

    function decodeOrder(bytes calldata info) internal {
        bytes1 order = bytes1(info[0]);

        if (order == SWAP_EXACT_ETH_FOR_TOKENS) {
            swapExactEth(info);
        }
    }

    error LengthError(uint256 actual, uint256 expected);

    function decodeAmountInfo(bytes memory data)
        internal
        view
        returns (
            bytes1 max,
            bytes1 ord,
            bytes1 len,
            bytes1 dec,
            bytes1 end,
            bytes32 amt
        )
    {
        uint8 last;
        unchecked {
            last = uint8(data.length - 1);
        }
        console.logBytes1(bytes1(data[2]));
        console.logBytes1(bytes1(data[3]));
        console.logBytes1(bytes1(data[4]));
        console.logBytes1(bytes1(data[5]));

        console.log("brek");

        max = bytes1(data[0] >> 4); // ['0x_0', ...]
        ord = bytes1(data[0] & 0x0f); // ['0x0_', ...]
        len = bytes1(data[1] & 0xf0); // ['0x_0']
        dec = bytes1(data[1] & 0x0f); // ['0x0_']
        end = bytes1(data[last]); // [... , '0x00']

        console.logBytes1(max);
        console.logBytes1(ord);
        console.logBytes1(len);
        console.logBytes1(dec);
        console.logBytes1(end);

        console.log("brek");
        console.log(uint8(len));

        /*         if (uint8(len) > data.length - 2)
            revert LengthError(uint256(data.length), uint8(len)); */
        bytes memory amount = new bytes(uint8(5));
        for (uint256 i; i != uint8(4); ) {
            uint256 index = 2 + i;
            bytes1 value = data[2 + i];
            console.logBytes1(value);
            if (index > last) revert LengthError(last, index);
            amount[i] = data[2 + i];
            unchecked {
                ++i;
            }
        }

        console.logBytes(amount);

        uint128 length = uint128(2);
        if (amount.length >= length + 6) revert LengthError(1, 1);
        assembly {
            amt := mload(add(add(amount, 0x06), 0x0))
        }
        console.log(uint256(amt));
    }
}
