# Primitive Hyper

Hyper is a replicating market maker.

## System Invariants

The system is designed around a single invariant:

```
Balance >= Reserve
```

Exposed via: `hyper.getNetBalance(token)`

For more invariants, [read this](./test/README.md).

## Installation

Required:

- Foundry
- Ganache
- Node >=v16.x
- Python (if running echidna)

### 1. Install foundry. [source](https://github.com/foundry-rs/foundry)

`curl -L https://foundry.paradigm.xyz | bash`

### 2. Restart terminal or reload `PATH`, then run:

`foundryup`

### 3. Install deps

`forge install`

### 4. Test

`yarn test`

## Resources

- [RMM in desmos](https://www.desmos.com/calculator/8py0nzdgfp)
- [Original codebase](https://github.com/primitivefinance/rmm-core)
- [solstat](https://github.com/primitivefinance/solstat)
- [Replicating Market Makers](https://github.com/angeris/angeris.github.io/blob/master/papers/rmms.pdf)
- [RMM whitepaper](https://primitive.xyz/whitepaper)
- [High precision calculator](https://keisan.casio.com/calculator)
