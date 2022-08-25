pragma solidity 0.8.13;

import "../shared/BaseTest.sol";

import "../../contracts/test/TestERC20.sol";
import "../../contracts/prototype/HyperPrototype.sol";

contract Forwarder is Test {
    TestHyperPrototype public hyper;

    bytes4 public expectedError;

    constructor() {
        hyper = TestHyperPrototype(msg.sender);
    }

    function set(bytes4 err) public {
        expectedError = err;
    }

    // Assumes Hyper calls this, for testing only.
    function pass(bytes calldata data) external returns (bool) {
        //payable(hyper).call{value: 0}(data)
        try hyper.process(data) {
            //emit log("sucess calling hyper");
        } catch (bytes memory reason) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }

        return true;
    }
}

/**
 * @notice Testing the primary logic of the AMM is complicated because of the many parameters,
 * and specific math involved. Here's a rough guide to thoroughly test if pools are working as expected.
 *
 * // --- Add Liquidity --- //
 *
 * Prerequesites:
 * 1. Hyper contract deployed, two ERC20 token contracts deployed.
 * 2. Pair created in Hyper.
 * 3. Curve parameters created in Hyper.
 * 4. Pool instantiated in Hyper.
 *
 * Adding liquidity:
 * 1. Use Instructions library to encode add liquidity parameters as a single calldata byte string.
 * 2. Call a contract with the data which forwards it to the Hyper contract.
 */
contract TestHyperPrototype is HyperPrototype, BaseTest {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    Forwarder public forwarder;
    TestERC20 public asset;
    TestERC20 public quote;
    uint48 __poolId;

    function setUp() public {
        (asset, quote) = handlePrerequesites();
    }

    function handlePrerequesites() public returns (TestERC20 token0, TestERC20 token1) {
        // Set the forwarder.
        forwarder = new Forwarder();

        // 1. Two token contracts.
        token0 = new TestERC20("token0", "token0 name", 18);
        token1 = new TestERC20("token1", "token1 name", 18);

        // 2. Create pair
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint16 pairId = uint16(_pairNonce);

        // 3. Create curve
        data = Instructions.encodeCreateCurve(
            DEFAULT_SIGMA,
            DEFAULT_MATURITY,
            uint16(1e4 - DEFAULT_GAMMA),
            DEFAULT_STRIKE
        );
        success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint32 curveId = uint32(_curveNonce);

        __poolId = Instructions.encodePoolId(pairId, curveId);

        // 4. Create pool
        data = Instructions.encodeCreatePool(__poolId, DEFAULT_PRICE);
        success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        assertEq(_doesPoolExist(__poolId), true);
        assertEq(_pools[__poolId].lastTick != 0, true);
        assertEq(_pools[__poolId].liquidity == 0, true);
    }

    // --- Implemented --- //

    function process(bytes calldata data) external {
        uint48 poolId_;
        bytes1 instruction = bytes1(data[0] & 0x0f);
        if (instruction == Instructions.UNKNOWN) revert UnknownInstruction();

        if (instruction == Instructions.ADD_LIQUIDITY) {
            (poolId_, ) = _addLiquidity(data);
        } else if (instruction == Instructions.REMOVE_LIQUIDITY) {
            (poolId_, , ) = _removeLiquidity(data);
        } else if (instruction == Instructions.SWAP) {
            (poolId_, , , ) = _swapExactForExact(data);
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

    // --- Helpers --- //

    function getSlotLiquidity(int24 slot) public view returns (uint256) {
        return _slots[__poolId][slot].totalLiquidity;
    }

    function getSlotLiquidityDelta(int24 slot) public view returns (int256) {
        return _slots[__poolId][slot].liquidityDelta;
    }

    // --- Swap --- //

    function testFailS_wNonExistentPoolIdReverts() public {
        bytes memory data = Instructions.encodeSwap(0, 0x0001030, 0x01, 0x01, 0x01, 0x01, 0);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testFailS_wZeroSwapAmountReverts() public {
        bytes memory data = Instructions.encodeSwap(0, __poolId, 0x01, 0x00, 0x01, 0x01, 0);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    /// @dev this ones tough... how do we know what slot was swapped in?
    function testS_wSlotTimestampUpdatedWithSlotTransition() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
            0,
            __poolId,
            DEFAULT_TICK - 2560,
            DEFAULT_TICK + 2560,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);

        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = _slots[__poolId][23028].timestamp; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = _slots[__poolId][23028].timestamp;
        assertTrue(next != prev);
    }

    function testS_wPoolPriceUpdated() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
            0,
            __poolId,
            DEFAULT_TICK - 2560,
            DEFAULT_TICK + 2560,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = _pools[__poolId].lastPrice; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = _pools[__poolId].lastPrice;
        assertTrue(next != prev);
    }

    function testS_wPoolSlotIndexUpdated() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
            0,
            __poolId,
            DEFAULT_TICK - 2560,
            DEFAULT_TICK + 2560,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        int256 prev = _pools[__poolId].lastTick; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        int256 next = _pools[__poolId].lastTick;
        assertTrue(next != prev);
    }

    function testS_wPoolLiquidityUnchanged() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
            0,
            __poolId,
            DEFAULT_TICK - 2560,
            DEFAULT_TICK + 2560,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);
        uint256 prev = _pools[__poolId].liquidity; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = _pools[__poolId].liquidity;
        assertTrue(next == prev);
    }

    function testS_wPoolTimestampUpdated() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
            0,
            __poolId,
            DEFAULT_TICK - 2560,
            DEFAULT_TICK + 2560,
            0x13, // 19 zeroes, so 10e19 liquidity, note: 0x0a amount breaks test? todo: handle case where insufficient liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = _pools[__poolId].blockTimestamp; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = _pools[__poolId].blockTimestamp;
        assertTrue(next != prev);
    }

    function testS_wGlobalAssetBalanceIncreases() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
            0,
            __poolId,
            DEFAULT_TICK - 2560,
            DEFAULT_TICK + 2560,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = _globalReserves[address(asset)]; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = _globalReserves[address(asset)];
        assertTrue(next > prev);
    }

    function testS_wGlobalQuoteBalanceDecreases() public {
        // Add liquidity first
        bytes memory data = Instructions.encodeAddLiquidity(
            0,
            __poolId,
            DEFAULT_TICK - 2560,
            DEFAULT_TICK + 2560,
            0x13, // 19 zeroes, so 10e19 liquidity
            0x01
        );
        bool success = forwarder.pass(data);
        assertTrue(success);
        // move some time
        vm.warp(block.timestamp + 1);

        uint256 prev = _globalReserves[address(quote)]; // todo: fix, I know this slot from console.log.

        // need to swap a large amount so we cross slots. This is 2e18. 0x12 = 18 10s, 0x02 = 2
        data = Instructions.encodeSwap(0, __poolId, 0x12, 0x02, 0x1f, 0x01, 0);
        success = forwarder.pass(data);
        assertTrue(success);

        uint256 next = _globalReserves[address(quote)];
        assertTrue(next < prev);
    }

    // --- Add liquidity --- //

    function testFailA_LNonExistentPoolIdReverts() public {
        uint48 random = uint48(48);
        bytes memory data = Instructions.encodeAddLiquidity(0, random, 0, 0, 0x01, 0x01);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");
    }

    function testFailA_LZeroLiquidityReverts() public {
        uint8 liquidity = 0;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, 0, 0, 0x00, liquidity);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");
    }

    function testA_LFullAddLiquidity() public {
        uint256 price = _pools[__poolId].lastPrice;
        Curve memory curve = _curves[uint32(__poolId)];
        uint256 theoreticalR2 = HyperSwapLib.computeR2WithPrice(
            price,
            curve.strike,
            curve.sigma,
            curve.maturity - _blockTimestamp()
        );
        int24 min = int24(-887272);
        int24 max = -min;
        uint8 power = uint8(0x06); // 6 zeroes
        uint8 amount = uint8(0x04); // 4 with 6 zeroes = 4_000_000 wei
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, min, max, power, amount);

        forwarder.pass(data);

        uint256 globalR1 = _globalReserves[address(quote)];
        uint256 globalR2 = _globalReserves[address(asset)];
        assertTrue(globalR1 > 0);
        assertTrue(globalR2 > 0);
        assertTrue((theoreticalR2 - FixedPointMathLib.divWadUp(globalR2, 4_000_000)) <= 1e14);
    }

    function testA_LLowSlotLiquidityDeltaIncrease() public {
        int24 loTick = DEFAULT_TICK;
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        int256 liquidityDelta = getSlotLiquidityDelta(loTick);
        assertTrue(liquidityDelta > 0);
    }

    function testA_LHighSlotLiquidityDeltaDecrease() public {
        int24 loTick = DEFAULT_TICK;
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        int256 liquidityDelta = getSlotLiquidityDelta(hiTick);
        assertTrue(liquidityDelta < 0);
    }

    function testA_LLowSlotLiquidityIncrease() public {
        int24 loTick = DEFAULT_TICK;
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 liquidity = getSlotLiquidity(loTick);
        assertEq(liquidity, 10);
    }

    function testA_LHighSlotLiquidityIncrease() public {
        int24 loTick = DEFAULT_TICK;
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 liquidity = getSlotLiquidity(hiTick);
        assertEq(liquidity, 10);
    }

    function testA_LLowSlotInstantiatedChange() public {
        int24 slot = DEFAULT_TICK;
        bool instantiated = _slots[__poolId][slot].instantiated;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, slot, slot + 2, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        bool change = _slots[__poolId][slot].instantiated;
        assertTrue(instantiated != change);
    }

    function testA_LHighSlotInstantiatedChange() public {
        int24 slot = DEFAULT_TICK;
        bool instantiated = _slots[__poolId][slot].instantiated;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, slot - 2, slot, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        bool change = _slots[__poolId][slot].instantiated;
        assertTrue(instantiated != change);
    }

    function testA_LPositionLowTickUpdated() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = hiTick - 2;
        uint96 positionId = uint96(bytes12(abi.encodePacked(__poolId, loTick, hiTick)));

        int24 prevPositionLoTick = _positions[address(forwarder)][positionId].loTick;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        int24 nextPositionLoTick = _positions[address(forwarder)][positionId].loTick;

        assertTrue(prevPositionLoTick == 0);
        assertTrue(nextPositionLoTick == loTick);
    }

    function testA_LPositionHighTickUpdated() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = hiTick - 2;
        uint96 positionId = uint96(bytes12(abi.encodePacked(__poolId, loTick, hiTick)));

        int24 prevPositionHiTick = _positions[address(forwarder)][positionId].hiTick;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        int24 nextPositionHiTick = _positions[address(forwarder)][positionId].hiTick;

        assertTrue(prevPositionHiTick == 0);
        assertTrue(nextPositionHiTick == hiTick);
    }

    function testA_LPositionTimestampUpdated() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = hiTick - 2;
        uint96 positionId = uint96(bytes12(abi.encodePacked(__poolId, loTick, hiTick)));

        uint256 prevPositionTimestamp = _positions[address(forwarder)][positionId].blockTimestamp;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTimestamp = _positions[address(forwarder)][positionId].blockTimestamp;

        assertTrue(prevPositionTimestamp == 0);
        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == block.timestamp);
    }

    function testA_LPositionTotalLiquidityIncreases() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = hiTick - 2;
        uint96 positionId = uint96(bytes12(abi.encodePacked(__poolId, loTick, hiTick)));

        uint256 prevPositionTotalLiquidity = _positions[address(forwarder)][positionId].totalLiquidity;

        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextPositionTotalLiquidity = _positions[address(forwarder)][positionId].totalLiquidity;

        assertTrue(prevPositionTotalLiquidity == 0);
        assertTrue(nextPositionTotalLiquidity > prevPositionTotalLiquidity);
    }

    function testA_LGlobalAssetIncreases() public {
        uint256 prevGlobal = _globalReserves[address(asset)];
        int24 loTick = DEFAULT_TICK;
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = _globalReserves[address(asset)];
        assertTrue(nextGlobal != 0, "next reserves is zero");
        assertTrue(nextGlobal > prevGlobal, "reserves did not change");
    }

    function testA_LGlobalQuoteIncreases() public {
        uint256 prevGlobal = _globalReserves[address(quote)];
        int24 loTick = DEFAULT_TICK - 256; // Enough below to have quote.
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 nextGlobal = _globalReserves[address(quote)];
        assertTrue(nextGlobal != 0, "next reserves is zero");
        assertTrue(nextGlobal > prevGlobal, "reserves did not change");
    }

    // --- Remove Liquidity --- //

    function testFailR_LZeroLiquidityReverts() public {
        bytes memory data = Instructions.encodeRemoveLiquidity(0, __poolId, 1, 1, 0x00, 0x00);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testFailR_LNonExistentPoolReverts() public {
        bytes memory data = Instructions.encodeRemoveLiquidity(0, 42, 1, 1, 0x01, 0x01);
        bool success = forwarder.pass(data);
        assertTrue(!success);
    }

    function testR_LLowSlotLiquidityDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prev = _slots[__poolId][lo].totalLiquidity;

        data = Instructions.encodeRemoveLiquidity(0, __poolId, lo, hi, power, amount);
        success = forwarder.pass(data);

        uint256 next = _slots[__poolId][lo].totalLiquidity;
        assertTrue(next < prev);
    }

    function testR_LHighSlotLiquidityDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prev = _slots[__poolId][hi].totalLiquidity;

        data = Instructions.encodeRemoveLiquidity(0, __poolId, lo, hi, power, amount);
        success = forwarder.pass(data);

        uint256 next = _slots[__poolId][hi].totalLiquidity;
        assertTrue(next < prev);
    }

    function testR_LLowSlotLiquidityDeltaDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        int256 prev = getSlotLiquidityDelta(lo);

        data = Instructions.encodeRemoveLiquidity(0, __poolId, lo, hi, power, amount);
        success = forwarder.pass(data);

        int256 next = getSlotLiquidityDelta(lo);
        assertTrue(next < prev);
    }

    function testR_LHighSlotLiquidityDeltaIncreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        int256 prev = getSlotLiquidityDelta(hi);

        data = Instructions.encodeRemoveLiquidity(0, __poolId, lo, hi, power, amount);
        success = forwarder.pass(data);

        int256 next = getSlotLiquidityDelta(hi);
        assertTrue(next > prev);
    }

    function testR_LLowSlotInstantiatedChanges() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        bool prev = _slots[__poolId][lo].instantiated;

        data = Instructions.encodeRemoveLiquidity(0, __poolId, lo, hi, power, amount);
        success = forwarder.pass(data);

        bool next = _slots[__poolId][lo].instantiated;
        assertTrue(next != prev);
    }

    function testR_LHighSlotInstantiatedChanges() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        bool prev = _slots[__poolId][hi].instantiated;

        data = Instructions.encodeRemoveLiquidity(0, __poolId, lo, hi, power, amount);
        success = forwarder.pass(data);

        bool next = _slots[__poolId][hi].instantiated;
        assertTrue(next != prev);
    }

    function testR_LPositionTimestampUpdated() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint96 positionId = uint96(bytes12(abi.encodePacked(__poolId, loTick, hiTick)));
        uint256 prevPositionTimestamp = _positions[address(forwarder)][positionId].blockTimestamp;

        uint256 warpTimestamp = block.timestamp + 1;
        vm.warp(warpTimestamp);

        data = Instructions.encodeRemoveLiquidity(0, __poolId, loTick, hiTick, power, amount);
        success = forwarder.pass(data);

        uint256 nextPositionTimestamp = _positions[address(forwarder)][positionId].blockTimestamp;

        assertTrue(nextPositionTimestamp > prevPositionTimestamp && nextPositionTimestamp == warpTimestamp);
    }

    function testR_LPositionTotalLiquidityDecreases() public {
        int24 hiTick = DEFAULT_TICK;
        int24 loTick = DEFAULT_TICK - 256;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint96 positionId = uint96(bytes12(abi.encodePacked(__poolId, loTick, hiTick)));
        uint256 prevPositionLiquidity = _positions[address(forwarder)][positionId].totalLiquidity;

        data = Instructions.encodeRemoveLiquidity(0, __poolId, loTick, hiTick, power, amount);
        success = forwarder.pass(data);

        uint256 nextPositionLiquidity = _positions[address(forwarder)][positionId].totalLiquidity;

        assertTrue(nextPositionLiquidity < prevPositionLiquidity);
    }

    function testR_LGlobalAssetDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prev = _globalReserves[address(asset)];

        data = Instructions.encodeRemoveLiquidity(0, __poolId, lo, hi, power, amount);
        success = forwarder.pass(data);

        uint256 next = _globalReserves[address(asset)];
        assertTrue(next < prev, "reserves did not change");
    }

    function testR_LGlobalQuoteDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prev = _globalReserves[address(quote)];

        data = Instructions.encodeRemoveLiquidity(0, __poolId, lo, hi, power, amount);
        success = forwarder.pass(data);

        uint256 next = _globalReserves[address(quote)];
        assertTrue(next < prev, "reserves did not change");
    }

    // --- Stake Position --- //

    function testS_PPositionStakedUpdated() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint96 positionId = Instructions.encodePositionId(__poolId, lo, hi);

        bool prevPositionStaked = _positions[address(forwarder)][positionId].staked;

        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        bool nextPositionStaked = _positions[address(forwarder)][positionId].staked;

        assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        assertTrue(nextPositionStaked, "Position staked is not true.");
    }

    function testS_PSlotLowTickStakedLiquidityDeltaIncreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        int256 prevStakedLiquidityDelta = _slots[__poolId][lo].stakedLiquidityDelta;

        uint96 positionId = Instructions.encodePositionId(__poolId, lo, hi);
        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        int256 nextStakedLiquidityDelta = _slots[__poolId][lo].stakedLiquidityDelta;

        assertTrue(
            nextStakedLiquidityDelta > prevStakedLiquidityDelta,
            "Lo tick staked liquidity delta did not increase."
        );
    }

    function testS_PSlotHiTickStakedLiquidityDeltaDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        int256 prevStakedLiquidityDelta = _slots[__poolId][hi].stakedLiquidityDelta;

        uint96 positionId = Instructions.encodePositionId(__poolId, lo, hi);
        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        int256 nextStakedLiquidityDelta = _slots[__poolId][hi].stakedLiquidityDelta;

        assertTrue(
            nextStakedLiquidityDelta < prevStakedLiquidityDelta,
            "Hi tick staked liquidity delta did not decrease."
        );
    }

    function testS_PPoolStakedLiquidityUpdated() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint256 prevPoolStakedLiquidity = _pools[__poolId].stakedLiquidity;

        uint96 positionId = Instructions.encodePositionId(__poolId, lo, hi);
        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        uint256 nextPoolStakedLiquidity = _pools[__poolId].stakedLiquidity;

        if (lo <= _pools[__poolId].lastTick && hi > _pools[__poolId].lastTick) {
            assertTrue(nextPoolStakedLiquidity > prevPoolStakedLiquidity, "Pool staked liquidity did not increase.");
            assertTrue(
                nextPoolStakedLiquidity == _positions[address(forwarder)][positionId].totalLiquidity,
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

    function testU_PPositionStakedUpdated() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint96 positionId = Instructions.encodePositionId(__poolId, lo, hi);
        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        bool prevPositionStaked = _positions[address(forwarder)][positionId].staked;

        data = Instructions.encodeUnstakePosition(positionId);
        success = forwarder.pass(data);

        bool nextPositionStaked = _positions[address(forwarder)][positionId].staked;

        assertTrue(nextPositionStaked != prevPositionStaked, "Position staked did not update.");
        assertTrue(!nextPositionStaked, "Position staked is true.");
    }

    function testU_PSlotLowTickStakedLiquidityDeltaDecreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint96 positionId = Instructions.encodePositionId(__poolId, lo, hi);
        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        int256 prevStakedLiquidityDelta = _slots[__poolId][lo].stakedLiquidityDelta;

        data = Instructions.encodeUnstakePosition(positionId);
        success = forwarder.pass(data);

        int256 nextStakedLiquidityDelta = _slots[__poolId][lo].stakedLiquidityDelta;

        assertTrue(
            nextStakedLiquidityDelta < prevStakedLiquidityDelta,
            "Lo tick staked liquidity delta did not decrease."
        );
    }

    function testU_PSlotHiTickStakedLiquidityDeltaIncreases() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint96 positionId = Instructions.encodePositionId(__poolId, lo, hi);
        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        int256 prevStakedLiquidityDelta = _slots[__poolId][hi].stakedLiquidityDelta;

        data = Instructions.encodeUnstakePosition(positionId);
        success = forwarder.pass(data);

        int256 nextStakedLiquidityDelta = _slots[__poolId][hi].stakedLiquidityDelta;

        assertTrue(
            nextStakedLiquidityDelta > prevStakedLiquidityDelta,
            "Hi tick staked liquidity delta did not increase."
        );
    }

    function testU_PPoolStakedLiquidityUpdated() public {
        int24 lo = DEFAULT_TICK - 256;
        int24 hi = DEFAULT_TICK;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, lo, hi, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success);

        uint96 positionId = Instructions.encodePositionId(__poolId, lo, hi);
        data = Instructions.encodeStakePosition(positionId);
        success = forwarder.pass(data);

        uint256 prevPoolStakedLiquidity = _pools[__poolId].stakedLiquidity;

        data = Instructions.encodeUnstakePosition(positionId);
        success = forwarder.pass(data);

        uint256 nextPoolStakedLiquidity = _pools[__poolId].stakedLiquidity;

        if (lo <= _pools[__poolId].lastTick && hi > _pools[__poolId].lastTick) {
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

    function testFailC_PrSameTokensReverts() public {
        address token = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(token, token);
        bool success = forwarder.pass(data);
        assertTrue(!success, "forwarder call failed");
    }

    function testFailC_PrPairExistsReverts() public {
        bytes memory data = Instructions.encodeCreatePair(address(asset), address(quote));
        bool success = forwarder.pass(data);
    }

    function testFailC_PrLowerDecimalBoundsReverts() public {
        address token0 = address(new TestERC20("t", "t", 5));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
    }

    function testFailC_PrUpperDecimalBoundsReverts() public {
        address token0 = address(new TestERC20("t", "t", 24));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
    }

    function testC_PrPairNonceIncrementedReturnsOneAdded() public {
        uint256 prevNonce = _pairNonce;
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint256 nonce = _pairNonce;
        assertEq(nonce, prevNonce + 1);
    }

    function testC_PrFetchesPairIdReturnsNonZero() public {
        uint256 prevNonce = _pairNonce;
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint256 pairId = _getPairId[token0][token1];
        assertTrue(pairId != 0);
    }

    function testC_PrFetchesPairDataReturnsAddresses() public {
        uint256 prevNonce = _pairNonce;
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint16 pairId = _getPairId[token0][token1];
        Pair memory pair = _pairs[pairId];
        assertEq(pair.tokenBase, token0);
        assertEq(pair.tokenQuote, token1);
        assertEq(pair.decimalsBase, 18);
        assertEq(pair.decimalsQuote, 18);
    }

    // --- Create Curve --- //

    function testFailC_CuCurveExistsReverts() public {
        Curve memory curve = _curves[uint32(__poolId)]; // Existing curve from helper setup
        bytes memory data = Instructions.encodeCreateCurve(
            curve.sigma,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            curve.strike
        );
        bool success = forwarder.pass(data);
    }

    function testFailC_CuFeeParameterOutsideBoundsReverts() public {
        Curve memory curve = _curves[uint32(__poolId)]; // Existing curve from helper setup
        bytes memory data = Instructions.encodeCreateCurve(curve.sigma, curve.maturity, 5e4, curve.strike);
        bool success = forwarder.pass(data);
    }

    function testFailC_CuExpiringPoolZeroSigmaReverts() public {
        Curve memory curve = _curves[uint32(__poolId)]; // Existing curve from helper setup
        bytes memory data = Instructions.encodeCreateCurve(0, curve.maturity, uint16(1e4 - curve.gamma), curve.strike);
        bool success = forwarder.pass(data);
    }

    function testFailC_CuExpiringPoolZeroStrikeReverts() public {
        Curve memory curve = _curves[uint32(__poolId)]; // Existing curve from helper setup
        bytes memory data = Instructions.encodeCreateCurve(curve.sigma, curve.maturity, uint16(1e4 - curve.gamma), 0);
        bool success = forwarder.pass(data);
    }

    function testC_CuCurveNonceIncrementReturnsOne() public {
        uint256 prevNonce = _curveNonce;
        Curve memory curve = _curves[uint32(__poolId)]; // Existing curve from helper setup
        bytes memory data = Instructions.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            curve.strike
        );
        bool success = forwarder.pass(data);
        uint256 nextNonce = _curveNonce;
        assertEq(prevNonce, nextNonce - 1);
    }

    function testC_CuFetchesCurveIdReturnsNonZero() public {
        Curve memory curve = _curves[uint32(__poolId)]; // Existing curve from helper setup
        bytes memory data = Instructions.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            curve.strike
        );
        bytes32 rawCurveId = Decoder.toBytes32(
            abi.encodePacked(curve.sigma + 1, curve.maturity, uint16(1e4 - curve.gamma), curve.strike)
        );
        bool success = forwarder.pass(data);
        uint32 curveId = _getCurveIds[rawCurveId];
        assertTrue(curveId != 0);
    }

    function testC_CuFetchesCurveDataReturnsParametersSet() public {
        Curve memory curve = _curves[uint32(__poolId)]; // Existing curve from helper setup
        bytes memory data = Instructions.encodeCreateCurve(
            curve.sigma + 1,
            curve.maturity,
            uint16(1e4 - curve.gamma),
            curve.strike
        );
        bytes32 rawCurveId = Decoder.toBytes32(
            abi.encodePacked(curve.sigma + 1, curve.maturity, uint16(1e4 - curve.gamma), curve.strike)
        );
        bool success = forwarder.pass(data);
        uint32 curveId = _getCurveIds[rawCurveId];
        Curve memory newCurve = _curves[curveId];
        assertEq(newCurve.sigma, curve.sigma + 1);
        assertEq(newCurve.maturity, curve.maturity);
        assertEq(newCurve.gamma, curve.gamma);
        assertEq(newCurve.strike, curve.strike);
    }

    // --- Create Pool --- //

    function testFailC_PoZeroPriceParameterReverts() public {
        bytes memory data = Instructions.encodeCreatePool(1, 0);
        bool success = forwarder.pass(data);
    }

    function testFailC_PoExistentPoolReverts() public {
        bytes memory data = Instructions.encodeCreatePool(__poolId, 1);
        bool success = forwarder.pass(data);
    }

    function testFailC_PoZeroCurveIdReverts() public {
        bytes memory data = Instructions.encodeCreatePool(0x010000, 1);
        bool success = forwarder.pass(data);
    }

    function testFailC_PoZeroPairIdReverts() public {
        bytes memory data = Instructions.encodeCreatePool(0x000001, 1);
        bool success = forwarder.pass(data);
    }

    function testFailC_PoExpiringPoolExpiredReverts() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint16 pairId = _getPairId[token0][token1];

        Curve memory curve = _curves[uint32(__poolId)]; // Existing curve from helper setup
        data = Instructions.encodeCreateCurve(curve.sigma + 1, uint32(0), uint16(1e4 - curve.gamma), curve.strike);
        bytes32 rawCurveId = Decoder.toBytes32(
            abi.encodePacked(curve.sigma + 1, uint32(0), uint16(1e4 - curve.gamma), curve.strike)
        );
        success = forwarder.pass(data);

        uint32 curveId = _getCurveIds[rawCurveId];
        uint48 id = Instructions.encodePoolId(pairId, curveId);
        data = Instructions.encodeCreatePool(id, 1_000);
        success = forwarder.pass(data);
    }

    function testC_PoFetchesPoolDataReturnsNonZeroBlockTimestamp() public {
        address token0 = address(new TestERC20("t", "t", 18));
        address token1 = address(new TestERC20("t", "t", 18));
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        uint16 pairId = _getPairId[token0][token1];

        Curve memory curve = _curves[uint32(__poolId)]; // Existing curve from helper setup
        data = Instructions.encodeCreateCurve(curve.sigma + 1, curve.maturity, uint16(1e4 - curve.gamma), curve.strike);
        bytes32 rawCurveId = Decoder.toBytes32(
            abi.encodePacked(curve.sigma + 1, curve.maturity, uint16(1e4 - curve.gamma), curve.strike)
        );
        success = forwarder.pass(data);

        uint32 curveId = _getCurveIds[rawCurveId];
        uint48 id = Instructions.encodePoolId(pairId, curveId);
        data = Instructions.encodeCreatePool(id, 1_000);
        success = forwarder.pass(data);

        uint256 time = _pools[id].blockTimestamp;
        assertTrue(time != 0);
    }
}
