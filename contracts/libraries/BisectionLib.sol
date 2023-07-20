// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

/// @dev Thrown when the lower bound is greater than the upper bound.
error BisectionLib_InvalidBounds(uint256 lower, uint256 upper);
/// @dev Thrown when the result of the function `fx` for each input, `upper` and `lower`, is the same sign.
error BisectionLib_RootOutsideBounds(uint256 lower, uint256 upper);

/**
 * @notice
 * The function `fx` must be continuous and monotonic.
 *
 * @dev
 * Bisection is a method of finding the root of a function.
 * The root is the point where the function crosses the x-axis.
 *
 * @param args The arguments to pass to the function `fx`.
 * @param lower The lower bound of the root to find.
 * @param upper The upper bound of the root to find.
 * @param epsilon The maximum distance between the lower and upper results.
 * @param maxIterations The maximum amount of loop iterations to run.
 * @param fx The function to find the root of.
 * @return root The root of the function `fx`.
 */
function bisection(
    bytes memory args,
    uint256 lower,
    uint256 upper,
    uint256 epsilon,
    uint256 maxIterations,
    function(bytes memory,uint256) pure returns (int256) fx
) pure returns (uint256 root) {
    if (lower > upper) revert BisectionLib_InvalidBounds(lower, upper);
    // Passes the lower and upper bounds to the optimized function.
    // Reverts if the optimized function `fx` returns both negative or both positive values.
    // This means that the root is not between the bounds.
    // The root is between the bounds if the product of the two values is negative.
    int256 lowerOutput = fx(args, lower);
    int256 upperOutput = fx(args, upper);
    if (lowerOutput * upperOutput > 0) {
        revert BisectionLib_RootOutsideBounds(lower, upper);
    }

    // Distance is optimized to equal `epsilon`.
    uint256 distance = upper - lower;

    uint256 iterations; // Bounds the amount of loops to `maxIterations`.
    do {
        // Bisection uses the point between the lower and upper bounds.
        // The `distance` is halved each iteration.
        root = (lower + upper) / 2;

        int256 output = fx(args, root);

        // If the product is negative, the root is between the lower and root.
        // If the product is positive, the root is between the root and upper.
        if (output * lowerOutput <= 0) {
            upper = root; // Set the new upper bound to the root because we know its between the lower and root.
        } else {
            lower = root; // Set the new lower bound to the root because we know its between the upper and root.
            lowerOutput = output; // root function value becomes new lower output value
        }

        // Update the distance with the new bounds.
        distance = upper - lower;

        unchecked {
            iterations++; // Increment the iterator.
        }
    } while (distance > epsilon && iterations < maxIterations);
}
