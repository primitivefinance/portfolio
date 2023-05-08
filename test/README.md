# Primitive Portfolio Testing

Primitive follows [test driven development](https://en.wikipedia.org/wiki/Test-driven_development) and the principles described in [Microsoft Unit Testing Best Practices](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices).

For solidity, Primitive follows the [Primitive Standards for Solidity](https://github.com/primitivefinance/pso-sol).

# Table of Contents

- [I. Introduction](#i-introduction)
  - [Installation](#installation)
- [II. Primitive System Invariants](#ii-primitive-system-invariants)
- [III. Basic Testing](#iii-basic-testing)
  - [Unit tests](#unit-tests)
    - [Foundry](.)
- [IV. Advanced Testing](#iv-advanced-testing)
  - [Invariant Tests](#invariant-testing)
    - [Echidna](../echidna/)
    - [Foundry](./invariant/)
  - [Differential tests](#differential-testing)
    - [Solstat library](https://github.com/primitivefinance/solstat)

# I. Introduction

Portfolio has multiple layers of possible states the system can be in. There are token pairs, pool configurations, different portfolios, and multiple positions which all need to be tested. To accomplish this, the test suite was designed to be extensible as possible while keeping things as simple as they can be.

## Installation

For an installation guide, check out the [README](../README.md) in the root directory.

---

# II. Primitive System Invariants

System invariants are tested using [Foundry's invariant testing](https://book.getfoundry.sh/forge/invariant-testing).

Thanks to horsefacts.eth for their stellar walkthrough of building an invariant test suite: [Invariant Testing WETH with Foundry](https://mirror.xyz/horsefacts.eth/Jex2YVaO65dda6zEyfM_-DXlXhOWCAoSpOx5PLocYgw).

### Portfolio.sol

#### Global

- Token balances of Portfolio should be greater than or equal to the `reserves` of all tokens.
- For every pool, `reserves` of the pool's tokens should always be greater than the `getPoolReserves` output for the pool's entire liquidity.
- The sum of liquidity in all pools must be equal to the sum of liquidity of every position, less the `BURNED_LIQUIDITY` amount.
- The `lock` variable must always return `1` outside of execution.
- The `__account__.settled` variable must always return true outside of execution.
- The `__account__.warm` variable must always be an empty array outside of execution.

#### Deposit

- Preconditions:
  - `msg.value` is greater than zero.
- During Execution:
  - The `msg.value` amount of ether sent to the contract is deposited into the weth contract via `deposit() payable`.
- Postconditions:
  - `msg.sender`'s `balances` value of `weth` increased by `msg.value`.
  - Portfolio's `address(this).balance` is equal to the balance prior to calling the function.
  - Portfolio's `reserves` value for `weth` increased by `msg.value`.
  - Portfolio's `balanceOf` `weth` increased by `msg.value`.
  - The `Deposit` event was emitted.

#### Allocate

- Preconditions:
  - The `pools` value for `poolId` must have a `lastPrice` != 0 and a `lastTimestamp` != 0.
  - `msg.sender` must have approved `Portfolio` as a spender of tokens.
  - `msg.sender` must have a balance to spend equal to `amounts` returned by the function `getLiquidityDeltas` for `deltaLiquidity` for `poolId`, or `msg.sender` must have an equivalent amount in their `balances` for both tokens.
- During Execution:
  - n/a
- Postconditions:
  - The `pools` `liquidity` for `poolId` always increases by `deltaLiquidity` if not making the first allocation, if making the first allocation the `BURNED_LIQUIDITY` amount is lost.
  - The `pools` `liquidity` for `poolId` never decreases.
  - The `msg.sender`'s `positions` amount for `poolId` increases by `deltaLiquidity`, less `BURNED_LIQUIDITY` if making the first allocation of the pool.
  - Portfolio's `reserves` value for the pool's tokens increased by respective amounts computed with `getPoolReserves`, if the `msg.sender` did not have enough tokens in their `balances`.
  - The `balanceOf` Portfolio for the pool's tokens increased by respective amounts computed with `getPoolReserves`, if the `msg.sender` did not have enough tokens in their `balances`.
  - The `Allocate` event is emitted.

#### Deallocate

- Preconditions:
  - The `msg.sender`'s `positions` amount for `poolId` is greater than zero.
- During Execution:
  - n/a
- Postconditions:
  - The `pools` `liquidity` for `poolId` always decreases by `deltaLiquidity`.
  - The `pools` `liquidity` for `poolId` never increases.
  - The `msg.sender`'s `positions` amount for `poolId` always decreases by `deltaLiquidity`.
  - The `msg.sender`'s `balances` value for the pool's tokens increases by respective amounts computed with `getPoolReserves`.
  - Portfolio's `reserves` value for the pool's tokens stays the same.
  - The `balanceOf` Portfolio for the pool's tokens stays the same.
  - The `Deallocate` event is emitted.

#### Swap

- Preconditions:
  - For swaps with the argument `sellAsset = 1` then the input token for `poolId` is the pair's `pair.tokenAsset`, else swaps with the argument `sellAsset = 0` the input token for `poolId` is the pair's `pair.tokenQuote`
    - `msg.sender` must have approved token to be spent by Portfolio and have `input` of balance of tokens held by their address, or there must be a surplus of tokens in the contract from `getNetBalance` and `useMax` must be set to true.
  - The `pools` `poolId` value must return a `lastTimestamp` != 0, `lastPrice` != 0, and `liquidity` != 0.
  - The `input` amount must be greater than zero.
  - The `poolId`'s `curve.maturity` value must be less than `block.timestamp`.
- During Execution:
  - n/a
- Postconditions:
  - Portfolio's `reserves` changed:
    - For `input` amount, changed by `input` if `msg.sender` paid with external tokens.
    - For `output` amount, changed by `output` amount if not used in consecutive instructions.
  - Portfolio's `balanceOf` value for each token remains unchanged before or after a swap.
  - The `Swap` event was emitted.

# III. Basic Testing

## Unit Tests

The unit test suite is slightly more complicated to be able to support thorough coverage across a large amount of possible states and scenarios.

| Unit Test Glossary |                                                                 |
| ------------------ | --------------------------------------------------------------- |
| Ghost              | A variable that lives in the test environment.                  |
| Actor              | An address that is the `msg.sender` for calls to the `subject`. |
| Subject            | The target contract being tested upon.                          |
| Asset              | The `asset` token of a pair that is used in a pool.             |
| Quote              | The `quote`token of a pair that is used in a pool.              |
| Config             | Set of parameters used by a pool in a Portfolio.                |
| Objective          | Virtual functions to implement of a Portfolio.                  |
| Portfolio          | Abstract contract that inherits Objective.                      |
| {name}Portfolio    | Portfolio that implements the Objective virtual contract.       |

To solve the problems posed by the many possible states of the system, the unit tests are designed to be extensible:

| Testing problems                         | Solutions                                  |
| ---------------------------------------- | ------------------------------------------ |
| Portfolios with different objectives.    | Ghost subject var makes tests inheritable. |
| Pools with many possible configurations. | ConfigsLib to manage configs.              |
| Redundant inputs for each test.          | GhostLib helper to manage key variables.   |
| Multiple tokens/actors.                  | ActorsLib and SubjectsLib.                 |
| Time dependent state.                    | Cheatcodes!                                |

### Test walkthrough

#### 1. Setup

In [Setup.sol](./Setup.sol) the contracts that are being tested upon or used to test are deployed via the [HelperSubjectsLib](./HelperSubjectsLib.sol). The single subject is a `Portfolio` instance, and can be accessed via `SubjectsState.last` variable.

Ghost state is then initialized to a private variable in Setup `_ghost`, which sets the CURRENT actor (`msg.sender`) to the Test contract which inherits Setup.sol. The ghost `subject` variable is set to the `SubjectsState.last` value. Since there is no pool that exists, poolId is initialized to 0.

The `setUp` function can be overridden with a new subject that implements the `IPortfolio` interface.

```
function setUp() public override {
    super.setUp();
    address new_subject = address(new RMM02Portfolio(address(subjects().weth)));
    subjects().change_subject(new_subject);
}
```

This will enable the ability to make a new test file, change the subject, inherit the unit tests, and the unit tests will target the new subject.

#### 2. Simple Testing

We are going to use an extremely simple test to show how to build unit tests for Portfolio.

Start by creating a new foundry test file and import the `Setup.sol` file, here's a vscode snippet to make this super easy!

```
> cmd + shift + p
> configure user snippets
> new snippet
> "solidity.json"

{
	"Template Test File": {
		"prefix": "template-sol-test",
		"body": [
			"// SPDX-License-Identifier: GPL-3.0-only",
			"pragma solidity ^0.8.4;",
			"$2",
			"import './Setup.sol';",
			"$2",
			"contract TestTemplate is Setup {",
			"$2",
			"}"
		],
		"description": "Boilerplate for solidity test file."
	}
}
```

Next, let's build a simple unit test that checks the user is credited WETH for depositing ether into Portfolio:

```
function test_deposit_increases_user_weth_balance() public useActor {
    uint amount = 10 ether;
    uint prev = ghost().balance(actor(), subject().WETH());
    subject().deposit{value: amount}();
    uint post = ghost().balance(actor(), subject().WETH());
    assertEq(post, prev + amount, "missing-weth-deposit");
}
```

To call the Portfolio contract, we use `subject()` to fetch the `IPortfolio` instance that was loaded during `setUp`.

Using the modifier `useActor` will call `vm.prank` on the current `actor()`. This will mean that all calls into `subject()` will have the `msg.sender` equal to the `actor()`. Very useful for ensuring the correct address is calling the subject! The default `actor()` is initialized in the `setUp` function to be the Unit Test contract which inherits the `Setup.sol` test file.

Also notice that the `ghost()` variable is called and we utilize it's `balance` method. This will call `getBalance` on the `subject` variable that is loaded into the ghost environment. This does NOT call the `balanceOf` function.

#### 3. Complicated Testing

To test some functionality of Portfolio, a more complicated pre-requisite state is required. To get Portfolio to this state, modifiers are used. This is working, but we might take it out in the future since it can make the unit tests more complicated.

Here's an example of testing the `allocate` functionality of a Portfolio, which requires the `msg.sender` to approve Portfolio as a spender, `msg.sender` has a balance of tokens, and a pool is created to allocate to.

```
function test_allocate_modifies_liquidity()
  public defaultConfig useActor usePairTokens(10 ether) isArmed
{
        // Arguments for test.
        uint128 amount = 0.1 ether;
        // Fetch the ghost variables to interact with the target pool.
        uint64 xid = ghost().poolId;
        // Fetch the variable we are changing (pool.liquidity).
        uint256 prev = ghost().pool().liquidity;
        // Trigger the function being tested.

        bytes[] memory instructions = new bytes[](1);
        instructions[0] = abi.encodeCall(
            IPortfolioActions.allocate,
            (false, xid, amount, type(uint128).max, type(uint128).max)
        );
        subject().multicall(instructions);

        // Fetch the variable changed.
        uint256 post = ghost().pool().liquidity;
        // Ghost assertions comparing the actual and expected deltas.
        assertEq(post, prev + amount, "pool.liquidity");
        // Direct assertions of pool state.
        assertEq(
            ghost().pool().liquidity - BURNED_LIQUIDITY,
            ghost().position(actor()),
            "position != pool.liquidity"
        );
    }
```

Walking through the modifiers used, here's what each of them does:

| modifier            | description                                                        |
| ------------------- | ------------------------------------------------------------------ |
| defaultConfig       | Creates a pool in Portfolio using default config variables.        |
| useActor            | Starts a `vm.prank` for the current `ghost().actor`.               |
| usePairTokens(uint) | Mints tokens to `actor()` and approves `subject()` as the spender. |
| isArmed             | Checks newly created pool's `poolId` is in the ghost state.        |

These modifiers make it easy to setup basic state that Portfolio needs to test certain actions, but it can make it difficult to debug.

> Ordering of modifiers matter! For example, the `allocateSome` modifier will revert if a `defaultConfig` modifier comes after. This is because `defaultConfig` will set the `ghost().poolId` variable, which is used by `allocateSome` modifier.

# IV. Advanced Testing

## Invariant Testing

Foundry's invariant testing covers the end-to-end system testing of Portfolio. View the tests [here](./invariant/).

During Primitive's audit with Trail of Bits, an echidna invariant test suite was built. This test suite needs to be revisited and updated to match the latest changes in the codebase. You can view it [here](../echidna/).

> todo: Write a guide on building invariant tests for Portfolio.

## Differential Testing

The solstat library dependency implements a library that is written in javascript. Differential testing is used to ensure the solidity implementation matches the javascript implementation. View the differential test suite [here](https://github.com/primitivefinance/solstat).
