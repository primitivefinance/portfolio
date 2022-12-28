# Crytic Tests

NOTE: Currently blocked by crytic-compile. There's some difficulty in getting these echidna tests to work because of the use of free functions, and foundry.

These are Echidna based testing files for developing a thorough corpus of coverage.

## Setup

[Setup instructions](../README.md)

## Run tests

1. `forge install`
2. `yarn install`
3. `yarn test:echidna`

## Configuration

`test/crytic` is the folder that holds all the echidna related configs and "corpus".

Echidna needs a config, which is stored at `test/crytic/config.yaml`. This should be passed to echidna with the flag `--config` if used in the CLI.

Echidna has a corpus which stores all the information on a contract after its been run by echidna, e.g. which lines of code reverted.

Corpus is stored in `test/crytic/corpus`, which is specified in the echidna config.

Echidna uses `crytic-compile` in the background to compile the files. Crytic compile will delegate the work to the testing framework, e.g. hardhat, foundry, etc., if specified. For us, we are letting crytic-compile default to Hardhat, which uses the root `hardhat.config.ts` file.

## Issues?

- crytic-compile is sensitive to the specific build/cache/contract folders. Make sure the `crytic-export` folder is being written to after trying to run `crytic-compile`. You can use the command, `yarn build:crytic` to test run compilation without echidna.

- Using forge framework requires the use of the 'crytic' profile in the foundry.toml config.

## Notes (TODO: remove)

- Using echidna 2.0.4, `assert` does not seem to trigger a failure for echidna for solidity ^0.8.0.
