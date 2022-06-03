// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../Decompiler.sol";

import "./DSTest.sol";
import "./Helpers.sol";

contract TestExternalDecompiler {
    TestDecompiler public compiler;

    constructor(address compiler_) {
        compiler = TestDecompiler(payable(compiler_));
    }

    function testAddLiquidity() internal {
        // These amounts are trailing zero run length encoded. So they will be 4 and 4, with 2 and 3 zeroes respectively.
        // uint256 deltaBase = 400;
        // uint256 deltaQuote = 4000;

        uint8 ecode = 0x01; // useMax = 0, enigma code = b = 1 = add liquidity
        uint48 poolId = uint48(0x0100000001); // pairId = 0x01, curveId = 0x00000001
        uint8 power0 = uint8(0x02); // Two appended zeros
        // since length is 1, we only use one byte!
        uint8 amount0 = uint8(0x04); // so 4 and two zeroes = 400
        uint8 power1 = uint8(0x03); // Three zeroes
        // since length is 1, we only use one byte!
        uint8 amount1 = uint8(0x04); // three appended zeroes, so 4000
        uint8 pointer = uint8(0x0A); // ecode + 6 byte poolId + pointer + power + 1 byte amount
        bytes memory data = abi.encodePacked(ecode, poolId, pointer, power0, amount0, power1, amount1);
        compiler.testProcess(data, poolId);
    }

    function testRemoveLiquidity() internal {
        // uint256 deltaLiquidity = 20; // Only remove a portion

        uint48 poolId = uint48(0x0100000001); // pairId = 0x01, curveId = 0x00000001

        uint8 ecode = 0x03; // useMax = 0, enigma code = 3 = remove liquidity
        uint8 amount0Info = uint8(0x01); // note: higher order bits SHOULD BE 1, but its 0 for now until the deoder is refactored. Only uses lower order bits.
        // since length is 1, we only use one byte!
        uint8 amount0 = uint8(0x02); // so 2 and two zeroes = 400
        // this is using the trailing run-length encoded amounts!
        bytes memory data = abi.encodePacked(ecode, poolId, amount0Info, amount0);
        compiler.testProcess(data, poolId);
    }

    function testCreatePair(address token0, address token1) internal {
        bytes memory data = Instructions.encodeCreatePair(token0, token1);
        compiler.testProcess(data, 0);
    }

    function testCreateCurve(
        uint24 sigma,
        uint32 maturity,
        uint16 fee,
        uint128 strike
    ) internal {
        bytes memory data = Instructions.encodeCreateCurve(sigma, maturity, fee, strike);
        compiler.testProcess(data, 0);
    }

    function testCreatePool(address token0, address token1) internal {
        {
            bytes memory data = Instructions.encodeCreatePair(token0, token1);
            compiler.testProcess(data, 0);
        }
        {
            uint24 sigma = StandardPoolHelpers.SIGMA;
            uint32 maturity = StandardPoolHelpers.MATURITY + uint32(block.timestamp);
            uint16 fee = StandardPoolHelpers.FEE;
            uint128 strike = StandardPoolHelpers.STRIKE;
            bytes memory data = Instructions.encodeCreateCurve(sigma, maturity, fee, strike);
            compiler.testProcess(data, 0);
        }

        {
            uint48 poolId = uint48(0x0100000001);
            uint128 basePerLiquidity = StandardPoolHelpers.INTERNAL_BASE; // expects parameters to match standard ones.
            uint128 deltaLiquidity = StandardPoolHelpers.INTERNAL_LIQUIDITY / 1e3; // only mint 1/1000th of the standard liquidity
            bytes memory data = Instructions.encodeCreatePool(poolId, basePerLiquidity, deltaLiquidity);
            compiler.testCreatePool(data);
        }
    }

    function testProcess(address base, address quote) public {
        testCreatePool(base, quote);
        testAddLiquidity();
        testRemoveLiquidity();
    }

    function testJumpProcess(address token0, address token1) public {
        uint8 ecode = uint8(0xaa);
        uint8 length = uint8(0x02);
        uint8 pointer0;
        uint8 pointer1;

        bytes memory data0;
        bytes memory data1;

        {
            data0 = Instructions.encodeCreatePair(token0, token1);
            pointer0 = uint8(data0.length) + 3;
        }
        {
            uint24 sigma = StandardPoolHelpers.SIGMA;
            uint32 maturity = StandardPoolHelpers.MATURITY + uint32(block.timestamp);
            uint16 fee = StandardPoolHelpers.FEE;
            uint128 strike = StandardPoolHelpers.STRIKE;
            data1 = Instructions.encodeCreateCurve(sigma, maturity, fee, strike);
            pointer1 = pointer0 + uint8(data1.length) + 1;
        }

        bytes memory data = abi.encodePacked(ecode, length, pointer0, data0, pointer1, data1);
        compiler.testJumpProcess(data);
    }
}

contract TestDecompiler is DSTest, Helpers, Decompiler {
    function _liquidityPolicy() internal pure override returns (uint256) {
        return 0;
    }

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
            _addressCache[token0] = true;
            _addressCache[token1] = true;

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
        _addressCache[token] = true; // note: `_settleToken` will return early if not true
        globalReserves[token] += 10; // creates a debt that tokens must enter to fill
        _settleToken(token);
        uint256 balance = IERC20(token).balanceOf(address(this));
        assertEq(balance, 10, "settle-debit");
        assertTrue(!_addressCache[token], "address-cache-one");

        // Second, settle a payout
        _addressCache[token] = true;
        globalReserves[token] -= 10; // creates a credit, freeing tokens to be paid
        _settleToken(token);
        balance = balances[msg.sender][token]; // tokens are paid to credit accounts
        assertEq(balance, 10, "settle-credit");
        assertTrue(!_addressCache[token], "address-cache-two");
    }

    function testProcess(bytes calldata data, uint48 poolId) public {
        if (poolId != 0) helperCreateStandardPool(poolId);
        _process(data);
    }

    /// @dev Should be formatted like a jump instruction set with a INSTRUCTION_JUMP opcode.
    function testJumpProcess(bytes calldata data) public {
        _jumpProcess(data);
    }

    // --- External -- //

    function testDraw(
        address token,
        uint256 amount,
        address to
    ) public {}

    function testFund(address token, uint256 amount) public {}

    // --- Old Decompiler --- //

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
        return _swapExactForExact(data);
    }

    function testMain(bytes calldata data) public {
        if (data[0] != Instructions.INSTRUCTION_JUMP) {
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
    ) public view returns (uint256 deltaLiquidity) {
        deltaLiquidity = getLiquidityMinted(poolId, deltaBase, deltaQuote);
    }
}
