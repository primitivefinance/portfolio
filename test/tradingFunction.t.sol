// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./Setup.sol";

/**
 * @dev Please, solidity, add support for fixed sized arrays in storage!
 *
 * [NormalCurve({
 *             reserveXPerWad: 0,
 *             reserveYPerWad: 0,
 *             strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
 *             standardDeviationWad: NormalConfiguration_DEFAULT_VOLATILITY_BPS * 1e14, // 10%
 *             timeRemainingSeconds: NormalConfiguration_DEFAULT_DURATION_SEC,
 *             invariant: 0
 *         }),
 *         NormalCurve({
 *             reserveXPerWad: 0,
 *             reserveYPerWad: 0,
 *             strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
 *             standardDeviationWad: MIN_VOLATILITY * 1e14, // .01%
 *             timeRemainingSeconds: NormalConfiguration_DEFAULT_DURATION_SEC, // 1 days in seconds
 *             invariant: 0
 *         }),
 *         NormalCurve({
 *             reserveXPerWad: 0,
 *             reserveYPerWad: 0,
 *             strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
 *             standardDeviationWad: MAX_VOLATILITY * 1e14, // 250%,
 *             timeRemainingSeconds: NormalConfiguration_DEFAULT_DURATION_SEC,
 *             invariant: 0
 *         }),
 *         NormalCurve({
 *             reserveXPerWad: 0,
 *             reserveYPerWad: 0,
 *             strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
 *             standardDeviationWad: NormalConfiguration_DEFAULT_VOLATILITY_BPS * 1e14, // 10%,
 *             timeRemainingSeconds: MIN_DURATION,
 *             invariant: 0
 *         }),
 *         NormalCurve({
 *             reserveXPerWad: 0,
 *             reserveYPerWad: 0,
 *             strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
 *             standardDeviationWad: NormalConfiguration_DEFAULT_VOLATILITY_BPS * 1e14, // 10%
 *             timeRemainingSeconds: MAX_DURATION,
 *             invariant: 0
 *         })
 *     ];
 * @author alexangelj
 * @notice Uses the branching tree technique (BTT), defined in tradingFunction.tree.
 */
contract TestTradingFunction is Setup {
    NormalCurve[] public profiles;

    function setUp() public override {
        super.setUp();

        profiles.push(
            NormalCurve({
                reserveXPerWad: 0,
                reserveYPerWad: 0,
                strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
                standardDeviationWad: NormalConfiguration_DEFAULT_VOLATILITY_BPS
                    * 1e14, // 10%
                timeRemainingSeconds: NormalConfiguration_DEFAULT_DURATION_SEC,
                invariant: 0
            })
        );

        profiles.push(
            NormalCurve({
                reserveXPerWad: 0,
                reserveYPerWad: 0,
                strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
                standardDeviationWad: MIN_VOLATILITY * 1e14, // .01%
                timeRemainingSeconds: NormalConfiguration_DEFAULT_DURATION_SEC, // 1 days in seconds
                invariant: 0
            })
        );

        profiles.push(
            NormalCurve({
                reserveXPerWad: 0,
                reserveYPerWad: 0,
                strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
                standardDeviationWad: MAX_VOLATILITY * 1e14, // 250%,
                timeRemainingSeconds: NormalConfiguration_DEFAULT_DURATION_SEC,
                invariant: 0
            })
        );

        profiles.push(
            NormalCurve({
                reserveXPerWad: 0,
                reserveYPerWad: 0,
                strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
                standardDeviationWad: NormalConfiguration_DEFAULT_VOLATILITY_BPS
                    * 1e14, // 10%,
                timeRemainingSeconds: MIN_DURATION,
                invariant: 0
            })
        );

        profiles.push(
            NormalCurve({
                reserveXPerWad: 0,
                reserveYPerWad: 0,
                strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD,
                standardDeviationWad: NormalConfiguration_DEFAULT_VOLATILITY_BPS
                    * 1e14, // 10%
                timeRemainingSeconds: MAX_DURATION,
                invariant: 0
            })
        );
    }

    uint256 public UPPER_BOUND = WAD;
    uint256 public LOWER_BOUND = 0;

    /// @dev Trading function is monotonic when reserves change by at least more than 1 wei.
    /// This is because a 1 wei change is a rounding error for the trading function.
    uint256 public MONOTONICITY_DELTA = 2;

    NormalCurve defaultCurve = NormalCurve({
        reserveXPerWad: 0,
        reserveYPerWad: 0,
        strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD, // $1
        standardDeviationWad: NormalConfiguration_DEFAULT_VOLATILITY_BPS * 1e14, // 100%
        timeRemainingSeconds: NormalConfiguration_DEFAULT_DURATION_SEC, // 1 days in seconds
        invariant: 0
    });

    NormalCurve normalCurve = defaultCurve;

    modifier whenReserveXPerWadIsAtTheUpperBound() {
        normalCurve.reserveXPerWad = UPPER_BOUND;
        _;
        delete normalCurve;
    }

    modifier whenReserveYPerWadIsNotAtTheLowerBound() {
        normalCurve.reserveYPerWad++;
        _;
        delete normalCurve;
    }

    function test_WhenReserveYPerWadIsNotAtTheLowerBound()
        external
        whenReserveXPerWadIsAtTheUpperBound
        whenReserveYPerWadIsNotAtTheLowerBound
    {
        // It should revert with `NormalStrategyLib_LowerReserveYBoundNotReached`
        vm.expectRevert(NormalStrategyLib_LowerReserveYBoundNotReached.selector);
        normalCurve.tradingFunction();
    }

    modifier whenReserveYPerWadIsAtTheLowerBound() {
        normalCurve.reserveYPerWad = LOWER_BOUND;
        _;
    }

    function test_WhenReserveYPerWadIsAtTheLowerBound()
        external
        whenReserveXPerWadIsAtTheUpperBound
        whenReserveYPerWadIsAtTheLowerBound
    {
        // It should return σ√τ
        int256 expected = int256(normalCurve.computeStdDevSqrtTau());
        int256 actual = normalCurve.tradingFunction();
        assertEq(
            actual, expected, "tradingFunction should return stdDevSqrtTau"
        );
    }

    modifier whenReserveXPerWadIsNotAtTheUpperBound() {
        normalCurve.reserveXPerWad++;
        _;
    }

    function test_WhenReserveXPerWadIsNotAtTheUpperBound()
        external
        whenReserveYPerWadIsAtTheLowerBound
        whenReserveXPerWadIsNotAtTheUpperBound
    {
        // It should revert with `NormalStrategyLib_UpperReserveXBoundNotReached`
        vm.expectRevert(NormalStrategyLib_UpperReserveXBoundNotReached.selector);
        normalCurve.tradingFunction();
    }

    function test_WhenReserveXPerWadIsAtTheUpperBound()
        external
        whenReserveYPerWadIsAtTheLowerBound
        whenReserveXPerWadIsAtTheUpperBound
    {
        // It should return σ√τ
        int256 expected = int256(normalCurve.computeStdDevSqrtTau());
        int256 actual = normalCurve.tradingFunction();
        assertEq(
            actual, expected, "tradingFunction should return stdDevSqrtTau"
        );
    }

    modifier whenReserveXPerWadIsAtTheLowerBound() {
        normalCurve.reserveXPerWad = LOWER_BOUND;
        _;
    }

    modifier whenReserveYPerWadIsNotAtTheUpperBound() {
        if (normalCurve.reserveYPerWad >= UPPER_BOUND) {
            normalCurve.reserveYPerWad--;
        }

        if (normalCurve.reserveYPerWad == LOWER_BOUND) {
            normalCurve.reserveYPerWad++;
        }
        _;
    }

    function test_WhenReserveYPerWadIsNotAtTheUpperBound()
        external
        whenReserveXPerWadIsAtTheLowerBound
        whenReserveYPerWadIsNotAtTheUpperBound
    {
        // It should revert with `NormalStrategyLib_UpperReserveYBoundNotReached`
        vm.expectRevert(NormalStrategyLib_UpperReserveYBoundNotReached.selector);
        normalCurve.tradingFunction();
    }

    modifier whenReserveYPerWadIsAtTheUpperBound() {
        normalCurve.reserveYPerWad = UPPER_BOUND;
        _;
    }

    function test_WhenReserveYPerWadIsAtTheUpperBound()
        external
        whenReserveXPerWadIsAtTheLowerBound
        whenReserveYPerWadIsAtTheUpperBound
    {
        // It should return σ√τ if reserveYPerWad
        int256 expected = int256(normalCurve.computeStdDevSqrtTau());
        int256 actual = normalCurve.tradingFunction();
        assertEq(
            actual, expected, "tradingFunction should return stdDevSqrtTau"
        );
    }

    modifier whenReserveXPerWadIsNotAtTheLowerBound() {
        if (normalCurve.reserveXPerWad <= LOWER_BOUND) {
            normalCurve.reserveXPerWad++;
        }
        _;
    }

    function test_WhenReserveXPerWadIsNotAtTheLowerBound()
        external
        whenReserveYPerWadIsAtTheUpperBound
        whenReserveXPerWadIsNotAtTheLowerBound
    {
        // It should revert with `NormalStrategyLib_LowerReserveXBoundNotReached`
        vm.expectRevert(NormalStrategyLib_LowerReserveXBoundNotReached.selector);
        normalCurve.tradingFunction();
    }

    function test_WhenReserveXPerWadIsAtTheLowerBound()
        external
        whenReserveYPerWadIsAtTheUpperBound
        whenReserveXPerWadIsAtTheLowerBound
    {
        // It should return σ√τ
        int256 expected = int256(normalCurve.computeStdDevSqrtTau());
        int256 actual = normalCurve.tradingFunction();
        assertEq(
            actual, expected, "tradingFunction should return stdDevSqrtTau"
        );
    }

    modifier whenReserveXPerWadAndReserveYPerWadAreBothNotAtAnyBound() {
        if (normalCurve.reserveXPerWad <= LOWER_BOUND) {
            normalCurve.reserveXPerWad++;
        }

        if (normalCurve.reserveXPerWad >= UPPER_BOUND) {
            normalCurve.reserveXPerWad--;
        }

        if (normalCurve.reserveYPerWad <= LOWER_BOUND) {
            normalCurve.reserveYPerWad++;
        }

        if (normalCurve.reserveYPerWad >= UPPER_BOUND) {
            normalCurve.reserveYPerWad--;
        }
        _;
    }

    function test_WhenReserveXPerWadAndReserveYPerWadAreBothNotAtAnyBound()
        external
        whenReserveXPerWadAndReserveYPerWadAreBothNotAtAnyBound
    {
        // It should not revert
        // It should return `Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ`
        uint256 stdDevSqrtTau = normalCurve.computeStdDevSqrtTau();
        int256 invariant = normalCurve.tradingFunction();
        assertTrue(
            invariant != int256(stdDevSqrtTau),
            "tradingFunction should not return only stdDevSqrtTau"
        );
    }

    function test_fuzz_WhenReserveXPerWadAndReserveYPerWadAreBothNotAtAnyBound(
        uint256 seed
    ) external whenReserveXPerWadAndReserveYPerWadAreBothNotAtAnyBound {
        normalCurve.reserveXPerWad =
            bound(seed, LOWER_BOUND + 1, UPPER_BOUND - 1);
        normalCurve.reserveYPerWad =
            bound(seed, LOWER_BOUND + 1, normalCurve.strikePriceWad - 1);

        // It should not revert
        // It should return `Φ⁻¹(y/K) - Φ⁻¹(1-x) + σ√τ`
        uint256 stdDevSqrtTau = normalCurve.computeStdDevSqrtTau();
        int256 invariant = normalCurve.tradingFunction();
        assertTrue(
            invariant != int256(stdDevSqrtTau),
            "tradingFunction should not return only stdDevSqrtTau"
        );
    }

    modifier whenUsingAllParameterProfiles(uint256 rand) {
        uint256 index = rand % profiles.length;
        normalCurve = profiles[index];
        (normalCurve.reserveXPerWad, normalCurve.reserveYPerWad) = normalCurve
            .approximateReservesGivenPrice(normalCurve.strikePriceWad);
        _;
    }

    modifier whenIncreasingReserveXPerWad() {
        int256 prev = normalCurve.tradingFunction();
        normalCurve.reserveXPerWad += MONOTONICITY_DELTA;
        _;
        int256 post = normalCurve.tradingFunction();
        assertTrue(post > prev, "Invariant should increase");
    }

    function test_fuzz_WhenIncreasingReserveXPerWad(uint256 rand)
        external
        whenUsingAllParameterProfiles(rand)
        whenIncreasingReserveXPerWad
    {
        // It should increase the invariant
    }

    modifier whenIncreasingReserveYPerWad() {
        int256 prev = normalCurve.tradingFunction();
        normalCurve.reserveYPerWad += MONOTONICITY_DELTA;
        _;
        int256 post = normalCurve.tradingFunction();
        assertTrue(post > prev, "Invariant should increase");
    }

    function test_fuzz_WhenIncreasingReserveYPerWad(uint256 rand)
        external
        whenUsingAllParameterProfiles(rand)
        whenIncreasingReserveYPerWad
    {
        // It should increase the invariant
    }

    modifier whenDecreasingReserveXPerWad() {
        int256 prev = normalCurve.tradingFunction();
        normalCurve.reserveXPerWad -= MONOTONICITY_DELTA;
        _;
        int256 post = normalCurve.tradingFunction();
        assertTrue(post < prev, "Invariant should decrease");
    }

    function test_fuzz_WhenDecreasingReserveXPerWad(uint256 rand)
        external
        whenUsingAllParameterProfiles(rand)
        whenDecreasingReserveXPerWad
    {
        // It should decrease the invariant
    }

    modifier whenDecreasingReserveYPerWad() {
        int256 prev = normalCurve.tradingFunction();
        normalCurve.reserveYPerWad -= MONOTONICITY_DELTA;
        _;
        int256 post = normalCurve.tradingFunction();
        assertTrue(post < prev, "Invariant should decrease");
    }

    function test_fuzz_WhenDecreasingReserveYPerWad(uint256 rand)
        external
        whenUsingAllParameterProfiles(rand)
        whenDecreasingReserveYPerWad
    {
        // It should decrease the invariant
    }
}
