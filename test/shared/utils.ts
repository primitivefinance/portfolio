import { BigNumber } from 'ethers'
import { parseEther } from 'ethers/lib/utils'
import { toBn } from 'evm-bn'

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

export const StandardPoolHelpers = {
  strike: parseEther('10'),
  sigma: 1e4,
  maturity: 31556953, // note: the contracts _blockTimestamp is set to 100.
  fee: 100,
  gamma: 1e4 - 100,
  internalBase: parseEther('0.308537538726000000'),
  internalQuote: parseEther('3.085375387260000000'),
  internalLiquidity: parseEther('1'),
}

export const Values = {
  ZERO_BN: toBn('0'),
  ONE: 1,
  TEN: 10,
  HUNDRED: 1e2,
  THOUSAND: 1e3,
  ETHER: parseEther('1'),
  TEN_ETHER: parseEther('10'),
  HUNDRED_ETHER: parseEther('100'),
}
