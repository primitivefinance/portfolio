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
        token0 = new TestERC20("TestERC20", "TEST", 18);
        token1 = new TestERC20("TestERC20", "TEST", 18);

        weth = new WETH();
        hyper = new HyperWrapper(address(weth));
    }

    function testWeth() public {
        assertEq(hyper.WETH(), address(weth));
    }

    function testCreatePool() public {
        bytes memory data = Encoder.encodeCreatePool(address(token0), address(token1), hex"0101");

        hyper.process(data);
    }
}
