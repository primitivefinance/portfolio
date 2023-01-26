pragma solidity ^0.8.0;
import "./EchidnaStateHandling.sol";

contract FundingDrawing is EchidnaStateHandling {

    // ******************** Funding ********************

    function fund_with_correct_preconditions_should_succeed(uint256 assetAmount, uint256 quoteAmount) public {
        // asset and quote amount > 1
        assetAmount = between(assetAmount, 1, type(uint64).max);
        quoteAmount = between(quoteAmount, 1, type(uint64).max);

        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(assetAmount, quoteAmount);

        emit LogUint256("assetAmount", assetAmount);
        emit LogUint256("quoteAmount", quoteAmount);
        mint_and_approve(_asset, assetAmount);
        mint_and_approve(_quote, quoteAmount);

        if (_asset.balanceOf(address(this)) < assetAmount) {
            emit LogUint256("asset balance", _asset.balanceOf(address(this)));
        }
        if (_quote.balanceOf(address(this)) < quoteAmount) {
            emit LogUint256("quote balance", _quote.balanceOf(address(this)));
        }

        fund_token(address(_asset), assetAmount);
        fund_token(address(_quote), quoteAmount);
    }

    function fund_with_insufficient_funds_should_fail(uint256 assetAmount, uint256 quoteAmount) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(assetAmount, quoteAmount);

        assetAmount = between(assetAmount, 1, type(uint256).max);
        quoteAmount = between(quoteAmount, 1, type(uint256).max);

        try _hyper.fund(address(_asset), assetAmount) {
            emit AssertionFailed("BUG: Funding with insufficient asset should fail");
        } catch {}

        try _hyper.fund(address(_quote), quoteAmount) {
            emit AssertionFailed("Funding with insufficient quote should fail");
        } catch {}
    }

    function fund_with_insufficient_allowance_should_fail(uint256 id, uint256 fundAmount) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(id, fundAmount);

        uint256 smallAssetAllowance = between(fundAmount, 1, fundAmount - 1);

        // mint the asset to address(this) and approve some amount < fund
        _asset.mint(address(this), fundAmount);
        _asset.approve(address(_hyper), smallAssetAllowance);
        try _hyper.fund(address(_asset), fundAmount) {
            emit LogUint256("small asset allowance", smallAssetAllowance);
            emit AssertionFailed("BUG: insufficient allowance on asset should fail.");
        } catch {}

        // mint the quote token to address(this), approve some amount < fund
        _quote.mint(address(this), fundAmount);
        _quote.approve(address(_hyper), smallAssetAllowance);
        try _hyper.fund(address(_quote), fundAmount) {
            emit LogUint256("small quote allowance", smallAssetAllowance);
            emit AssertionFailed("BUG: insufficient allowance on quote should fail.");
        } catch {}
    }

    function fund_with_zero(uint256 id1, uint256 id2) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_hyper_tokens(id1, id2);

        mint_and_approve(_asset, 0);
        mint_and_approve(_quote, 0);
        _hyper.fund(address(_asset), 0);
        _hyper.fund(address(_quote), 0);
    }

    function fund_token(address token, uint256 amount) private returns (bool) {
        // TODO Refactor: reuse the HelperHyperView.getState() keeps this cleaner
        uint256 senderBalancePreFund = EchidnaERC20(token).balanceOf(address(this));
        uint256 virtualBalancePreFund = getBalance(address(_hyper), address(this), address(token));
        uint256 reservePreFund = getReserve(address(_hyper), address(token));
        uint256 hyperBalancePreFund = EchidnaERC20(token).balanceOf(address(_hyper));

        try _hyper.fund(address(token), amount) {} catch (bytes memory error) {
            emit LogBytes("error", error);
            assert(false);
        }

        // sender's token balance should decrease
        // usdc sender pre token balance = 100 ; usdc sender post token = 100 - 1
        uint256 senderBalancePostFund = EchidnaERC20(token).balanceOf(address(this));
        if (senderBalancePostFund != senderBalancePreFund - amount) {
            emit LogUint256("postTransfer sender balance", senderBalancePostFund);
            emit LogUint256("preTransfer:", senderBalancePreFund);
            emit AssertionFailed("BUG: Sender balance of token did not decrease by amount after funding");
        }
        // hyper balance of the sender should increase
        // pre hyper balance = a; post hyperbalance + 100
        uint256 virtualBalancePostFund = getBalance(address(_hyper), address(this), address(token));
        if (virtualBalancePostFund != virtualBalancePreFund + amount) {
            emit LogUint256("tracked balance after funding", virtualBalancePostFund);
            emit LogUint256("tracked balance before funding:", virtualBalancePreFund);
            emit AssertionFailed("BUG: Tracked balance of sender did not increase after funding");
        }
        // hyper reserves for token should increase
        // reserve balance = b; post reserves + 100
        uint256 reservePostFund = getReserve(address(_hyper), address(token));
        if (reservePostFund != reservePreFund + amount) {
            emit LogUint256("reserve after funding", reservePostFund);
            emit LogUint256("reserve balance before funding:", reservePreFund);
            emit AssertionFailed("BUG: Reserve of hyper did not increase after funding");
        }
        // hyper's token balance should increase
        // pre balance of usdc = y; post balance = y + 100
        uint256 hyperBalancePostFund = EchidnaERC20(token).balanceOf(address(_hyper));
        if (hyperBalancePostFund != hyperBalancePreFund + amount) {
            emit LogUint256("hyper token balance after funding", hyperBalancePostFund);
            emit LogUint256("hyper balance before funding:", hyperBalancePreFund);
            emit AssertionFailed("BUG: Hyper token balance did not increase after funding");
        }
        return true;
    }    
}
