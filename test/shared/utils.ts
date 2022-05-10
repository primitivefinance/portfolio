import { BigNumber } from 'ethers';

export function formatAmount(amount: string | number, trailing: number = 0) {
  const hex = BigNumber.from(amount)._hex;
  const zeros = BigNumber.from(trailing)._hex;
  return `${zeros}${hex.slice(2)}`;
}
