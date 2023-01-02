# Primitive Hyper RMM

Full vision of Primitive Replicating Market Maker.

## Notes

- [x] Investigate use of msg.value! (used in fund).
- [x] Improve/fix swap. Assigned to Clement.
- [ ] Investigate gas costs of swaps.
- [x] Investigate curve/pair nonces. Assigned to Alex.
- [ ] Add utility functions to fetch all data. Assigned to Alex.
- [ ] Add random swaps to invariant testing.
- [ ] Investigate typecasting.
- [ ] Investiate assembly usage.
- [ ] Explore refactor of free functions. I like free functions but they are so new that not many testing frameworks have good support yet.
- [ ] Explore implications of time movement creating price changes. Cannot change price and liquidity at the same time, thats an invariant!

#### Allocate

Adding liquidity increases pool and position liquidity balances, and charges the caller the virtual balances of tokens required to back that liquidity.

Virtual balances depend on price.

Price should not change when adding liquidity.

If liquidity changes, virtual balances need to be updated, which would require tokens to be paid to the contract.

Changing a position:

- Timestamp synced
- Fees are synced
- Position Liquidity is touched
  - Pool is touched
    - Reserves are touched

#### Notes

- Increasing reserves but paying entirely with internal balance leads to a deficit and therefore invariant failure.
- Be careful about `storage` or `memory` when using the library types. If a pool is computing important values, it should always be from storage, else it might not have the updates in the transaction. There was a bug where I was using the `lastTau` method on a pool in memory, and this was not updated even though the same `storage` pool was updated.
- Unbounded loops in free functions (for view ones at least) will revert with "EVM Error: Stack overflow"
- For tokens with lower decimals, there is a minimum amount of liquidity that can be allocated/removed. This is because liquidity is in WAD units while token amounts could be smaller, if they have low decimals.

## todo

- [x] Fix tests, especially swaps.
- [x] Solstat tests. - sunday
- [x] Refactor accounting system!
- [ ] Work on docs 1 pager for auditor - monday
- [ ] Light gas analysis/optimization - none
- [ ] Finish stake/unstake - sunday
- [x] Add parameter validation to changeParameters function
- [x] Rename HyperLib to HyperLib ?
- [x] TOKEN DECIMALS NOT HANDLED
- [ ] Claim fees working and tested
- [ ] Investigate price movements by swap.
