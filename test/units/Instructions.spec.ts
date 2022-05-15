import hre from 'hardhat'
import { TestInstructions } from 'typechain-types'
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
    const info = data.bytes // removes opcode byte
    expect(result[0]).to.be.hexEqual(bytesToHex(info.slice(1, 21)))
    expect(result[1]).to.be.hexEqual(bytesToHex(info.slice(21)))
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
    const info = data.bytes // removes opcode byte
    expect(result[0]).to.be.eq(parseInt(bytesToHex(info.slice(1, 4))))
    expect(result[1]).to.be.eq(parseInt(bytesToHex(info.slice(4, 8))))
    expect(result[2]).to.be.eq(parseInt(bytesToHex(info.slice(8, 10))))
    expect(result[3]).to.be.eq(parseInt(bytesToHex(info.slice(10))))
  })

  it('testDecodeCreatePool', async function () {
    const pairId = 4
    const curveId = 2 ^ 6
    const basePerLiquidity = BigNumber.from(400)
    const deltaLiquidity = BigNumber.from(1)
    const data = instruct.encodeCreatePool(pairId, curveId, basePerLiquidity, deltaLiquidity)
    const result = await instructions.testDecodeCreatePool(data.hex)
    const info = data.bytes // removes opcode byte
    expect(result[0]).to.be.eq(parseInt(bytesToHex(info.slice(1, 7))))
    expect(result[1]).to.be.eq(parseInt(bytesToHex(info.slice(1, 3))))
    expect(result[2]).to.be.eq(parseInt(bytesToHex(info.slice(3, 7))))
    expect(result[3]).to.be.eq(parseInt(bytesToHex(info.slice(7, 23))))
    expect(result[4]).to.be.eq(parseInt(bytesToHex(info.slice(23))))
  })

  it('testDecodeRemoveLiquidity', async function () {
    const poolId = 8
    const pairId = 0
    const useMax = false
    const deltaLiquidity = BigNumber.from(72)
    const data = instruct.encodeRemoveLiquidity(useMax, poolId, deltaLiquidity)
    const result = await instructions.testDecodeRemoveLiquidity(data.hex)
    expect(result[0]).to.be.eq(useMax ? 1 : 0)
    expect(result[1]).to.be.eq(poolId)
    expect(result[2]).to.be.eq(pairId)
    expect(result[3]._hex).to.be.hexEqual(deltaLiquidity._hex)
  })

  it('testDecodeAddLiquidity', async function () {
    const poolId = 8
    const useMax = false
    const deltaBase = BigNumber.from(300)
    const deltaQuote = BigNumber.from(700)
    const data = instruct.encodeAddLiquidity(useMax, poolId, deltaBase, deltaQuote)
    const result = await instructions.testDecodeAddLiquidity(data.hex)
    await instructions.testDecodeAddLiquidityGas(data.hex)
    expect(result[0]).to.be.eq(useMax ? 1 : 0)
    expect(result[1]).to.be.eq(poolId)
    expect(result[2]._hex).to.be.hexEqual(deltaBase._hex)
    expect(result[3]._hex).to.be.hexEqual(deltaQuote._hex)
  })

  it('testDecodeSwap', async function () {
    const poolId = 8
    const dir = 0
    const useMax = false
    const deltaIn = BigNumber.from(300)
    const deltaOut = BigNumber.from(732)
    const data = instruct.encodeSwapExactTokens(useMax, poolId, deltaIn, deltaOut, dir)
    const result = await instructions.testDecodeSwap(data.hex)
    await instructions.testDecodeSwap(data.hex)
    expect(result[0]).to.be.eq(useMax ? 1 : 0)
    expect(result[1]).to.be.eq(poolId)
    expect(result[2]._hex).to.be.hexEqual(deltaIn._hex)
    expect(result[3]._hex).to.be.hexEqual(deltaOut._hex)
    expect(result[4]).to.be.eq(dir)
  })
})
