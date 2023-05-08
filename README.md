> Beta: Not production ready. Pending on-going audits.

# Primitive Portfolio

On-chain portfolio management. Optimized for managing risk and liquidity.

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/primitivefinance/portfolio#contributing) [![](https://dcbadge.vercel.app/api/server/primitive?style=flat)](https://discord.gg/primitive) [![Twitter Badge](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/primitivefi)


# Portfolio Security

[Visit Primitive Security](https://www.primitive.xyz/security) to view a comprehensive overview of the security initiatives of Portfolio.

## System Invariants

The system is designed around a single invariant:

```
Actual balance of tokens in contract >= virtually tracked token balance in `__account__.reserves`.
```

Exposed via: `Portfolio.getNetBalance(token)`

For more invariants, [read this](./test/README.md).

# Portfolio Manual

## Clone

```
git clone https://github.com/primitivefinance/portfolio.git
```

## Installation

Required:

- Foundry
- Python (if running echidna)

### 1. Install foundry. [source](https://github.com/foundry-rs/foundry)

```
curl -L https://foundry.paradigm.xyz | bash
```

### 2. Restart terminal or reload `PATH`, then run:

```
foundryup
```

### 3. Install deps

```
forge install
```

### 4. Test

```
forge test --match-contract TestRMM01
```

## Resources

- [Portfolio Yellow Paper (Deprecated)](https://www.primitive.xyz/papers/yellow.pdf)
- [RMM in desmos](https://www.desmos.com/calculator/8py0nzdgfp)
- [Original codebase](https://github.com/primitivefinance/rmm-core)
- [solstat](https://github.com/primitivefinance/solstat)
- [Replicating Market Makers](https://github.com/angeris/angeris.github.io/blob/master/papers/rmms.pdf)
- [RMM whitepaper](https://primitive.xyz/whitepaper)
- [High precision calculator](https://keisan.casio.com/calculator)

## Audits

| Security Firm      | Review Time | Status    |
| ------------------ | ----------- | --------- |
| ChainSecurity      | 8-weeks     | Completed |
| Trail of Bits      | 8-weeks     | Completed |
| Spearbit           | 5-weeks     | Completed |
| Spearbit Extension | 2-weeks     | Pending   |


## Contributing

Important:
- This codebase uses the FORGE formatter. This is not prettier. If you have not already, make sure if you use vs code that the `formatOnSave`config variable uses forge fmt instead of prettier.
- Setup the proper settings using this guide: [forge fmt for formatOnSave vscode](https://github.com/juanfranblanco/vscode-solidity/pull/359#issue-1344943156).

When making a pull request:
- All tests pass.
- Code coverage does not change.
- Code follows the style guide:
    - Follows Primitive [styling](https://github.com/primitivefinance/pso-sol) rules.
    - Run `forge fmt`.
    - Code is thoroughly commented with natspec where relevant.
- If making a change to the contracts:
    - Gas snapshots are provided and demonstrate an improvement (or an acceptable deficit given other improvements).
    - New tests for all new features or code paths.
- If making a modification to third-party dependencies, yarn audit passes.
- A descriptive summary of the PR has been provided.
