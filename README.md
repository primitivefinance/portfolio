> Beta: Portfolio is experimental software. Use at your own risk.

# Portfolio by Primitive
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/primitivefinance/portfolio#contributing) [![](https://dcbadge.vercel.app/api/server/primitive?style=flat)](https://discord.gg/primitive) [![Twitter Badge](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/primitivefi)

Portfolio is an automated market making protocol for implementing custom liquidity distribution strategies at the lowest cost possible.

## Table of Contents

- [Overview](#overview)
- [Deployments](#deployments)
- [Security](#security)
- [Install](#install)
- [Documentation](#documentation)
- [Resources](#resources)
- [Contributing](#contributing)
- [License](#license)

## Overview

Portfolio is an automated market making protocol for creating custom liquidity distribution strategies at the lowest cost possible. Each pool in Portfolio can be created with a default strategy or custom strategy that defines a trading function, determining the available prices offered by the provider's liquidity. These pools all exist within the single Portfolio smart contract resulting in significantly lower gas costs for liquidity providers and swappers.

Read the local [docs](./docs/src/), hosted docs [docs.primitive.xyz](https://docs.primitive.xyz), or the [formal specification](https://primitive.xyz/whitepaper) for more information.


## Deployments

### Canonical Cross-chain Deployment Addresses

| Contract             | Canonical cross-chain address                |
| -------------------- | -------------------------------------------- |
| Portfolio 1.3.0-beta | `0x82360b9a2076a09ea8abe2b3e11aed89de3a02d1` |
| Portfolio 1.4.0-beta | `todo`                                       |
| Portfolio 1.5.0-beta | `n/a`                                       |

### Deployments by Chain

| Network  | Portfolio 1.3.0-beta                                                                                                          | Portfolio v1.4.0-beta | Portfolio v1.5.0-beta |
| -------- | ----------------------------------------------------------------------------------------------------------------------------- | --------------------- | --------------------- |
| Ethereum | [0x82360b9a2076a09ea8abe2b3e11aed89de3a02d1](https://etherscan.io/address/0x82360b9a2076a09ea8abe2b3e11aed89de3a02d1 )        | n/a                  |n/a                  |
| Base     | n/a                                                                                                                           | n/a                  |n/a                  |
| Sepolia  | [0x82360b9a2076a09ea8abe2b3e11aed89de3a02d1](https://sepolia.etherscan.io/address/0x82360b9a2076a09ea8abe2b3e11aed89de3a02d1) | n/a                  |n/a                  |

# Security

[Visit Primitive Security](https://www.primitive.xyz/security) to view a comprehensive overview of the security initiatives of Portfolio.

## Audits

| Security Firm                                                                                                 | Date       | Review Time | Status    | Final Commit w/ Fixes                                                                                                                         |
| ------------------------------------------------------------------------------------------------------------- | ---------- | ----------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| [ChainSecurity](https://github.com/primitivefinance/security/blob/main/audits/portfolio/chainsecurity.pdf)    | 2022-05-31 | 8-weeks     | Completed | [c6f692f41c1d20ac09acb832923bd46500fd8e06](https://github.com/primitivefinance/portfolio/commit/c6f692f41c1d20ac09acb832923bd46500fd8e06)     |
| [Trail of Bits](https://github.com/primitivefinance/security/blob/main/audits/portfolio/trailofbits.pdf)      | 2023-01-31 | 8-weeks     | Completed | n/a                                                                                                                                           |
| [Spearbit #1](https://github.com/primitivefinance/security/blob/main/audits/portfolio/spearbit.pdf)           | 2023-03-31 | 5-weeks     | Completed | [tag/v1.1.0-beta](https://github.com/primitivefinance/portfolio/releases/tag/v1.1.0-beta)                                                     |
| [Spearbit #1 Extension](https://github.com/primitivefinance/security/blob/main/audits/portfolio/spearbit.pdf) | 2023-05-12 | 2-weeks     | Competed  | [36e9efa28332fa03f6d5910edda2fec2f5937190](https://github.com/primitivefinance/portfolio/commit/36e9efa28332fa03f6d5910edda2fec2f5937190 )    |
| Spearbit #2                                                                                                   | 2023-07-78 | 2-weeks     | Completed | [tag/v1.5.0-beta-spearbit-2023-08-complete](https://github.com/primitivefinance/portfolio/releases/tag/v1.5.0-beta-spearbit-2023-08-complete) |

## Install

To install locally and compile contracts: 

#### [Required] Foundry. [Source](https://github.com/foundry-rs/foundry).
If not installed, run the following:
```bash
# First install foundryup
curl -L https://foundry.paradigm.xyz | bash

# Restart terminal or reload `PATH`, then run foundryup
foundryup
```
#### [Required] Install Deps
```bash
forge install
```

#### Usage

##### Testing
```bash
FOUNDRY_PROFILE=test forge test
```

##### Building
```bash
FOUNDRY_PROFILE=optimized forge build --skip test
```

##### Coverage

[Optional] Install coverage gutters [vs code extension](https://github.com/ryanluker/vscode-coverage-gutters).

Then run this to generate a coverage report:

```bash
forge coverage --report lcov
```

### Install Artifacts via NPM
To install the artifacts to use in your own project:


```bash
npm install @primitivexyz/portfolio
```


# Documentation

## Hosted
[Visit Primitive Documentation](https://docs.primitive.xyz) to view the hosted documentation for Portfolio.


## Local

### Autogenerated documentation:

Generated from the natspc of the contracts.

```bash
FOUNDRY_PROFILE=default forge doc --build --serve --port 4000
```

### Written documentation:

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


## Copyright

[AGPL-3.0](./LICENSE) © 2023 Primitive Bits, Inc.