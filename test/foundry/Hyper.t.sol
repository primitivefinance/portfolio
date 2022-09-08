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
}

/** Bubbles up custom errors. */
contract Forwarder is Test {
    HyperTester public hyper;

    constructor(address prototype) {
        hyper = HyperTester(payable(prototype));
    }

    // Assumes Hyper calls this, for testing only.
    function pass(bytes calldata data) external returns (bool) {
        try hyper.process(data) {} catch (bytes memory reason) {
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

contract TestHyperSingle is StandardHelpers, Test {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    HyperTester public __hyper;
    WETH public weth;
    Forwarder public forwarder;
    TestERC20 public asset;
    TestERC20 public quote;
    uint48 __poolId;

    function setUp() public {
        weth = new WETH();
        __hyper = new HyperTester(address(weth));
        (asset, quote) = handlePrerequesites();
    }

    function testHyper() public {
        HyperPool memory p = __hyper.pools(1);
    }

    function handlePrerequesites() public returns (TestERC20 token0, TestERC20 token1) {
        // Set the forwarder.
        forwarder = new Forwarder(address(__hyper));

        // 1. Two token contracts.
        token0 = new TestERC20("token0", "token0 name", 18);
        token1 = new TestERC20("token1", "token1 name", 18);

        // 2. Create pair
        bytes memory data = Instructions.encodeCreatePair(address(token0), address(token1));
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint16 pairId = uint16(__hyper.getPairNonce());

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

        uint32 curveId = uint32(__hyper.getCurveNonce());

        __poolId = Instructions.encodePoolId(pairId, curveId);

        // 4. Create pool
        data = Instructions.encodeCreatePool(__poolId, DEFAULT_PRICE);
        success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        assertEq(__hyper.doesPoolExist(__poolId), true);
        assertEq(__hyper.pools(__poolId).lastTick != 0, true);
        assertEq(__hyper.pools(__poolId).liquidity == 0, true);
    }
}
