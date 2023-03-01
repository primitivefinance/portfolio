pragma solidity ^0.8.4;
import "./EchidnaStateHandling.sol";

contract FundingDrawingDepositing is EchidnaStateHandling {
    // ******************** Funding ********************

    function fund_with_correct_preconditions_should_succeed(uint256 assetAmount, uint256 quoteAmount) public {
        // asset and quote amount > 1
        assetAmount = between(assetAmount, 1, type(uint64).max);
        quoteAmount = between(quoteAmount, 1, type(uint64).max);

        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_Portfolio_tokens(assetAmount, quoteAmount);

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
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_Portfolio_tokens(assetAmount, quoteAmount);

        assetAmount = between(assetAmount, 1, type(uint256).max);
        quoteAmount = between(quoteAmount, 1, type(uint256).max);

        try _portfolio.fund(address(_asset), assetAmount) {
            emit AssertionFailed("BUG: Funding with insufficient asset should fail");
        } catch {}

        try _portfolio.fund(address(_quote), quoteAmount) {
            emit AssertionFailed("Funding with insufficient quote should fail");
        } catch {}
    }

    function fund_with_insufficient_allowance_should_fail(uint256 id, uint256 fundAmount) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_Portfolio_tokens(id, fundAmount);

        uint256 smallAssetAllowance = between(fundAmount, 1, fundAmount - 1);

        // mint the asset to address(this) and approve some amount < fund
        _asset.mint(address(this), fundAmount);
        _asset.approve(address(_portfolio), smallAssetAllowance);
        try _portfolio.fund(address(_asset), fundAmount) {
            emit LogUint256("small asset allowance", smallAssetAllowance);
            emit AssertionFailed("BUG: insufficient allowance on asset should fail.");
        } catch {}

        // mint the quote token to address(this), approve some amount < fund
        _quote.mint(address(this), fundAmount);
        _quote.approve(address(_portfolio), smallAssetAllowance);
        try _portfolio.fund(address(_quote), fundAmount) {
            emit LogUint256("small quote allowance", smallAssetAllowance);
            emit AssertionFailed("BUG: insufficient allowance on quote should fail.");
        } catch {}
    }

    function fund_with_zero(uint256 id1, uint256 id2) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_Portfolio_tokens(id1, id2);

        mint_and_approve(_asset, 0);
        mint_and_approve(_quote, 0);
        _portfolio.fund(address(_asset), 0);
        _portfolio.fund(address(_quote), 0);
    }

    function fund_token(address token, uint256 amount) private returns (bool) {
        uint256 senderBalancePreFund = EchidnaERC20(token).balanceOf(address(this));
        uint256 virtualBalancePreFund = getBalance(address(_portfolio), address(this), address(token));
        uint256 reservePreFund = getReserve(address(_portfolio), address(token));
        uint256 PortfolioBalancePreFund = EchidnaERC20(token).balanceOf(address(_portfolio));

        try _portfolio.fund(address(token), amount) {} catch (bytes memory error) {
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
        // Portfolio balance of the sender should increase
        // pre Portfolio balance = a; post Portfoliobalance + 100
        uint256 virtualBalancePostFund = getBalance(address(_portfolio), address(this), address(token));
        if (virtualBalancePostFund != virtualBalancePreFund + amount) {
            emit LogUint256("tracked balance after funding", virtualBalancePostFund);
            emit LogUint256("tracked balance before funding:", virtualBalancePreFund);
            emit AssertionFailed("BUG: Tracked balance of sender did not increase after funding");
        }
        // Portfolio reserves for token should increase
        // reserve balance = b; post reserves + 100
        uint256 reservePostFund = getReserve(address(_portfolio), address(token));
        if (reservePostFund != reservePreFund + amount) {
            emit LogUint256("reserve after funding", reservePostFund);
            emit LogUint256("reserve balance before funding:", reservePreFund);
            emit AssertionFailed("BUG: Reserve of Portfolio did not increase after funding");
        }
        // Portfolio's token balance should increase
        // pre balance of usdc = y; post balance = y + 100
        uint256 PortfolioBalancePostFund = EchidnaERC20(token).balanceOf(address(_portfolio));
        if (PortfolioBalancePostFund != PortfolioBalancePreFund + amount) {
            emit LogUint256("Portfolio token balance after funding", PortfolioBalancePostFund);
            emit LogUint256("Portfolio balance before funding:", PortfolioBalancePreFund);
            emit AssertionFailed("BUG: Portfolio token balance did not increase after funding");
        }
        return true;
    }

    // ******************** Draw ********************
    function draw_should_succeed(uint256 assetAmount, uint256 quoteAmount, address recipient) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_Portfolio_tokens(assetAmount, quoteAmount);

        assetAmount = between(assetAmount, 1, type(uint64).max);
        quoteAmount = between(quoteAmount, 1, type(uint64).max);
        emit LogUint256("asset amount: ", assetAmount);
        emit LogUint256("quote amount:", quoteAmount);

        require(recipient != address(_portfolio));
        require(recipient != address(0));

        draw_token(address(_asset), assetAmount, recipient);
        draw_token(address(_quote), quoteAmount, recipient);
    }

    function draw_token(address token, uint256 amount, address recipient) private {
        // make sure a user has funded already
        uint256 virtualBalancePreFund = getBalance(address(_portfolio), address(this), address(token));
        require(virtualBalancePreFund > 0);
        amount = between(amount, 1, virtualBalancePreFund);

        uint256 recipientBalancePreFund = EchidnaERC20(token).balanceOf(address(recipient));
        uint256 reservePreFund = getReserve(address(_portfolio), address(token));
        uint256 PortfolioBalancePreFund = EchidnaERC20(token).balanceOf(address(_portfolio));

        _portfolio.draw(token, amount, recipient);

        //-- Postconditions
        // caller balance should decrease
        // pre caller balance = a; post caller balance = a - 100
        uint256 virtualBalancePostFund = getBalance(address(_portfolio), address(this), address(token));
        if (virtualBalancePostFund != virtualBalancePreFund - amount) {
            emit LogUint256("virtual balance post draw", virtualBalancePostFund);
            emit LogUint256("virtual balance pre draw", virtualBalancePreFund);
            emit AssertionFailed("BUG: virtual balance should decrease after drawing tokens");
        }
        // reserves should decrease
        uint256 reservePostFund = getReserve(address(_portfolio), address(token));
        if (reservePostFund != reservePreFund - amount) {
            emit LogUint256("reserve post draw", reservePostFund);
            emit LogUint256("reserve pre draw", reservePreFund);
            emit AssertionFailed("BUG: reserve balance should decrease after drawing tokens");
        }
        // to address should increase
        // pre-token balance = a; post-token = a + 100
        uint256 recipientBalancePostFund = EchidnaERC20(token).balanceOf(address(recipient));
        if (recipientBalancePostFund != recipientBalancePreFund + amount) {
            emit LogUint256("recipient balance post draw", recipientBalancePostFund);
            emit LogUint256("recipient balance pre draw", recipientBalancePreFund);
            emit AssertionFailed("BUG: recipient balance should increase after drawing tokens");
        }
        // Portfolio token's balance should decrease
        uint256 tokenPostFund = EchidnaERC20(token).balanceOf(address(_portfolio));
        if (tokenPostFund != PortfolioBalancePreFund - amount) {
            emit LogUint256("token post draw", tokenPostFund);
            emit LogUint256("token pre draw", PortfolioBalancePreFund);
            emit AssertionFailed("BUG: Portfolio token balance should increase after drawing tokens");
        }
    }

    function draw_to_zero_should_fail(uint256 assetAmount, uint256 quoteAmount) public {
        (EchidnaERC20 _asset, ) = get_Portfolio_tokens(assetAmount, quoteAmount);

        // make sure a user has funded already
        uint256 virtualBalancePreFund = getBalance(address(_portfolio), address(this), address(_asset));
        emit LogUint256("virtual balance pre fund", virtualBalancePreFund);
        require(virtualBalancePreFund >= 0);
        assetAmount = between(assetAmount, 1, virtualBalancePreFund);

        try _portfolio.draw(address(_asset), assetAmount, address(0)) {
            emit AssertionFailed("BUG: draw should fail attempting to transfer to zero");
        } catch {}
    }

    function fund_then_draw(uint256 whichToken, uint256 amount) public {
        (EchidnaERC20 _asset, EchidnaERC20 _quote) = get_Portfolio_tokens(amount, whichToken);

        // this can be extended to use the token list in `PortfolioTokens`
        address token;
        if (whichToken % 2 == 0) token = address(_asset);
        else token = address(_quote);

        mint_and_approve(_asset, amount);
        mint_and_approve(_quote, amount);

        uint256 PortfolioBalancePreFund = EchidnaERC20(token).balanceOf(address(_portfolio));
        require(PortfolioBalancePreFund == 0);

        uint256 virtualBalancePreFund = getBalance(address(_portfolio), address(this), address(token));
        uint256 recipientBalancePreFund = EchidnaERC20(token).balanceOf(address(this));
        uint256 reservePreFund = getReserve(address(_portfolio), address(token));

        // Call fund and draw
        _portfolio.fund(token, amount);
        _portfolio.draw(token, amount, address(this));

        //-- Postconditions
        // caller balance should be equal
        uint256 virtualBalancePostFund = getBalance(address(_portfolio), address(this), address(token));
        if (virtualBalancePostFund != virtualBalancePreFund) {
            emit LogUint256("virtual balance post fund-draw", virtualBalancePostFund);
            emit LogUint256("virtual balance pre fund-draw", virtualBalancePreFund);
            emit AssertionFailed("BUG: virtual balance should be equal after fund-draw");
        }
        // reserves should be equal
        uint256 reservePostFund = getReserve(address(_portfolio), address(token));
        if (reservePostFund != reservePreFund) {
            emit LogUint256("reserve post fund-draw", reservePostFund);
            emit LogUint256("reserve pre fund-draw", reservePreFund);
            emit AssertionFailed("BUG: reserve balance should be equal after fund-draw");
        }
        // recipient = sender balance should be equal
        uint256 recipientBalancePostFund = EchidnaERC20(token).balanceOf(address(this));
        if (recipientBalancePostFund != recipientBalancePreFund) {
            emit LogUint256("recipient balance post fund-draw", recipientBalancePostFund);
            emit LogUint256("recipient balance pre fund-draw", recipientBalancePreFund);
            emit AssertionFailed("BUG: recipient balance should be equal after fund-draw");
        }
        // Portfolio token's balance should be equal
        uint256 tokenPostFund = EchidnaERC20(token).balanceOf(address(_portfolio));
        if (tokenPostFund != PortfolioBalancePreFund) {
            emit LogUint256("token post fund-draw", tokenPostFund);
            emit LogUint256("token pre fund-draw", PortfolioBalancePreFund);
            emit AssertionFailed("BUG: Portfolio token balance should be equal after fund-draw");
        }
    }

    // ******************** Deposits ********************

    function deposit_with_correct_postconditions_should_succeed() public payable {
        require(msg.value > 0);
        emit LogUint256("msg.value", msg.value);

        uint256 thisEthBalancePre = address(this).balance;
        uint256 reserveBalancePre = getReserve(address(_portfolio), address(_weth));
        uint256 wethBalancePre = _weth.balanceOf(address(_portfolio));

        try _portfolio.deposit{value: msg.value}() {
            uint256 thisEthBalancePost = address(this).balance;
            uint256 reserveBalancePost = getReserve(address(_portfolio), address(_weth));
            uint256 wethBalancePost = _weth.balanceOf(address(_portfolio));
            // Eth balance of this contract should decrease by the deposited amount
            if (thisEthBalancePost != thisEthBalancePre - msg.value) {
                emit LogUint256("eth balance post transfer (sender)", thisEthBalancePost);
                emit LogUint256("eth balance pre transfer (sender)", thisEthBalancePre);
                emit AssertionFailed("sender's eth balance should not change.");
            }
            // Portfolio reserve of WETH should increase by msg.value
            if (reserveBalancePost != reserveBalancePre + msg.value) {
                emit LogUint256("weth reserve post transfer (Portfolio)", reserveBalancePost);
                emit LogUint256("weth reserve pre transfer (Portfolio)", reserveBalancePre);
                emit AssertionFailed("Portfolio's weth reserve should increase by added amount.");
            }
            // Portfolio balance of WETH should increase by msg.value
            if (wethBalancePost != wethBalancePre + msg.value) {
                emit LogUint256("weth balance post transfer (Portfolio)", wethBalancePost);
                emit LogUint256("weth balance pre transfer (Portfolio)", wethBalancePre);
                emit AssertionFailed("Portfolios's weth balance should increase by added amount.");
            }
        } catch (bytes memory err) {
            emit LogBytes("error", err);
            emit AssertionFailed("BUG: deposit should not have failed.");
        }
    }
}
