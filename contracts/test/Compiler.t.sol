pragma solidity ^0.8.0;

import "./DSTest.sol";
import "./Helpers.sol";

import "../Compiler.sol";

contract TestExternalCompiler {
    TestCompiler public compiler;

    constructor(address compiler_) {
        compiler = TestCompiler(payable(compiler_));
    }
}

contract TestCompiler is DSTest, Helpers, Compiler {
    // --- Internal -- //

    function testApplyCredit(address token, uint256 amount) public {
        uint256 pre = balances[msg.sender][token];
        _applyCredit(token, amount);
        uint256 post = balances[msg.sender][token];
        assertEq(post, pre + amount, "apply-credit-amount");
    }

    function testApplyDebit(address token, uint256 amount) public {
        balances[msg.sender][token] = amount; // Set credit higher so it will enter first condition of debit.

        // note: Apply debit will attempt to debit the msg.sender internal balance.
        uint256 pre = balances[msg.sender][token];
        _applyDebit(token, amount);
        uint256 post = balances[msg.sender][token];
        assertEq(post, pre - amount, "apply-debit-amount-one");

        // Test second condition, which will pull tokens
        delete balances[msg.sender][token]; // note: Clear the credit to enter debit second condition.
        pre = 0;
        uint256 preGlobal = globalReserves[token];
        uint256 preBalAccount = IERC20(token).balanceOf(msg.sender);
        uint256 preBalContract = IERC20(token).balanceOf(address(this));

        _applyDebit(token, amount);

        post = balances[msg.sender][token];
        uint256 postGlobal = globalReserves[token];
        uint256 postBalAccount = IERC20(token).balanceOf(msg.sender);
        uint256 postBalContract = IERC20(token).balanceOf(address(this));

        assertEq(post, pre, "apply-debit-amount-two"); // credit balance doesn't change.
        assertEq(postGlobal, preGlobal + 0, "apply-debit-global");
        assertEq(postBalAccount, preBalAccount - amount, "apply-debit-user");
        assertEq(postBalContract, preBalContract + amount, "apply-debit-contract");
    }

    function testSettleBalances(address token0, address token1) public {
        uint16 pairIdOne = uint16(1);
        uint16 pairIdTwo = uint16(2);

        uint256 credit = balances[msg.sender][token1];

        // Create pairs of tokens to settle
        Pair storage pairOne = pairs[pairIdOne];
        pairOne.tokenBase = token0;
        pairOne.tokenQuote = token1;

        Pair storage pairTwo = pairs[pairIdTwo];
        pairTwo.tokenBase = token1;
        pairTwo.tokenQuote = token0;

        // Array that is looped through in `_settleBalances`
        _tempPairIds.push(pairIdOne);
        _tempPairIds.push(pairIdTwo);

        {
            // cache both tokens so the pairs grab them
            addressCache[token0] = true;
            addressCache[token1] = true;

            // create a debit for token0 token by having more global balance than actual
            globalReserves[token0] += 20;
            bool success = IERC20(token0).transferFrom(msg.sender, address(this), 20);
            require(success, "token0-in");
            globalReserves[token0] += 10; // creates a credit, freeing tokens to be paid
            // create a credit for token0 token by having less global balance than actual
            globalReserves[token1] += 20;
            success = IERC20(token1).transferFrom(msg.sender, address(this), 20);
            require(success, "token1-in");
            globalReserves[token1] -= 10; // creates a credit, freeing tokens to be paid
        }

        require(_tempPairIds.length == 2, "temp-length");

        uint256 preBal0 = IERC20(token0).balanceOf(address(this));
        uint256 preBal1 = IERC20(token1).balanceOf(address(this));
        _settleBalances(); // Net no change in actual token balance in this test function.
        uint256 postBal0 = IERC20(token0).balanceOf(address(this));
        uint256 postBal1 = IERC20(token1).balanceOf(address(this));

        assertEq(postBal0, preBal0 + 10, "settle-debit-balance");
        assertEq(postBal1, preBal1, "settle-credit-balance"); // tokens are not sent out, instead applied to internal balance
        assertEq(balances[msg.sender][token1], credit + 10, "settle-credit-account");
        assertTrue(_tempPairIds.length == 0, "temp-pair-ids"); // should always be zero outside of call.
    }

    function testSettleToken(address token) public {
        // First, settle a debt
        addressCache[token] = true; // note: `_settleToken` will return early if not true
        globalReserves[token] += 10; // creates a debt that tokens must enter to fill
        _settleToken(token);
        uint256 balance = IERC20(token).balanceOf(address(this));
        assertEq(balance, 10, "settle-debit");
        assertTrue(!addressCache[token], "address-cache-one");

        // Second, settle a payout
        addressCache[token] = true;
        globalReserves[token] -= 10; // creates a credit, freeing tokens to be paid
        _settleToken(token);
        balance = balances[msg.sender][token]; // tokens are paid to credit accounts
        assertEq(balance, 10, "settle-credit");
        assertTrue(!addressCache[token], "address-cache-two");
    }

    // --- External -- //

    function testDraw(
        address token,
        uint256 amount,
        address to
    ) public {}

    function testFund(address token, uint256 amount) public {}

    // --- Old Compiler --- //

    uint256 public timestamp;

    function setTimestamp(uint256 timestamp_) public {
        timestamp = timestamp_;
    }

    function _blockTimestamp() internal view override(EnigmaVirtualMachine) returns (uint128) {
        return uint128(timestamp);
    }

    function setTokens(
        uint16 pairId,
        address base,
        address quote
    ) public {
        pairs[pairId] = Pair({
            tokenBase: base,
            decimalsBase: IERC20(base).decimals(),
            tokenQuote: quote,
            decimalsQuote: IERC20(quote).decimals()
        });
    }

    function setLiquidity(
        uint48 poolId,
        uint256 base,
        uint256 quote,
        uint256 liquidity
    ) public {
        pools[poolId] = Pool({
            internalBase: uint128(base),
            internalQuote: uint128(quote),
            internalLiquidity: uint128(liquidity),
            blockTimestamp: uint128(block.timestamp)
        });
    }

    function setCurve(
        uint32 curveId,
        uint128 strike,
        uint24 sigma,
        uint32 maturity,
        uint32 gamma
    ) public {
        curves[curveId] = Curve({strike: strike, sigma: sigma, maturity: maturity, gamma: gamma});
    }

    // --- Create --- //

    function testCreatePair(bytes calldata data) public returns (uint16) {
        return _createPair(data);
    }

    function testCreateCurve(bytes calldata data) public returns (uint32) {
        return _createCurve(data);
    }

    function testCreatePool(bytes calldata data)
        public
        returns (
            uint48,
            uint256,
            uint256
        )
    {
        return _createPool(data);
    }

    function testRemoveLiquidity(bytes calldata data)
        public
        returns (
            uint48,
            uint256,
            uint256
        )
    {
        return _removeLiquidity(data);
    }

    function testAddLiquidity(bytes calldata data) public returns (uint48, uint256) {
        return _addLiquidity(data);
    }

    function testSwapExactTokens(bytes calldata data) public returns (uint48, uint256) {
        return _swapExactTokens(data);
    }

    /// @dev Should be formatted like a jump instruction set with a INSTRUCTION_JUMP opcode.
    function testJumpProcess(bytes calldata data) public returns (uint256) {
        _jumpProcess(data);
    }

    function testMain(bytes calldata data) public {
        if (data[0] != INSTRUCTION_JUMP) {
            _process(data);
        } else {
            _jumpProcess(data);
        }

        _settleBalances();
    }

    // -- Test --

    function testGetLiquidityMinted(
        uint48 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    )
        public
        view
        returns (
            uint256 deltaLiquidity,
            uint256 deltaQuote2,
            uint256 deltaLiquidity2
        )
    {
        deltaLiquidity = getLiquidityMinted(poolId, deltaBase, deltaQuote);
        (deltaLiquidity2, deltaQuote2) = getLiquidityMinted2(poolId, deltaBase);
    }

    function getLiquidityMinted2(uint48 poolId, uint256 deltaBase)
        public
        view
        returns (uint256 deltaLiquidity, uint256 deltaQuote)
    {
        Pool memory pool = pools[poolId];
        uint256 liquidity0 = (deltaBase * pool.internalLiquidity) / uint256(pool.internalBase);
        deltaQuote = (uint256(pool.internalBase) * liquidity0) / uint256(pool.internalLiquidity);
        deltaLiquidity = liquidity0;
        uint256 liquidity1 = (deltaQuote * pool.internalLiquidity) / uint256(pool.internalQuote);
        uint256 deltaLiquidity1 = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    }

    function testGetReportedPrice(
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint256 riskyPerLiquidity,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public view returns (int128) {
        return
            ReplicationMath.getReportedPrice(
                scaleFactorRisky,
                scaleFactorStable,
                riskyPerLiquidity,
                strike,
                sigma,
                tau
            );
    }
}
