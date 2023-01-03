# Foundry tests

## Setup

All Hyper tests inherit `TestHyperSetup.sol`, which inherits all the helpers in `test/helpers/`.

On setup the following state is initialized:

- Weth deployed.
- Hyper deployed.
- Hyper "RevertCatcher" is deployed. RevertCatcher will call an externally exposed `process` function, which will bubble up custom errors. Used for debugging `fallback`.
- Tokens are deployed.
- A "default" scenario is saved to state, which uses a set of default parameters, e.g. 1 ether of liquidity. To be used in tests.
- A pool is created and the poolId for it is attached to `defaultScenario` state.
- All tokens are approved for all users, to be spent by all contracts.
- All users are funded with starting balance.

## Unit Test

There are individual test contracts for each Hyper function. Each contract will test for the invariants specified [Here](../README.md).
