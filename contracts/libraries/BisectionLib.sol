pragma solidity ^0.8.4;

struct Bisection {
    uint256 terminalPriceWad;
    uint256 volatilityFactorWad;
    uint256 timeRemainingSec;
    uint256 independentReserve;
    uint256 dependentReserve;
}

function bisection(
    Bisection memory args,
    int256 ain,
    int256 bin,
    int256 eps,
    int256 max,
    function(Bisection memory,int256) pure returns (int256) fx
) pure returns (int256 root) {
    // Chosen `a` and `b` are incorrect.
    // False if ain * bin < 0, !(ain * bin < 0).
    int256 fxa = fx(args, ain);
    int256 fxb = fx(args, bin);
    require(fxa * fxb < 0, "gt 0");
    /* assembly {
            if iszero(slt(mul(fxa, fxb), 0)) { revert(0, 0) }
        } */

    int256 dif;
    int256 itr;
    assembly {
        dif := sub(bin, ain) // todo: check for overflow/underflow
    } // Are we getting closer to epsilon?

    do {
        assembly {
            root := sdiv(add(ain, bin), 2) // todo: check for overflow
        } // root = a + b / 2

        int256 fxr = fx(args, root);
        if (fxr == 0) break;
        fxa = fx(args, ain);

        assembly {
            // todo: check for overflow
            switch slt(mul(fxr, fxa), 0)
            // Decide which side to repeat, `a` or `b`.
            case 1 { bin := root }
            // 1 if fxr * fxa < 0
            case 0 { ain := root } // else 0
            itr := add(itr, 1) // Increment iterator.
        }
    } while (dif >= eps && itr < max);
}
