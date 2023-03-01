# Primitive Portfolio Testing

Primitive follows [test driven development](https://en.wikipedia.org/wiki/Test-driven_development).

We follow the principles described in this [Microsoft Unit Testing Best Practices](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices).

For solidity, we follow the [Primitive Smart Contract Style Guide]().

# Table of Contents

- I. Introduction
  - [Installation]()
- II.
  - [Primitive System Invariants]()
- III. Basic
  - [Unit tests]()
    - [Foundry]()
    - [Hardhat]()
  - [End-to-end tests]()
    - [Hardhat]()
    - [Echidna]()
- IV. Advanced
  - [Fuzz tests]()
    - [Echidna]()
    - [Foundry]()
  - [Differential tests]()
    - [Solstat library]()
  - [Fork testing]()
  - [Adversarial testing]()

# I. Introduction

This test suite is comprehensive. There are unit tests written using foundry and hardhat, fuzz testing with echidna and foundry, and invariant testing using foundry.

## Installation

The setup is a little complicated... here&#39;s what is going on:

### Pre-reqs: Must have python, node >=v16.0.0, ganache, and yarn.

### 1. Install nix. [source](https://nixos.org/download.html#nix-install-linux)

`sh <(curl -L https://nixos.org/nix/install) --no-daemon`

### 2. Install foundry. [source](https://github.com/foundry-rs/foundry)

`curl -L https://foundry.paradigm.xyz | bash`

### 3. Restart terminal or reload `PATH`, then run:

`foundryup`

### 4. Install crytic-compile. [source](https://github.com/crytic/crytic-compile)

`pip3 install crytic-compile`

### 5.Install echidna using nix. [source](https://github.com/crytic/echidna)

`nix-env -i -f https://github.com/crytic/echidna/tarball/master`

At this point, you should be setup to interact with the test suites.

### 6. Install deps

`yarn install`

### 7. Install submodules

`forge install`

### 8. Test

`yarn test`, `yarn test:echidna`.

### 9. Clean up cached builds

`yarn clean`.

### 10. Get gas report

`yarn profile`

---

# II. Primitive System Invariants

System invariants are tested using Foundry's invariant testing. There is no documentation for Foundry's invariant testing at the moment, so use the dapptools docs as a reference: [Invariant Testing](https://github.com/dapphub/dapptools/blob/master/src/dapp/README.md#invariant-testing).

### Portfolio.sol

#### Global

- Token balances of Portfolio should be greater than or equal to the `reserves` of all tokens.
- For every pool, `reserves` of the pool's tokens should always be greater than the `getAmounts` output for the pool's entire liquidity.
- The sum of liquidity in all pools must be equal to the sum of liquidity of every position.
- The `lock` variable must always return `1` outside of execution.
- The `__account__.settled` variable must always return true outside of execution.
- The `__account__.prepared` variable must always return false outside of execution.
- The `__account__.warm` variable must always be an empty array outside of execution.

#### Deposit

- Preconditions:
  - `msg.value` is greater than zero.
- During Execution:
  - The `msg.value` amount of ether sent to the contract is deposited into the weth contract via `deposit() payable`.
- Postconditions:
  - Caller's `balances` value of `weth` increased by `msg.value`.
  - Portfolio's `address(this).balance` is equal to the balance prior to calling the function.
  - Portfolio's `reserves` value for `weth` increased by `msg.value`.
  - Portfolio's `balanceOf` `weth` increased by `msg.value`.
  - The `Deposit` event was emitted.

#### Fund

- Preconditions:
  - Caller must approve Portfolio to spend `amount` of tokens.
  - Caller must have a balance greater than equal to `amount` of tokens.
- During Execution:
  - The `token` must be added to the `__account__.warm` address array.
  - The `__account__.cache` mapping must return `true` for `token`.
- Postconditions:
  - The Caller's `balances` value for the `token` increased by `amount`.
  - The `IncreaseUserBalance` event was emitted.
  - Portfolio's `reserves` value for the `token` increased by `amount`.
  - The `balanceOf` Portfolio for `token` increased by `amount`.
  - Calling `draw` with the same `amount` always suceeds.

#### Draw

- Preconditions:
  - Caller must have a `balances` of `token` greater than or equal to `amount` to withdraw.
- During Execution:
  - Internal `AccountSystem.debit` function returns `true`.
- Postcondition:
  - The Caller's `balances` value for `token` decreased by `amount`.
  - The `DecreaseUserBalance` event was emitted.
  - Portfolio's `reserves` value for the `token` decreased by `amount`.
  - The `to` address received `amount` of token or `amount` of Ether, if `token === weth`.
  - Portfolio's `balanceOf` value for `token` decreased by `amount`.

#### Claim

- Preconditions:
  - Caller has a position.
- During Execution:
-
- Postcondition:
  - Fee growth values updated if different from pool growth checkpoints.
  - If tokens were owed, decremented from position.
  - If tokens were owed, getBalance of token increased for Caller.
  - Credit event emitted.

#### Allocate

- Preconditions:
  - The `pools` value for `poolId` must have a `lastPrice` != 0 and a `lastTimestamp` != 0.
  - Caller must have approved and have a balance to spend equal to `amounts` returned by the function `getAmounts` for `deltaLiquidity` for `poolId`, or Caller must have an equivalent amount in their `balances` for both tokens.
- During Execution:
  - n/a
- Postconditions:
  - The `pools` `liquidity` for `poolId` always increases by `deltaLiquidity`.
  - The `pools` `liquidity` for `poolId` never decreases.
  - The Caller's `positions` `freeLiquidity` for `poolId` always increased by `deltaLiquidity`.
  - Calling `unallocate` with the same `deltaLiquidity` always succeeds when the time elapsed in seconds between calls is greater than `JIT_LIQUIDITY_POLICY`.
  - If `pools` `feeGrowth{}` value for `poolId` is different from the previous time the same Caller allocated to `poolId`, the position's change in `feeGrowth{}` must not be zero.
  - Portfolio's `reserves` value for the pool's tokens increased by respective amounts computed with `getAmounts`, if the Caller did not have enough tokens in their `balances`.
  - The `balanceOf` Portfolio for the pool's tokens increased by respective amounts computed with `getAmounts`, if the Caller did not have enough tokens in their `balances`.
  - The `ChangePosition` event is emitted.
  - The `Allocate` event is emitted.
  - The `EarnFees` event was emitted if the `feeGrowth{}` values changed.

#### Unallocate

- Preconditions:
  - The Caller's `positions` `freeLiquidity` for `poolId` is greater than zero.
  - The Caller's `positions` `lastTimestamp` for `poolId` is less than `block.timestamp` by at least (equal) `JIT_LIQUIDITY_POLICY` seconds.
- During Execution:
  - n/a
- Postconditions:
  - The `pools` `liquidity` for `poolId` always decreases by `deltaLiquidity`.
  - The `pools` `liquidity` for `poolId` never increases.
  - The Caller's `positions` `freeLiquidity` for `poolId` always decreases by `deltaLiquidity`.
  - If `pools` `feeGrowth{}` value for `poolId` is different from the previous time the same Caller allocated to `poolId`, the position's change in `feeGrowth{}` must not be zero.
  - The Caller's `balances` value for the pool's tokens increases by respective amounts computed with `getAmounts`.
  - Portfolio's `reserves` value for the pool's tokens stays the same.
  - The `balanceOf` Portfolio for the pool's tokens stays the same.
  - The `DecreasePosition` event is emitted.
  - The `Unallocate` event is emitted.
  - The `EarnFees` event was emitted if the `feeGrowth{}` values changed.

#### Swap

- Preconditions:
  - For swaps with the argument `direction = 0` then the input token for `poolId` is the pair's `pair.tokenAsset`, else or swaps with the argument `direction = 1` then the input token for `poolId` is the pair's `pair.tokenQuote`
    - Caller must have approved token to be spent by Portfolio and have `input` of tokens, or Caller must have `input` of tokens in their `balances`.
  - The `pools` `poolId` value must return a `lastTimestamp` != 0, `lastPrice` != 0, and `liquidity` != 0.
  - The `input` amount must be greater than zero.
  - The `poolId`'s `curve.maturity` value must be less than `block.timestamp`.
- During Execution:
  - If `useMax` === 1, the `remainder` value in memory must be initialized with the Caller's entire `balances` value of the input token.
  - The memory `_swap.price` value must not be:
    - Greater than `limit` price if `direction == 0`.
    - Less than `limit` price if `direction == 1`.
- Postconditions:
  - Portfolio's `reserves` changed:
    - For `input` amount, changed by zero if Caller used their internal balance.
    - For `input` amount, changed by `input` if Caller paid with external tokens.
    - For `output` amount, changed by zero.
  - Portfolio's `balanceOf` respective tokens changed equal to changes in `reserves`.
  - The `Swap` event was emitted.
  - The `PoolUpdate` event was emitted.
