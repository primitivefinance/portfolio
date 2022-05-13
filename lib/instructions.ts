import { BigNumber } from 'ethers'
import { defaultAbiCoder, hexlify, hexZeroPad, isHexString } from 'ethers/lib/utils'
import { decodePackedByte, encodePackedByte, trailingRunLengthEncode } from './encoders'
import { bytesToHex, hexToBytes } from './units'

/**
 * "Opcodes" of the Enigma Virtual Machine.
 */
export enum Instructions {
  UNKNOWN = 0x00,
  ADD_LIQUIDITY = 0x01,
  ADD_LIQUIDITY_ETH = 0x02,
  REMOVE_LIQUIDITY = 0x03,
  REMOVE_LIQUIDITY_ETH = 0x04,
  SWAP_EXACT_TOKENS_FOR_TOKENS = 0x05,
  SWAP_TOKENS_FOR_EXACT_TOKENS,
  SWAP_EXACT_ETH_FOR_TOKENS,
  SWAP_TOKENS_FOR_EXACT_ETH,
  SWAP_EXACT_TOKENS_FOR_ETH,
  SWAP_ETH_FOR_EXACT_TOKENS,
  CREATE_POOL,
  CREATE_PAIR,
  CREATE_CURVE = 0x0d,
}

// --- Full Instruction Encoders --- //

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

export function encodeCreatePair(base: string, quote: string): { bytes: number[]; hex: string } {
  const opcode = Instructions.CREATE_PAIR
  if (!isHexString(base)) throw new Error(`Base address not a hex string: ${base}`)
  if (!isHexString(quote)) throw new Error(`Quote address not a hex string: ${quote}`)
  const bytes = [...hexToBytes(hexlify(opcode)), ...hexToBytes(base), ...hexToBytes(quote)]
  return { bytes, hex: bytesToHex(bytes) }
}

export function encodeCreateCurve(
  strike: BigNumber,
  sigma: number,
  maturity: number,
  fee: number
): { bytes: number[]; hex: string } {
  const opcode = Instructions.CREATE_CURVE
  const strikeByte = hexZeroPad(strike.toHexString(), 16)
  const sigmaByte = hexZeroPad(hexlify(sigma), 3)
  const maturityByte = hexZeroPad(hexlify(maturity), 4)
  const feeByte = hexZeroPad(hexlify(fee), 2)
  const bytes = [
    ...hexToBytes(hexlify(opcode)),
    ...hexToBytes(sigmaByte),
    ...hexToBytes(maturityByte),
    ...hexToBytes(feeByte),
    ...hexToBytes(strikeByte),
  ]
  return { bytes, hex: bytesToHex(bytes) }
}

export function encodePoolId(pairId: number, curveId: number): { bytes: number[]; hex: string } {
  const pairBytes = hexZeroPad(hexlify(pairId), 2)
  const curveBytes = hexZeroPad(hexlify(curveId), 4)
  const bytes = [...hexToBytes(pairBytes), ...hexToBytes(curveBytes)]
  return { bytes, hex: bytesToHex(bytes) }
}

export function encodeCreatePool(
  pairId: number,
  curveId: number,
  basePerLiquidity: BigNumber,
  deltaLiquidity: BigNumber
): { bytes: number[]; hex: string } {
  const opcode = Instructions.CREATE_POOL
  const pairBytes = hexZeroPad(hexlify(pairId), 2)
  const curveBytes = hexZeroPad(hexlify(curveId), 4)
  const basePerLiquidityBytes = hexZeroPad(basePerLiquidity.toHexString(), 16)
  const deltaLiquidityBytes = hexZeroPad(deltaLiquidity.toHexString(), 16)
  const bytes = [
    ...hexToBytes(hexlify(opcode)),
    ...hexToBytes(pairBytes),
    ...hexToBytes(curveBytes),
    ...hexToBytes(basePerLiquidityBytes),
    ...hexToBytes(deltaLiquidityBytes),
  ]
  return { bytes, hex: bytesToHex(bytes) }
}

export function encodeRemoveLiquidity(
  useMax: boolean,
  poolId: number,
  deltaLiquidity: BigNumber
): { bytes: number[]; hex: string } {
  const opcode = Instructions.REMOVE_LIQUIDITY
  const firstByte = encodeFirstByte(useMax, opcode)
  if (useMax) return { bytes: [firstByte], hex: bytesToHex([firstByte]) }
  const { amount, decimals } = trailingRunLengthEncode(deltaLiquidity.toString())
  const decimalBytes = encodeSecondByte(0, decimals)
  const poolIdBytes = hexZeroPad(hexlify(poolId), 6)
  const bytes = [firstByte, ...hexToBytes(poolIdBytes), decimalBytes, ...hexToBytes(BigNumber.from(amount)._hex)]
  return { bytes, hex: bytesToHex(bytes) }
}

/* export function encodeAddLiquidity(
  useMax: number,
  poolId: number,
  amount: BigNumber
): { bytes: number[]; hex: string } {
  const opcode = Instructions.ADD_LIQUIDITY
  const pairBytes = hexZeroPad(hexlify(pairId), 2)
  const curveBytes = hexZeroPad(hexlify(curveId), 4)
  const basePerLiquidityBytes = hexZeroPad(basePerLiquidity.toHexString(), 16)
  const deltaLiquidityBytes = hexZeroPad(deltaLiquidity.toHexString(), 16)
  const bytes = [
    ...hexToBytes(hexlify(opcode)),
    ...hexToBytes(pairBytes),
    ...hexToBytes(curveBytes),
    ...hexToBytes(basePerLiquidityBytes),
    ...hexToBytes(deltaLiquidityBytes),
  ]
  return { bytes, hex: bytesToHex(bytes) }
} */

export function decodePoolId(bytes: number[]): string {
  return bytesToHex(bytes)
}
