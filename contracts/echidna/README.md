🎉 Here we are again! 

## Running Echidna 

```
echidna-test . --contract EchidnaE2E --config E2E.yaml
```

## Installation 

Needed a few workarounds in Slither and Echidna so I'm making these changes explicit here. 

While not mandatory, I do recommend using a virtual environment as it may break your existing pip/python integrations. [Here](https://github.com/crytic/slither/wiki/Developer-installation) we have instructions for getting a virtualenv for Slither setup – the same process can be followed. 

1. We needed to set override flags for crytic-compile and slither to work on this codebase, which are encompassed in the `crytic_compile.config.json` and `slither.config.json` in this PR. 
2. Run `pip install git+https://github.com/crytic/slither.git@dev` from the root `hyper` directory 
3. Install the latest version of `echidna`. The builds are available here: https://github.com/crytic/echidna/actions/runs/3857295651