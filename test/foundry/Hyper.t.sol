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

    function process(bytes calldata data) external payable {
        uint48 poolId_;
        bytes1 instruction = bytes1(data[0] & 0x0f);
        if (instruction == Instructions.UNKNOWN) revert UnknownInstruction();

        if (instruction == Instructions.ADD_LIQUIDITY) {
            (poolId_, ) = _allocate(data);
        } else if (instruction == Instructions.REMOVE_LIQUIDITY) {
            (poolId_, , ) = _unallocate(data);
        } else if (instruction == Instructions.SWAP) {
            (poolId_, , , ) = _swapExactIn(data);
        } else if (instruction == Instructions.STAKE_POSITION) {
            (poolId_, ) = _stakePosition(data);
        } else if (instruction == Instructions.UNSTAKE_POSITION) {
            (poolId_, ) = _unstakePosition(data);
        } else if (instruction == Instructions.CREATE_POOL) {
            (poolId_) = _createPool(data);
        } else if (instruction == Instructions.CREATE_CURVE) {
            _createCurve(data);
        } else if (instruction == Instructions.CREATE_PAIR) {
            _createPair(data);
        } else {
            revert UnknownInstruction();
        }
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
        __wrapEther(weth);
        __dangerousUnwrapEther(weth, msg.sender, 1e18);
    }

    // Assumes Hyper calls this, for testing only.
    function pass(bytes calldata data) external payable returns (bool) {
        try hyper.process{value: msg.value}(data) {} catch (bytes memory reason) {
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

function testMyMsgSender() view returns (address) {
    console.log(msg.sender);
    return msg.sender;
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
    uint48 __poolId;

    function setUp() public {
        weth = new WETH();
        __contractBeingTested = new HyperTester(address(weth));
        (asset, quote) = handlePrerequesites();
    }

    function testHyper() public {
        HyperPool memory p = IHyperStruct(address(__contractBeingTested)).pools(1);
    }

    function handlePrerequesites() public returns (TestERC20 token0, TestERC20 token1) {
        // Set the forwarder.
        forwarder = new Forwarder(address(__contractBeingTested));

        // 1. Two token contracts.
        token0 = new TestERC20("token0", "token0 name", 18);
        token1 = new TestERC20("token1", "token1 name", 18);

        // 2. Create pair
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint16 pairId = uint16(__contractBeingTested.getPairNonce());

        // 3. Create curve
        data = Instructions.encodeCreateCurve(
            DEFAULT_SIGMA,
            DEFAULT_MATURITY,
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            DEFAULT_STRIKE
        );
        success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint32 curveId = uint32(__contractBeingTested.getCurveNonce());

        __poolId = Instructions.encodePoolId(pairId, curveId);

        // 4. Create pool
        data = Instructions.encodeCreatePool(__poolId, DEFAULT_PRICE);
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

    function testFreeFunctionContext() public {
        console.log(address(this));
        console.log(msg.sender);
        testMyMsgSender();
    }

    // --- Ether --- //

    function testAllocateWETH() public {
        forwarder.freeWrapEther{value: 4e18}(address(weth));
        /*  // 2. Create pair
        bytes memory data = Instructions.encodeCreatePair(address(weth), address(quote));
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");
        uint16 pairId = uint16(__contractBeingTested.getPairNonce());
        uint32 curveId = uint32(__contractBeingTested.getCurveNonce());
        uint48 wethPoolId = Instructions.encodePoolId(pairId, curveId);

        // 4. Create pool
        data = Instructions.encodeCreatePool(wethPoolId, DEFAULT_PRICE);
        success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        data = Instructions.encodeAddLiquidity(
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
        bytes memory data = Instructions.encodeSwap(0, 0x0001030, 0x01, 0x01, 0x01, 0x01, 0);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testFailSwapExactInZeroSwapAmountReverts() public {
        bytes memory data = Instructions.encodeSwap(0, __poolId, 0x01, 0x00, 0x01, 0x01, 0);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testSwapExactInPoolPriceUpdated() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
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
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = getPool(__poolId).lastPrice;
        assertTrue(next != prev);
    }

    function testSwapExactInPoolSlotIndexUpdated() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
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
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        int256 next = getPool(__poolId).lastTick;
        assertTrue(next != prev);
    }

    function testSwapExactInPoolLiquidityUnchanged() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
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
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = getPool(__poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapExactInPoolTimestampUpdated() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
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
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = getPool(__poolId).blockTimestamp;
        assertTrue(next != prev);
    }

    function testSwapExactInGlobalAssetBalanceIncreases() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = __contractBeingTested.globalReserves(address(asset)); // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = __contractBeingTested.globalReserves(address(asset));
        assertTrue(next > prev);
    }

    function testSwapExactInGlobalQuoteBalanceDecreases() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = __contractBeingTested.globalReserves(address(quote)); // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = __contractBeingTested.globalReserves(address(quote));
        assertTrue(next < prev);
    }

    // --- Add liquidity --- //

    function testFailAllocateNonExistentPoolIdReverts() public {
        uint48 random = uint48(48);
        bytes memory data = Instructions.encodeAddLiquidity(0, random, 0x01, 0x01);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");
    }

    function testFailAllocateZeroLiquidityReverts() public {
        uint8 liquidity = 0;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, 0x00, liquidity);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");
    }

    function testAllocateFullAddLiquidity() public {
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
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);

        forwarder.pass(data);

        uint256 globalR1 = __contractBeingTested.globalReserves(address(quote));
        uint256 globalR2 = __contractBeingTested.globalReserves(address(asset));
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
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
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
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTotalLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        assertTrue(prevPositionTotalLiquidity == 0);
        assertTrue(nextPositionTotalLiquidity > prevPositionTotalLiquidity);
    }

    function testAllocateGlobalAssetIncreases() public {
        uint256 prevGlobal = __contractBeingTested.globalReserves(address(asset));
        int24 loTick = DEFAULT_TICK;
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = __contractBeingTested.globalReserves(address(asset));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    function testAllocateGlobalQuoteIncreases() public {
        uint256 prevGlobal = __contractBeingTested.globalReserves(address(quote));
        int24 loTick = DEFAULT_TICK - 256; // Enough below to have quote.
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = __contractBeingTested.globalReserves(address(quote));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    // --- Remove Liquidity --- //

    function testFailUnallocateZeroLiquidityReverts() public {
        bytes memory data = Instructions.encodeRemoveLiquidity(0, __poolId, 0x00, 0x00);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testFailUnallocateNonExistentPoolReverts() public {
        bytes memory data = Instructions.encodeRemoveLiquidity(0, 42, 0x01, 0x01);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testUnallocatePositionTimestampUpdated() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint48 positionId = uint48(bytes6(abi.encodePacked(__poolId)));
        uint256 prevPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        uint256 warpTimestamp = block.timestamp + 1;
        vm.warp(warpTimestamp);

        data = Instructions.encodeRemoveLiquidity(0, __poolId, power, amount);
        success = forwarder.pass(data);

        uint256 nextPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == warpTimestamp);
    }

    function testUnallocatePositionTotalLiquidityDecreases() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint48 positionId = uint48(bytes6(abi.encodePacked(__poolId)));
        uint256 prevPositionLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        data = Instructions.encodeRemoveLiquidity(0, __poolId, power, amount);
        success = forwarder.pass(data);

        uint256 nextPositionLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        assertTrue(nextPositionLiquidity < prevPositionLiquidity);
    }

    function testUnallocateGlobalAssetDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prev = __contractBeingTested.globalReserves(address(asset));

        data = Instructions.encodeRemoveLiquidity(0, __poolId, power, amount);
        success = forwarder.pass(data);

        uint256 next = __contractBeingTested.globalReserves(address(asset));
        assertTrue(next < prev, "globalReserves did not change");
    }

    function testUnallocateGlobalQuoteDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prev = __contractBeingTested.globalReserves(address(quote));

        data = Instructions.encodeRemoveLiquidity(0, __poolId, power, amount);
        success = forwarder.pass(data);

        uint256 next = __contractBeingTested.globalReserves(address(quote));
        assertTrue(next < prev, "globalReserves did not change");
    }

    // --- Stake Position --- //

    function testStakePositionStakedUpdated() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint48 positionId = Instructions.encodePositionId(__poolId);

        bool prevPositionStaked = getPosition(address(forwarder), positionId).stakeEpochId != 0;

        data = Instructions.encodeStakePosition(positionId);
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
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prevPoolStakedLiquidity = getPool(__poolId).stakedLiquidity;

        uint48 positionId = Instructions.encodePositionId(__poolId);
        data = Instructions.encodeStakePosition(positionId);
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
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint48 positionId = Instructions.encodePositionId(__poolId);
        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        vm.warp(__contractBeingTested.EPOCH_INTERVAL() + 1);

        // touch pool to update it so we know how much staked liquidity the position has
        data = Instructions.encodeSwap(0, __poolId, 0x09, 0x01, 0x10, 0x01, 0);
        success = forwarder.pass(data);

        uint256 prevPositionStaked = getPosition(address(forwarder), positionId).unstakeEpochId;

        data = Instructions.encodeUnstakePosition(positionId);
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
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint48 positionId = Instructions.encodePositionId(__poolId);
        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        vm.warp(__contractBeingTested.EPOCH_INTERVAL() + 1);

        // touch pool to update it so we know how much staked liquidity the position has
        data = Instructions.encodeSwap(0, __poolId, 0x09, 0x01, 0x10, 0x01, 0);
        success = forwarder.pass(data);

        uint256 prevPoolStakedLiquidity = getPool(__poolId).stakedLiquidity;

        data = Instructions.encodeUnstakePosition(positionId);
        success = forwarder.pass(data);

        vm.warp((__contractBeingTested.EPOCH_INTERVAL() + 1) * 2);

        // touch pool to update it so we know how much staked liquidity the position has
        data = Instructions.encodeSwap(0, __poolId, 0x01, 0x01, 0x10, 0x01, 0);
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
        bytes memory data = Instructions.encodeCreatePair(token, token);
        bool success = forwarder.pass(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testFailCreatePairPairExistsReverts() public {
        bytes memory data = Instructions.encodeCreatePair(address(asset), address(quote));
        bool success = forwarder.pass(data);
    }

    function testFailCreatePairLowerDecimalBoundsReverts() public {
        address token0 = address(new TestERC20("t", "t", 5));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
    }

    function testFailCreatePairUpperDecimalBoundsReverts() public {
        address token0 = address(new TestERC20("t", "t", 24));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
    }

    function testCreatePairPairNonceIncrementedReturnsOneAdded() public {
        uint256 prevNonce = __contractBeingTested.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint256 nonce = __contractBeingTested.getPairNonce();
        assertEq(nonce, prevNonce + 1);
    }

    function testCreatePairFetchesPairIdReturnsNonZero() public {
        uint256 prevNonce = __contractBeingTested.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint256 pairId = __contractBeingTested.getPairId(token0, token1);
        assertTrue(pairId != 0);
    }

    function testCreatePairFetchesPairDataReturnsAddresses() public {
        uint256 prevNonce = __contractBeingTested.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
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
        bytes memory data = Instructions.encodeCreateCurve(
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
        bytes memory data = Instructions.encodeCreateCurve(
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
        bytes memory data = Instructions.encodeCreateCurve(
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
        bytes memory data = Instructions.encodeCreateCurve(
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
        bytes memory data = Instructions.encodeCreateCurve(
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
        bytes memory data = Instructions.encodeCreateCurve(
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
        bytes memory data = Instructions.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = Decoder.toBytes32(
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
        bytes memory data = Instructions.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = Decoder.toBytes32(
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
        bytes memory data = Instructions.encodeCreatePool(1, 0);
        bool success = forwarder.pass(data);
    }

    function testFailCreatePoolExistentPoolReverts() public {
        bytes memory data = Instructions.encodeCreatePool(__poolId, 1);
        bool success = forwarder.pass(data);
    }

    function testFailCreatePoolZeroPairIdReverts() public {
        bytes memory data = Instructions.encodeCreatePool(0x000001, 1);
        bool success = forwarder.pass(data);
    }

    function testFailCreatePoolExpiringPoolExpiredReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint16 pairId = __contractBeingTested.getPairId(token0, token1);

        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        data = Instructions.encodeCreateCurve(
            curve.sigma + 1,
            uint32(0),
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = Decoder.toBytes32(
            abi.encodePacked(curve.sigma + 1, uint32(0), uint16(1e4 - curve.gamma), curve.strike)
        );
        success = forwarder.pass(data);

        uint32 curveId = __contractBeingTested.getCurveId(rawCurveId);
        uint48 id = Instructions.encodePoolId(pairId, curveId);
        data = Instructions.encodeCreatePool(id, 1_000);
        success = forwarder.pass(data);
    }

    function testCreatePoolFetchesPoolDataReturnsNonZeroBlockTimestamp() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint16 pairId = __contractBeingTested.getPairId(token0, token1);

        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        data = Instructions.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bytes32 rawCurveId = Decoder.toBytes32(
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
        uint48 id = Instructions.encodePoolId(pairId, curveId);
        data = Instructions.encodeCreatePool(id, 1_000);
        success = forwarder.pass(data);

        uint256 time = getPool(id).blockTimestamp;
        assertTrue(time != 0);
    }
}
