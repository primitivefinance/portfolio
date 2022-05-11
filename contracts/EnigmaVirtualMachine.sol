pragma solidity ^0.8.0;

interface EnigmaDataStructures {
    struct Tokens {
        address tokenBase;
        uint16 decimalsBase;
        address tokenQuote;
        uint16 decimalsQuote;
    }

    struct Pool {
        uint128 internalBase;
        uint128 internalQuote;
        uint128 internalLiquidity;
        uint128 blockTimestamp;
    }

    struct Position {
        uint256 liquidity;
        uint128 blockTimestamp;
    }
}

contract EnigmaVirtualMachine is EnigmaDataStructures {
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

    // ----- Enigma State ----- //
    // Pool id -> Pool Data Structure.
    mapping(uint8 => Pool) public pools;
    // Pool id -> Tokens of a Pool.
    mapping(uint8 => Tokens) public tokens;
    // Token -> Touched Flag. Stored temporary to signal which token reserves were tapped.
    mapping(address => bool) public addressCache;
    // Token -> Physical Reserves.
    mapping(address => uint256) public globalReserves;
    // User -> Pool id -> Liquidity Positions.
    mapping(address => mapping(uint8 => Position)) public positions;
    // User -> Token -> Interal Balance.
    mapping(address => mapping(address => uint256)) public balances;

    // --- Internal --- //

    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }
}
