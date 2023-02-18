// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/**
    @dev Marginal price to trade y (∆) for x (∆′).

    Variable | Name         | Value
    ---------|--------------|-----------
    γ        | Gamma        | 1 - fee, Percentage
    K        | Strike       | K > 0, Wad
    k        | Invariant    | 2^128 > k > -2^128, Signed integer
    y        | Quote        | K >= y >= 0, Wad
    x        | Asset        | 1 >= x >= 0, Wad

    @custom:source https://primitive.xyz/whitepaper-rmm-01.pdf
 */

import "solmate/utils/FixedPointMathLib.sol";
import "contracts/libraries/Price.sol";

using FixedPointMathLib for uint256;

uint256 constant HALF_SCALAR = 1e9;
uint256 constant WAD = 1 ether;

/**
 @custom:math 1 / φ( Φ^(−1) (x) )
 */
function d_ppf(int256 input) pure returns (int256) {
    int256 numerator;
    int256 denominator;
    assembly {
        numerator := mul(WAD, WAD)
    }

    denominator = Gaussian.pdf(Gaussian.ppf(input));

    int256 output;
    assembly {
        output := sdiv(numerator, denominator)
    }

    return output;
}

struct Parameters {
    uint256 stk;
    uint256 vol;
    uint256 tau;
    uint256 fee;
    int256 inv;
}

/**
    todo: currently broken, marginal price goes lower after a swap in, should go higher!
    @dev Marginal price to trade y (∆) for x (∆′).
    @custom:math ( d∆′ / d∆ ) (∆) = (K / γ) φ( Φ^(−1)( ( y + γ∆ − k) / K ) + σ√τ) × (Φ−1)′ ( (y + γ∆ − k) / K )
    @custom:source https://primitive.xyz/whitepaper-rmm-01.pdf
 */
function computeMarginalPriceQuoteIn(
    uint256 d_y,
    uint256 R_y,
    uint256 stk,
    uint256 vol,
    uint256 tau,
    uint256 fee,
    int256 inv
) pure returns (uint256) {
    Parameters memory params = Parameters({stk: stk, vol: vol, tau: tau, fee: fee, inv: inv});
    uint256 volSqrtTau;
    uint256 gamma;
    {
        uint256 tauWadYears = Price.convertSecondsToWadYears(params.tau);
        uint256 volWad = Price.convertPercentageToWad(params.vol);
        uint256 feeWad = Price.convertPercentageToWad(params.fee);
        uint256 sqrtTau = tauWadYears.sqrt();
        gamma = FixedPointMathLib.WAD - feeWad;
        volSqrtTau = (sqrtTau * HALF_SCALAR).mulWadDown(volWad);
    }

    uint256 part0 = R_y + d_y.mulWadDown(gamma); // ( y + γ∆)
    assembly {
        part0 := add(part0, inv) // // ( y + γ∆ − k)
    }

    uint256 part1 = part0.divWadDown(params.stk); // ( y + γ∆ − k) / K )
    int256 part2 = Gaussian.ppf(int256(part1)); // Φ^(−1)( ( y + γ∆ − k) / K )

    int256 part3;
    assembly {
        part3 := add(part2, volSqrtTau) // Φ^(−1)( ( y + γ∆ − k) / K ) + σ√τ
    }

    uint256 part4 = (params.stk).divWadDown(gamma); // K / γ
    uint256 part5 = part4.mulWadDown(uint256(Gaussian.pdf(int256(part3)))); // (K / γ) φ( Φ^(−1)( ( y + γ∆ − k) / K ) + σ√τ)

    int256 part6 = d_ppf(int256(part1)); // (Φ−1)′ ( (y + γ∆ − k) / K )

    uint256 d_x; // ( d∆′ / d∆ ) (∆) = part5 * part6
    assembly {
        d_x := mul(part5, part6)
        d_x := sdiv(d_x, WAD)
    }

    return d_x;
}

/**
    @dev Marginal price to trade x (∆) for y (∆′).
    @custom:math (d∆′ / d∆) (∆) = γKφ(Φ−1(1 − x − γ∆) − σ√τ ) × (Φ−1)′(1 − x − γ∆)
    @custom:source https://primitive.xyz/whitepaper-rmm-01.pdf
 */
function computeMarginalPriceAssetIn(
    uint256 d_x,
    uint256 R_x,
    uint256 stk,
    uint256 vol,
    uint256 tau,
    uint256 fee,
    int256 inv
) pure returns (uint256) {
    Parameters memory params = Parameters({stk: stk, vol: vol, tau: tau, fee: fee, inv: inv});
    uint256 sqrtTau;
    uint256 volSqrtTau;
    uint256 gamma;
    {
        uint256 tauWadYears = Price.convertSecondsToWadYears(params.tau);
        uint256 volWad = Price.convertPercentageToWad(params.vol);
        uint256 feeWad = Price.convertPercentageToWad(params.fee);
        gamma = FixedPointMathLib.WAD - feeWad;
        sqrtTau = tauWadYears.sqrt();
        volSqrtTau = (sqrtTau * HALF_SCALAR).mulWadDown(volWad);
    }

    uint256 part0 = WAD - R_x - d_x.mulWadDown(gamma); // 1 wad > x > 0 wad
    int256 part1 = Gaussian.ppf(int256(part0));

    uint256 part2;
    assembly {
        part2 := sub(part1, volSqrtTau)
    }

    uint256 part3 = gamma.mulWadDown(params.stk);
    int256 part4 = Gaussian.pdf(int256(part2));
    uint256 part5 = part3.mulWadDown(uint256(part4));

    int256 part6 = d_ppf(int256(part0)); // todo: fix, need derivative!
    uint256 d_y;
    assembly {
        d_y := mul(part5, part6) // todo: unsigned * signed, dangerous!
        d_y := sdiv(d_y, WAD)
    }

    return d_y;
}
