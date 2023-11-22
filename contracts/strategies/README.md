# Portfolio Strategies

Portfolio pools can either use the *default* strategy or rely on an external custom strategy. The latter allows for custom logic to be executed within the pool at specific points in its lifecycle: after the creation of a pool or before a swap.

Portfolio will rely on specific callback functions that the custom strategy contracts must implement. These functions can be found in the [IStrategy](../interfaces/IStrategy.sol) interface, but it is recommended to inherit from the [StrategyTemplate](./StrategyTemplate.sol) abstract contract to get some default features such as the `onlyPortfolio` modifier.

## Writing a custom Strategy

(wip)
