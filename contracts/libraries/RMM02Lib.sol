pragma solidity >=0.8.13;

import "solmate/utils/FixedPointMathLib.sol";
import {PortfolioPool} from "../PortfolioLib.sol";

/**
 * @notice Geometric portfolio objective.
 */
library RMM02Lib {
    using FixedPointMathLib for uint;
    using FixedPointMathLib for int;

    /**
     * @custom:math k = 1 - (R_x / w)^(w) (R_y/(1-w))^(1-w)
     */
    function invariantOf(PortfolioPool memory pool, uint R_x, uint R_y, uint weight) internal pure returns (int) {
        //(uint R_x, uint R_y) = (pool.virtualX, pool.virtualY);
        uint w1 = weight;
        uint w2 = 1 ether - weight;

        int part0 = int(R_x.divWadDown(w1)).powWad(int(w1));
        int part1 = int(R_y.divWadDown(w2)).powWad(int(w2));

        int result = (part0 * part1) / int(1 ether);
        return result;
    }

    function getAmountOut(
        PortfolioPool memory pool,
        uint weight,
        bool xIn,
        uint amountIn,
        uint feeBps
    ) internal view returns (uint) {
        if (xIn) {
            uint input = (pool.virtualX * 1 ether) / (pool.virtualX + amountIn);
            int bi = int(weight.divWadDown(1 ether - weight));
            int pow = int(input).powWad(bi);
            uint a0 = uint(pool.virtualY).mulWadDown(uint(int(1 ether) - pow));
            return a0;
        } else {
            return 72;
        }
    }

    // p = bi / wi / bo / wo
    // price = (bi / weight ) / (bo / (1 - weight))
    // price = bi * 1 / weight * (1 - weight) / bo
    // price * weight / (1 - weight) = bi / bo
    // price *
    function computeReservesWithPrice(
        PortfolioPool memory pool,
        uint price,
        uint weight,
        uint balance
    ) internal pure returns (uint R_x, uint R_y) {
        pool;
        uint wi = weight;
        uint wo = 1 ether - weight;

        R_x = balance;
        R_y = R_x.divWadDown(price.mulWadDown(wi.divWadDown(1 ether - wo)));
    }

    function computePrice(PortfolioPool memory pool, uint weight) internal pure returns (uint price) {
        price = uint(pool.virtualX).divWadDown(weight).mulWadDown((1 ether - weight).divWadDown(uint(pool.virtualY)));
    }
}
