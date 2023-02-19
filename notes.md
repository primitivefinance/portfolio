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
| E2E       | Full system tests with invariants.                                       |
