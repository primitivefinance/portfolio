import hre from 'hardhat'
import { TestInstructions } from '../../typechain-types/test/TestInstructions'
import * as instruct from '../../lib'
import { expect } from 'chai'
import { bytesToHex } from '../../lib'
import { BigNumber } from 'ethers'

describe('Instructions', function () {
  let instructions: TestInstructions

  this.beforeEach(async function () {
    instructions = await (await hre.ethers.getContractFactory('TestInstructions')).deploy()
    await instructions.deployed()
  })

  it('testDecodeCreatePair', async function () {
    const one = '0x0000000000000000000000000000000000000001'
    const two = '0x0000000000000000000000000000000000000002'

    const data = instruct.encodeCreatePair(one, two)
    const result = await instructions.testDecodeCreatePair(data.hex)
    expect(result[0]).to.be.hexEqual(bytesToHex(data.bytes.slice(0, 20)))
    expect(result[1]).to.be.hexEqual(bytesToHex(data.bytes.slice(20)))
  })

  it('testDecodePoolId', async function () {
    const pairId = 4
    const curveId = 2 ^ 6
    const data = instruct.encodePoolId(pairId, curveId)
    const result = await instructions.testDecodePoolId(data.hex)
    expect(result[0]).to.be.eq(parseInt(data.hex))
    expect(result[1]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(0, 2))))
    expect(result[2]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(2))))
  })

  it('testDecodeCreateCurve', async function () {
    const strike = BigNumber.from(50)
    const sigma = 1e4
    const maturity = 200
    const fee = 100
    const data = instruct.encodeCreateCurve(strike, sigma, maturity, fee)
    const result = await instructions.testDecodeCreateCurve(data.hex)
    expect(result[0]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(0, 3))))
    expect(result[1]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(3, 7))))
    expect(result[2]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(7, 9))))
    expect(result[3]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(9))))
  })

  it('testDecodeCreatePool', async function () {
    const pairId = 4
    const curveId = 2 ^ 6
    const basePerLiquidity = BigNumber.from(400)
    const deltaLiquidity = BigNumber.from(1)
    const data = instruct.encodeCreatePool(pairId, curveId, basePerLiquidity, deltaLiquidity)
    const result = await instructions.testDecodeCreatePool(data.hex)
    expect(result[0]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(0, 6))))
    expect(result[1]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(0, 2))))
    expect(result[2]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(2, 6))))
    expect(result[3]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(6, 22))))
    expect(result[4]).to.be.eq(parseInt(bytesToHex(data.bytes.slice(22))))
  })
})
