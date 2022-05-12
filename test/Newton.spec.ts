import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'
import { TestNewton } from '../typechain-types/test/TestNewton'
import { toBn } from 'evm-bn'
import { formatEther } from 'ethers/lib/utils'

const FIXED_X64_DENOMINATOR = BigNumber.from('2').pow(64)

function numberToFixedX64(value: number): BigNumber {
  return toBn(value.toString()).mul(FIXED_X64_DENOMINATOR).div(toBn('1'))
  /* if (value < 0) {
    return toBn(value.toString()).mul(FIXED_X64_DENOMINATOR).div(toBn('1'))
  } else {
    return toBn(value.toString()).shl(64).div(toBn('1'))
  } */
}

function fixedX64ToNumber(value: BigNumber): number {
  const hex = value.mul(toBn('1')).div(FIXED_X64_DENOMINATOR)._hex
  const formatted = formatEther(hex)
  return parseFloat(formatted)
  /*  if (value.lt(0)) {
    const hex = value.mul(toBn('1')).div(FIXED_X64_DENOMINATOR)._hex
    const formatted = formatEther(hex)
    return parseFloat(formatted)
  } else {
    const hex = value.shr(64)._hex
    return parseFloat(hex)
  } */
}

describe('Newton', function () {
  let newton: TestNewton

  this.beforeEach(async function () {
    newton = (await (await ethers.getContractFactory('TestNewton')).deploy()) as TestNewton
  })

  it('Converts numbers to FixedPointX64 and back', async function () {
    const start = 2
    const fixed = numberToFixedX64(2)
    const number = fixedX64ToNumber(fixed)
    expect(start).to.be.equal(number)
    expect(fixed._hex).to.be.equal(toBn('2').shl(64).div(toBn('1'))._hex)
  })

  describe('Newton Methods', function () {
    it('Runs newtons method successfully', async function () {
      const initial = -4
      await newton.testComputeOutput(numberToFixedX64(initial))
      await newton.testCompute(numberToFixedX64(initial))
      await newton.testComputeTen(numberToFixedX64(initial))
      const result = await newton.result()
      const parsed = fixedX64ToNumber(result)
      const expected = -1
      expect(Math.round(parsed * 100) / 100).to.be.equal(expected)
    })
  })
})
