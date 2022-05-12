import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'
import { TestNewton } from '../../typechain-types/test/TestNewton'
import { toBn } from 'evm-bn'
import { formatEther } from 'ethers/lib/utils'

import { floatToFixedX64, fixedX64ToFloat } from '../../lib/units'

describe('Newton', function () {
  let newton: TestNewton

  this.beforeEach(async function () {
    newton = (await (await ethers.getContractFactory('TestNewton')).deploy()) as TestNewton
  })

  it('Converts numbers to FixedPointX64 and back', async function () {
    const start = 2
    const fixed = floatToFixedX64(2)
    const number = fixedX64ToFloat(fixed)
    expect(start).to.be.equal(number)
    expect(fixed._hex).to.be.equal(toBn('2').shl(64).div(toBn('1'))._hex)
  })

  describe('Newton Methods', function () {
    it('Runs newtons method successfully', async function () {
      const initial = -4
      await newton.testComputeOutput(floatToFixedX64(initial))
      await newton.testCompute(floatToFixedX64(initial))
      await newton.testComputeTen(floatToFixedX64(initial))
      const result = await newton.result()
      const parsed = fixedX64ToFloat(result)
      const expected = -1
      expect(Math.round(parsed * 100) / 100).to.be.equal(expected)
    })
  })
})
