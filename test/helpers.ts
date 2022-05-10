import { BigNumber, BigNumberish } from 'ethers'
import { hexlify } from 'ethers/lib/utils'
import { toBn } from 'evm-bn'

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

// Flag in the higher order bits of the first byte.
export function encodeIsMaxFlag(isMax: boolean): number {
  return isMax ? 1 : 0 << 4
}

// Flag in the higher order bits of the second byte.
export function encodeInfoFlag(info: number): number {
  return info << 4
}

// Higher order bits flag bit packed with lower order order bits.
export function encodeFirstByte(isMax: boolean, order: Orders): number {
  return encodeIsMaxFlag(isMax) | order
}

/**
 *
 * Packs info into higher order bits and decimals into lower order bits.
 * If decimals is greater than the lower order bits, then the entire bits is dedicated to it.
 * Note: That makes sense... If we have 0xc3, what is the c? is the space of the bit (16 - 1) less the decimals (15 - 3) = 12 = 0xc
 * @param info
 * @param decimals
 * @returns
 */
export function encodeSecondByte(info: number, decimals: number): number {
  if (info <= 1) return decimals
  return encodeInfoFlag(info) | decimals
}

/**
 * Encodes a raw wei value by converting it to a hex then trimming trailing zeroes.
 *
 * @param wei Raw wei value string, NOT a hex value.
 * @returns
 */
export function encodeMiddleBytes(wei: string): { bytes: number[]; decimals: number } {
  const encoded = reverseRunLengthEncode(wei)
  return { bytes: hexToBytes(encoded.amount._hex), decimals: encoded.decimals }
}

/**
 * Returns the higher order and lower order bits, as `max` and `ord` respectively.
 * @param byte
 * @returns
 */
export function decodeFirstByte(byte: number): { max: boolean; ord: number } {
  const max = (byte & 0xf0) >> 4 > 0
  const ord = byte & 0x0f
  return { max, ord }
}

export function decodeSecondByte(byte: number): { inf: number; dec: number } {
  const hasInfo = byte >> 4 > 1
  const inf = hasInfo ? (byte & 0xf0) >> 4 : 0x0
  const dec = hasInfo ? byte & 0x0f : byte
  return { inf, dec }
}

/**
 * Converts the middle bytes to hexadecimal.
 *
 * @remarks
 * The hexadecimal value must have its zeroes attached, which were trimmed when encoded.
 *
 * @param bytes
 * @returns
 */
export function decodeMiddleBytes(bytes: number[]): { amt: number } {
  const hex = bytesToHex(bytes)
  return { amt: +hex }
}

export function decodeLastByte(byte: number): { end: number } {
  return { end: +bytesToHex([byte]) }
}

export function deconstructCalldata(hexString: string): {
  firstByte: number
  secondByte: number
  middleBytes: number[]
  lastByte: number
} {
  const bytes = hexToBytes(hexString)
  const firstByte = bytes[0]
  const secondByte = bytes[1]
  const middleBytes = bytes.slice(2, bytes.length - 1)
  const lastByte = bytes[bytes.length - 1]
  return { firstByte, secondByte, middleBytes, lastByte }
}

export function encodeAmountBytes(amountHex: string): number {
  return +reverseRunLengthEncode(amountHex).amount._hex
}

export function encodeTransaction(
  isMax: boolean,
  order: Orders,
  amountInWei: BigNumber,
  pairIndexHex: string
): number[] {
  const { amount, decimals } = encodeAmount(amountInWei)
  const info = 0 // extra info
  return encodeParameters(isMax, order, info, decimals, +amount._hex, +pairIndexHex)
}

export function encodeAmount(raw: BigNumber): { amount: BigNumber; decimals: number } {
  return reverseRunLengthEncode(raw)
}

/**
 *
 * @param amt Run-length encoded amount.
 * @returns byte array of the converted hex amount.
 */
/* export function encodeMiddleBytes(amt: number): number[] {
  const hex = hexlify(amt).substring(2)
  const bytes = hexToBytes(hex)
  console.log({ bytes })
  return bytes
} */

/**
 *
 * @param max isMax flag to signal a swap of the entire balance.
 * @param ord Order type to signal a swap, allocate, or remove.
 * @param inf Extra order info.
 * @param dec Amount of zeroes appending to end of the amount, effectively decimals.
 * @param amt Run-length encoded amount.
 * @param end Last byte to signal the pair to swap in.
 * @returns byteArray of values that can be converted to hex with `bytesToHex`
 */
export function encodeParameters(
  max: boolean,
  ord: number,
  inf: number,
  dec: number,
  amt: number,
  end: number
): number[] {
  const bytesArray = [
    encodeFirstByte(max, ord),
    encodeSecondByte(inf, dec),
    ...encodeMiddleBytes(amt.toString()).bytes,
    end,
  ]
  return bytesArray
}

export function stringToBytesToHex(value: string): string {
  if (value.substring(0, 2) !== '0x') throw Error(`not a hexadecimal ${value}`)
  return hexlify(hexToBytes(value.substring(2)))
}

export function hexToBytes(hex) {
  if (hex.substring(0, 2) === '0x') hex = hex.substring(2)
  let bytes: number[] = []
  for (let c = 0; c < hex.length; c += 2) bytes.push(parseInt(hex.substr(c, 2), 16))
  return bytes
}

// Convert a byte array to a hex string
export function bytesToHex(bytes) {
  let hex: string[] = []
  for (let i = 0; i < bytes.length; i++) {
    var current = bytes[i] < 0 ? bytes[i] + 256 : bytes[i]
    hex.push((current >>> 4).toString(16))
    hex.push((current & 0xf).toString(16))
  }
  return '0x' + hex.join('')
}

export function runLengthDecode(value: string, decimals: number): BigNumber {
  const big = toBn(value, decimals)
  return big
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
