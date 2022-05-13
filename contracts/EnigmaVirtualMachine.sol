pragma solidity ^0.8.0;

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

contract EnigmaVirtualMachine is EnigmaDataStructures {
    // --- Internal --- //

    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }

    // ----- Enigma Storage ---- //

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
    // Pool id -> Pool Data Structure.
    mapping(uint32 => Pool) public pools;
    /// Pool Id -> Curve.
    mapping(uint32 => Curve) public curves;
    // Pool id -> Pair of a Pool.
    mapping(uint16 => Pair) public pairs;
    // Token -> Touched Flag. Stored temporary to signal which token reserves were tapped.
    mapping(address => bool) public addressCache;
    // Token -> Physical Reserves.
    mapping(address => uint256) public globalReserves;
    // User -> Pool id -> Liquidity Positions.
    mapping(address => mapping(uint32 => Position)) public positions;
    // User -> Token -> Interal Balance.
    mapping(address => mapping(address => uint256)) public balances;

    uint256 public constant PERCENTAGE = 1e4;
    uint256 public constant PRECISION = 1e18;
}
