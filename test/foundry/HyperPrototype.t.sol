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
        data = Instructions.encodeCreatePool(__poolId, DEFAULT_PRICE, DEFAULT_LIQUIDITY);
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

    // --- Helpers --- //

    function getTickLiquidity(int24 tick) public view returns (uint256) {
        return _slots[tick].totalLiquidity;
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

    function testA_LLowTickLiquidityIncrease() public {
        int24 loTick = DEFAULT_TICK;
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 liquidity = getTickLiquidity(loTick);
        assertEq(liquidity, 10);
    }

    function testA_LHighTickLiquidityIncrease() public {
        int24 loTick = DEFAULT_TICK;
        int24 hiTick = DEFAULT_TICK + 2;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, loTick, hiTick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        uint256 liquidity = getTickLiquidity(hiTick);
        assertEq(liquidity, 10);
    }

    function testA_LLowTickInstantiatedChange() public {
        int24 tick = DEFAULT_TICK;
        bool instantiated = _slots[tick].instantiated;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, tick, tick + 2, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        bool change = _slots[tick].instantiated;
        assertTrue(instantiated != change);
    }

    function testA_LHighTickInstantiatedChange() public {
        int24 tick = DEFAULT_TICK;
        bool instantiated = _slots[tick].instantiated;
        uint8 amount = 0x01;
        uint8 power = 0x01;
        bytes memory data = Instructions.encodeAddLiquidity(0, __poolId, tick - 2, tick, power, amount);
        bool success = forwarder.pass(data);
        assertTrue(success, "forwarder call failed");

        bool change = _slots[tick].instantiated;
        assertTrue(instantiated != change);
    }

    function testA_LGlobalAssetIncrease() public {
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

    function testA_LGlobalQuoteIncrease() public {
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
        bytes memory data = Instructions.encodeCreatePool(1, 0, 1);
        bool success = forwarder.pass(data);
    }

    function testFailC_PoExistentPoolReverts() public {
        bytes memory data = Instructions.encodeCreatePool(__poolId, 1, 1);
        bool success = forwarder.pass(data);
    }

    function testFailC_PoZeroCurveIdReverts() public {
        bytes memory data = Instructions.encodeCreatePool(0x010000, 1, 1);
        bool success = forwarder.pass(data);
    }

    function testFailC_PoZeroPairIdReverts() public {
        bytes memory data = Instructions.encodeCreatePool(0x000001, 1, 1);
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
        data = Instructions.encodeCreatePool(id, 1_000, 1_000);
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
        data = Instructions.encodeCreatePool(id, 1_000, 1_000);
        success = forwarder.pass(data);

        uint256 time = _pools[id].blockTimestamp;
        assertTrue(time != 0);
    }
}
