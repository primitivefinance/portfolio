pragma solidity ^0.8.0;

import "../../test/helpers/HelperHyperProfiles.sol" as DefaultValues;
import "./GlobalInvariants.sol";

contract EchidnaE2E is GlobalInvariants {
    constructor() GlobalInvariants() {
        EchidnaERC20 _asset = create_token("Asset Token", "ADEC6", 6);
        EchidnaERC20 _quote = create_token("Quote Token", "QDEC18", 18);
        add_created_hyper_token(_asset);
        add_created_hyper_token(_quote);
        create_pair_with_safe_preconditions(1, 2);
        create_non_controlled_pool(0, 1, 0, 0, 0, 100);
    }

    OS.AccountSystem hyperAccount;

    // ******************** Check Proper System Deployment ********************
    function check_proper_deployment() public view {
        assert(address(_weth) != address(0));
        assert(address(_hyper) != address(0));

        // Note: This invariant may break with tokens on hooks.
        assert(_hyper.locked() == 1);

        // Retrieve the OS.__account__
        (bool prepared, bool settled) = _hyper.__account__();
        assert(!prepared);
        assert(settled);

        address[] memory warmTokens = _hyper.getWarm();
        assert(warmTokens.length == 0);
    }

    using SafeCastLib for uint256;

    // ******************** Claim ********************
    function claim_should_succeed_with_correct_preconditions(
        uint256 id,
        uint256 deltaAsset,
        uint256 deltaQuote
    ) public {
        (, uint64 poolId, , ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("pool id:", uint256(poolId));

        HyperPosition memory preClaimPosition = getPosition(address(_hyper), address(this), poolId);
        require(preClaimPosition.lastTimestamp != 0);

        try _hyper.claim(poolId, deltaAsset, deltaQuote) {
            // if tokens were owned, decrement from position
            // if tokens were owed, getBalance of tokens increased for the caller
        } catch {
            emit AssertionFailed("BUG: claim function should have succeeded");
        }
    }

    function create_special_pool() public {
        require(!specialPoolCreated, "Special Pool already created");
        uint24 pairId = create_special_pair();
        create_special_pool(pairId, PoolParams(0, 0, 1, 0, 0, 0, 100));
    }

    // Future invariant: Funding with WETH and then depositing with ETH should have the same impact on the pool
}
