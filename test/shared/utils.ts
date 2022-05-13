import { BigNumber } from 'ethers'
import { parseEther } from 'ethers/lib/utils'

export function formatAmount(amount: string | number, trailing: number = 0) {
  const hex = BigNumber.from(amount)._hex
  const zeros = BigNumber.from(trailing)._hex
  return `${zeros}${hex.slice(2)}`
}

export const BasicRealPool = {
  strike: parseEther('10'),
  sigma: 1e4,
  maturity: 60 * 60 * 24 * 365, // note: the contracts _blockTimestamp is set to 100.
  fee: 100,
  gamma: 1e4 - 100,
  internalBase: parseEther('0.69'),
  internalQuote: BigNumber.from('669038505037077076'),
  internalLiquidity: parseEther('1'),
}
