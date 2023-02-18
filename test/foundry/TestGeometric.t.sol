pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import "contracts/GeometricPortfolio.sol";
import "contracts/test/TestERC20.sol";

contract TestGeometric is Test {
    WETH weth;
    GeometricPortfolio instance;
    TestERC20 token0;
    TestERC20 token1;
    uint64 poolId;

    function setUp() public {
        weth = new WETH();
        instance = new GeometricPortfolio(address(weth));
        create_allocate();
    }

    function create_allocate() internal {
        token0 = new TestERC20("0", "0", 18);
        token1 = new TestERC20("1", "1", 18);

        instance.createPair(address(token0), address(token1));
        instance.createPool(
            uint24(1),
            address(0),
            uint16(0),
            uint16(100),
            uint16(100),
            uint16(100),
            uint16(4),
            1 ether,
            1 ether
        );

        deal(address(token0), address(this), 100 ether);
        deal(address(token1), address(this), 100 ether);
        token0.approve(address(instance), type(uint).max);
        token1.approve(address(instance), type(uint).max);

        poolId = Enigma.encodePoolId(uint24(1), false, uint32(1));
        instance.allocate(poolId, 10 ether);
    }

    function test_portfolio() public {
        assertEq(instance.VERSION(), "beta-v0.1.0");
    }

    function test_invariant_of() public {
        HyperPool memory pool;
        pool.virtualX = 1 ether;
        pool.virtualY = 1 ether;

        uint weight = 0.5 ether;
        int invariant = GeometricMath.invariantOf(pool, pool.virtualX, pool.virtualY, weight);
        console.logInt(invariant);
    }

    function test_get_amount_out() public {
        HyperPool memory pool;
        pool.virtualX = 1 ether;
        pool.virtualY = 1 ether;

        uint weight = 0.5 ether;
        uint a0 = GeometricMath.getAmountOut(pool, weight, true, 0.1 ether, 0);
        console.log("out", a0);
    }

    function test_swap() public {
        HyperPool memory pool;
        pool.virtualX = 1 ether;
        pool.virtualY = 1 ether;
        uint weight = 0.5 ether;
        uint amountIn = 0.1 ether;
        uint out = GeometricMath.getAmountOut(pool, weight, true, amountIn, 0);
        console.log("got output", out);
        bytes memory data = Enigma.encodeSwap(uint8(0), poolId, 0, uint128(amountIn), 0, uint128(out), uint8(0));
        uint prevBal = instance.getBalance(address(this), address(token1));
        (bool success, ) = address(instance).call(data);
        uint postBal = instance.getBalance(address(this), address(token1));
        require(success, "failed call");
        console.log(postBal, prevBal, postBal - prevBal);
        assertTrue(postBal > prevBal, "no output");
    }
}
