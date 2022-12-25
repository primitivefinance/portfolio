# Primitive Hyper Testing

Primitive follows [test driven development](https://en.wikipedia.org/wiki/Test-driven_development), writing tests before logic. We follow the principles described in this [Microsoft Unit Testing Best Practices](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices), even though it is written for .NET projects.

For solidity, we follow the [Primitive Smart Contract Style Guide]().

# Table of Contents

- I. Introduction
  - [Installation]()
  - [Invariant Specification]()
- II. Basic
  - [Unit tests]()
    - [Foundry]()
    - [Hardhat]()
  - [End-to-end tests]()
    - [Hardhat]()
    - [Echidna]()
- III. Advanced
  - [Fuzz tests]()
    - [Echidna]()
    - [Foundry]()
  - [Differential tests]()
    - [Solstat library]()
  - [Fork testing]()
  - [Adversarial testing]()

# I. Introduction

This test suite is comprehensive. We use three different testing frameworks; a test for our tests.

## Installation

The setup is a little complicated... here&#39;s what is going on:

### Pre-reqs: Must have python, node >=v16.0.0, and yarn.

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

### 6. `yarn install`

### 7. `forge install`

### 8. `yarn test`, `yarn test:hardhat`, `yarn test:echidna`.

### 9. Clean up cached builds with `yarn clean`.

### 10. Get gas report with `yarn profile`

# II. Invariant Specification
