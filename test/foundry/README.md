# Solidity Tests with Foundry

These are solidity written unit tests for both contract testing and fuzzing.

## Notes

- In Price library, `getXWithPrice` rounds up. Nevermind, there was a `+ 1` on the function. Investigate further.
- In Price library, `getPriceWithX` has precision of 1e-14.
