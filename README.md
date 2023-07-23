> Beta: Not production ready. Pending on-going audits.

# Portfolio by Primitive

Portfolio is an automated market making protocol for implementing custom liquidity distribution strategies at the lowest cost possible.

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/primitivefinance/portfolio#contributing) [![](https://dcbadge.vercel.app/api/server/primitive?style=flat)](https://discord.gg/primitive) [![Twitter Badge](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/primitivefi)

## Installation

#### [Required] Foundry. [Source](https://github.com/foundry-rs/foundry).
If not installed, run the following:
```bash
# First install foundryup
curl -L https://foundry.paradigm.xyz | bash

# Restart terminal or reload `PATH`, then run foundryup
foundryup
```

### Install & Run

```bash
forge install & forge test
```

# Security

[Visit Primitive Security](https://www.primitive.xyz/security) to view a comprehensive overview of the security initiatives of Portfolio.

## Audits

| Security Firm      | Review Time | Status    |
| ------------------ | ----------- | --------- |
| ChainSecurity      | 8-weeks     | Completed |
| Trail of Bits      | 8-weeks     | Completed |
| Spearbit           | 5-weeks     | Completed |
| Spearbit Extension | 2-weeks     | Competed   |
| Spearbit Extension #2 | 2-weeks     | Pending   |


# Documentation

## Hosted
[Visit Primitive Documentation](https://docs.primitive.xyz) to view the hosted documentation for Portfolio.


## Local

To build the documentation locally:

#### [Required] Rust & Cargo
If not installed, follow the [rust installation instructions](https://www.rust-lang.org/tools/install).

#### [Required] Mdbook
If not installed, run the following:
```bash
cargo install mdbook
```

### Build and serve

```bash
cd docs
mdbook serve --open
```

## Resources

- [Hosted Documentation](https://docs.primitive.xyz)
- [Portfolio Yellow Paper (Deprecated)](https://www.primitive.xyz/papers/yellow.pdf)
- [RMM in desmos](https://www.desmos.com/calculator/8py0nzdgfp)
- [Original codebase](https://github.com/primitivefinance/rmm-core)
- [solstat](https://github.com/primitivefinance/solstat)
- [Replicating Market Makers](https://github.com/angeris/angeris.github.io/blob/master/papers/rmms.pdf)
- [RMM whitepaper](https://primitive.xyz/whitepaper)
- [High precision calculator](https://keisan.casio.com/calculator)


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
