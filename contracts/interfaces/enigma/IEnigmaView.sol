pragma solidity ^0.8.0;

/// @title IEnigmaView
/// @dev Public view functions exposed by the Enigma's higher level contracts.
interface IEnigmaView {
    // --- Liquidity --- //

    /// @notice Computes the amount of time passed since the Position's liquidity was updated.
    /// @custom:mev Just In Time (JIT) liquidity is adding and removing liquidity as a sandwich around a transaction.
    /// It's mitigated with a distance calculated between the time it was added and removed.
    /// If the distance is non-zero, it means liquidity was allocated and removed in different blocks.
    /// @custom:security High. An incorrectly computed distance could lead to possible
    /// negative (or positive) effects to accounts interacting with the Enigma.
    function checkJitLiquidity(address account, uint48 poolId)
        external
        view
        returns (uint256 distance, uint256 timestamp);

    /// @notice Computes the pro-rata amount of liquidity minted from allocating `deltaBase` and `deltaQuote` amounts.
    /// @dev Designed to round in a direction disadvantageous to the account minting liquidity.
    /// @custom:security High. Liquidity amounts minted have a direct impact on liquidity pools.
    function getLiquidityMinted(
        uint48 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) external view returns (uint256 deltaLiquidity);

    // --- Swap --- //

    /// @notice Uses the ReplicationMath.sol trading function to check if a swap is valid.
    /// @dev Warning! Can revert if poolId references an unsynced pool. Returns a fixed point 64.64 formatted value.
    /// @custom:security Critical. The invariant check is the most important check for the Enigma.
    /// @return invariant FixedPoint64.64 invariant value denominated in `quoteToken` units.
    function getInvariant(uint48 poolId) external view returns (int128 invariant);

    /// @notice Computes amount of base and quote tokens entitled to `liquidity` amount.
    /// @dev Can be used to fetch the expected amount of tokens withdrawn from removing `liquidity`.
    /// @custom:security Medium. Designed to round in a direction disadvantageous to the liquidity owner.
    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        external
        view
        returns (uint256 deltaBase, uint256 deltaQuote);
}
