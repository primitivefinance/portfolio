pragma solidity ^0.8.4;

import "solmate/tokens/WETH.sol";
import "contracts/test/EchidnaERC20.sol";
import "./Helper.sol";
import {
    RMM01Portfolio as Portfolio,
    Account as AccountLib,
    SafeCastLib,
    Enigma as EnigmaLib
} from "contracts/RMM01Portfolio.sol";
import "../helpers/HelperPortfolioView.sol";
import "contracts/libraries/EnigmaLib.sol" as ProcessingLib;

contract EchidnaStateHandling is Helper, HelperPortfolioView {
    bool hasFunded;
    Portfolio public immutable _portfolio;
    WETH public immutable _weth;

    constructor() {
        _weth = new WETH();
        _portfolio = new Portfolio(address(_weth));
    }

    // Portfolio Tokens
    EchidnaERC20[] public PortfolioTokens;
    uint64 internal specialPoolId;
    bool internal specialPoolCreated;

    struct PoolParams {
        uint16 priorityFee;
        uint16 fee;
        uint16 volatility;
        uint16 duration;
        uint16 jit;
        uint128 maxPrice;
        uint128 price;
    }

    function add_created_Portfolio_token(EchidnaERC20 token) internal {
        PortfolioTokens.push(token);
    }

    function get_Portfolio_tokens(
        uint256 id1,
        uint256 id2
    ) internal view returns (EchidnaERC20 asset, EchidnaERC20 quote) {
        // This assumes that PortfolioTokens.length is always >2
        if (poolIds.length == 2) {
            id1 = 0;
            id2 = 1;
        } else {
            id1 = between(id1, 0, PortfolioTokens.length - 1);
            id2 = between(id2, 0, PortfolioTokens.length - 1);
        }
        require(id1 != id2);
        return (PortfolioTokens[id1], PortfolioTokens[id2]);
    }

    function get_token_at_index(uint256 index) internal view returns (EchidnaERC20 token) {
        return PortfolioTokens[index];
    }

    // Pairs
    uint24[] pairIds;

    function save_pair_id(uint24 pairId) internal {
        pairIds.push(pairId);
    }

    function retrieve_created_pair(uint256 id) internal view returns (uint24 pairId) {
        require(pairIds.length > 0);
        id = between(id, 0, pairIds.length);
        return pairIds[id];
    }

    // Pools
    uint64[] poolIds;

    function save_pool_id(uint64 id) internal {
        poolIds.push(id);
    }

    function is_created_pool(uint64 id) internal view returns (bool) {
        for (uint8 i = 0; i < poolIds.length; i++) {
            if (poolIds[i] == id) return true;
        }
        return false;
    }

    function retrieve_random_pool_and_tokens(uint256 id)
        internal
        view
        returns (PortfolioPool memory pool, uint64 poolId, EchidnaERC20 asset, EchidnaERC20 quote)
    {
        // assumes that at least one pool exists because it's been created in the constructor
        uint256 random = between(id, 0, poolIds.length - 1);
        if (poolIds.length == 1) random = 0;

        pool = getPool(address(_portfolio), poolIds[random]);
        poolId = poolIds[random];
        PortfolioPair memory pair = pool.pair;
        quote = EchidnaERC20(pair.tokenQuote);
        asset = EchidnaERC20(pair.tokenAsset);
    }

    function retrieve_non_expired_pool_and_tokens()
        internal
        view
        returns (PortfolioPool memory pool, uint64 poolId, EchidnaERC20 asset, EchidnaERC20 quote)
    {
        for (uint8 i = 0; i < poolIds.length; i++) {
            // will auto skew to the first pool that is not expired, however this should be okay.
            // this gives us a higher chance to return a pool that is not expired through iterating
            pool = getPool(address(_portfolio), poolIds[i]);
            PortfolioCurve memory curve = pool.params;
            if (curve.maturity() > block.timestamp) {
                PortfolioPair memory pair = pool.pair;
                return (pool, poolIds[i], EchidnaERC20(pair.tokenQuote), EchidnaERC20(pair.tokenAsset));
            }
        }
    }

    function mint_and_approve(EchidnaERC20 token, uint256 amount) internal {
        token.mint(address(this), amount);
        token.approve(address(_portfolio), type(uint256).max);
    }
}
