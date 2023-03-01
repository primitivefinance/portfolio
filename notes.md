Proposed structure

| Name                       | Description                                              |
| -------------------------- | -------------------------------------------------------- |
| Objective                  | Virtual functions that must be implemented by Portfolio. |
| Portfolio -> Machine       | Core architecture with generalized logic.                |
| MathLib                    | Math functions for Objective.                            |
| Portfolio                  | Implements Objective and inherits Portfolio.             |
| Os -> AccountLib           | Generalized accounting logic.                            |
| Enigma -> ProcessorLib     | Generalized alternative multicall and abi.               |
| Assembly -> AssemblyLib    | Yul functions for general use.                           |
| PortfolioLib -> MachineLib | Library for utilities for generalized logic.             |

Test Suite

| File      | Description                                                              |
| --------- | ------------------------------------------------------------------------ |
| Setup     | Creates contracts, actors, scenarios, and configs to be used in testing. |
| Portfolio | Unit tests for implemented Portfolios.                                   |
| Library   | Unit tests for libraries.                                                |
| invariant | Full system tests with invariants.                                       |

Testing a few different contracts that each implement PortfolioVirtual is going to be tricky.

Here's what we need and how we can solve it:

| Problem                                                 | Solution                                                                  |
| ------------------------------------------------------- | ------------------------------------------------------------------------- |
| Different contracts with same interface                 | Internal virtual function in test setup that returns test subject.        |
| Pools with different configurations                     | ?                                                                         |
| Redundant inputs per test, e.g. poolId, tokens, actors. | Ghost variable state accessed via a virtual internal function.            |
| Multiple tokens and actors                              | Managed via a registry lib with easy ways to fetch, add, and remove them. |
| Time based test scenarios                               | Cheatcodes, and maybe a library to manage the time with more granularity. |

Implemented above table, here's how it turned out:

| Problem                                                     | Solution                                                                                                              |
| ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Different contracts, same interfaces.                       | HelperSubjectsLib. Inherit tests and setup. Override setup and call `change_subject`.                                 |
| Different configuration parameters.                         | HelperConfigsLib. Create new configs from default values, edit them easily, then use to create pools.                 |
| Redundant inputs or variables, e.g. poolId, tokens, actors. | HelperGhostLib. Loads a poolId, basically a config, and exposes functions to fetch the key info like tokens.          |
| Multiple tokens and actors.                                 | HelperSubjectsLib and HelperActorsLib. Use subjects to manage contracts being acted upon and actors to manage actors. |
| Common actions, e.g. approve and mint.                      | HelperUtils. Custom types that implement utility functions and expose them globally via `using .. for ... global;`.   |

Swap notes

Swap steps for RMM01:

- Compute the invariant using block.timestamp.
- Compute amountIn scaled to WAD.
- Compute next reserve in WAD given fee charged on amountIn.
- Compute next reserve out WAD given next reserve in.
- Compute difference of next reserve out to get amountOut.
- Scale amountOut to decimals from WAD.
