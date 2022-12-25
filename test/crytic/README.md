# Crytic Tests

These are Echidna based testing files for developing a thorough corpus of coverage.

## Setup

The setup is a little complicated... here&#39;s what is going on:

### Pre-reqs: Must have python!

### 1. Installed nix. [source](https://nixos.org/download.html#nix-install-linux)

`sh <(curl -L https://nixos.org/nix/install) --no-daemon`

### 2. Installed crytic-compile

`pip3 install crytic-compile`

### 3.Installed echidna using nix

`nix-env -i -f https://github.com/crytic/echidna/tarball/master`

At this point, you should be setup to interact with the crytic test suite.

### How it works

`test/crytic` is the folder that holds all the echidna related configs and "corpus".

Echidna needs a config, which is stored at `test/crytic/config.yaml`. This should be passed to echidna with the flag `--config` if used in the CLI.

Echidna has a corpus which stores all the information on a contract after its been run by echidna, e.g. which lines of code reverted.

Corpus is stored in `test/crytic/corpus`, which is specified in the echidna config.

Echidna uses `crytic-compile` in the background to compile the files. Crytic compile will delegate the work to the testing framework, e.g. hardhat, foundry, etc., if specified. For us, we are letting crytic-compile default to Hardhat, which uses the root `hardhat.config.ts` file.

### Issues?

- crytic-compile is sensitive to the specific build/cache/contract folders. Make sure the `crytic-export` folder is being written to after trying to run `crytic-compile`. You can use the command, `yarn build:crytic` to test run compilation without echidna.

- Using forge framework requires the use of the 'crytic' profile in the foundry.toml config.
