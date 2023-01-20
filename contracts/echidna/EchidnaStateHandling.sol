pragma solidity ^0.8.0;

import "../test/EchidnaERC20.sol";
import "./Helper.sol";

contract EchidnaStateHandling is Helper{
    // Hyper Tokens
    EchidnaERC20[] public hyperTokens;

    function add_created_hyper_token(EchidnaERC20 token) internal {
        hyperTokens.push(token);
    }
    function get_hyper_tokens(uint256 id1, uint256 id2) internal view returns (EchidnaERC20 asset, EchidnaERC20 quote) {
        // This assumes that hyperTokens.length is always >2
        id1 = between(id1, 0, hyperTokens.length - 1);
        id2 = between(id2, 0, hyperTokens.length - 1);
        require(id1 != id2);
        return (hyperTokens[id1], hyperTokens[id2]);
    }    
    function get_token_at_index(uint256 index) internal view returns (EchidnaERC20 token){
        return hyperTokens[index];
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
}