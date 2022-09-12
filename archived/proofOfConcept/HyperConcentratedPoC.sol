pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "solstat/Gaussian.sol";
import "solstat/Invariant.sol";

import "./EnigmaVirtualMachinePoc.sol";

/// @dev Liquidity allocated to price space for either curve type, perpetual or expiring.
abstract contract HyperConcentratedPoC is EnigmaVirtualMachinePoc {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    /**
     * @param lastPrice The previous price at which a swap occured.
     * @param lastLiquidity The previous amount of liquidity at which a swap occurred.
     * @param lastTimestamp The block.timestamp of the last swap.
     */
    struct PriceAndLiquidity {
        uint256 lastPrice;
        uint256 lastLiquidity;
        uint256 lastTimestamp;
        uint256 originTime;
    }

    mapping(uint48 => PriceAndLiquidity) public grid;

    function setPrice(
        uint48 poolId,
        uint256 price,
        uint256 liquidity
    ) public {
        grid[poolId] = PriceAndLiquidity(price, liquidity, uint256(_blockTimestamp()), 0);
    }

    uint48 public _tempPoolId;

    struct SwapArgs {
        uint48 id;
        uint256 amount;
        uint256 lastPrice;
        uint256 livePrice;
        uint256 nextPrice;
    }

    function _swap(
        uint48 poolId,
        uint8 direction,
        uint256 swapAmount,
        uint256 priceLimit
    )
        internal
        returns (
            uint256 price,
            uint256 amountIn,
            uint256 amountOut,
            uint256 remainder
        )
    {
        _tempPoolId = poolId;

        SwapArgs memory args = SwapArgs(poolId, swapAmount, 0, 0, 0);

        // Get the last price to start at.
        args.lastPrice = getStalePrice(args.id);

        // Get the last liquidity at the price.
        uint256 liquidity = getStaleLiquidity(args.id);

        // todo: fix inefficiency from stack too deep error
        // Compute the delta in time since last price update.
        PriceAndLiquidity memory info = grid[args.id];
        Curve memory curve = curves[uint32(args.id)];
        uint256 tau = curve.maturity - info.lastTimestamp;
        uint256 timeDelta = _blockTimestamp() - grid[args.id].lastTimestamp;
        // todo: handle double slot price crosses from theta
        // Theoretical price at which swaps start at given the amount of time that has passed.
        args.livePrice = getLivePrice(args.id, args.lastPrice, tau, timeDelta);

        // Gets the next price to compute the max distance between prices for this range.
        args.nextPrice = args.lastPrice - 3e18; //getNextPrice(args.livePrice); todo: fix formula

        // Compute the amounts to swap
        (price, amountIn, amountOut, remainder) = getSwapAmounts(args.amount, args.lastPrice, args.nextPrice, 1e18);

        //  --- Handle the actual swap. ---

        if (price != args.lastPrice) grid[args.id].lastPrice = price; // Update the pool's last price.

        // todo: actual token transfers
        // todo: handle limit price
        // todo: multiple iteration swap

        delete _tempPoolId;
    }

    function getSwapAmounts(
        uint256 swapAmount,
        uint256 lastPrice,
        uint256 nextPrice,
        uint256 liquidity
    )
        public
        view
        returns (
            uint256 price,
            uint256 amountIn,
            uint256 amountOut,
            uint256 remainder
        )
    {
        // Get change in reserve given max distance movement between prices.
        amountIn = getDeltaX(lastPrice, nextPrice);

        // If the swap amount is more than the max amount, then update the price to the next one.
        if (swapAmount >= amountIn) price = nextPrice;
        else price = getNextPriceGivenAmount(lastPrice, swapAmount);
    }

    /**
     * @notice Computes a price given a change in the respective reserve.
     * custom:math Maybe? P_b = P_a e^{Φ^-1(amount)}
     */
    function getNextPriceGivenAmount(uint256 lastPrice, uint256 amount) public view returns (uint256 price) {
        Curve memory curve = curves[uint32(_tempPoolId)];
        uint256 tau = curve.maturity - _blockTimestamp();
        uint256 lastReserve = computeBaseGivenPrice(lastPrice, curve.strike, curve.sigma, tau);
        uint256 nextReserve = lastReserve + amount;
        price = computePriceGivenBase(nextReserve, curve.strike, curve.sigma, tau);
    }

    /**
     * @custom:math X = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
     */
    function getDeltaX(uint256 lastPrice, uint256 nextPrice) public view returns (uint256 deltaX) {
        Curve memory curve = curves[uint32(_tempPoolId)];
        uint256 tau = curve.maturity - _blockTimestamp();
        uint256 lastReserve = computeBaseGivenPrice(lastPrice, curve.strike, curve.sigma, tau);
        uint256 nextReserve = computeBaseGivenPrice(nextPrice, curve.strike, curve.sigma, tau);
        deltaX = nextPrice < lastPrice ? nextReserve - lastReserve : lastReserve - nextReserve;
    }

    function getAmountsGivenChangeInPrice(uint256 priceChange, uint256 liquidity)
        public
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        // todo: fix
        amountIn = 1;
        amountOut = 1;
    }

    function getChangeInPriceGivenChangeInReserve(uint256 amount, uint256 liquidity)
        public
        view
        returns (uint256 priceChange)
    {
        // todo: fix
        priceChange = amount * liquidity;
    }

    function getStalePrice(uint48 poolId) public view returns (uint256) {
        return grid[poolId].lastPrice;
    }

    function getStaleLiquidity(uint48 poolId) public view returns (uint256) {
        return grid[poolId].lastLiquidity;
    }

    uint256 public constant YEAR = 31556953;
    uint256 public constant DOUBLE_WAD = 2e18;
    uint256 public constant WAD = 1e18;
    uint256 public constant HALF_WAD = 1e17;
    uint256 public constant SQRT_WAD = 1e9;

    /**
     * P(τ - ε) = ( P(τ)^(√(1 - ε/τ)) / K^2 )e^((1/2)(t^2)(√(τ)√(τ- ε) - (τ - ε)))
     */
    function getLivePrice(
        uint48 poolId,
        uint256 lastPrice,
        uint256 lastTau,
        uint256 timeDelta
    ) public view returns (uint256) {
        Curve memory curve = curves[uint32(poolId)];
        console.log(curve.strike, lastPrice, lastTau, timeDelta);

        uint256 tauYears;
        assembly {
            tauYears := sdiv(mul(lastTau, WAD), YEAR) // tau * WAD / year = time in years scaled to WAD
        }

        uint256 epsilonYears;
        assembly {
            epsilonYears := sdiv(mul(timeDelta, WAD), YEAR) // epsilon * WAD / year = epsilon in years scaled to WAD
        }

        uint256 term_0 = WAD - (epsilonYears.divWadUp(tauYears)); // WAD - ((epsilon * WAD) / tau rounded down), units are WAD - WAD, time units cancel out
        uint256 term_1 = term_0.sqrt(); // this sqrts WAD, so we end up with SQRT_WAD units

        uint256 term_2 = lastPrice.divWadUp(curve.strike); // p(t) / K, both units are already WAD
        uint256 term_3 = uint256(int256(term_2).powWad(int256(term_1 * SQRT_WAD)));

        // -- other section -- //

        uint256 currentTau = tauYears - epsilonYears; // WAD - WAD = WAD
        uint256 tausSqrt = tauYears.sqrt() * (currentTau).sqrt(); // sqrt(1e18) = 1e9, so 1e9 * 1e9 = 1e18
        uint256 term_4 = tausSqrt - currentTau; // WAD - WAD = WAD

        uint256 sigmaWad = (uint256(curve.sigma) * WAD) / 1e4;

        uint256 term_5 = (sigmaWad * sigmaWad) / DOUBLE_WAD; // 1e4 * 1e4 * 1e17 / 1e4 = 1e17, which is half WAD

        uint256 term_6 = uint256((int256(term_5.mulWadDown(term_4))).expWad()); // exp(WAD * WAD / WAD)
        uint256 term_7 = uint256(curve.strike).mulWadDown(term_6); // WAD * WAD / WAD

        uint256 price = term_3.mulWadDown(term_7); // WAD * WAD / WAD = WAD
        return price;
    }

    function getNextPrice(uint256 livePrice) public view returns (uint256) {
        // todo: implement price grid.
        return livePrice;
    }

    error CdfErr(int256 amt);

    /**
     * @dev Computes the reserve given a price of the asset of that reserve.
     * @custom:math X = 1 - N(d1)
     * @custom:math d₁ = ( ln(S/K) + (σ²/2)τ ) / σ√τ
     * @custom:math X = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
     */
    function computeBaseGivenPrice(
        uint256 price,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal view returns (uint256 x) {
        int256 ln = FixedPointMathLib.lnWad(int256(FixedPointMathLib.divWadDown(price, strike)));
        uint256 tauYears;
        assembly {
            tauYears := sdiv(mul(tau, WAD), YEAR)
        }

        uint256 sigmaWad = (uint256(sigma) * WAD) / 1e4;
        uint256 doubleSigma = (sigmaWad * sigmaWad) / DOUBLE_WAD;
        uint256 halfSigmaTau = doubleSigma * tauYears;
        uint256 sqrtTauSigma = (tauYears.sqrt() * 1e9).mulWadDown(sigmaWad);

        int256 lnOverVol = (ln * Gaussian.ONE + int256(halfSigmaTau)) / int256(sqrtTauSigma);
        int256 cdf = Gaussian.cdf(lnOverVol);
        if (cdf > Gaussian.ONE) revert CdfErr(cdf);
        x = uint256(Gaussian.ONE - cdf);

        console.log("computed x given price", x, price);
    }

    error OOB(uint256 amt);

    /**
     * @custom:math price = `strike` e^{Φ^{-1}(1 - `reserve`) (`sigma` sqrt{`tau`})} e^{-1 / 2 `sigma`^{2} `tau`}
     * @custom:math p_x = Ke^(Φ^-1(1 - x)σ√τ - 1/2σ^2τ)
     */
    function computePriceGivenBase(
        uint256 reserve,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public view returns (uint256 price) {
        uint256 tauYears = convertSecondsToWadYears(tau);
        uint256 sigmaWad = convertPercentageToWad(sigma);
        if (reserve > WAD) revert OOB(reserve);
        uint256 input = WAD - reserve;
        uint256 sigmaSqrtTau = sigmaWad.mulWadDown(tauYears.sqrt() * 1e9);
        uint256 doubleSigma = (sigmaWad * sigmaWad) / DOUBLE_WAD; // 1/2 o^2
        uint256 halfSigmaTau = doubleSigma.mulWadDown(tauYears); // 1/2 o^2 tau
        int256 secondTerm = (-int256(halfSigmaTau)).expWad();
        int256 firstTerm = int256(uint256(Gaussian.ppf(int256(input))).mulWadDown(sigmaSqrtTau)).expWad();
        price = strike.mulWadDown(uint256(firstTerm)).mulWadDown(uint256(secondTerm));
        console.log("given x, computed price", reserve, price);
    }

    function convertSecondsToWadYears(uint256 amountSeconds) public view returns (uint256 wadYears) {
        assembly {
            wadYears := div(mul(amountSeconds, WAD), YEAR)
        }
    }

    function convertPercentageToWad(uint256 percentage) public view returns (uint256 percentWad) {
        uint256 percentageScalar = 1e4;
        assembly {
            percentWad := div(mul(percentage, WAD), percentageScalar)
        }
    }
}
