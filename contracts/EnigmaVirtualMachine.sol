pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

import "./libraries/Instructions.sol";
import "./libraries/Decoder.sol";

interface EnigmaDataStructures {
    struct Pair {
        address tokenBase;
        uint8 decimalsBase;
        address tokenQuote;
        uint8 decimalsQuote;
    }

    struct Pool {
        uint128 internalBase;
        uint128 internalQuote;
        uint128 internalLiquidity;
        uint128 blockTimestamp;
    }

    struct Position {
        uint128 liquidity;
        uint128 blockTimestamp;
    }

    struct Curve {
        uint128 strike;
        uint24 sigma;
        uint32 maturity;
        uint32 gamma;
    }
}

interface EnigmaErrors {
    error BalanceError();
}

contract EnigmaVirtualMachine is EnigmaDataStructures, EnigmaErrors {
    // --- Internal --- //
    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }

    function _balanceOf(address token) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        if (!success || data.length != 32) revert BalanceError();
        return abi.decode(data, (uint256));
    }

    // ----- Reentrancy ----- //
    error LockedError();
    modifier lock() {
        if (locked != 1) revert LockedError();

        locked = 2;
        _;
        locked = 1;
    }

    // ----- Enigma Opcodes ----- //
    bytes1 public constant UNKNOWN = bytes1(0x00);
    bytes1 public constant ADD_LIQUIDITY = bytes1(0x01);
    bytes1 public constant ADD_LIQUIDITY_ETH = bytes1(0x02);
    bytes1 public constant REMOVE_LIQUIDITY = bytes1(0x03);
    bytes1 public constant REMOVE_LIQUIDITY_ETH = bytes1(0x04);
    bytes1 public constant SWAP_EXACT_TOKENS_FOR_TOKENS = bytes1(0x05);
    bytes1 public constant SWAP_TOKENS_FOR_EXACT_TOKENS = bytes1(0x06);
    bytes1 public constant SWAP_EXACT_ETH_FOR_TOKENS = bytes1(0x07);
    bytes1 public constant SWAP_TOKENS_FOR_EXACT_ETH = bytes1(0x08);
    bytes1 public constant SWAP_EXACT_TOKENS_FOR_ETH = bytes1(0x09);
    bytes1 public constant SWAP_ETH_FOR_EXACT_TOKENS = bytes1(0x0A);
    bytes1 public constant CREATE_POOL = bytes1(0x0B);
    bytes1 public constant CREATE_PAIR = bytes1(0x0C);
    bytes1 public constant CREATE_CURVE = bytes1(0x0D);

    // ----- Enigma State ----- //
    // Pool id -> Pair of a Pool.
    mapping(uint16 => Pair) public pairs;
    // Pool id -> Pool Data Structure.
    mapping(uint48 => Pool) public pools;
    /// Pool id -> Curve.
    mapping(uint32 => Curve) public curves;
    // Token -> Touched Flag. Stored temporary to signal which token reserves were tapped.
    mapping(address => bool) public addressCache;
    // Raw curve parameters packed into bytes32 mapped onto a Curve id when it was deployed.
    mapping(bytes32 => uint32) public getCurveIds;
    // Token -> Physical Reserves.
    mapping(address => uint256) public globalReserves;
    // Base Token -> Quote Token -> Pair id
    mapping(address => mapping(address => uint16)) public getPairId;
    // User -> Token -> Interal Balance.
    mapping(address => mapping(address => uint256)) public balances;
    // User -> Pool id -> Liquidity Positions.
    mapping(address => mapping(uint48 => Position)) public positions;
    /// @dev Reentrancy guard initialized to state
    uint256 private locked = 1;
    /// @dev A value incremented by one on pair creation. Reduces calldata.
    uint256 public pairNonce;
    /// @dev A value incremented by one on curve creation. Reduces calldata.
    uint256 public curveNonce;
    /// @dev Constant amount of basis points. All percentage values are integers in basis points.
    uint256 public constant PERCENTAGE = 1e4;
    /// @dev Constant amount of 1 ether. All liquidity values have 18 decimals.
    uint256 public constant PRECISION = 1e18;
    /// @dev Used to compute the amount of liquidity to burn on creating a pool.
    uint256 public constant MIN_LIQUIDITY_FACTOR = 6;
}
