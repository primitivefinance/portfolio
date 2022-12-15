pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../../contracts/test/TestERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";

import "../../contracts/Hyper.sol";

/** @dev Exposes process and jump process as external functions to test directly instead of through fallback. */
contract HyperTester is Hyper {
    constructor(address weth) Hyper(weth) {}

    uint public TEST_JIT_POLICY;

    function setJitPolicy(uint policy) public {
        TEST_JIT_POLICY = policy;
    }

    function _liquidityPolicy() internal view override returns (uint) {
        return TEST_JIT_POLICY;
    }

    function assertSettlementInvariant(address token, address[] memory accounts) public {
        uint reserve = getReserves(token);
        uint physical = TestERC20(token).balanceOf(address(this));
        if (reserve != physical) {
            uint sum;
            // @dev important! could be wrong if we miss an account with an internal balance
            for (uint i; i != accounts.length; ++i) {
                uint balance = getBalances(accounts[i], token);
                sum += balance;
            }
            if ((reserve + sum) != physical) revert SettlementInvariantInvalid(physical, reserve + sum);
        }
    }

    error SettlementInvariantInvalid(uint, uint);

    function check(uint48 poolId, address[] memory accounts) external {
        Pair memory pair = pairs[uint16(poolId >> 32)];
        assertSettlementInvariant(pair.tokenAsset, accounts);
        assertSettlementInvariant(pair.tokenQuote, accounts);
    }

    function doesPoolExist(uint48 poolId) external view returns (bool) {
        return exists(pools, poolId);
    }

    /** @dev This is an implemented function to test process, so it has to have settle and re-entrancy guard. */
    function jumpProcess(bytes calldata data) external payable lock settle {
        CPU._jumpProcess(data, super._process);
    }

    /** @dev This is an implemented function to test process, so it has to have settle and re-entrancy guard. */
    function process(bytes calldata data) external payable lock settle {
        super._process(data);
    }

    function getAmounts(uint48 poolId) public returns (uint deltaAsset, uint deltaQuote) {
        return _getAmounts(poolId);
    }
}

/** @dev Forwards calls to Hyper. Bubbles up custom errors. */
contract Forwarder is Test {
    HyperTester public hyper;

    constructor(address prototype) {
        hyper = HyperTester(payable(prototype));
    }

    receive() external payable {}

    function approve(address token, address spender) external {
        TestERC20(token).approve(spender, type(uint256).max);
    }

    /** @dev Assumes Hyper calls this, for testing only. Uses try catch to bubble up errors. */
    function process(bytes calldata data) external payable returns (bool) {
        try hyper.process{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }

    /** @dev Assumes Hyper calls this, for testing only. Uses try catch to bubble up errors. */
    function jumpProcess(bytes calldata data) external payable returns (bool) {
        try hyper.jumpProcess{value: msg.value}(data) {} catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        return true;
    }
}

uint128 constant DEFAULT_STRIKE = 10e18;
uint24 constant DEFAULT_SIGMA = 1e4;
uint32 constant DEFAULT_MATURITY = 31556953; // adds 1
uint16 constant DEFAULT_FEE = 100;
uint32 constant DEFAULT_GAMMA = 9900;
uint32 constant DEFAULT_PRIORITY_GAMMA = 9950;
uint128 constant DEFAULT_QUOTE_RESERVE = 3085375116376210650;
uint128 constant DEFAULT_ASSET_RESERVE = 308537516918601823;
uint128 constant DEFAULT_LIQUIDITY = 1e18;
uint128 constant DEFAULT_PRICE = 10e18;
int24 constant DEFAULT_TICK = int24(23027); // 10e18, rounded up! pay attention

interface IHyperStruct {
    function curves(uint32 curveId) external view returns (Curve memory);

    function pairs(uint16 pairId) external view returns (Pair memory);

    function positions(address owner, uint48 positionId) external view returns (HyperPosition memory);

    function pools(uint48 poolId) external view returns (HyperPool memory);

    function globalReserves(address token) external view returns (uint256);
}

function createPool(
    address token0,
    address token1,
    uint24 sigma,
    uint32 maturity,
    uint16 fee,
    uint16 priorityFee,
    uint128 strike,
    uint128 price
) returns (bytes memory data) {
    bytes[] memory instructions = new bytes[](3);
    uint48 magicPoolId = 0x000000000000;
    instructions[0] = (CPU.encodeCreatePair(token0, token1));
    instructions[1] = (CPU.encodeCreateCurve(sigma, maturity, fee, priorityFee, strike));
    instructions[2] = (CPU.encodeCreatePool(magicPoolId, price));
    data = CPU.encodeJumpInstruction(instructions);
}

contract TestHyperSingle is Test {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    receive() external payable {}

    uint48 __poolId;
    WETH public __weth__;
    HyperTester public __contractBeingTested__;
    Forwarder public forwarder;
    TestERC20 public asset;
    TestERC20 public quote;
    TestERC20 public fakeToken0;

    address[] public __addressesUsedInTesting__;

    function setUp() public {
        __weth__ = new WETH();
        __contractBeingTested__ = new HyperTester(address(__weth__));
        (asset, quote, fakeToken0) = handlePrerequesites();
        __addressesUsedInTesting__.push(address(this));
        __addressesUsedInTesting__.push(address(__contractBeingTested__));
    }

    modifier checkSettlementInvariant() {
        _;
        __contractBeingTested__.check(__poolId, __addressesUsedInTesting__);
    }

    function handlePrerequesites() public returns (TestERC20 token0, TestERC20 token1, TestERC20 fakeToken0) {
        // Set the forwarder.
        forwarder = new Forwarder(address(__contractBeingTested__));
        __addressesUsedInTesting__.push(address(forwarder));

        // 1. Two token contracts, minted and approved to spend.
        fakeToken0 = new TestERC20("fakeToken0", "fakeToken0 name", 18);
        token0 = new TestERC20("token0", "token0 name", 18);
        token1 = new TestERC20("token1", "token1 name", 18);
        token0.mint(address(this), 440e18);
        token1.mint(address(this), 440e18);
        token0.mint(address(forwarder), 440e18);
        token1.mint(address(forwarder), 440e18);
        token0.approve(address(__contractBeingTested__), type(uint256).max);
        token1.approve(address(__contractBeingTested__), type(uint256).max);
        forwarder.approve(address(token0), address(__contractBeingTested__));
        forwarder.approve(address(token1), address(__contractBeingTested__));

        // 2. Bundled operation set to create a pair, curve, and pool.
        bytes memory data = createPool(
            address(token0),
            address(token1),
            DEFAULT_SIGMA,
            uint32(block.timestamp) + DEFAULT_MATURITY,
            uint16(1e4 - DEFAULT_GAMMA),
            uint16(1e4 - DEFAULT_PRIORITY_GAMMA),
            DEFAULT_STRIKE,
            DEFAULT_PRICE
        );

        bool success = forwarder.jumpProcess(data);
        assertTrue(success, "forwarder call failed");

        uint16 pairId = uint16(__contractBeingTested__.getPairNonce());
        uint32 curveId = uint32(__contractBeingTested__.getCurveNonce());
        __poolId = CPU.encodePoolId(pairId, curveId);

        assertEq(__contractBeingTested__.doesPoolExist(__poolId), true);
        assertEq(IHyperStruct(address(__contractBeingTested__)).pools(__poolId).lastTick != 0, true);
        assertEq(IHyperStruct(address(__contractBeingTested__)).pools(__poolId).liquidity == 0, true);
    }

    // --- Helpers --- //

    function getPool(uint48 poolId) public view returns (HyperPool memory) {
        return IHyperStruct(address(__contractBeingTested__)).pools(poolId);
    }

    function getCurve(uint32 curveId) public view returns (Curve memory) {
        return IHyperStruct(address(__contractBeingTested__)).curves(curveId);
    }

    function getPair(uint16 pairId) public view returns (Pair memory) {
        return IHyperStruct(address(__contractBeingTested__)).pairs(pairId);
    }

    function getPosition(address owner, uint48 positionId) public view returns (HyperPosition memory) {
        return IHyperStruct(address(__contractBeingTested__)).positions(owner, positionId);
    }

    function getReserves(address token) public view returns (uint) {
        return __contractBeingTested__.getReserves(token);
    }

    function getBalances(address owner, address token) public view returns (uint) {
        return __contractBeingTested__.getBalances(owner, token);
    }

    // ===== Getters ===== //

    function testGetAmounts() public {
        Curve memory curve = getCurve(uint32(__poolId));
        (uint deltaAsset, uint deltaQuote) = __contractBeingTested__.getAmounts(__poolId);

        assertEq(deltaAsset, DEFAULT_ASSET_RESERVE);
        assertEq(deltaQuote, DEFAULT_QUOTE_RESERVE);
    }

    function testGetLiquidityMinted() public {
        uint deltaLiquidity = __contractBeingTested__.getLiquidityMinted(__poolId, 1, 1e19);
    }

    // ===== CPU ===== //

    function testJumpProcessCreatesPair() public {
        bytes[] memory instructions = new bytes[](1);
        instructions[0] = (CPU.encodeCreatePair(address(fakeToken0), address(quote)));
        bytes memory data = CPU.encodeJumpInstruction(instructions);
        bool success = forwarder.jumpProcess(data);
        assertTrue(success);

        uint16 pairId = uint16(__contractBeingTested__.getPairNonce());
        Pair memory pair = getPair(pairId);
        assertTrue(pair.tokenAsset != address(0));
        assertTrue(pair.tokenQuote != address(0));
    }

    function testProcessRevertsWithUnknownInstructionZeroOpcode() public {
        vm.expectRevert(UnknownInstruction.selector);
        forwarder.process(hex"00");
    }

    function testProcessRevertsWithUnknownInstruction() public {
        vm.expectRevert(UnknownInstruction.selector);
        forwarder.process(hex"44");
    }

    // ===== Effects ===== //

    function testSyncPool() public {
        vm.warp(1);
        __contractBeingTested__.syncPool(__poolId);
    }

    function testDrawReducesBalance() public checkSettlementInvariant {
        // First fund the account
        __contractBeingTested__.fund(address(asset), 4000);

        // Draw
        uint prevBalance = getBalances(address(this), address(asset));
        __contractBeingTested__.draw(address(asset), 4000, address(this));
        uint nextBalance = getBalances(address(this), address(asset));

        assertTrue(nextBalance == 0);
        assertTrue(nextBalance < prevBalance);
    }

    function testDrawRevertsWithDrawBalance() public {
        vm.expectRevert(DrawBalance.selector);
        __contractBeingTested__.draw(address(asset), 1e18, address(this));
    }

    function testDrawFromWethTransfersEther() public checkSettlementInvariant {
        // First fund the account
        __contractBeingTested__.fund{value: 4000}(address(__weth__), 4000);

        // Draw
        uint prevBalance = address(this).balance;
        __contractBeingTested__.draw(address(__weth__), 4000, address(this));
        uint nextBalance = address(this).balance;

        assertTrue(nextBalance > prevBalance);
    }

    function testFundIncreasesBalance() public checkSettlementInvariant {
        uint prevBalance = getBalances(address(this), address(asset));
        __contractBeingTested__.fund(address(asset), 4000);
        uint nextBalance = getBalances(address(this), address(asset));

        assertTrue(nextBalance > prevBalance);
    }

    function testFundWrapsEther() public checkSettlementInvariant {
        uint prevWethBalance = __weth__.balanceOf(address(__contractBeingTested__));
        uint prevBalance = address(this).balance;
        __contractBeingTested__.fund{value: 4000}(address(__weth__), 4000);
        uint nextBalance = address(this).balance;
        uint nextWethBalance = __weth__.balanceOf(address(__contractBeingTested__));

        assertTrue(nextBalance < prevBalance);
        assertTrue(nextWethBalance > prevWethBalance);
    }

    // --- Swap --- //

    function testSwapExactInNonExistentPoolIdReverts() public {
        uint48 failureArg = 0x0001030;
        bytes memory data = CPU.encodeSwap(0, 0x0001030, 0x01, 0x01, 0x01, 0x01, 0);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        bool success = forwarder.process(data);
        assertTrue(!success);
    }

    function testSwapExactInZeroSwapAmountReverts() public {
        uint128 failureArg = 0;
        bytes memory data = CPU.encodeSwap(0, __poolId, 0x01, failureArg, 0x01, 0x01, 0);
        vm.expectRevert(ZeroInput.selector);
        bool success = forwarder.process(data);
        assertTrue(!success);
    }

    function testSwapExactInPoolPriceUpdated() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.process(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = getPool(__poolId).lastPrice;

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.process(data);
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
        bool success = forwarder.process(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        int256 prev = getPool(__poolId).lastTick;

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.process(data);
        assertTrue(success);

        int256 next = getPool(__poolId).lastTick;
        assertTrue(next != prev);
    } */

    function testSwapUseMax() public checkSettlementInvariant {
        uint amount = type(uint256).max;
        uint limit = amount;
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.process(data);
        assertTrue(success);

        // move some time
        vm.warp(block.timestamp + 1);
        uint256 prev = getPool(__poolId).liquidity;

        __contractBeingTested__.swap(__poolId, true, amount, limit);

        uint256 next = getPool(__poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapInQuote() public checkSettlementInvariant {
        uint limit = type(uint256).max;
        uint amount = 2222;
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.process(data);
        assertTrue(success);

        // move some time
        vm.warp(block.timestamp + 1);
        uint256 prev = getPool(__poolId).liquidity;

        __contractBeingTested__.swap(__poolId, false, amount, limit);

        uint256 next = getPool(__poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapReverse() public {
        uint limit = type(uint256).max;
        uint amount = 2222;
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.process(data);
        assertTrue(success);

        // move some time
        uint256 prev = getBalances(address(this), address(asset));

        (uint output, ) = __contractBeingTested__.swap(__poolId, true, amount, limit);
        (uint input, ) = __contractBeingTested__.swap(__poolId, false, output, limit);

        uint256 next = getBalances(address(this), address(asset));
        console.log(amount, input);
        assertTrue(next <= prev);
        assertTrue(input < amount);
    }

    function testSwapExpiredPoolReverts() public {
        uint limit = type(uint256).max;
        uint amount = 2222;
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.process(data);
        assertTrue(success);

        // move some time beyond maturity
        vm.warp(getCurve(uint32(__poolId)).maturity + 1);

        vm.expectRevert(PoolExpiredError.selector);
        __contractBeingTested__.swap(__poolId, false, amount, limit);
    }

    function testSwapExactInPoolLiquidityUnchanged() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.process(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);
        uint256 prev = getPool(__poolId).liquidity;

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.process(data);
        assertTrue(success);

        uint256 next = getPool(__poolId).liquidity;
        assertTrue(next == prev);
    }

    function testSwapExactInPoolTimestampUpdated() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity, note: 0x0a amount breaks test? todo: handle case where insufficient liquidity
            0x01
        );
        bool success = forwarder.process(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = getPool(__poolId).blockTimestamp;

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.process(data);
        assertTrue(success);

        uint256 next = getPool(__poolId).blockTimestamp;
        assertTrue(next != prev);
    }

    function testSwapExactInGlobalAssetBalanceIncreases() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.process(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = getReserves(address(asset));

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.process(data);
        assertTrue(success);

        uint256 next = getReserves(address(asset));
        assertTrue(next > prev);
    }

    function testSwapExactInGlobalQuoteBalanceDecreases() public checkSettlementInvariant {
        // Add liquidity first
        bytes memory data = CPU.encodeAllocate(
            0,
            __poolId,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.process(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = getReserves(address(quote));

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = CPU.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.process(data);
        assertTrue(success);

        uint256 next = getReserves(address(quote));
        assertTrue(next < prev);
    }

    // --- Allocate --- //

    function testAllocateNonExistentPoolIdReverts() public {
        uint48 failureArg = uint48(48);
        bytes memory data = CPU.encodeAllocate(0, failureArg, 0x01, 0x01);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        bool success = forwarder.process(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testAllocateZeroLiquidityReverts() public {
        uint8 failureArg = 0;
        bytes memory data = CPU.encodeAllocate(0, __poolId, 0x00, failureArg);
        vm.expectRevert(ZeroLiquidityError.selector);
        bool success = forwarder.process(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testProcessAllocateFull() public checkSettlementInvariant {
        uint256 price = getPool(__poolId).lastPrice;
        Curve memory curve = getCurve(uint32(__poolId));
        uint256 theoreticalR2 = HyperSwapLib.computeR2WithPrice(
            price,
            curve.strike,
            curve.sigma,
            curve.maturity - block.timestamp
        );

        uint8 power = uint8(0x06); // 6 zeroes
        uint8 amount = uint8(0x04); // 4 with 6 zeroes = 4_000_000 wei
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);

        forwarder.process(data);

        uint256 globalR1 = getReserves(address(quote));
        uint256 globalR2 = getReserves(address(asset));
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        assertTrue((theoreticalR2 - FixedPointMathLib.divWadUp(globalR2, 4_000_000)) <= 1e14);
    }

    function testAllocateFull() public checkSettlementInvariant {
        uint256 price = getPool(__poolId).lastPrice;
        Curve memory curve = getCurve(uint32(__poolId));
        uint256 theoreticalR2 = HyperSwapLib.computeR2WithPrice(
            price,
            curve.strike,
            curve.sigma,
            curve.maturity - block.timestamp
        );

        __contractBeingTested__.allocate(__poolId, 4e6);

        uint256 globalR1 = getReserves(address(quote));
        uint256 globalR2 = getReserves(address(asset));
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        assertTrue((theoreticalR2 - FixedPointMathLib.divWadUp(globalR2, 4_000_000)) <= 1e14);
    }

    function testAllocateUseMax() public checkSettlementInvariant {
        uint maxLiquidity = __contractBeingTested__.getLiquidityMinted(
            __poolId,
            asset.balanceOf(address(this)),
            quote.balanceOf(address(this))
        );

        (uint deltaAsset, uint deltaQuote) = __contractBeingTested__.getReservesDelta(__poolId, maxLiquidity);

        __contractBeingTested__.allocate(__poolId, type(uint256).max);

        assertEq(maxLiquidity, getPool(__poolId).liquidity);
        assertEq(deltaAsset, getReserves(address(asset)));
        assertEq(deltaQuote, getReserves(address(quote)));
    }

    function testAllocatePositionTimestampUpdated() public checkSettlementInvariant {
        uint48 positionId = __poolId;

        uint256 prevPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        assertTrue(prevPositionTimestamp == 0);
        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == block.timestamp);
    }

    function testAllocatePositionTotalLiquidityIncreases() public checkSettlementInvariant {
        uint48 positionId = __poolId;

        uint256 prevPositionTotalLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTotalLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        assertTrue(prevPositionTotalLiquidity == 0);
        assertTrue(nextPositionTotalLiquidity > prevPositionTotalLiquidity);
    }

    function testAllocateGlobalAssetIncreases() public checkSettlementInvariant {
        uint256 prevGlobal = getReserves(address(asset));

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = getReserves(address(asset));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    function testAllocateGlobalQuoteIncreases() public checkSettlementInvariant {
        uint256 prevGlobal = getReserves(address(quote));

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = getReserves(address(quote));
        assertTrue(nextGlobal != 0, "next globalReserves is zero");
        assertTrue(nextGlobal > prevGlobal, "globalReserves did not change");
    }

    // --- Remove Liquidity --- //

    function testUnallocateUseMax() public {
        uint maxLiquidity = getPosition(msg.sender, __poolId).totalLiquidity;

        __contractBeingTested__.unallocate(__poolId, type(uint256).max);

        assertEq(0, getPool(__poolId).liquidity);
    }

    function testUnallocateZeroLiquidityReverts() public {
        bytes memory data = CPU.encodeUnallocate(0, __poolId, 0x00, 0x00);
        vm.expectRevert(ZeroLiquidityError.selector);
        bool success = forwarder.process(data);
        assertTrue(!success);
    }

    function testUnallocateNonExistentPoolReverts() public {
        uint48 failureArg = 42;
        bytes memory data = CPU.encodeUnallocate(0, 42, 0x01, 0x01);
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        bool success = forwarder.process(data);
        assertTrue(!success);
    }

    function testUnallocatePositionJitPolicyReverts() public checkSettlementInvariant {
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success, "forwarder call failed");

        // Set the distance for the position by warping in time.
        uint256 distance = 22;
        uint256 warpTimestamp = block.timestamp + distance;
        vm.warp(warpTimestamp);

        // Set the policy from 0 (default 0 in test contract).
        __contractBeingTested__.setJitPolicy(999999999999);

        data = CPU.encodeUnallocate(0, __poolId, power, amount);

        vm.expectRevert(abi.encodeWithSelector(JitLiquidity.selector, distance));
        success = forwarder.process(data);
        assertTrue(!success, "Should not suceed in testUnllocatePositionJit");
    }

    function testUnallocatePositionTimestampUpdated() public checkSettlementInvariant {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success, "forwarder call failed");

        uint48 positionId = __poolId;
        uint256 prevPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        uint256 warpTimestamp = block.timestamp + 1;
        vm.warp(warpTimestamp);

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = forwarder.process(data);

        uint256 nextPositionTimestamp = getPosition(address(forwarder), positionId).blockTimestamp;

        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == warpTimestamp);
    }

    function testUnallocatePositionTotalLiquidityDecreases() public checkSettlementInvariant {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success, "forwarder call failed");

        uint48 positionId = __poolId;
        uint256 prevPositionLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = forwarder.process(data);

        uint256 nextPositionLiquidity = getPosition(address(forwarder), positionId).totalLiquidity;

        assertTrue(nextPositionLiquidity < prevPositionLiquidity);
    }

    function testUnallocateGlobalAssetDecreases() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success);

        uint256 prev = getReserves(address(asset));

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = forwarder.process(data);

        uint256 next = getReserves(address(asset));
        assertTrue(next < prev, "globalReserves did not change");
    }

    function testUnallocateGlobalQuoteDecreases() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success);

        uint256 prev = getReserves(address(quote));

        data = CPU.encodeUnallocate(0, __poolId, power, amount);
        success = forwarder.process(data);

        uint256 next = getReserves(address(quote));
        assertTrue(next < prev, "globalReserves did not change");
    }

    // --- Stake Position --- //

    function testStakeExternalEpochIncrements() public {
        uint8 amount = 0x05;
        __contractBeingTested__.allocate(__poolId, amount);

        uint prevId = getPosition(address(this), __poolId).stakeEpochId;
        __contractBeingTested__.stake(__poolId);
        uint nextId = getPosition(address(this), __poolId).stakeEpochId;

        assertTrue(nextId != prevId);
    }

    function testStakePositionStakedUpdated() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success);

        uint48 positionId = __poolId;

        bool prevPositionStaked = getPosition(address(forwarder), positionId).stakeEpochId != 0;

        data = CPU.encodeStakePosition(positionId);
        success = forwarder.process(data);

        bool nextPositionStaked = getPosition(address(forwarder), positionId).stakeEpochId != 0;

        assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        assertTrue(nextPositionStaked, "Position staked is not true.");
    }

    function testStakePoolStakedLiquidityUpdated() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success);

        uint256 prevPoolStakedLiquidity = getPool(__poolId).stakedLiquidity;

        uint48 positionId = __poolId;
        data = CPU.encodeStakePosition(positionId);
        success = forwarder.process(data);

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

    function testStakeNonExistentPoolIdReverts() public {
        uint48 failureArg = 3214;
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        __contractBeingTested__.stake(failureArg);
    }

    function testStakeNonZeroStakeEpochIdReverts() public {
        __contractBeingTested__.allocate(__poolId, 4355);
        __contractBeingTested__.stake(__poolId); // Increments stake epoch id

        vm.expectRevert(abi.encodeWithSelector(PositionStakedError.selector, __poolId));
        __contractBeingTested__.stake(__poolId);
    }

    function testStakePositionZeroLiquidityReverts() public {
        vm.expectRevert(abi.encodeWithSelector(PositionZeroLiquidityError.selector, __poolId));
        __contractBeingTested__.stake(__poolId);
    }

    // --- Unstake Position --- //

    function testUnstakeExternalEpochIncrements() public {
        uint8 amount = 0x05;
        __contractBeingTested__.allocate(__poolId, amount);
        __contractBeingTested__.stake(__poolId);

        uint prevId = getPosition(address(this), __poolId).unstakeEpochId;
        __contractBeingTested__.unstake(__poolId);
        uint nextId = getPosition(address(this), __poolId).unstakeEpochId;

        assertTrue(nextId != prevId);
    }

    function testUnstakePositionStakedUpdated() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK + 256; // fails if not above current tick
        uint8 amount = 0x01;
        uint8 power = 0x0f;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success);

        uint48 positionId = __poolId;
        data = CPU.encodeStakePosition(positionId);
        success = forwarder.process(data);

        vm.warp(__contractBeingTested__.EPOCH_INTERVAL() + 1);

        // touch pool to update it so we know how much staked liquidity the position has
        data = CPU.encodeSwap(0, __poolId, 0x09, 0x01, 0x10, 0x01, 0);
        success = forwarder.process(data);

        uint256 prevPositionStaked = getPosition(address(forwarder), positionId).unstakeEpochId;

        data = CPU.encodeUnstakePosition(positionId);
        success = forwarder.process(data);

        uint256 nextPositionStaked = getPosition(address(forwarder), positionId).unstakeEpochId;

        assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        assertTrue(nextPositionStaked != 0, "Position staked is true.");
    }

    // note: some unintended side effects most likely from update/sync pool messing with price
    // it creates a discrepency in the contract where the contract holds more tokens than the sum
    // of all claims is entitled to.
    function testUnstakePoolStakedLiquidityUpdated() public checkSettlementInvariant {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK + 256; // note: fails if pool.lastTick <= hi
        uint8 amount = 0x01;
        uint8 power = 0x0f;
        bytes memory data = CPU.encodeAllocate(0, __poolId, power, amount);
        bool success = forwarder.process(data);
        assertTrue(success);

        uint48 positionId = __poolId;
        data = CPU.encodeStakePosition(positionId);
        success = forwarder.process(data);

        vm.warp(__contractBeingTested__.EPOCH_INTERVAL() + 1);

        // touch pool to update it so we know how much staked liquidity the position has
        data = CPU.encodeSwap(0, __poolId, 0x09, 0x01, 0x10, 0x01, 0);
        success = forwarder.process(data);

        uint256 prevPoolStakedLiquidity = getPool(__poolId).stakedLiquidity;

        data = CPU.encodeUnstakePosition(positionId);
        success = forwarder.process(data);

        vm.warp((__contractBeingTested__.EPOCH_INTERVAL() + 1) * 2);

        // touch pool to update it so we know how much staked liquidity the position has
        data = CPU.encodeSwap(0, __poolId, 0x01, 0x01, 0x10, 0x01, 0);
        success = forwarder.process(data);

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

    function testUnstakeNonExistentPoolIdReverts() public {
        uint48 failureArg = 1224;
        vm.expectRevert(abi.encodeWithSelector(NonExistentPool.selector, failureArg));
        __contractBeingTested__.unstake(failureArg);
    }

    function testUnstakeNotStakedReverts() public {
        vm.expectRevert(abi.encodeWithSelector(PositionNotStakedError.selector, __poolId));
        __contractBeingTested__.unstake(__poolId);
    }

    // --- Create Pair --- //

    function testCreatePairSameTokensReverts() public {
        address token = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(token, token);
        vm.expectRevert(SameTokenError.selector);
        bool success = forwarder.process(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testCreatePairPairExistsReverts() public {
        bytes memory data = CPU.encodeCreatePair(address(asset), address(quote));
        vm.expectRevert(abi.encodeWithSelector(PairExists.selector, 1));
        bool success = forwarder.process(data);
    }

    function testCreatePairLowerDecimalBoundsAssetReverts() public {
        address token0 = address(new TestERC20("t", "t", 5));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(DecimalsError.selector, 5));
        bool success = forwarder.process(data);
    }

    function testCreatePairLowerDecimalBoundsQuoteReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 5));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(DecimalsError.selector, 5));
        bool success = forwarder.process(data);
    }

    function testCreatePairUpperDecimalBoundsAssetReverts() public {
        address token0 = address(new TestERC20("t", "t", 24));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(DecimalsError.selector, 24));
        bool success = forwarder.process(data);
    }

    function testCreatePairUpperDecimalBoundsQuoteReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 24));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        vm.expectRevert(abi.encodeWithSelector(DecimalsError.selector, 24));
        bool success = forwarder.process(data);
    }

    function testCreatePairPairNonceIncrementedReturnsOneAdded() public {
        uint256 prevNonce = __contractBeingTested__.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.process(data);
        uint256 nonce = __contractBeingTested__.getPairNonce();
        assertEq(nonce, prevNonce + 1);
    }

    function testCreatePairFetchesPairIdReturnsNonZero() public {
        uint256 prevNonce = __contractBeingTested__.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.process(data);
        uint256 pairId = __contractBeingTested__.getPairId(token0, token1);
        assertTrue(pairId != 0);
    }

    function testCreatePairFetchesPairDataReturnsAddresses() public {
        uint256 prevNonce = __contractBeingTested__.getPairNonce();
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.process(data);
        uint16 pairId = __contractBeingTested__.getPairId(token0, token1);
        Pair memory pair = getPair(pairId);
        assertEq(pair.tokenAsset, token0);
        assertEq(pair.tokenQuote, token1);
        assertEq(pair.decimalsBase, 18);
        assertEq(pair.decimalsQuote, 18);
    }

    // --- Create Curve --- //

    function testCreateCurveCurveExistsReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(CurveExists.selector, 1));
        bool success = forwarder.process(data);
    }

    function testCreateCurveFeeParameterOutsideBoundsReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        uint16 failureArg = 5e4;
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            failureArg,
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(FeeOOB.selector, failureArg));
        bool success = forwarder.process(data);
    }

    function testCreateCurvePriorityFeeParameterOutsideBoundsReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        uint16 failureArg = 5e4;
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            failureArg,
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(PriorityFeeOOB.selector, failureArg));
        bool success = forwarder.process(data);
    }

    function testCreateCurveExpiringPoolZeroSigmaReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        uint24 failureArg = 0;
        bytes memory data = CPU.encodeCreateCurve(
            failureArg,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        vm.expectRevert(abi.encodeWithSelector(MinSigma.selector, failureArg));
        bool success = forwarder.process(data);
    }

    function testCreateCurveExpiringPoolZeroStrikeReverts() public {
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        uint128 failureArg = 0;
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            failureArg
        );
        vm.expectRevert(abi.encodeWithSelector(MinStrike.selector, failureArg));
        bool success = forwarder.process(data);
    }

    function testCreateCurveCurveNonceIncrementReturnsOne() public {
        uint256 prevNonce = __contractBeingTested__.getCurveNonce();
        Curve memory curve = getCurve(uint32(__poolId)); // Existing curve from helper setup
        bytes memory data = CPU.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            uint16(1e4 - curve.priorityGamma),
            curve.strike
        );
        bool success = forwarder.process(data);
        uint256 nextNonce = __contractBeingTested__.getCurveNonce();
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
        bool success = forwarder.process(data);
        uint32 curveId = __contractBeingTested__.getCurveId(rawCurveId);
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
        bool success = forwarder.process(data);
        uint32 curveId = __contractBeingTested__.getCurveId(rawCurveId);
        Curve memory newCurve = getCurve(curveId);
        assertEq(newCurve.sigma, curve.sigma + 1);
        assertEq(newCurve.maturity, curve.maturity);
        assertEq(newCurve.gamma, curve.gamma);
        assertEq(newCurve.priorityGamma, curve.priorityGamma);
        assertEq(newCurve.strike, curve.strike);
    }

    // --- Create Pool --- //

    function testCreatePoolZeroPriceParameterReverts() public {
        uint128 failureArg = 0;
        bytes memory data = CPU.encodeCreatePool(1, failureArg);
        vm.expectRevert(ZeroPrice.selector);
        bool success = forwarder.process(data);
    }

    function testCreatePoolExistentPoolReverts() public {
        uint48 failureArg = __poolId;
        bytes memory data = CPU.encodeCreatePool(failureArg, 1);
        vm.expectRevert(PoolExists.selector);
        bool success = forwarder.process(data);
    }

    function testCreatePoolMagicPairId() public {
        // Create a new curve to increment the nonce to 2
        bytes memory data = CPU.encodeCreateCurve(4, type(uint32).max - 1, 4, 4, 4);
        forwarder.process(data);

        uint48 magicVariable = 0x000000000002;
        data = CPU.encodeCreatePool(magicVariable, 1);
        bool success = forwarder.process(data);
        assertTrue(success);
    }

    function testCreatePoolMagicCurveId() public {
        // Create a new pair to increment the nonce to 2
        bytes memory data = CPU.encodeCreatePair(address(quote), address(__weth__));
        forwarder.process(data);

        uint48 magicVariable = 0x000200000000;
        data = CPU.encodeCreatePool(magicVariable, 1);
        bool success = forwarder.process(data);
        assertTrue(success);
    }

    function testCreatePoolExpiringPoolExpiredReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.process(data);
        uint16 pairId = __contractBeingTested__.getPairId(token0, token1);

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
        success = forwarder.process(data);

        uint32 curveId = __contractBeingTested__.getCurveId(rawCurveId);
        uint48 id = CPU.encodePoolId(pairId, curveId);
        data = CPU.encodeCreatePool(id, 1_000);
        vm.expectRevert(PoolExpiredError.selector);
        success = forwarder.process(data);
    }

    function testCreatePoolFetchesPoolDataReturnsNonZeroBlockTimestamp() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = CPU.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.process(data);
        uint16 pairId = __contractBeingTested__.getPairId(token0, token1);

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
        success = forwarder.process(data);

        uint32 curveId = __contractBeingTested__.getCurveId(rawCurveId);
        uint48 id = CPU.encodePoolId(pairId, curveId);
        data = CPU.encodeCreatePool(id, 1_000);
        success = forwarder.process(data);

        uint256 time = getPool(id).blockTimestamp;
        assertTrue(time != 0);
    }
}
