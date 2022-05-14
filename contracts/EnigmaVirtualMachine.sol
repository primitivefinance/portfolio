pragma solidity ^0.8.0;

import "./interfaces/IEnigma.sol";
import "./interfaces/IERC20.sol";
import "./libraries/Decoder.sol";
import "./libraries/Instructions.sol";

/// @title Enigma Virtual Machine
/// @notice Defines the possible instruction set which must be processed in a higher-level compiler.
/// @dev Implements low-level `balanceOf`, re-entrancy guard, instruction constants and state.
abstract contract EnigmaVirtualMachine is IEnigma {
    // --- Reentrancy --- //
    modifier lock() {
        if (locked != 1) revert LockedError();

        locked = 2;
        _;
        locked = 1;
    }

    // --- Internal --- //
    /// @dev Gas optimized `balanceOf` method.
    function _balanceOf(address token) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        if (!success || data.length != 32) revert BalanceError();
        return abi.decode(data, (uint256));
    }

    /// @dev Overridable in tests.
    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }

    // --- Instructions --- //
    bytes1 public constant UNKNOWN = 0x00;
    bytes1 public constant ADD_LIQUIDITY = 0x01;
    bytes1 public constant ADD_LIQUIDITY_ETH = 0x02;
    bytes1 public constant REMOVE_LIQUIDITY = 0x03;
    bytes1 public constant REMOVE_LIQUIDITY_ETH = 0x04;
    bytes1 public constant SWAP_EXACT_TOKENS_FOR_TOKENS = 0x05;
    bytes1 public constant SWAP_TOKENS_FOR_EXACT_TOKENS = 0x06;
    bytes1 public constant SWAP_EXACT_ETH_FOR_TOKENS = 0x07;
    bytes1 public constant SWAP_TOKENS_FOR_EXACT_ETH = 0x08;
    bytes1 public constant SWAP_EXACT_TOKENS_FOR_ETH = 0x09;
    bytes1 public constant SWAP_ETH_FOR_EXACT_TOKENS = 0x0A;
    bytes1 public constant CREATE_POOL = 0x0B;
    bytes1 public constant CREATE_PAIR = 0x0C;
    bytes1 public constant CREATE_CURVE = 0x0D;
    bytes1 public constant INSTRUCTION_JUMP = 0xAA;
    // --- State --- //
    /// @dev Pool id -> Pair of a Pool.
    mapping(uint16 => Pair) public pairs;
    /// @dev Pool id -> Pool Data Structure.
    mapping(uint48 => Pool) public pools;
    /// @dev Pool id -> Curve Data Structure stores parameters.
    mapping(uint32 => Curve) public curves;
    /// @dev Token -> Touched Flag. Stored temporary to signal which token reserves were tapped.
    mapping(address => bool) public addressCache;
    /// @dev Raw curve parameters packed into bytes32 mapped onto a Curve id when it was deployed.
    mapping(bytes32 => uint32) public getCurveIds;
    /// @dev Token -> Physical Reserves.
    mapping(address => uint256) public globalReserves;
    /// @dev Base Token -> Quote Token -> Pair id
    mapping(address => mapping(address => uint16)) public getPairId;
    /// @dev User -> Token -> Interal Balance.
    mapping(address => mapping(address => uint256)) public balances;
    /// @dev User -> Pool id -> Liquidity Positions.
    mapping(address => mapping(uint48 => Position)) public positions;
    /// @dev Reentrancy guard initialized to state
    uint256 private locked = 1;
    /// @dev A value incremented by one on pair creation. Reduces calldata.
    uint256 public pairNonce;
    /// @dev A value incremented by one on curve creation. Reduces calldata.
    uint256 public curveNonce;
    /// @dev Amount of seconds of available time to swap past maturity of a pool.
    uint256 public constant BUFFER = 300;
    /// @dev Constant amount of basis points. All percentage values are integers in basis points.
    uint256 public constant PERCENTAGE = 1e4;
    /// @dev Constant amount of 1 ether. All liquidity values have 18 decimals.
    uint256 public constant PRECISION = 1e18;
    /// @dev Maximum pool fee.
    uint256 public constant MAX_POOL_FEE = 1e3;
    /// @dev Used to compute the amount of liquidity to burn on creating a pool.
    uint256 public constant MIN_LIQUIDITY_FACTOR = 6;
}
