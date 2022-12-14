pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../../contracts/test/TestERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";

import "../../contracts/Hyper.sol";

contract HyperTester is Hyper {
    constructor(address weth) Hyper(weth) {}

    function doesPoolExist(uint48 poolId) external view returns (bool) {
        return _doesPoolExist(poolId);
    }

    // --- Implemented --- //

    function jumpProcess(bytes calldata data) external payable {
        CPU._jumpProcess(data, _process);
    }

    function process(bytes calldata data) external payable {
        super._process(data);
    }

    function _pay(address token, address to, uint amount) private {
        SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, to, amount);
    }
}

/** Bubbles up custom errors. */
contract Forwarder is Test {
    HyperTester public hyper;

    constructor(address prototype) {
        hyper = HyperTester(payable(prototype));
    }

    receive() external payable {}

    function freeWrapEther(address weth) external payable {
        __wrapEther__(weth);
        __dangerousUnwrapEther__(weth, msg.sender, 1e18);
    }

    function approve(address token, address spender) public {
        TestERC20(token).approve(spender, type(uint256).max);
    }

    // Assumes Hyper calls this, for testing only. Uses try catch to bubble up errors.
    function pass(bytes calldata data) external payable returns (bool) {
        try hyper.process{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }

    // Assumes Hyper calls this, for testing only. Uses try catch to bubble up errors.
    function jumpProcess(bytes calldata data) external payable returns (bool) {
        try hyper.jumpProcess{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }
}

contract StandardHelpers {
    uint128 public constant DEFAULT_STRIKE = 1e19;
    uint24 public constant DEFAULT_SIGMA = 1e4;
    uint32 public constant DEFAULT_MATURITY = 31556953; // adds 1
    uint16 public constant DEFAULT_FEE = 100;
    uint32 public constant DEFAULT_GAMMA = 9900;
    uint32 public constant DEFAULT_PRIORITY_GAMMA = 9950;
    uint128 public constant DEFAULT_R1_QUOTE = 3085375387260000000;
    uint128 public constant DEFAULT_R2_ASSET = 308537538726000000;
    uint128 public constant DEFAULT_LIQUIDITY = 1e18;
    uint128 public constant DEFAULT_PRICE = 10e18;
    int24 public constant DEFAULT_TICK = int24(23027); // 10e18, rounded up! pay attention
}

interface IHyperStruct {
    function curves(uint32 curveId) external view returns (Curve memory);

    function pairs(uint16 pairId) external view returns (Pair memory);

    function positions(address owner, uint48 positionId) external view returns (HyperPosition memory);

    function pools(uint48 poolId) external view returns (HyperPool memory);

    function globalReserves(address token) external view returns (uint256);
}

contract TestHyperSingle is StandardHelpers, Test {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    receive() external payable {}

    HyperTester public __contractBeingTested;
    WETH public weth;
    Forwarder public forwarder;
    TestERC20 public asset;
    TestERC20 public quote;
    TestERC20 public fakeToken0;
    uint48 __poolId;

    function setUp() public {
        weth = new WETH();
        __contractBeingTested = new HyperTester(address(weth));
        (asset, quote, fakeToken0) = handlePrerequesites();
    }

    function testHyper() public {
        HyperPool memory p = IHyperStruct(address(__contractBeingTested)).pools(1);
    }

    function handlePrerequesites() public returns (TestERC20 token0, TestERC20 token1, TestERC20 fakeToken0) {
        // Set the forwarder.
        forwarder = new Forwarder(address(__contractBeingTested));

        // 1. Two token contracts, minted and approved to spend.
        fakeToken0 = new TestERC20("fakeToken0", "fakeToken0 name", 18);
        token0 = new TestERC20("token0", "token0 name", 18);
        token1 = new TestERC20("token1", "token1 name", 18);
        token0.approve(address(__contractBeingTested), type(uint256).max);
        token1.approve(address(__contractBeingTested), type(uint256).max);
        token0.mint(address(forwarder), 440e18);
        token1.mint(address(forwarder), 440e18);
        forwarder.approve(address(token0), address(__contractBeingTested));
        forwarder.approve(address(token1), address(__contractBeingTested));

        // 2. Create pair
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint16 pairId = uint16(__contractBeingTested.getPairNonce());

        // 3. Create curve
        data = CPU.encodeCreateCurve(
            DEFAULT_SIGMA,
            DEFAULT_MATURITY,
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            DEFAULT_STRIKE
        );
        success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint32 curveId = uint32(__contractBeingTested.getCurveNonce());

        __poolId = CPU.encodePoolId(pairId, curveId);

        // 4. Create pool
        data = CPU.encodeCreatePool(__poolId, DEFAULT_PRICE);
        success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        assertEq(__contractBeingTested.doesPoolExist(__poolId), true);
        assertEq(IHyperStruct(address(__contractBeingTested)).pools(__poolId).lastTick != 0, true);
        assertEq(IHyperStruct(address(__contractBeingTested)).pools(__poolId).liquidity == 0, true);
    }

    // --- Helpers --- //

    function getPool(uint48 poolId) public view returns (HyperPool memory) {
        return IHyperStruct(address(__contractBeingTested)).pools(poolId);
    }

    function getCurve(uint32 curveId) public view returns (Curve memory) {
        return IHyperStruct(address(__contractBeingTested)).curves(curveId);
    }

    function getPair(uint16 pairId) public view returns (Pair memory) {
        return IHyperStruct(address(__contractBeingTested)).pairs(pairId);
    }

    function getPosition(address owner, uint48 positionId) public view returns (HyperPosition memory) {
        return IHyperStruct(address(__contractBeingTested)).positions(owner, positionId);
    }

    function getReserves(address token) public view returns (uint) {
        return __contractBeingTested.__reserves__(token);
    }

    function getBalances(address owner, address token) public view returns (uint) {
        return __contractBeingTested.__balances__(owner, token);
    }

    // --- Jump --- //
    bytes[] public instructions;

    function testJumpProcess() public {
        instructions.push(CPU.encodeCreatePair(address(fakeToken0), address(quote)));
        console.log(instructions.length);
        bytes memory data = CPU.encodeJumpInstruction(instructions);
        console.log(data.length);
        console.logBytes(instructions[0]);
        console.logBytes(data);
        bool success = forwarder.jumpProcess(data);
        assertTrue(success);

        delete instructions;
    }

    // --- Ether --- //

    function testAllocateWETH() public {
        forwarder.freeWrapEther{value: 4e18}(address(weth));
        /*  // 2. Create pair
        bytes memory data = CPU.encodeCreatePair(address(weth), address(quote));
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");
        uint16 pairId = uint16(__contractBeingTested.getPairNonce());
        uint32 curveId = uint32(__contractBeingTested.getCurveNonce());
        uint48 wethPoolId = CPU.encodePoolId(pairId, curveId);

        // 4. Create pool
        data = CPU.encodeCreatePool(wethPoolId, DEFAULT_PRICE);
        success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        data = CPU.encodeAllocate(
            0,
            wethPoolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        success = forwarder.pass{value: 10e18}(data);
        assertTrue(success); */
    }

    // --- Swap --- //

    function testFailSwapExactInNonExistentPoolIdReverts() public {
        bytes memory data = CPU.encodeSwap(0, 0x0001030, 0x01, 0x01, 0x01, 0x01, 0);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testFailSwapExactInZeroSwapAmountReverts() public {
        bytes memory data = CPU.encodeSwap(0, __poolId, 0x01, 0x00, 0x01, 0x01, 0);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testSwapExactInPoolPriceUpdated() public {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = getPool(__poolId).lastPrice; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = getPool(__poolId).lastPrice;
        assertTrue(next != prev);
    }

    /* function testSwapExactInPoolSlotIndexUpdated() public {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        int256 prev = getPool(__poolId).lastTick; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        int256 next = getPool(__poolId).lastTick;
        assertTrue(next != prev);
    } */

    function testSwapExactInPoolLiquidityUnchanged() public {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);
        uint256 prev = getPool(__poolId).liquidity; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = getPool(__poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapExactInPoolTimestampUpdated() public {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity, note: 0x0a amount breaks test? todo: handle case where insufficient liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = getPool(__poolId).blockTimestamp; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = getPool(__poolId).blockTimestamp;
        assertTrue(next != prev);
    }

    function testSwapExactInGlobalAssetBalanceIncreases() public {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = getReserves(address(asset)); // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = getReserves(address(asset));
        assertTrue(next > prev);
    }

    function testSwapExactInGlobalQuoteBalanceDecreases() public {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = getReserves(address(quote)); // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = getReserves(address(quote));
        assertTrue(next < prev);
    }

    // --- Add liquidity --- //

    function testFailAllocateNonExistentPoolIdReverts() public {
        uint48 random = uint48(48);
        bytes memory data = CPU.encodeAllocate(0, random, 0x01, 0x01);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");
    }

    function testFailAllocateZeroLiquidityReverts() public {
        uint8 liquidity = 0;
        bytes memory data = CPU.encodeAllocate(0, __poolId, 0x00, liquidity);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");
    }

    function testAllocateFullAllocate() public {
        uint256 price = getPool(__poolId).lastPrice;
        Curve memory curve = getCurve(uint32(__poolId));
        uint256 theoreticalR2 = HyperSwapLib.computeR2WithPrice(
            price,
            curve.strike,
            curve.sigma,
            curve.maturity - block.timestamp
        );
        int24 min = int24(-887272);
        int24 max = -min;
        uint8 power = uint8(0x06); // 6 zeroes
        uint8 amount = uint8(0x04); // 4 with 6 zeroes = 4_000_000 wei
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);

        forwarder.pass(data);

        uint256 globalR1 = getReserves(address(quote));
        uint256 globalR2 = getReserves(address(asset));
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        assertTrue((theoreticalR2 - FixedPointMathLib.divWadUp(globalR2, 4_000_000)) <= 1e14);
    }

    function testAllocatePositionTimestampUpdated() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = hiTick - 2;
        uint48 positionId = uint48(bytes6(abi.encodePacked(__poolId)));

        uint256 prevPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        assertTrue(prevPositionTimestamp == 0);
        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == block.timestamp);
    }

    function testAllocatePositionTotalLiquidityIncreases() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = hiTick - 2;
        uint48 positionId = uint48(bytes6(abi.encodePacked(__poolId)));

        uint256 prevPositionTotalLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTotalLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        assertTrue(prevPositionTotalLiquidity == 0);
        assertTrue(nextPositionTotalLiquidity > prevPositionTotalLiquidity);
    }

    function testAllocateGlobalAssetIncreases() public {
        uint256 prevGlobal = getReserves(address(asset));
        int24 loTick = DEFAULT_TICK;
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = getReserves(address(asset));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    function testAllocateGlobalQuoteIncreases() public {
        uint256 prevGlobal = getReserves(address(quote));
        int24 loTick = DEFAULT_TICK - 256; // Enough below to have quote.
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = getReserves(address(quote));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    // --- Remove Liquidity --- //

    function testFailUnallocateZeroLiquidityReverts() public {
        bytes memory data = CPU.encodeUnallocate(0, __poolId, 0x00, 0x00);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testFailUnallocateNonExistentPoolReverts() public {
        bytes memory data = CPU.encodeUnallocate(0, 42, 0x01, 0x01);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testUnallocatePositionTimestampUpdated() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint48 positionId = uint48(bytes6(abi.encodePacked(__poolId)));
        uint256 prevPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        uint256 warpTimestamp = block.timestamp + 1;
        vm.warp(warpTimestamp);

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = forwarder.pass(data);

        uint256 nextPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == warpTimestamp);
    }

    function testUnallocatePositionTotalLiquidityDecreases() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint48 positionId = uint48(bytes6(abi.encodePacked(__poolId)));
        uint256 prevPositionLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = forwarder.pass(data);

        uint256 nextPositionLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        assertTrue(nextPositionLiquidity < prevPositionLiquidity);
    }

    function testUnallocateGlobalAssetDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prev = getReserves(address(asset));

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = forwarder.pass(data);

        uint256 next = getReserves(address(asset));
        assertTrue(next < prev, "globalReserves did not change");
    }

    function testUnallocateGlobalQuoteDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prev = getReserves(address(quote));

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = forwarder.pass(data);

        uint256 next = getReserves(address(quote));
        assertTrue(next < prev, "globalReserves did not change");
    }

    // --- Stake Position --- //

    function testStakePositionStakedUpdated() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint48 positionId = __poolId;

        bool prevPositionStaked = getPosition(address(forwarder), positionId).stakeEpochId != 0;

        data = CPU.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        bool nextPositionStaked = getPosition(address(forwarder), positionId).stakeEpochId != 0;

        assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        assertTrue(nextPositionStaked, "Position staked is not true.");
    }

    function testStakePoolStakedLiquidityUpdated() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prevPoolStakedLiquidity = getPool(__poolId).stakedLiquidity;

        uint48 positionId = __poolId;
        data = CPU.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        uint256 nextPoolStakedLiquidity = getPool(__poolId).stakedLiquidity;

        if (lo <= getPool(__poolId).lastTick && hi > getPool(__poolId).lastTick) {
            assertTrue(nextPoolStakedLiquidity > prevPoolStakedLiquidity, "Pool staked liquidity did not increase.");
            assertTrue(
                nextPoolStakedLiquidity == getPosition(address(forwarder), positionId).totalLiquidity,
                "Pool staked liquidity not equal to liquidity of staked position."
            );
        } else {
            assertTrue(
                nextPoolStakedLiquidity == prevPoolStakedLiquidity,
                "Pool staked liquidity changed even though position staked out of range."
            );
        }
    }

    // --- Unstake Position --- //

    function testUnstakePositionStakedUpdated() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK + 256; // fails if not above current tick
        uint8 amount = 0x01;
        uint8 power = 0x0f;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint48 positionId = __poolId;
        data = CPU.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        vm.warp(__contractBeingTested.EPOCH_INTERVAL() + 1);

        // touch pool to update it so we know how much staked liquidity the position has
        data = CPU.encodeSwap(0, __poolId, 0x09, 0x01, 0x10, 0x01, 0);
        success = forwarder.pass(data);

        uint256 prevPositionStaked = getPosition(address(forwarder), positionId).unstakeEpochId;

        data = CPU.encodeUnstakePosition(positionId);
        success = forwarder.pass(data);

        uint256 nextPositionStaked = getPosition(address(forwarder), positionId).unstakeEpochId;

        assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        assertTrue(nextPositionStaked != 0, "Position staked is true.");
    }

    function testUnstakePoolStakedLiquidityUpdated() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK + 256; // note: Fails if pool.lastTick <= hi
        uint8 amount = 0x01;
        uint8 power = 0x0f;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint48 positionId = __poolId;
        data = CPU.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        vm.warp(__contractBeingTested.EPOCH_INTERVAL() + 1);

        // touch pool to update it so we know how much staked liquidity the position has
        data = CPU.encodeSwap(0, __poolId, 0x09, 0x01, 0x10, 0x01, 0);
        success = forwarder.pass(data);

        uint256 prevPoolStakedLiquidity = getPool(__poolId).stakedLiquidity;

        data = CPU.encodeUnstakePosition(positionId);
        success = forwarder.pass(data);

        vm.warp((__contractBeingTested.EPOCH_INTERVAL() + 1) * 2);

        // touch pool to update it so we know how much staked liquidity the position has
        data = CPU.encodeSwap(0, __poolId, 0x01, 0x01, 0x10, 0x01, 0);
        success = forwarder.pass(data);

        // todo: currently fails because unstaking does not change staked liquidity.
        uint256 nextPoolStakedLiquidity = getPool(__poolId).stakedLiquidity;

        if (lo <= getPool(__poolId).lastTick && hi > getPool(__poolId).lastTick) {
            assertTrue(nextPoolStakedLiquidity < prevPoolStakedLiquidity, "Pool staked liquidity did not increase.");
            assertTrue(nextPoolStakedLiquidity == 0, "Pool staked liquidity does not equal 0 after unstake.");
        } else {
            assertTrue(
                nextPoolStakedLiquidity == prevPoolStakedLiquidity,
                "Pool staked liquidity changed even though position staked out of range."
            );
        }
    }

    // --- Create Pair --- //

    function testFailCreatePairSameTokensReverts() public {
        address token = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(token, token);
        bool success = forwarder.pass(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testFailCreatePairPairExistsReverts() public {
        bytes memory data = CPU.encodeCreatePair(address(asset), address(quote));
        bool success = forwarder.pass(data);
    }

    function testFailCreatePairLowerDecimalBoundsReverts() public {
        address token0 = address(new TestERC20("t", "t", 5));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
    }

    function testFailCreatePairUpperDecimalBoundsReverts() public {
        address token0 = address(new TestERC20("t", "t", 24));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
    }

    function testCreatePairPairNonceIncrementedReturnsOneAdded() public {
        uint256 prevNonce = __contractBeingTested.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint256 nonce = __contractBeingTested.getPairNonce();
        assertEq(nonce, prevNonce + 1);
    }

    function testCreatePairFetchesPairIdReturnsNonZero() public {
        uint256 prevNonce = __contractBeingTested.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint256 pairId = __contractBeingTested.getPairId(token0, token1);
        assertTrue(pairId != 0);
    }

    function testCreatePairFetchesPairDataReturnsAddresses() public {
        uint256 prevNonce = __contractBeingTested.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint16 pairId = __contractBeingTested.getPairId(token0, token1);
        Pair memory pair = getPair(pairId);
        assertEq(pair.tokenBase, token0);
        assertEq(pair.tokenQuote, token1);
        assertEq(pair.decimalsBase, 18);
        assertEq(pair.decimalsQuote, 18);
    }

    // --- Create Curve --- //

    function testFailCreateCurveCurveExistsReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bool success = forwarder.pass(data);
    }

    function testFailCreateCurveFeeParameterOutsideBoundsReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            5e4,
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bool success = forwarder.pass(data);
    }

    function testFailCreateCurvePriorityFeeParameterOutsideBoundsReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            5e4,
            curve.strike
        );
        bool success = forwarder.pass(data);
    }

    function testFailCreateCurveExpiringPoolZeroSigmaReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            0,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bool success = forwarder.pass(data);
    }

    function testFailCreateCurveExpiringPoolZeroStrikeReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            0
        );
        bool success = forwarder.pass(data);
    }

    function testCreateCurveCurveNonceIncrementReturnsOne() public {
        uint256 prevNonce = __contractBeingTested.getCurveNonce();
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bool success = forwarder.pass(data);
        uint256 nextNonce = __contractBeingTested.getCurveNonce();
        assertEq(prevNonce, nextNonce - 1);
    }

    function testCreateCurveFetchesCurveIdReturnsNonZero() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = CPU.toBytes32(
            abi.encodePacked(
                curve.sigma + 1,
                curve.maturity,
                uint16(1e4 - curve.gamma),
                uint16(1e4 - curve.priorityGamma),
                curve.strike
            )
        );
        bool success = forwarder.pass(data);
        uint32 curveId = __contractBeingTested.getCurveId(rawCurveId);
        assertTrue(curveId != 0);
    }

    function testCreateCurveFetchesCurveDataReturnsParametersSet() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = CPU.toBytes32(
            abi.encodePacked(
                curve.sigma + 1,
                curve.maturity,
                uint16(1e4 - curve.gamma),
                uint16(1e4 - curve.priorityGamma),
                curve.strike
            )
        );
        bool success = forwarder.pass(data);
        uint32 curveId = __contractBeingTested.getCurveId(rawCurveId);
        Curve memory newCurve = getCurve(curveId);
        assertEq(newCurve.sigma, curve.sigma + 1);
        assertEq(newCurve.maturity, curve.maturity);
        assertEq(newCurve.gamma, curve.gamma);
        assertEq(newCurve.priorityGamma, curve.priorityGamma);
        assertEq(newCurve.strike, curve.strike);
    }

    // --- Create Pool --- //

    function testFailCreatePoolZeroPriceParameterReverts() public {
        bytes memory data = CPU.encodeCreatePool(1, 0);
        bool success = forwarder.pass(data);
    }

    function testFailCreatePoolExistentPoolReverts() public {
        bytes memory data = CPU.encodeCreatePool(__poolId, 1);
        bool success = forwarder.pass(data);
    }

    function testFailCreatePoolZeroPairIdReverts() public {
        bytes memory data = CPU.encodeCreatePool(0x000001, 1);
        bool success = forwarder.pass(data);
    }

    function testFailCreatePoolExpiringPoolExpiredReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint16 pairId = __contractBeingTested.getPairId(token0, token1);

        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            uint32(0),
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = CPU.toBytes32(
            abi.encodePacked(curve.sigma + 1, uint32(0), uint16(1e4 - curve.gamma), curve.strike)
        );
        success = forwarder.pass(data);

        uint32 curveId = __contractBeingTested.getCurveId(rawCurveId);
        uint48 id = CPU.encodePoolId(pairId, curveId);
        data = CPU.encodeCreatePool(id, 1_000);
        success = forwarder.pass(data);
    }

    function testCreatePoolFetchesPoolDataReturnsNonZeroBlockTimestamp() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint16 pairId = __contractBeingTested.getPairId(token0, token1);

        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = CPU.toBytes32(
            abi.encodePacked(
                curve.sigma + 1,
                curve.maturity,
                uint16(1e4 - curve.gamma),
                uint16(1e4 - curve.priorityGamma),
                curve.strike
            )
        );
        success = forwarder.pass(data);

        uint32 curveId = __contractBeingTested.getCurveId(rawCurveId);
        uint48 id = CPU.encodePoolId(pairId, curveId);
        data = CPU.encodeCreatePool(id, 1_000);
        success = forwarder.pass(data);

        uint256 time = getPool(id).blockTimestamp;
        assertTrue(time != 0);
    }
}
