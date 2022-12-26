# Solidity Tests with Foundry

These are solidity written unit tests for both contract testing and fuzzing.

## Notes

- In Price library, `computeR2WithPrice` rounds up. Nevermind, there was a `+ 1` on the function. Investigate further.
- In Price library, `computePriceWithR2` has precision of 1e-14.
