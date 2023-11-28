# Writing a custom strategy

## Introduction

Portfolio pools can either use the *default* strategy or rely on an external custom strategy. The latter option allows custom logic to be executed within the pool at specific points in its lifecycle: after the creation of a pool or during a swap.

Portfolio will rely on specific functions that the custom strategy contracts must implement. These functions can be found in the [IStrategy](../interfaces/IStrategy.sol) interface, but it is recommended to inherit from the [StrategyTemplate](./StrategyTemplate.sol) abstract contract to get some default features such as the `onlyPortfolio` modifier.

## Strategy functions

### Swap Lifecycle

```
 ┌────┐┌─────────┐     ┌────────┐
 │User││Portfolio│     │Strategy│
 └─┬──┘└────┬────┘     └───┬────┘
   │        │              │
   │ swap() │              │
   │───────>│              │
   │        │              │
   │        │validatePool()│
   │        │─────────────>│
   │        │              │
   │        │ beforeSwap() │
   │        │─────────────>│
   │        │              │
   │        │validateSwap()│
   │        │─────────────>│
 ┌─┴──┐┌────┴────┐     ┌───┴────┐
 │User││Portfolio│     │Strategy│
 └────┘└─────────┘     └────────┘
 ```

### `afterCreate()`

```solidity
    function afterCreate(
        uint64 poolId,
        bytes calldata strategyArgs
    ) external returns (bool success);
```

This function is called after the creation of a pool and allows the strategy to perform any initialization logic. The `strategyArgs` parameter is the same as the one passed to the `createPool` function of the Portfolio contract.

### `beforeSwap()`

```solidity
    function beforeSwap(
        uint64 poolId,
        bool sellAsset,
        address swapper
    ) external returns (bool success, int256 invariant);
```

This function is called before a swap is executed and must return a boolean indicating whether the swap should be allowed or not, along with the current invariant.
