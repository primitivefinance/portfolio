// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/Hyper.sol";
import "../helpers/HelperHyperActions.sol";

interface Quoter {
    function quoteExactInputSingle(address, address, uint24, uint256, uint160) external returns (uint256);
}

interface Factory {
    function getPool(address, address, uint24) external view returns (address);
}

struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // the most-recently updated index of the observations array
    uint16 observationIndex;
    // the current maximum number of observations that are being stored
    uint16 observationCardinality;
    // the next maximum number of observations to store, triggered in observations.write
    uint16 observationCardinalityNext;
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint8 feeProtocol;
    // whether the pool is locked
    bool unlocked;
}

interface Uni {
    function slot0() external view returns (Slot0 memory);
}

interface ERC20 {
    function approve(address, uint) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);
}

contract Addresses {
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    Quoter quoter = Quoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    Factory factory = Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
}

// must --fork-url
contract TestAnalysisSwap is Test, Addresses, HelperHyperActions {
    Hyper hyper;
    Uni pool;
    uint24 fee = 3000;
    uint64 poolId = 0x0000010100000001;
    uint128 maxPrice;
    uint stk;
    uint price;

    function setUp() public {
        hyper = new Hyper(WETH);
        pool = Uni(factory.getPool(WETH, USDC, fee));
        console.log("Got pool: ", address(pool));
        price = pool.slot0().sqrtPriceX96;
        price = 1e36 / (((price * price * 10 ** ERC20(USDC).decimals())) >> (96 * 2));
        stk = (price * 5) / 4;
        console.log("stk", stk);
        console.log("Got price of WETH-USDC 30bps", price);
        console.log("Got strike", stk);

        vm.deal(address(this), 1_000 ether);
        (bool success, bytes memory revertData) = address(hyper).call{value: 1_000 ether}(
            createPool(WETH, USDC, address(this), 1, 30, 5_500, 365, 1, uint128(stk), uint128(price))
        );
        assertTrue(success, "create pool failed");

        deal(USDC, address(this), 1_000 ether);
        ERC20(USDC).approve(address(hyper), type(uint256).max);
        hyper.allocate(poolId, 1_000 ether);
    }

    function __testFuzzSwapOutput(uint16 vol, uint16 dur, uint128 strike) public {
        vol = uint16(bound(vol, 500, 2_000));
        dur = uint16(bound(dur, 10, 100));
        strike = uint128(bound(strike, stk, price * 2)); // between strike and twice the price

        hyper.changeParameters(poolId, 0, 0, 0);

        uint target = 1261714834;
        uint actual = hyper.getAmountOut(poolId, true, 1 ether);
        assertTrue(actual < target, "Found a value!");
        console.log("Actual", actual);
    }
}
