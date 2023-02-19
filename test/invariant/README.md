# End-to-End Tests

These are full end to end system tests using random action calls and checked against the system invariants.

## Setup

To use Foundry's invariant testing, you must expose a `targetContracts() view returns(address[] memory)` function. This is done in `test/E2E/setup/TestInvariantSetup.sol.sol`. Without this, the invariant testing has no public functions to call to mutate state.

In `test/E2E/setup/TestE2ESetup.sol` we push "invariant" contracts to that array. Each invariant contract has a public function that mutates the contract's state in some way.

Invariant tests are run with `forge test --match-contract TestE2EInvariant.sol`. This will assert all the invariants as state is being mutated by the invariant contracts that inherit `test/E2E/setup/InvariantTargetContract.sol`.

It's important the invariant contracts are not `.t.sol` files.

## System Invariants

Read system invariants [Here](../README.md).

## Notes

BUG: A revert in a free function will let all invariant tests pass?
BUG: Reverting in assembly will let all invariant tests pass?
