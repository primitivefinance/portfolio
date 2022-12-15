pragma solidity 0.8.13;

import "../Hyper.sol";
import "../interfaces/IHyper.sol";
import {HyperPool, Pair, Curve} from "../EnigmaTypes.sol";

struct LoadedParameters {
    uint48 poolId;
    Curve curve;
    Pair pair;
}

uint128 constant DEFAULT_STRIKE = 1e19;
uint24 constant DEFAULT_SIGMA = 1e4;
uint32 constant DEFAULT_MATURITY = 31556953; // adds 1
uint16 constant DEFAULT_FEE = 100;
uint32 constant DEFAULT_GAMMA = 9900;
uint32 constant DEFAULT_PRIORITY_GAMMA = 9950;
uint128 constant DEFAULT_QUOTE_RESERVE = 3085375387260000000;
uint128 constant DEFAULT_ASSET_RESERVE = 308537538726000000;
uint128 constant DEFAULT_LIQUIDITY = 1e18;
uint128 constant DEFAULT_PRICE = 10e18;
int24 constant DEFAULT_TICK = int24(23027); // 10e18, rounded up! pay attention

interface IHyperStruct {
    function curves(uint32 curveId) external view returns (Curve memory);

    function pairs(uint16 pairId) external view returns (Pair memory);

    function positions(address owner, uint96 positionId) external view returns (HyperPosition memory);

    function pools(uint48 poolId) external view returns (HyperPool memory);

    function globalReserves(address token) external view returns (uint256);
}

contract HyperCaller {
    error InvalidToken(address);

    Hyper public hyper;

    constructor(address hyper_) {
        hyper = Hyper(payable(hyper_));
    }

    LoadedParameters public loaded;

    /**
     * @notice Loads a pool with default parameters.
     */
    function loadDefaultPool(address token0, address token1) public {
        loadPool(
            token0,
            token1,
            DEFAULT_STRIKE,
            DEFAULT_SIGMA,
            DEFAULT_MATURITY,
            DEFAULT_GAMMA,
            DEFAULT_PRIORITY_GAMMA
        );
    }

    /**
     * @notice Fetches a pool and loads it into this contract's state.
     * @dev Creates a pool if does not exist.
     */
    function loadPool(
        address token0,
        address token1,
        uint128 strike,
        uint24 sigma,
        uint32 maturity,
        uint32 gamma,
        uint32 priorityGamma
    ) public {
        (Pair memory pair, uint16 pairId) = createPair(token0, token1);
        (Curve memory curve, uint32 curveId) = createCurve(
            strike,
            sigma,
            maturity,
            uint16(1e4 - gamma),
            uint16(1e4 - priorityGamma)
        );
        uint128 price = 10e18;
        (, uint48 poolId) = createPool(pairId, curveId, price);
        loaded = LoadedParameters({poolId: poolId, curve: curve, pair: pair});
    }

    /**
     * @notice Creates a pool using an already created pair and curve.
     */
    function createPool(uint16 pairId, uint32 curveId, uint128 price) public returns (HyperPool memory, uint48) {
        uint48 poolId = uint48(bytes6(abi.encodePacked(pairId, curveId)));
        HyperPool memory pool = IHyperStruct(address(hyper)).pools(poolId);
        if (pool.blockTimestamp == 0) send(CPU.encodeCreatePool(poolId, price));
        return (pool, poolId);
    }

    function createPair(address token0, address token1) public returns (Pair memory, uint16) {
        uint16 pairId = hyper.getPairId(token0, token1);
        if (pairId == 0) {
            send(CPU.encodeCreatePair(token0, token1));
            pairId = uint16(hyper.getPairNonce());
        }
        Pair memory pair = IHyperStruct(address(hyper)).pairs(pairId);
        return (pair, pairId);
    }

    function createCurve(
        uint128 strike,
        uint24 sigma,
        uint32 maturity,
        uint16 fee,
        uint16 priorityFee
    ) public returns (Curve memory, uint32) {
        bytes32 rawCurveId = bytes32(abi.encodePacked(sigma, maturity, fee, priorityFee, strike));
        uint32 curveId = hyper.getCurveId(rawCurveId);
        if (curveId == 0) {
            send(CPU.encodeCreateCurve(sigma, maturity, fee, priorityFee, strike));
            curveId = uint32(hyper.getCurveNonce());
        }
        Curve memory curve = IHyperStruct(address(hyper)).curves(curveId);
        return (curve, curveId);
    }

    function allocate(uint256 amount) external {
        uint8 useMax = 0;
        bytes memory data = CPU.encodeAllocate(
            useMax,
            loaded.poolId,
            uint8(0),
            asm.toUint128(amount)
        ); /* abi.encodePacked(
            CPU.pack(bytes1(useMax), CPU.ALLOCATE),
            loaded.poolId,
            uint8(0),
            uint128(amount)
        ); */
        send(data);
    }

    function unallocate(uint256 amount) external {
        uint8 useMax = 0;
        bytes memory data = abi.encodePacked(
            CPU.pack(bytes1(useMax), CPU.UNALLOCATE),
            loaded.poolId,
            uint8(0),
            uint128(amount)
        );
        send(data);
    }

    function swapExactIn(address token, uint256 amountIn, uint256 limitPrice) external {
        Pair memory pair = loaded.pair;
        uint8 direction = pair.tokenAsset == token ? 0 : pair.tokenQuote == token ? 1 : type(uint8).max;
        if (direction == type(uint8).max) revert InvalidToken(token);

        _swap(0, loaded.poolId, amountIn, limitPrice, direction);
    }

    function _swap(uint8 useMax, uint48 poolId, uint256 input, uint256 limit, uint8 direction) internal {
        // pointer to the beginning of the limit price amount.
        // 0x0a = 10 and 0x0f = 15, so at the 25th byte is when the next amount starts
        // 1 bytes useMax and instruction + 6 poolId + 1 pointer + 17 input amount = 25
        uint8 pointer = 0x0a + 0x0f;
        bytes memory data = abi.encodePacked(
            CPU.pack(bytes1(useMax), CPU.SWAP),
            poolId,
            pointer,
            uint8(0),
            uint128(input),
            uint8(0),
            uint128(limit),
            direction
        );
        send(data);
    }

    /**
     * @notice Low level call to Hyper, which receives the payload as msg.data and processes it.
     */
    function send(bytes memory data) internal {
        (bool success, bytes memory reason) = address(hyper).call(data);
        if (!success) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
        require(success, "Failed hyper call");
    }
}
