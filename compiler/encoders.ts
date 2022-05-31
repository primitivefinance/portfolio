// --- Byte Manipulation --- //

// Left shift 4 bits to put into the higher order bits of a byte.
export function encodeHigherBit(value: number): number {
  return value << 4
}

export function decodeHigherBit(value: number): number {
  return value >> 4
}

// Combines a value in higher order bits with lower order bits.
export function encodePackedByte(higherBits: number, lowerBits: number): number {
  return encodeHigherBit(higherBits) | lowerBits
}

export function decodePackedByte(byte: number): { higher: number; lower: number } {
  const higher = decodeHigherBit(byte & 0xf0)
  const lower = byte & 0x0f
  return { higher, lower }
}

// --- Encoding Algorithms --- //

/**
 * Starts at the end of a number and counts zeros up until hitting a non-zero wei.
 * @param float Raw float float as a string.
 * @returns Quantity of trailing zeros.
 */
export function countEndZeros(float: string): number {
  let count: number = 0
  let i = float.length - 1 // start at end element
  if (float[i] != '0') return 0 // If last float isn't a zero, return early.
  while (float[i] == '0') {
    count++
    i--
  }
  return count
}

/**
 * Removes the trailing zeros of a non-hexadecimal wei (e.g. an amount of wei).
 *
 * @param wei Raw wei value as a string to remove trailing zeros of.
 * @param count Amount of trailing zeroes.
 * @returns Substring of `wei` starting at the last non-zero value.
 */
export function removeTrailingZeroes(wei: string, count: number): string {
  return wei.substring(0, wei.length - count)
}

/**
 *
 * @param wei Raw non-hexadecimal wei (e.g. amount of wei) to encode.
 * @returns amount Encoded `wei` as a hexadecimal.
 * @returns decimals Amount of trailing zeros that were trimmed from the `wei`.
 */
export function trailingRunLengthEncode(wei: string): { amount: string; decimals: number } {
  const decimals = countEndZeros(wei)
  const amount = removeTrailingZeroes(wei, decimals)
  return { amount, decimals }
}
