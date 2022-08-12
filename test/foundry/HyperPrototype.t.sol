pragma solidity 0.8.13;

import "../shared/BaseTest.sol";

import "../../contracts/prototype/HyperPrototype.sol";

contract TestHyperPrototype is HyperPrototype, BaseTest {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    function testSlick() public {
        bool perpetual = (0 | 1 | 0) == 0;
        console.log("is perpetual?", perpetual);
        assembly {
            perpetual := iszero(or(0, or(1, 0))) // ((strike == 0 && sigma == 0) && maturity == 0)
        }

        console.log("is perpetual?", perpetual);
    }

    function testComputePriceWithTickFn() public {
        uint256 price = __computePriceGivenTickIndex(int24(512));
        console.log(price);

        int24 tick = __computeTickIndexGivenPrice(price);
        console.logInt(tick);
        assertEq(tick, int24(512));
    }

    /**
        e^(ln(1.0001) * tickIndex) = price

        ln(price) = ln(1.0001) * tickIndex

        tickIndex = ln(price) / ln(1.0001)
     */
    function __computePriceGivenTickIndex(int24 tickIndex) internal view returns (uint256 price) {
        int256 tickWad = int256(tickIndex) * int256(FixedPointMathLib.WAD);
        price = uint256(FixedPointMathLib.powWad(1_0001e14, tickWad));
    }

    function __computeTickIndexGivenPrice(uint256 priceWad) internal view returns (int24 tick) {
        uint256 numerator = uint256(int256(priceWad).lnWad());
        uint256 denominator = uint256(int256(1_0001e14).lnWad());
        uint256 val = numerator / denominator + 1;
        tick = int24(int256((numerator)) / int256(denominator) + 1);
    }
}
