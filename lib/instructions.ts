import { BigNumber } from 'ethers'
import { hexlify } from 'ethers/lib/utils'
import { decodePackedByte, encodePackedByte, trailingRunLengthEncode } from './encoders'
import { bytesToHex, hexToBytes } from './units'

/**
 * "Opcodes" of the Enigma Virtual Machine.
 */
export enum Instructions {
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
  CREATE_POOL,
}

/**
 *
 * @param isMax Use Max balance flag
 * @param instruct
 * @param amountInWei
 * @param pairIndexHex
 * @returns
 */
export function encodeInstructions(
  isMax: boolean,
  instruct: Instructions,
  amountInWei: string,
  pairIndexHex: string
): number[] {
  const info = 0 // extra info
  const { amount, decimals } = trailingRunLengthEncode(amountInWei)
  const big = BigNumber.from(amount)
  return encodeArguments(isMax, instruct, info, decimals, +big._hex, +pairIndexHex)
}

export function decodeInstructions(hexString: string): {
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

// --- Hyper Encoders --- //

// Higher order bits flag bit packed with lower order order bits.
export function encodeFirstByte(isMax: boolean, instruction: Instructions): number {
  return encodePackedByte(isMax ? 1 : 0, instruction)
}

/**
 * Returns the higher order and lower order bits, as `max` and `ord` respectively.
 * @param byte
 * @returns
 */
export function decodeFirstByte(byte: number): { max: boolean; ord: number } {
  const decoded = decodePackedByte(byte)
  const max = decoded.higher > 0
  const ord = decoded.lower
  return { max, ord }
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
  return encodePackedByte(info, decimals)
}

export function encodeMiddleBytes(encoded: number): { bytes: number[] } {
  const hex = hexlify(encoded)
  return { bytes: hexToBytes(hex) }
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

/**
 *
 * @param max isMax flag to signal a swap of the entire balance.
 * @param ord Order type to signal a swap, allocate, or remove.
 * @param inf Extra instruction info.
 * @param dec Amount of zeroes appending to end of the amount, effectively decimals.
 * @param amt Run-length encoded amount.
 * @param end Last byte to signal the pair to swap in.
 * @returns byteArray of values that can be converted to hex with `bytesToHex`
 */
export function encodeArguments(
  max: boolean,
  ord: number,
  inf: number,
  dec: number,
  amt: number,
  end: number
): number[] {
  const bytesArray = [encodeFirstByte(max, ord), encodeSecondByte(inf, dec), ...encodeMiddleBytes(amt).bytes, end]
  return bytesArray
}
