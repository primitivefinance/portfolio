//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./libraries/Decoder.sol";

interface IERC20 {
    function balanceOf(address guy) external view returns (uint256);
}

interface PrototypeEvents {
    // --- Events --- //

    /// @param order Type of swap.
    /// @param pair Pool id that was swapped.
    /// @param input Tokens or eth paid in the swap.
    /// @param output Tokens or eth received from the swap.
    event Swap(uint256 order, uint256 pair, uint256 input, uint256 output);
}

contract PrototypeDataStructures {
    // --- Structs --- //

    struct Pair {
        address token0;
        uint16 decimals0;
        address token1;
        uint16 decimals1;
    }

    struct Reserves {
        uint256 base;
        uint256 quote;
        uint256 slice;
    }

    struct Packet {
        bytes1 max;
        bytes1 ord;
        bytes1 inf;
        bytes1 dec;
        bytes1 end;
        uint256 amt;
    }

    mapping(uint8 => Reserves) public reserves;
    mapping(uint8 => Pair) public getPair;
}

contract PrototypeHyper is PrototypeEvents, PrototypeDataStructures {
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

    // --- Order Pairs --- //
    uint8 public constant MAIN_PAIR = uint8(1);

    // --- Only the fallback is called. --- //
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
    ) internal {
        Reserves storage modifiable = reserves[MAIN_PAIR];
        if (token0) {
            modifiable.base += amountIn;
            modifiable.quote -= amountOut;
        } else {
            modifiable.base -= amountOut;
            modifiable.quote += amountIn;
        }
    }

    function getOutput(uint256 input) public view returns (uint256) {
        return input;
    }

    function addLiquidity(bytes calldata data) internal {
        (bytes1 m, bytes1 o, bytes1 i, bytes1 d, bytes1 e, uint256 a) = Decoder.decodeArgs(data);
        Packet memory pkt = Packet(m, o, i, d, e, a);
    }

    function addLiquidityETH(bytes calldata data) internal {}

    function removeLiquidity(bytes calldata data) internal {}

    function removeLiquidityETH(bytes calldata data) internal {}

    function swapExactETHForTokens(bytes calldata data) internal {
        (, bytes1 ord, , , bytes1 end, uint256 amt) = Decoder.decodeArgs(data);
        Reserves storage modifiable = reserves[uint8(end)];
        modifiable.base += msg.value;
        modifiable.quote -= amt;
        emit Swap(uint8(ord), uint8(end), msg.value, amt);
    }

    function swapETHForExactTokens(bytes calldata data) internal {
        (, bytes1 ord, , , bytes1 end, uint256 amt) = Decoder.decodeArgs(data);
        Reserves storage modifiable = reserves[uint8(end)];
        modifiable.base += msg.value;
        modifiable.quote -= amt;
        emit Swap(uint8(ord), uint8(end), msg.value, amt);
    }

    function swapExactTokensForETH(bytes calldata data) internal {
        (, bytes1 ord, , , bytes1 end, uint256 amt) = Decoder.decodeArgs(data);
        Reserves storage modifiable = reserves[uint8(end)];
        modifiable.base += msg.value;
        modifiable.quote -= amt;
        emit Swap(uint8(ord), uint8(end), msg.value, amt);
    }

    function swapTokensForExactETH(bytes calldata data) internal {
        (, bytes1 ord, , , bytes1 end, uint256 amt) = Decoder.decodeArgs(data);
        Reserves storage modifiable = reserves[uint8(end)];
        modifiable.base += msg.value;
        modifiable.quote -= amt;
        emit Swap(uint8(ord), uint8(end), msg.value, amt);
    }

    function swapExactTokensForTokens(bytes calldata data) internal {
        (bytes1 max, bytes1 ord, , , bytes1 end, uint256 amt) = Decoder.decodeArgs(data);
        Reserves storage modifiable = reserves[uint8(end)];
        uint256 input = uint8(max) > 0 ? IERC20(getPair[uint8(end)].token0).balanceOf(msg.sender) : amt;
        uint256 output = getOutput(input);
        modifiable.base += input;
        modifiable.quote -= output;
        emit Swap(uint8(ord), uint8(end), input, output);
    }

    function swapTokensForExactTokens(bytes calldata data) internal {
        (, bytes1 ord, , , bytes1 end, uint256 amt) = Decoder.decodeArgs(data);
        Reserves storage modifiable = reserves[uint8(end)];
        modifiable.base += msg.value;
        modifiable.quote -= amt;
        emit Swap(uint8(ord), uint8(end), msg.value, amt);
    }

    function decodeOrder(bytes calldata info) internal {
        bytes1 order = bytes1(info[0]);

        if (order == ADD_LIQUIDITY) {
            addLiquidity(info);
        } else if (order == ADD_LIQUIDITY_ETH) {
            addLiquidityETH(info);
        } else if (order == REMOVE_LIQUIDITY) {
            removeLiquidity(info);
        } else if (order == REMOVE_LIQUIDITY_ETH) {
            removeLiquidityETH(info);
        } else if (order == SWAP_EXACT_ETH_FOR_TOKENS) {
            swapExactETHForTokens(info);
        } else if (order == SWAP_ETH_FOR_EXACT_TOKENS) {
            swapETHForExactTokens(info);
        } else if (order == SWAP_EXACT_TOKENS_FOR_ETH) {
            swapExactTokensForETH(info);
        } else if (order == SWAP_TOKENS_FOR_EXACT_ETH) {
            swapTokensForExactETH(info);
        } else if (order == SWAP_EXACT_TOKENS_FOR_TOKENS) {
            swapExactTokensForTokens(info);
        } else if (order == SWAP_TOKENS_FOR_EXACT_TOKENS) {
            swapTokensForExactTokens(info);
        }
    }
}
