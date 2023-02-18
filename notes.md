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
