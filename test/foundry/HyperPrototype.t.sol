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
    uint48 poolId;

    function setUp() public {
        (asset, quote) = handlePrerequesites();
    }

    function process(bytes calldata data) external {
        uint48 poolId_;
        bytes1 instruction = bytes1(data[0] & 0x0f);
        if (instruction == Instructions.UNKNOWN) revert UnknownInstruction();

        if (instruction == Instructions.ADD_LIQUIDITY) {
            (poolId_, ) = _addLiquidity(data);
        } else if (instruction == Instructions.REMOVE_LIQUIDITY) {
            (poolId_, , ) = _removeLiquidity(data);
        } else if (instruction == Instructions.SWAP) {
            (poolId_, ) = _swapExactForExact(data);
        } else if (instruction == Instructions.CREATE_POOL) {
            (poolId_, , ) = _createPool(data);
        } else if (instruction == Instructions.CREATE_CURVE) {
            _createCurve(data);
        } else if (instruction == Instructions.CREATE_PAIR) {
            _createPair(data);
        } else {
            revert UnknownInstruction();
        }
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
        uint16 pairId = uint16(_pairNonce);

        // 3. Create curve
        data = Instructions.encodeCreateCurve(
            DEFAULT_SIGMA,
            DEFAULT_MATURITY,
            uint16(1e4 - DEFAULT_GAMMA),
            DEFAULT_STRIKE
        );
        success = forwarder.pass(data);
        uint32 curveId = uint32(_curveNonce);

        poolId = Instructions.encodePoolId(pairId, curveId);
        console.log("pool id", poolId);

        // 4. Create pool
        data = Instructions.encodeCreatePool(poolId, DEFAULT_PRICE, DEFAULT_LIQUIDITY);
        forwarder.pass(data);

        assertEq(_doesPoolExist(poolId), true);
        assertEq(_pools[poolId].lastTick != 0, true);
        assertEq(_pools[poolId].liquidity == 0, true);
    }

    function testCountEndZeroes() public {
        uint256 amount = 1000;
        uint256 zeroes = uint256(Decoder.countEndZeroes(amount));
        console.log(zeroes);
    }

    function testDefaultAddLiquidity() public {
        uint8 power = uint8(0x06);
        uint8 amount = uint8(0x04);
        bytes memory data = Instructions.encodeAddLiquidity(
            uint8(0),
            poolId,
            DEFAULT_TICK - 4,
            DEFAULT_TICK + 4,
            power,
            amount
        );

        forwarder.pass(data);

        uint256 globalR1 = _globalReserves[address(asset)];
        assertEq(globalR1 > 0, true);
        console.log("Global R1 after adding liq", globalR1);
    }

    function testFailAttemptToCallNonExistentPool() public {
        uint48 randomPoolId = uint48(12825624);
        bytes memory data = Instructions.encodeAddLiquidity(
            uint8(0),
            randomPoolId,
            int24(0),
            int24(0),
            uint8(0),
            uint8(0)
        );
        forwarder.pass(data);
    }

    function testSlick() public {
        assertEq(_doesPoolExist(poolId), true);
        bool perpetual = (0 | 1 | 0) == 0;
        assembly {
            perpetual := iszero(or(0, or(1, 0))) // ((strike == 0 && sigma == 0) && maturity == 0)
        }
        assertEq(perpetual, false);
    }

    function testComputePriceWithTickFn() public {
        uint256 price = __computePriceGivenTickIndex(int24(512));
        int24 tick = __computeTickIndexGivenPrice(price);
        assertEq(tick, int24(512));
    }

    /**
        e^(ln(1.0001) * tickIndex) = price

        ln(price) = ln(1.0001) * tickIndex

        tickIndex = ln(price) / ln(1.0001)
     */
    function __computePriceGivenTickIndex(int24 tickIndex) internal view returns (uint256 price) {
        int256 tickWad = int256(tickIndex) * int256(FixedPointMathLib.WAD);
        price = uint256(FixedPointMathLib.powWad(1_0001e14, tickWad));
    }

    function __computeTickIndexGivenPrice(uint256 priceWad) internal view returns (int24 tick) {
        uint256 numerator = uint256(int256(priceWad).lnWad());
        uint256 denominator = uint256(int256(1_0001e14).lnWad());
        uint256 val = numerator / denominator + 1;
        tick = int24(int256((numerator)) / int256(denominator) + 1);
    }
}
