import { BigNumber, BigNumberish } from 'ethers'
import { hexlify } from 'ethers/lib/utils'

export enum Orders {
  UNKNOWN,
  ADD_LIQUIDITY,
  ADD_LIQUIDITY_ETH,
  REMOVE_LIQUIDITY,
  REMOVE_LIQUIDITY_ETH,
  SWAP_EXACT_TOKENS_FOR_TOKENS,
  SWAP_TOKENS_FOR_EXACT_TOKENS,
  SWAP_EXACT_ETH_FOR_TOKENS,
  SWAP_TOKENS_FOR_EXACT_ETH,
  SWAP_EXACT_TOKENS_FOR_ETH,
  SWAP_ETH_FOR_EXACT_TOKENS,
}

export function encodeOrder(order: Orders) {
  return BigNumber.from(0).add(Number(order))._hex
}

export function decodeOrder(data: BigNumberish) {
  data = data.toString()
  return data.substring(0, 2)
}

export function decodeEnd(data: BigNumberish) {
  data = data.toString()
  return data.substring(data.length - 2)
}

export function encodeParameters(order: Orders, amount: BigNumber, orderEnd = '0x05') {
  const ord = encodeOrder(order)
  const lenDec = '0x6b'
  const amt = reverseRunLengthEncode(amount).amount
  console.log('encode params')
  console.log(amt._hex, amt.toString())
  console.log(hexlify(140000415))
  const data = ord + lenDec.substring(2) + amt._hex.substring(2) + orderEnd.substring(2)
  return data
}

export function reverseRunLengthEncode(input: BigNumberish): { amount: BigNumber; decimals: number } {
  input = input.toString()
  const decimals = countEndZeros(input)
  const amount = BigNumber.from(trimEndZeros(input, decimals))
  return { amount, decimals }
}

function countEndZeros(value: string): number {
  let count: number = 0
  let i = value.length - 1 // start at end element
  if (value[i] != '0') return 0 // If last value isn't a zero, return early.
  while (value[i] == '0') {
    count++
    i--
  }
  return count
}

function trimEndZeros(value: string, count: number): string {
  return value.substring(0, value.length - count)
}

export function runLengthEncode(input: string): string {
  let output = ''
  let i = 0
  let count: number

  for (i; input[i]; i++) {
    count = 1
    while (input[i] === input[i + 1]) {
      count++
      i++
    }

    output += count.toString() + input[i]
  }

  return output
}

// bytes memory memBytes = hex"f00d20feed"

// uint8 testUint8 = 32; // 20 == 32
// resultUint8 = memBytes.toUint8(2);
// ah so 2 = start index at bytes array
