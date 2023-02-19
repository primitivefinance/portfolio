Proposed structure

| Name                    | Description                                          |
| ----------------------- | ---------------------------------------------------- |
| Objective               | Virtual functions that must be implemented by Hyper. |
| Hyper -> Machine        | Core architecture with generalized logic.            |
| MathLib                 | Math functions for Objective.                        |
| Portfolio               | Implements Objective and inherits Hyper.             |
| Os -> AccountLib        | Generalized accounting logic.                        |
| Enigma -> ProcessorLib  | Generalized alternative multicall and abi.           |
| Assembly -> AssemblyLib | Yul functions for general use.                       |
| HyperLib -> MachineLib  | Library for utilities for generalized logic.         |

Test Suite

| File      | Description                                                              |
| --------- | ------------------------------------------------------------------------ |
| Setup     | Creates contracts, actors, scenarios, and configs to be used in testing. |
| Portfolio | Unit tests for implemented Portfolios.                                   |
| Library   | Unit tests for libraries.                                                |
| invariant | Full system tests with invariants.                                       |

Testing a few different contracts that each implement HyperVirtual is going to be tricky.

Here's what we need and how we can solve it:

| Problem                                                 | Solution                                                                  |
| ------------------------------------------------------- | ------------------------------------------------------------------------- |
| Different contracts with same interface                 | Internal virtual function in test setup that returns test subject.        |
| Pools with different configurations                     | ?                                                                         |
| Redundant inputs per test, e.g. poolId, tokens, actors. | Ghost variable state accessed via a virtual internal function.            |
| Multiple tokens and actors                              | Managed via a registry lib with easy ways to fetch, add, and remove them. |
| Time based test scenarios                               | Cheatcodes, and maybe a library to manage the time with more granularity. |
