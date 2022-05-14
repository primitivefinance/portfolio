pragma solidity ^0.8.0;

import "./ABDKMath64x64.sol";

library Newton {
    using ABDKMath64x64 for int128;

    /// @notice Uses Newton's method to solve the root of the function `fx` within `maxRuns` with error `epsilon`.
    /// @param  x Initial guess of the root of `fx`.
    /// @param  epsilon Error boundary of the root.
    /// @param  maxRuns Maximum iterations before exiting the method's loop.
    /// @param  fx Function to solve the root of.
    /// @param  dx Derivative of the function `fx`.
    /// @return x Computed root, within the `maxRuns` of `fx`.
    function compute(
        int128 x,
        int128 epsilon,
        uint256 maxRuns,
        function(int128) pure returns (int128) fx,
        function(int128) pure returns (int128) dx
    ) internal pure returns (int128) {
        uint256 runs;
        int128 h = fx(x).div(dx(x));
        do {
            h = fx(x).div(dx(x));
            x = x.sub(h);
            unchecked {
                ++runs;
            }
        } while (h.abs() >= epsilon && runs < maxRuns);

        return x;
    }

    uint256 public constant TEN = 10;

    function computeTen(
        int128 x,
        int128 epsilon,
        function(int128) pure returns (int128) fx,
        function(int128) pure returns (int128) dx
    ) internal pure returns (int128) {
        uint256 runs;
        int128 h = fx(x).div(dx(x));
        do {
            h = fx(x).div(dx(x));
            x = x.sub(h);
            unchecked {
                ++runs;
            }
        } while (h.abs() >= epsilon && runs < TEN);

        return x;
    }
}
