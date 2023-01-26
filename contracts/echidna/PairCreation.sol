pragma solidity ^0.8.0;
import "./EchidnaStateHandling.sol";

contract PairCreation is EchidnaStateHandling {
    // ******************** Create Pairs ********************
    /**
     * Future Invariant: This assumes that there is a single pair of _asset and _quote token
     *      - In the future, can be extended to deploy tokens from here and save the address in a list
     * 			which allows echidna to test against different pairs.
     * 			- Assumption: 1 pair for now.
     */
    function create_token(
        string memory tokenName,
        string memory shortform,
        uint8 decimals
    ) public returns (EchidnaERC20 token) {
        token = new EchidnaERC20(tokenName, shortform, decimals, address(_hyper));
        assert(token.decimals() == decimals);
        if (decimals >= 6 && decimals <= 18) {
            add_created_hyper_token(token);
        }
        return token;
    }

    /* Future Invariant: This could be extended to create arbitrary pairs. 
    For now for complexity, I am leaving as is. 
    Test overlapping token pairs
    */
    function create_pair_with_safe_preconditions(uint256 id1, uint256 id2) public {
        // retrieve an existing rpair of tokens that wee created with 6-18 decimals
        (EchidnaERC20 asset, EchidnaERC20 quote) = get_hyper_tokens(id1, id2);
        emit LogUint256("decimals asset", asset.decimals());
        emit LogUint256("decimals quote", quote.decimals());
        emit LogUint256("pair ID", uint256(_hyper.getPairId(address(asset), address(quote))));

        require(asset.decimals() >= 6 && asset.decimals() <= 18);
        require(quote.decimals() >= 6 && quote.decimals() <= 18);
        require(asset != quote);
        // require that this pair ID does not exist yet
        if (_hyper.getPairId(address(asset), address(quote)) != 0) {
            return;
        }
        // without this, Echidna may decide to call the EchidnaERC20.setDecimals
        uint256 preCreationNonce = _hyper.getPairNonce();

        // encode createPair arguments and call hyper contract
        bytes memory createPairData = ProcessingLib.encodeCreatePair(address(asset), address(quote));
        (bool success, bytes memory err) = address(_hyper).call(createPairData);
        if (!success) {
            emit LogBytes("error", err);
            emit AssertionFailed("FAILED");
        }

        pair_id_saved_properly(address(asset), address(quote));

        uint256 pairNonce = _hyper.getPairNonce();
        assert(pairNonce == preCreationNonce + 1);
    }

    /**
     * Future Invariant: This can likely be extended to ensure that pairID's must always match backwards to the tokens saved
     */
    function pair_id_saved_properly(address asset, address quote) private {
        // retrieve recently created pair ID
        uint24 pairId = _hyper.getPairId(address(asset), address(quote));
        if (pairId == 0) {
            emit LogUint256("PairId Exists", uint256(pairId));
            assert(false);
        }

        // retrieve pair information and ensure pair was saved
        HyperPair memory pair = getPair(address(_hyper), pairId);
        assert(pair.tokenAsset == address(asset));
        assert(pair.decimalsAsset == EchidnaERC20(asset).decimals());
        assert(pair.tokenQuote == address(quote));
        assert(pair.decimalsQuote == EchidnaERC20(quote).decimals());

        // save internal Echidna state to test against
        save_pair_id(pairId);
    }

    function create_same_pair_should_fail() public {
        EchidnaERC20 quote = create_token("Create same pair asset fail", "CSPF", 18);
        bytes memory createPairData = ProcessingLib.encodeCreatePair(address(quote), address(quote));
        (bool success, ) = address(_hyper).call(createPairData);
        assert(!success);
    }

    function create_pair_with_less_than_min_decimals_should_fail(uint256 decimals) public {
        decimals = uint8(between(decimals, 0, 5));
        EchidnaERC20 testToken = create_token("create less min decimals asset fail", "CLMDF", uint8(decimals));
        EchidnaERC20 quote = create_token("create less min decimals quote", "CLMDQ", 18);
        bytes memory createPairData = ProcessingLib.encodeCreatePair(address(testToken), address(quote));
        (bool success, ) = address(_hyper).call(createPairData);
        assert(!success);
    }

    function create_pair_with_more_than_max_decimals_should_fail(uint256 decimals) public {
        decimals = uint8(between(decimals, 19, type(uint8).max));
        EchidnaERC20 testToken = create_token("Create more than max decimals fail", "CMTMF", uint8(decimals));
        EchidnaERC20 quote = create_token("Create more than max decimals fail quote", "CMTMF2", 18);
        bytes memory createPairData = ProcessingLib.encodeCreatePair(address(testToken), address(quote));
        (bool success, ) = address(_hyper).call(createPairData);
        assert(!success);
    }
}
