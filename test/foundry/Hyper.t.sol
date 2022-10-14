pragma solidity 0.8.13;

import {WETH} from "solmate/tokens/WETH.sol";

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../../contracts/test/TestERC20.sol";
import "../../contracts/Hyper.sol";
import "../../contracts/libraries/Encoder.sol";

contract HyperWrapper is Hyper {
    constructor(address WETH_) Hyper(WETH_) {}

    function process(bytes calldata data) external {
        _process(data);
    }
}

contract TestHyper is Test {
    TestERC20 public token0;
    TestERC20 public token1;

    WETH public weth;
    HyperWrapper public hyper;

    function setUp() public {
        TestERC20 tokenA = new TestERC20("TestERC20", "TEST", 18);
        TestERC20 tokenB = new TestERC20("TestERC20", "TEST", 6);

        (token0, token1) = address(tokenA) < address(tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);

        weth = new WETH();
        hyper = new HyperWrapper(address(weth));
    }

    function test_WETH() public {
        assertEq(hyper.WETH(), address(weth));
    }

    function test_createPool() public {
        bytes memory data = Encoder.encodeCreatePool(address(token0), address(token1), hex"0101");
        hyper.process(data);
    }

    function test_getPoolId() public {
        bytes memory data = Encoder.encodeCreatePool(address(token0), address(token1), hex"0101");
        hyper.process(data);
        assertEq(hyper.getPoolId(address(token0), address(token1)), 1);
    }
}
