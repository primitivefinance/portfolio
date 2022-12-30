# Primitive Hyper RMM

Full vision of Primitive Replicating Market Maker.

## Notes

- [ ] Investigate use of msg.value! (used in fund).
- [ ] Improve/fix swap. Assigned to Clement.
- [ ] Investigate gas costs of swaps.
- [ ] Investigate curve/pair nonces. Assigned to Alex.
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

### Epochs

Every curve parameter set has a "maturity" date. Once this timestamp is eclipsed, the curve becomes unusable in new pools. This creates waste + limits the reusability of curve parameters.

One idea is to introduce an epoch system in the contracts (which we've had at one point in time before, and kept it in this version). With an epoch system, pools can "ride along" with the epoch, instead of rely on it being a parameter in the curve parameter explicitly. It could be a parameter in the curve, but it would be more dynamic, e.g. "10 epoch cycles" instead of "January 21, 2023 at 3pm UTC".

A pool can not have its epoch cycle reset. This is an assumption though, it might be possible, but we don't know that yet.
