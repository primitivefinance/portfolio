pragma solidity ^0.8.0;

import "./DSTest.sol";
import "./Helpers.sol";

import "hardhat/console.sol";

import "../HyperLiquidity.sol";

/// @dev Used to build bytes in calldata to test `_addLiquidity` function.
contract TestExternalLiquidity {
    TestHyperLiquidity public hyper;

    constructor(address hyper_) {
        hyper = TestHyperLiquidity(hyper_);
    }

    function testAddLiquidity() public {
        // These amounts are trailing zero run length encoded. So they will be 4 and 4, with 2 and 3 zeroes respectively.
        uint256 deltaBase = 400;
        uint256 deltaQuote = 4000;

        uint8 ecode = 0x01; // useMax = 0, enigma code = b = 1 = add liquidity
        uint48 poolId = uint48(0x0100000001); // pairId = 0x01, curveId = 0x00000001
        uint8 amount0Info = uint8(0x12); // length of 1, two appended zeros
        // since length is 1, we only use one byte!
        uint8 amount0 = uint8(0x04); // so 4 and two zeroes = 400
        uint8 amount1Info = uint8(0x13); // length of 1, three zeroes
        // since length is 1, we only use one byte!
        uint8 amount1 = uint8(0x04); // three appended zeroes, so 4000
        // this is using the trailing run-length encoded amounts!
        bytes memory data = abi.encodePacked(ecode, poolId, amount0Info, amount0, amount1, amount1Info);
        hyper.testAddLiquidity(data, poolId, deltaBase, deltaQuote);
    }

    function testRemoveLiquidity() public {
        uint48 poolId = uint48(0x0100000001); // pairId = 0x01, curveId = 0x00000001
        uint256 deltaLiquidity = 20; // Only remove a portion

        uint8 ecode = 0x03; // useMax = 0, enigma code = 3 = remove liquidity
        uint8 amount0Info = uint8(0x01); // note: higher order bits SHOULD BE 1, but its 0 for now until the deoder is refactored. Only uses lower order bits.
        // since length is 1, we only use one byte!
        uint8 amount0 = uint8(0x02); // so 2 and two zeroes = 400
        // this is using the trailing run-length encoded amounts!
        bytes memory data = abi.encodePacked(ecode, poolId, amount0Info, amount0);
        hyper.testRemoveLiquidity(data, poolId, deltaLiquidity);
    }

    function testCreatePair(address token0, address token1) public {
        bytes memory data = Instructions.encodeCreatePair(token0, token1);
        hyper.testCreatePair(data, token0, token1);
    }

    function testCreateCurve(
        uint24 sigma,
        uint32 maturity,
        uint16 fee,
        uint128 strike
    ) public {
        bytes memory data = Instructions.encodeCreateCurve(sigma, maturity, fee, strike);
        hyper.testCreateCurve(data, sigma, maturity, fee, strike);
    }

    function testCreatePool(address token0, address token1) public {
        {
            bytes memory data = Instructions.encodeCreatePair(token0, token1);
            hyper.testCreatePair(data, token0, token1);
        }
        {
            uint24 sigma = StandardPoolHelpers.SIGMA;
            uint32 maturity = StandardPoolHelpers.MATURITY + uint32(block.timestamp);
            uint16 fee = StandardPoolHelpers.FEE;
            uint128 strike = StandardPoolHelpers.STRIKE;
            bytes memory data = Instructions.encodeCreateCurve(sigma, maturity, fee, strike);
            hyper.testCreateCurve(data, sigma, maturity, fee, strike);
        }

        {
            uint48 poolId = uint48(0x0100000001);
            uint128 basePerLiquidity = StandardPoolHelpers.INTERNAL_BASE; // expects parameters to match standard ones.
            uint128 deltaLiquidity = StandardPoolHelpers.INTERNAL_LIQUIDITY / 1e3; // only mint 1/1000th of the standard liquidity
            bytes memory data = Instructions.encodeCreatePool(poolId, basePerLiquidity, deltaLiquidity);
            hyper.testCreatePool(data);
        }
    }
}

contract TestHyperLiquidity is DSTest, Helpers, HyperLiquidity {
    // --- Must Implement --- //

    function testCheckJitLiquidity() public {
        uint48 poolId = uint48(3);
        Position storage pos = positions[msg.sender][poolId];

        pools[poolId].blockTimestamp = 10;

        (uint256 distance, uint256 current) = checkJitLiquidity(msg.sender, poolId);
        assertEq(current - 10, distance, "jit-distance");
    }

    function testGetLiquidityMinted() public {
        uint48 poolId = uint48(4);
        Pool storage pool = pools[poolId];
        pool.internalBase = 50;
        pool.internalQuote = 100;
        pool.internalLiquidity = 100;

        uint256 deltaBase = 5;
        uint256 deltaQuote = 10;
        uint256 deltaLiquidity = getLiquidityMinted(poolId, deltaBase, deltaQuote);
        assertEq(deltaLiquidity, (deltaBase * pool.internalLiquidity) / pool.internalBase);
        assertEq(deltaLiquidity, (deltaQuote * pool.internalLiquidity) / pool.internalQuote);
    }

    function testIncreaseGlobal(address token, uint256 amount) public {
        uint256 pre = globalReserves[token];
        _increaseGlobal(token, amount);
        uint256 post = globalReserves[token];
        assertEq(post, pre + amount, "increase-global");
    }

    function testDecreaseGlobal(address token, uint256 amount) public {
        globalReserves[token] = amount * 10;
        uint256 pre = globalReserves[token];
        require(pre > amount, "decrease-underflow");

        _decreaseGlobal(token, amount);
        uint256 post = globalReserves[token];
        assertEq(post, pre - amount, "decrease-global");
    }

    function testIncreasePosition(uint256 deltaLiquidity) public {
        uint48 poolId = uint48(2);
        Position storage pos = positions[msg.sender][poolId];

        uint256 pre = pos.liquidity;
        _increasePosition(poolId, deltaLiquidity);
        uint256 post = positions[msg.sender][poolId].liquidity;
        assertEq(post, pre + deltaLiquidity, "increase-position");
    }

    function testDecreasePosition(uint256 deltaLiquidity) public {
        uint48 poolId = uint48(2);
        Position storage pos = positions[msg.sender][poolId];

        uint256 minimum = deltaLiquidity + 1;

        uint256 pre = pos.liquidity + minimum;
        _decreasePosition(poolId, deltaLiquidity);
        uint256 post = positions[msg.sender][poolId].liquidity;
        assertEq(post, pre - deltaLiquidity, "decrease-position");
    }

    function testIncreaseLiquidity(
        uint256 deltaBase,
        uint256 deltaQuote,
        uint256 deltaLiquidity
    ) public {
        uint48 poolId = uint48(12);
        helperCreateStandardPool(poolId);

        Pair memory pair = pairs[uint16(poolId >> 32)];
        uint256 preGlobal0 = globalReserves[pair.tokenBase];
        uint256 preGlobal1 = globalReserves[pair.tokenQuote];

        Pool memory pre = pools[poolId];
        _increaseLiquidity(poolId, deltaBase, deltaQuote, deltaLiquidity);
        Pool memory post = pools[poolId];

        uint256 postGlobal0 = globalReserves[pair.tokenBase];
        uint256 postGlobal1 = globalReserves[pair.tokenQuote];

        assertEq(postGlobal0, preGlobal0 + uint256(deltaBase), "global-base");
        assertEq(postGlobal1, preGlobal1 + uint256(deltaQuote), "global-quote");
        assertEq(post.internalBase, pre.internalBase + uint256(deltaBase), "pool-base");
        assertEq(post.internalQuote, pre.internalQuote + uint256(deltaQuote), "pool-quote");
        assertEq(post.internalLiquidity, pre.internalLiquidity + uint256(deltaLiquidity), "pool-liquidity");
        assertEq(post.blockTimestamp, _blockTimestamp(), "pool-timestamp");
    }

    function testAddLiquidity(
        bytes calldata data,
        uint48 poolId,
        uint256 deltaBase,
        uint256 deltaQuote
    ) external {
        helperCreateStandardPool(poolId);

        Pair memory pair = pairs[uint16(poolId >> 32)];
        uint256 preGlobal0 = globalReserves[pair.tokenBase];
        uint256 preGlobal1 = globalReserves[pair.tokenQuote];
        uint256 deltaLiquidity = getLiquidityMinted(poolId, deltaBase, deltaQuote);

        Pool memory pre = pools[poolId];
        _addLiquidity(data);
        Pool memory post = pools[poolId];

        uint256 postGlobal0 = globalReserves[pair.tokenBase];
        uint256 postGlobal1 = globalReserves[pair.tokenQuote];

        assertEq(postGlobal0, preGlobal0 + uint256(deltaBase), "global-base");
        assertEq(postGlobal1, preGlobal1 + uint256(deltaQuote), "global-quote");
        assertEq(post.internalBase, pre.internalBase + uint256(deltaBase), "pool-base");
        assertEq(post.internalQuote, pre.internalQuote + uint256(deltaQuote), "pool-quote");
        assertEq(post.internalLiquidity, pre.internalLiquidity + uint256(deltaLiquidity), "pool-liquidity");
        assertEq(post.blockTimestamp, _blockTimestamp(), "pool-timestamp");
    }

    function testRemoveLiquidity(
        bytes calldata data,
        uint48 poolId,
        uint256 deltaLiquidity
    ) public returns (uint256 deltaBase, uint256 deltaQuote) {
        {
            (uint8 useMax, uint48 poolId_, uint16 pairId, uint128 deltaLiquidity_) = Instructions.decodeRemoveLiquidity(
                data
            );

            assertEq(deltaLiquidity_, deltaLiquidity, "decoded-liquidity");
            assertEq(poolId_, poolId, "decoded-poolId");
        }

        helperCreateStandardPool(poolId);

        uint256 totalLiquidity = pools[poolId].internalLiquidity;
        require(totalLiquidity > deltaLiquidity, "remove-too-much");
        // note: there might not be enough global tokens in the reserves to remove...
        (uint256 inputBase, uint256 inputQuote) = getPhysicalReserves(poolId, deltaLiquidity);
        _increaseLiquidity(poolId, inputBase, inputQuote, deltaLiquidity);
        _increasePosition(poolId, deltaLiquidity); // Ensure enough liqudiity to remove.

        Pair memory pair = pairs[uint16(poolId >> 32)];
        uint256 preGlobal0 = globalReserves[pair.tokenBase];
        uint256 preGlobal1 = globalReserves[pair.tokenQuote];

        Pool memory pre = pools[poolId];
        (, deltaBase, deltaQuote) = _removeLiquidity(data);
        Pool memory post = pools[poolId];

        uint256 postGlobal0 = globalReserves[pair.tokenBase];
        uint256 postGlobal1 = globalReserves[pair.tokenQuote];

        assertEq(deltaBase, inputBase, "remove-base");
        assertEq(deltaQuote, inputQuote, "remove-quote");
        assertEq(postGlobal0, preGlobal0 - uint256(inputBase), "global-base");
        assertEq(postGlobal1, preGlobal1 - uint256(inputQuote), "global-quote");
        assertEq(post.internalBase, pre.internalBase - uint256(inputBase), "pool-base");
        assertEq(post.internalQuote, pre.internalQuote - uint256(inputQuote), "pool-quote");
        assertEq(post.internalLiquidity, pre.internalLiquidity - uint256(deltaLiquidity), "pool-liquidity");
        assertEq(post.blockTimestamp, _blockTimestamp(), "pool-timestamp");
    }

    function testCreatePair(
        bytes calldata data,
        address token0,
        address token1
    ) public {
        uint16 preNonce = uint16(pairNonce);
        _createPair(data);
        uint16 postNonce = uint16(pairNonce);

        assertEq(postNonce, preNonce + 1, "pair-nonce");

        Pair memory pair = pairs[postNonce];
        assertEq(pair.tokenBase, token0);
        assertEq(pair.tokenQuote, token1);
    }

    function testCreateCurve(
        bytes calldata data,
        uint24 sigma,
        uint32 maturity,
        uint16 fee,
        uint128 strike
    ) public {
        uint32 preNonce = uint32(curveNonce);
        _createCurve(data);
        uint32 postNonce = uint32(curveNonce);

        assertEq(postNonce, preNonce + 1, "curve-nonce");

        Curve memory curve = curves[postNonce];
        assertEq(sigma, curve.sigma);
        assertEq(maturity, curve.maturity);
        assertEq(1e4 - fee, curve.gamma);
        assertEq(strike, curve.strike);
    }

    function testCreatePool(bytes calldata data) public {
        _createPool(data);
    }

    function testCreatePool(bytes calldata data, uint48 poolId) public {}

    // --- Compiler --- //
    function fund(address, uint256) external override {}

    function draw(
        address,
        uint256,
        address
    ) external override {}

    // --- Swap --- //
    function updateLastTimestamp(uint48) public override lock returns (uint128) {
        return _blockTimestamp();
    }

    function getInvariant(uint48) public view override returns (int128) {}

    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        public
        view
        override
        returns (uint256 deltaBase, uint256 deltaQuote)
    {
        Pool memory pool = pools[poolId];
        uint256 total = uint256(pool.internalLiquidity);
        deltaBase = (uint256(pool.internalBase) * deltaLiquidity) / total;
        deltaQuote = (uint256(pool.internalQuote) * deltaLiquidity) / total;
    }
}
