import { parseEther } from 'ethers/lib/utils'
import { toBn } from 'evm-bn'

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
