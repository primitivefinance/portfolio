import { toBn } from 'evm-bn'
import { BigNumber } from 'ethers'
import { formatEther } from 'ethers/lib/utils'

// --- Fixed Point --- //

const FIXED_X64_DENOMINATOR = BigNumber.from('2').pow(64)

export function floatToFixedX64(value: number): BigNumber {
  return toBn(value.toString()).mul(FIXED_X64_DENOMINATOR).div(toBn('1'))
}

export function fixedX64ToFloat(value: BigNumber): number {
  const hex = value.mul(toBn('1')).div(FIXED_X64_DENOMINATOR)._hex
  const formatted = formatEther(hex)
  return parseFloat(formatted)
}

// --- Bytes & Hex --- //

// Convert a hex string to a bytes array
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
