pragma solidity ^0.8.0;

interface IEnigmaEvents {
    // --- Critical --- //
    event IncreaseGlobal(address indexed base, address indexed quote, uint256 deltaBase, uint256 deltaQuote);
    event DecreaseGlobal(address indexed base, address indexed quote, uint256 deltaBase, uint256 deltaQuote);

    // --- Accounts --- //
    event IncreasePosition(address indexed account, uint48 indexed poolId, uint256 deltaLiquidity);
    event DecreasePosition(address indexed account, uint48 indexed poolId, uint256 deltaLiquidity);

    // --- Liquidity --- //
    event AddLiquidity(
        uint48 indexed poolId,
        uint16 indexed pairId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );
    event RemoveLiquidity(
        uint48 indexed poolId,
        uint16 indexed pairId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    // --- Uncommon --- //
    event CreateCurve(
        uint32 indexed curveId,
        uint128 strike,
        uint24 sigma,
        uint32 indexed maturity,
        uint32 indexed gamma
    );
    event CreatePair(uint16 indexed pairId, address indexed base, address indexed quote);
    event CreatePool(
        uint48 indexed poolId,
        uint16 indexed pairId,
        uint32 indexed curveId,
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    );

    // --- Swap --- //
    event Swap(uint256 id, uint256 input, uint256 output, address tokenIn, address tokenOut);
    event UpdateLastTimestamp(uint48 poolId);
}
