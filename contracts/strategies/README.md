# Writing a custom strategy

## Introduction

Portfolio pools can either use the *default* strategy or rely on an external custom strategy. The latter option allows custom logic to be executed within the pool at specific points in its lifecycle: after the creation of a pool or during a swap.

Portfolio will rely on specific functions that the custom strategy contracts must implement. These functions can be found in the [IStrategy](../interfaces/IStrategy.sol) interface, but it is recommended to inherit from the [StrategyTemplate](./StrategyTemplate.sol) abstract contract to get some default features such as the `onlyPortfolio` modifier.

## Strategy functions

Here is a summary of the workflow between a user, the `Portfolio` contract and a custom strategy contract:

```
 ┌────┐          ┌────────┐    ┌─────────┐
 │User│          │Strategy│    │Portfolio│
 └─┬──┘          └───┬────┘    └────┬────┘
   │                 │              │
   │getStrategyData()│              │
   │────────────────>│              │
   │                 │              │
   │          createPool()          │
   │───────────────────────────────>│
   │                 │              │
   │                 │validatePool()│
   │                 │<─────────────│
   │                 │              │
   │          updatePool()          │
   │───────────────────────────────>│
   │                 │              │
   │             swap()             │
   │───────────────────────────────>│
   │                 │              │
   │                 │ beforeSwap() │
   │                 │<─────────────│
   │                 │              │
   │                 │validateSwap()│
   │                 │<─────────────│
 ┌─┴──┐          ┌───┴────┐    ┌────┴────┐
 │User│          │Strategy│    │Portfolio│
 └────┘          └────────┘    └─────────┘

 ```

### `getStrategyData()`

```solidity
function getStrategyData(
    bytes memory data
) external pure returns (
    bytes memory strategyData,
    uint256 initialX,
    uint256 initialY
);
```

This function is meant to be called by users willing to create a new pool using a custom strategy. This is the only function called directly by the users (instead of `Portfolio` contract itself). It returns the data that should be passed to the `createPool` function of the Portfolio contract.

### `afterCreate()`

```solidity
function afterCreate(
    uint64 poolId,
    bytes calldata strategyArgs
) external returns (bool success);
```

This function is called by `Portfolio` after the creation of a pool in the `Portfolio` contract and allows the strategy to perform any initialization logic. The `strategyArgs` parameter is the same as the one passed to the `createPool` function of the Portfolio contract.

### `beforeSwap()`

```solidity
function beforeSwap(
    uint64 poolId,
    bool sellAsset,
    address swapper
) external returns (bool success, int256 invariant);
```

This function is called before a swap is executed and must return a boolean indicating whether the swap should be allowed or not, along with the current invariant.

### `validateSwap()`

```solidity
```

This function is called after a swap is executed and allows the strategy to perform any validation logic.

### `updatePool()`

```solidity
function updatePool(
    uint64 poolId,
    address caller,
    bytes memory data
) external;
```

The `updatePool` function provides an flexible way to update pool parameters. It is meant to be called via the `Portfolio` contract and requires a `poolId` along with some data encoded as `bytes`. Keep in mind that the `Portfolio` contract does not perform any validation on the data but simply pass them along.
