// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "solmate/utils/FixedPointMathLib.sol";

import "./EnigmaTypesPrototype.sol";

import "../interfaces/IWETH.sol";
import "../interfaces/IEnigma.sol";
import "../interfaces/IERC20.sol";
import "../libraries/Decoder.sol";
import "../libraries/Instructions.sol";
import "../libraries/SafeCast.sol";

function dangerousTransferETH(address to, uint256 value) {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH transfer error");
}

/// @title Enigma Virtual Machine.
/// @notice Stores the state of the Enigma with functions to change state.
/// @dev Implements low-level internal virtual functions, re-entrancy guard and state.
abstract contract EnigmaVirtualMachinePrototype is IEnigma {
    using SafeCast for uint256;
    // --- Reentrancy --- //
    modifier lock() {
        if (locked != 1) revert LockedError();

        locked = 2;
        _;
        locked = 1;
    }

    // --- Constructor --- //

    constructor(address weth) {
        WETH = weth;
    }

    // --- View --- //

    function _checkJitLiquidity(
        address account,
        uint48 poolId,
        int24 loTick,
        int24 hiTick
    ) internal view virtual returns (uint256 distance, uint256 timestamp) {
        uint96 positionId = uint96(bytes12(abi.encodePacked(poolId, loTick, hiTick)));
        uint256 previous = _positions[account][positionId].blockTimestamp;
        timestamp = _blockTimestamp();
        distance = timestamp - previous;
    }

    // --- Internal --- //
    /// @dev Must be implemented by the highest level contract.
    /// @notice Processing logic for instructions.
    function _process(bytes calldata data) internal virtual;

    /// @notice First byte should always be the INSTRUCTION_JUMP Enigma code.
    /// @dev Expects a special encoding method for multiple instructions.
    /// @param data Includes opcode as byte at index 0. First byte should point to next instruction.
    /// @custom:security Critical. Processes multiple instructions. Data must be encoded perfectly.
    function _jumpProcess(bytes calldata data) internal {
        uint8 length = uint8(data[1]);
        uint8 pointer = JUMP_PROCESS_START_POINTER; // note: [opcode, length, pointer, ...instruction, pointer, ...etc]
        uint256 start;

        // For each instruction set...
        for (uint256 i; i != length; ++i) {
            // Start at the index of the first byte of the next instruction.
            start = pointer;

            // Set the new pointer to the next instruction, located at the pointer.
            pointer = uint8(data[pointer]);

            // The `start:` includes the pointer byte, while the `:end` `pointer` is excluded.
            if (pointer > data.length) revert JumpError(pointer);
            bytes calldata instruction = data[start:pointer];

            // Process the instruction.
            _process(instruction[1:]); // note: Removes the pointer to the next instruction.
        }
    }

    /// @dev Gas optimized `balanceOf` method.
    function _balanceOf(address token, address account) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, account)
        );
        if (!success || data.length != 32) revert BalanceError();
        return abi.decode(data, (uint256));
    }

    /// @dev Overridable in tests.
    function _blockTimestamp() internal view virtual returns (uint128) {
        return uint128(block.timestamp);
    }

    /// @dev Overridable in tests.
    function _liquidityPolicy() internal view virtual returns (uint256) {
        return JUST_IN_TIME_LIQUIDITY_POLICY;
    }

    // --- Wrapped Ether --- //

    function _wrap() internal virtual {
        IWETH(WETH).deposit{value: msg.value}();
    }

    function _dangerousUnwrap(address to, uint256 amount) internal virtual {
        IWETH(WETH).withdraw(amount);

        // Marked as dangerous because it makes an external call to the `to` address.
        dangerousTransferETH(to, amount);
    }

    // --- Global --- //

    /// @dev Most important function because it manages the solvency of the Engima.
    /// @custom:security Critical. Global balances of tokens are compared with the actual `balanceOf`.
    function _increaseGlobal(address token, uint256 amount) internal {
        _globalReserves[token] += amount;
        emit IncreaseGlobal(token, amount);
    }

    /// @dev Equally important to `_increaseGlobal`.
    /// @custom:security Critical. Same as above. Implicitly reverts on underflow.
    function _decreaseGlobal(address token, uint256 amount) internal {
        _globalReserves[token] -= amount;
        emit DecreaseGlobal(token, amount);
    }

    // --- Positions --- //

    function _updatePositionFees(
        HyperPosition storage pos,
        uint48 poolId,
        uint256 feeGrowthInsideAsset,
        uint256 feeGrowthInsideQuote
    ) internal {
        uint256 tokensOwedAsset = FixedPointMathLib.divWadDown(
            feeGrowthInsideAsset - pos.feeGrowthInsideAssetLast,
            _pools[poolId].liquidity
        );

        uint256 tokensOwedQuote = FixedPointMathLib.divWadDown(
            feeGrowthInsideQuote - pos.feeGrowthInsideQuoteLast,
            _pools[poolId].liquidity
        );

        pos.feeGrowthInsideAssetLast = feeGrowthInsideAsset;
        pos.feeGrowthInsideQuoteLast = feeGrowthInsideQuote;

        pos.tokensOwedAsset += tokensOwedAsset;
        pos.tokensOwedQuote += tokensOwedQuote;
    }

    /// @dev Assumes the position is properly allocated to an account by the end of the transaction.
    /// @custom:security High. Only method of increasing the liquidity held by accounts.
    function _increasePosition(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint256 deltaLiquidity
    ) internal {
        uint96 positionId = uint96(bytes12(abi.encodePacked(poolId, loTick, hiTick)));

        HyperPosition storage pos = _positions[msg.sender][positionId];

        if (pos.totalLiquidity == 0) {
            pos.loTick = loTick;
            pos.hiTick = hiTick;
        }
        pos.totalLiquidity += deltaLiquidity.toUint128();
        pos.blockTimestamp = _blockTimestamp();

        (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) = getFeeGrowthInside(
            poolId,
            hiTick,
            loTick,
            _pools[poolId].lastTick,
            _pools[poolId].feeGrowthGlobalAsset,
            _pools[poolId].feeGrowthGlobalQuote
        );

        _updatePositionFees(pos, poolId, feeGrowthInsideAsset, feeGrowthInsideQuote);

        emit IncreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    /// @dev Equally important as `_increasePosition`.
    /// @custom:security Critical. Includes the JIT liquidity check. Implicitly reverts on liquidity underflow.
    function _decreasePosition(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint256 deltaLiquidity
    ) internal {
        uint96 positionId = uint96(bytes12(abi.encodePacked(poolId, loTick, hiTick)));

        HyperPosition storage pos = _positions[msg.sender][positionId];

        pos.totalLiquidity -= deltaLiquidity.toUint128();
        pos.blockTimestamp = _blockTimestamp();

        (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) = getFeeGrowthInside(
            poolId,
            hiTick,
            loTick,
            _pools[poolId].lastTick,
            _pools[poolId].feeGrowthGlobalAsset,
            _pools[poolId].feeGrowthGlobalQuote
        );

        _updatePositionFees(pos, poolId, feeGrowthInsideAsset, feeGrowthInsideQuote);

        emit DecreasePosition(msg.sender, poolId, deltaLiquidity);
    }

    /// @dev Reverts if liquidity was allocated within time elapsed in seconds returned by `_liquidityPolicy`.
    /// @custom:security High. Must be used in place of `_decreasePosition` in most scenarios.
    function _decreasePositionCheckJit(
        uint48 poolId,
        int24 loTick,
        int24 hiTick,
        uint256 deltaLiquidity
    ) internal {
        (uint256 distance, uint256 timestamp) = _checkJitLiquidity(msg.sender, poolId, loTick, hiTick);
        if (_liquidityPolicy() > distance) revert JitLiquidity(distance);

        _decreasePosition(poolId, loTick, hiTick, deltaLiquidity);
    }

    function getFeeGrowthInside(
        uint48 poolId,
        int24 hi,
        int24 lo,
        int24 current,
        uint256 feeGrowthGlobalAsset,
        uint256 feeGrowthGlobalQuote
    ) internal view returns (uint256 feeGrowthInsideAsset, uint256 feeGrowthInsideQuote) {
        HyperSlot storage hiTick = _slots[poolId][hi];
        HyperSlot storage loTick = _slots[poolId][lo];

        uint256 feeGrowthBelowAsset;
        uint256 feeGrowthBelowQuote;

        if (current >= lo) {
            feeGrowthBelowAsset = loTick.feeGrowthOutsideAsset;
            feeGrowthBelowQuote = loTick.feeGrowthOutsideQuote;
        } else {
            feeGrowthBelowAsset = feeGrowthGlobalAsset - loTick.feeGrowthOutsideAsset;
            feeGrowthBelowQuote = feeGrowthGlobalQuote - loTick.feeGrowthOutsideQuote;
        }

        uint256 feeGrowthAboveAsset;
        uint256 feeGrowthAboveQuote;
        if (current < hi) {
            feeGrowthAboveAsset = hiTick.feeGrowthOutsideAsset;
            feeGrowthAboveQuote = hiTick.feeGrowthOutsideQuote;
        } else {
            feeGrowthAboveAsset = feeGrowthGlobalAsset - hiTick.feeGrowthOutsideAsset;
            feeGrowthAboveQuote = feeGrowthGlobalQuote - hiTick.feeGrowthOutsideQuote;
        }

        feeGrowthInsideAsset = feeGrowthGlobalAsset - feeGrowthBelowAsset - feeGrowthAboveAsset;
        feeGrowthInsideQuote = feeGrowthGlobalQuote - feeGrowthBelowQuote - feeGrowthAboveQuote;
    }

    // --- State --- //
    /// @dev Pool id -> Tick -> Slot has liquidity at a price.
    mapping(uint48 => mapping(int24 => HyperSlot)) internal _slots;
    mapping(uint48 => mapping(uint256 => uint256)) internal epochRewardGrowthGlobal;
    mapping(uint48 => mapping(int24 => mapping(uint256 => uint256))) internal epochRewardGrowthOutside;
    /// @dev Pool id -> Pair of a Pool.
    mapping(uint16 => Pair) internal _pairs;
    /// @dev Pool id -> HyperPool Data Structure.
    mapping(uint48 => HyperPool) internal _pools;
    /// @dev Pool id -> Epoch Data Structure.
    mapping(uint48 => Epoch) internal _epochs;
    /// @dev Pool id -> Curve Data Structure stores parameters.
    mapping(uint32 => Curve) internal _curves;
    /// @dev Raw curve parameters packed into bytes32 mapped onto a Curve id when it was deployed.
    mapping(bytes32 => uint32) internal _getCurveIds;
    /// @dev Token -> Physical Reserves.
    mapping(address => uint256) internal _globalReserves;
    /// @dev Base Token -> Quote Token -> Pair id
    mapping(address => mapping(address => uint16)) internal _getPairId;
    /// @dev User -> Token -> Interal Balance.
    mapping(address => mapping(address => uint256)) internal _balances;
    /// @dev User -> Position Id -> Liquidity Position.
    mapping(address => mapping(uint96 => HyperPosition)) internal _positions;
    /// @dev Reentrancy guard initialized to state
    uint256 private locked = 1;
    /// @dev A value incremented by one on pair creation. Reduces calldata.
    uint256 internal _pairNonce;
    /// @dev A value incremented by one on curve creation. Reduces calldata.
    uint256 internal _curveNonce;
    /// @dev Distance between the location of prices on the price grid, so distance between price.
    int24 public constant TICK_SIZE = 256;
    /// @dev Amount of seconds of available time to swap past maturity of a pool.
    uint256 internal constant BUFFER = 300;
    /// @dev Constant amount of basis points. All percentage values are integers in basis points.
    uint256 internal constant PERCENTAGE = 1e4;
    /// @dev Constant amount of 1 ether. All liquidity values have 18 decimals.
    uint256 internal constant PRECISION = 1e18;
    /// @dev Maximum pool fee. 10.00%.
    uint256 internal constant MAX_POOL_FEE = 1e3;
    /// @dev Minimum pool fee. 0.01%.
    uint256 internal constant MIN_POOL_FEE = 1;
    /// @dev Used to compute the amount of liquidity to burn on creating a pool.
    uint256 internal constant MIN_LIQUIDITY_FACTOR = 6;
    /// @dev Policy for the "wait" time in seconds between adding and removing liquidity.
    uint256 internal constant JUST_IN_TIME_LIQUIDITY_POLICY = 4;
    /// @dev Amount of seconds that an epoch lasts.
    uint256 internal constant EPOCH_INTERVAL = 300;
    /// @dev Used as the first pointer for the jump process.
    uint8 internal constant JUMP_PROCESS_START_POINTER = 2;
    uint8 internal constant MIN_DECIMALS = 6;
    uint8 internal constant MAX_DECIMALS = 18;

    address public immutable WETH;
}
