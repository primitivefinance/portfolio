# Primitive Hyper RMM

Full vision of Primitive Replicating Market Maker.

## Notes

Investigate use of msg.value! (used in fund)

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
